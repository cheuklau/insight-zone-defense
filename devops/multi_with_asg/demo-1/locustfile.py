# Locust configuration file

from locust import HttpLocust, TaskSet
import resource

# Resolves a limit error
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