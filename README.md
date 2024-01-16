# Full-Stack Skeleton Project

This project is created to help with the initial creation and setup of a full-stack application using Django REST, PostgreSQL, ReactJS + Typescript @vite, and Docker. 

The docker-compose setup for development uses the built in django and node servers to make use of their hot-refresh functionality during the development process.

The production setup takes care of creating and running all migrations, creates the superuser, builds the frontend for production and starts up an `nginx` web server.

Both the python and the node base images use the `alpine` distribution of linux to keep the image sizes to the minimum.

---

# Set Up Your Project

To set up a full-stack project using this skeleton, you need to take the followig steps:

1. Prerequisites: Make sure you have Python and [Docker](https://docs.docker.com/get-docker/) locally on your computer.
2. Download the project and copy the `full-stack` folder as well as the two docker-compose files into your newly created project folder.
3. While still in the root folder, create a virtual Python environment with: `python3 -m venv venv`. This will only be needed for the initial setup, we will delete it later.
4. Activate the virtual environment: `source venv/bin/activate`
5. Install Django: `pip install 'django<5'`
6. `cd full-stack/backend`
7. Create the django project: `django-admin startproject django_project . ` - (Don't miss the dot, it has to be in the same folder for the Dockerfiles! If you want to give a name other than `django_project`, you have to update the `entrypoint.sh` file too!)
8. Add the necessary Python packages: `pip install decouple whitenoise psycopg2-binary djangorestframework django-cors-headers`
9. Create the requirements.txt file: `pip freeze > requirements.txt`
10. Create a `.env.dev` and a `.env.prod` file in the `full-stack/backend` folder and place in the following environment variables - filled in with your own (secret) details:

    `.env.dev`
    ```
    - SECRET_KEY=your-secret-django-key
    - DEBUG=True
    - DEVELOPMENT=1

    - POSTGRES_DB=db
    - POSTGRES_USER=db-username
    - POSTGRES_PASSWORD=db-password
    ```

    `.env.prod`
    ```
    - SECRET_KEY=your-secret-django-key
    - DEBUG=False

    - POSTGRES_DB=db
    - POSTGRES_USER=db-username
    - POSTGRES_PASSWORD=db-password

    - DJANGO_SUPERUSER_USERNAME=superuser-username
    - DJANGO_SUPERUSER_EMAIL=superuser-email
    - DJANGO_SUPERUSER_PASSWORD=superuser-password
    ```

11. Update the `settings.py` file with the followings:
    ```python
    from decouple import Config
    import os

    # Get the path to the directory of the current file
    current_dir = os.path.dirname(os.path.abspath(__file__))

    # Get the current environment from the DJANGO_ENV variable
    django_env = os.getenv('DJANGO_ENV', 'development')

    # Load the appropriate .env file
    env_file = os.path.join(current_dir, f'.env.{django_env}')
    config = Config(env_file)

    ###

    SECRET_KEY = config("SECRET_KEY", cast=str)

    ###

    DEBUG = config("DEBUG", cast=bool, default=False)

    ALLOWED_HOSTS = ['0.0.0.0', 'localhost']

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

    # Comment out or delete the default setting. We use postgres for both 
    # development and production.
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

12. `cd` into the `full-stack` folder and create a React + Typescript + @vite project: `npm create vite@latest` or with the [latest recommendation by @vite](https://vitejs.dev/guide/), name it `frontend`, choose the React + SWC and Typescript options.
13. Move the content of the `for-frontend` folder into your new `frontend` folder. You can now delete the original downloaded folder, you won't need it anymore.
14. In your new `vite.config.ts` file, add the server configuration to `defineConfig`:
    ```js
    export default defineConfig({
        plugins: [react()],
        // add this server configuration:
        server: {
            host: true,
        },
    });
    ```

---

# Docker

## Run the project in DEV mode

* For the first time, run the project with `docker-compose -p dev_your_app -f docker-compose.dev.yml up --build`. This will build all the necessary docker images and will also run the docker container. 
    - The forntend will be available on `http://localhost:5173`.
    - The backend server will be running on `http://localhost:8000`.
    Both servers refresh whenever the source code gets changed.
* To set up the database, you first need to apply the migrations: `docker exec -it backend python manage.py migrate`
* Then, create a superuser: `docker exec -it backend python manage.py createsuperuser`
* If you need to install a new package, Pillow in this case: `docker exec -it backend pip install Pillow`
* After each install, you have to update the requirements.txt: `docker exec -it backend pip freeze > requirements.txt.` This will overwrite your existing `requirements.txt` file with the current state of installed packages in the container.
* After each install, you also have to rebuild the Docker image using this command: `docker-compose -p dev_your_app -f docker-compose.dev.yml up --build && docker image prune -f`. The second, `docker image prune -f` command is used to remove the old image which otherwise would stay there, dangling. Please note however, that this command will remove all other dangling images in case there was any (although this is not a bad thing :)
* Whenever you modify the database models, don't forget to migrate the changes with the `docker exec -it backend python manage.py makemigrations` and the `docker exec -it backend python manage.py migrate` commands.

* To stop the container: `CTRL + C`.
* To start up the container again, run `docker-compose -p dev_your_app -f docker-compose.dev.yml up`.

* To destroy the container: `docker-compose -p dev_your_app -f docker-compose.dev.yml down`
* To destroy all the static files and database, run `docker volume prune`.

* If docker-compose is running as expected, you can safely remove your initial `venv`:
`rm -rf venv`

## Run the project in PRODUCTION mode

* For the first time, run the project with `docker-compose -p prod_your_app -f docker-compose.prod.yml up --build`. This will build all the necessary docker images, create and run all the migrations, create a superuser and will also start up the docker container. 
    - The full-stack app will be available locally on `http://localhost:80`.
    - The backend server will be available without the static files on `http://localhost:8000`.
* To stop the container: `CTRL + C`.
* To start up the container again, run `docker-compose -p prod_your_app -f docker-compose.prod.yml up`.
* To destroy the container: `docker-compose -p prod_your_app -f docker-compose.prod.yml down`
* To destroy all the static files and database, run `docker volume prune`.


---
---

**Enjoy :)** Let me know if you found it usefule or if you could improve it!

---
---