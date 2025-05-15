import pika
import os
import time

lavinmq_service = os.getenv('LAVINMQ_SERVICE', 'lavinmq')


QUEUE_NAME = 'job_queue'

def connect_to_lavinmq():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=lavinmq_service, port=5672))
    channel = connection.channel()
    return channel

def process_job(job):
    print(f"Job {job} is being processed...")
    time.sleep(5)  

def callback(ch, method, properties, body):
    job = body.decode()
    process_job(job)
    ch.basic_ack(delivery_tag=method.delivery_tag)

def start_consuming():
    channel = connect_to_lavinmq()
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=callback)
    print('Job processing started. Checking the queue...')
    channel.start_consuming()

if __name__ == '__main__':
    start_consuming()

