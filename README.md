# Full-Stack Skeleton Project

This project is created to help with the initial creation and setup of a full-stack application using Django REST, PostgreSQL, ReactJS + Typescript @vite, and Docker. 


---

# Set Up Your Project

To set up a full-stack project using this skeleton, you need to take the followig steps:

1. You will need Docker to utilise the project's docker configuration. https://docs.docker.com/get-docker/
2. Copy and unpack the project into a new, local folder.
3. Create a virtual Python environment with: `python3 -m venv venv`
4. Activate the virtual environment: `source venv/bin/activate`
5. Install Django: `pip install 'django<5'`
6. Create the django project: `django-admin startproject my_project_name . ` - (Don't miss the dot, it has to be in the same folder for the Dockerfiles!)
7. Add the necessary Python packages: `pip install decouple whitenoise psycopg2-binary djangorestframework django-cors-headers`
8. Create the requirements.txt file: `pip freeze > requirements.txt`
9. Create a `.env` file in the `full-stack/backend` folder and place in the following environment variables - filled in with your own (secret) details:
    - SECRET_KEY=your-secret-django-key
    - DEBUG=True
    - DEVELOPMENT=1

    - POSTGRES_DB=expense-app-db
    - POSTGRES_USER=db-username
    - POSTGRES_PASSWORD=db-password

    - DJANGO_SUPERUSER_USERNAME=superuser-username
    - DJANGO_SUPERUSER_EMAIL=superuser-email
    - DJANGO_SUPERUSER_PASSWORD=superuser-password

10. Update the `settings.py` file with the followings:
    ```python
    from decouple import config

    ###

    SECRET_KEY = config("SECRET_KEY", cast=str)

    ###

    DEBUG = config("DEBUG", cast=bool, default=False)

    ALLOWED_HOSTS = ['0.0.0.0']

    CORS_ALLOWED_ORIGINS = [
        "http://localhost",
        "http://127.0.0.1",
        "http://0.0.0.0",
    ]

    CORS_ALLOWED_CREDENTIALS = True

    ###

    INSTALLED_APPS = [
        
        ...
        'rest_framework', # new
        'corsheaders', # new
        
        'custom_commands', # new
    ]

    ###

    MIDDLEWARE = [
        'corsheaders.middleware.CorsMiddleware', # new
        'django.middleware.security.SecurityMiddleware',
        'whitenoise.middleware.WhiteNoiseMiddleware', # new
        ...
    ]

    # Comment Out the default setting.
    # DATABASES = {
    #     'default': {
    #         'ENGINE': 'django.db.backends.sqlite3',
    #         'NAME': BASE_DIR / 'db.sqlite3',
    #     }
    # }

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': config("POSTGRES_DB", cast=str),
            'USER': config("POSTGRES_USER", cast=str),
            'PASSWORD': config("POSTGRES_PASSWORD", cast=str),
            'HOST': 'db', # set in docker-compose.yml
            'PORT': '5432' # default postgres port
        }
    }

    ###

    STATIC_ROOT = BASE_DIR / 'staticfiles' # new
    WHITENOISE_STATIC_ROOT = BASE_DIR / 'staticfiles' # new

    ```

11. Cd into the `full-stack` folder and create a React + Typescript + @vite project: `npm create vite@latest` or with the [latest recommendation by @vite](https://vitejs.dev/guide/), name it `frontend`, choose the React + SWR and Typescript options.
12. Move the `Dockerfile.frontend` file into the `frontend` folder and rename it `Dockerfile`.

---

# Docker

## Build and run your project

* For the first time, run `docker-compose up --build`. This will build all the necessary docker images and will also run the docker container. 
    - The full-stack app will be available locally on `0.0.0.0:80`.
    - The backend server will be available without the static files on `0.0.0.0:8000`.
* To stop and destroy the container, run `docker-compose down`.
* To destroy all the static files and database, run `docker volume prune`.
* To start up the project again, run `docker-compose up`.

## Docker resources

* https://docs.docker.com/
* https://www.youtube.com/watch?v=8VHheCkw-7k
* https://www.youtube.com/watch?v=oX5ElI-koww