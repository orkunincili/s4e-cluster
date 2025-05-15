import pika
import os
import time
lavinmq_service = os.getenv('LAVINMQ_SERVICE', 'lavinmq')
connection = pika.BlockingConnection(pika.ConnectionParameters(host=lavinmq_service, port=5672))
channel = connection.channel()

queue_name = 'job_queue'
channel.queue_declare(queue=queue_name)

def publish_jobs():
    for i in range(100):
        job_message = f"Job {i+1}"
        channel.basic_publish(exchange='',
                              routing_key=queue_name,
                              body=job_message)
        print(f"Job {i+1} sent.")
        time.sleep(0.3)

try:
    print("Adding 100 jobs...")
    publish_jobs()
    print("100 jobs added successfully.")
except KeyboardInterrupt:
    print("Script interrupted.")
finally:
    connection.close()

