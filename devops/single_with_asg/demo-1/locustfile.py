# Locust stress tests an IP address
#
# Start instructions:
# locust --host=http://<ELB-URL>
#
# Run instructions:
# Go to http://127.0.0.1:8089/
# This will allow you to set the number of users to simulate and the hatch rate
# Click "Start swarming"

from locust import HttpLocust, TaskSet
import resource
resource.setrlimit(resource.RLIMIT_NOFILE, (10240, 9223372036854775807))

def index(l):
	l.client.get("/")

class UserBehavior(TaskSet):
	tasks = {index: 1} # We can define as many tasks as needed
	                   # Format is {name: number of reps}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    min_wait = 5000 # ms (time between tasks)
    max_wait = 9000 # ms (time between tasks)