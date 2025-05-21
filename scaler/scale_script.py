from kubernetes import client, config
import requests
import time
import os
import datetime

PROMETHEUS_URL = os.getenv('PROMETHEUS_URL', 'http://prometheus-operated.monitoring.svc.cluster.local:9090')
PROMQL_QUERY = 'lavinmq_queue_messages_ready'
DEPLOYMENT_NAME = "lavinmq-consumer"
NAMESPACE = "lavinmq"
if_hundred = False
def get_queue_length():
    try:
        resp = requests.get(
            f"{PROMETHEUS_URL}/api/v1/query",
            params={"query": PROMQL_QUERY}
        )
        result = resp.json()
        value = float(result['data']['result'][0]['value'][1])
        return value
    except Exception as e:
        print("Prometheus sorgusunda hata:", e)
        return None

def scale_deployment(replica_count):
    apps_v1 = client.AppsV1Api()

    # Deployment nesnesini al
    deployment = apps_v1.read_namespaced_deployment(name=DEPLOYMENT_NAME, namespace=NAMESPACE)

    # Replica sayısını değiştir
    deployment.spec.replicas = replica_count

    # Güncelle
    apps_v1.patch_namespaced_deployment(
        name=DEPLOYMENT_NAME,
        namespace=NAMESPACE,
        body=deployment
    )
    print(f"Deployment {DEPLOYMENT_NAME} {replica_count} replica ile güncellendi.")

if __name__ == "__main__":
    config.load_incluster_config()

    while True:
        msg_count = get_queue_length()
        if msg_count >= 100:
            print(f"{msg_count} job var. 25 pod başlatılıyor. {datetime.datetime.now()}")
            scale_deployment(25)
            if_hundred = True
        elif if_hundred and msg_count == 0:
            print(f"Kuyruk boş. {datetime.datetime.now()}")
            scale_deployment(0)
            if_hundred = False # Added controller to prevent re-scaling when the message count is 0 for 5 minutes
        else:
            print(f"{msg_count} job var. Eşik altında.")
        time.sleep(5)
