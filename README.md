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
8. Add the necessary Python packages: `pip install python-dotenv whitenoise psycopg2-binary djangorestframework django-cors-headers`
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

    - FRONTEND_URL_DEV=http://localhost:5173
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

    - FRONTEND_URL=http://localhost
    ```

11. Update the `settings.py` file with the followings:

    ```py
    from dotenv import load_dotenv
    import os

   # The .env file will only be loaded if the project is used without Docker.
    # If Docker is used, the DJANGO_ENV environment variable will be loaded from
    # the docker-compose.dev.yml or docker-compose.prod.yml files.
    load_dotenv(os.path.join(BASE_DIR, '.env'))

    # Check the DJANGO_ENV environment variable
    DJANGO_ENV = os.getenv('DJANGO_ENV')

    print('Environment: ', os.getenv('DJANGO_ENV'), '\n', 'BASE_DIR: ', BASE_DIR, '\n')
    if DJANGO_ENV == 'development':
        # Load the development .env file
        load_dotenv(os.path.join(BASE_DIR, '.env.dev'))
    else:
        # Load the production .env file
        load_dotenv(os.path.join(BASE_DIR, '.env.prod'))


    ###

    SECRET_KEY = os.getenv("SECRET_KEY")

    ###

    DEBUG = os.getenv("DEBUG", default=False)

    ALLOWED_HOSTS = ['0.0.0.0', 'localhost']

    # Allow CORS for the frontend
    CORS_ALLOWED_ORIGINS = [
        os.getenv("FRONTEND_URL_DEV", ""),
        os.getenv("FRONTEND_URL", "")
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
            'NAME': os.getenv("POSTGRES_DB"),
            'USER': os.getenv("POSTGRES_USER"),
            'PASSWORD': os.getenv("POSTGRES_PASSWORD"),
            'HOST': 'db', # set in docker-compose.yml
            'PORT': '5432' # default postgres port
        }
    }

    ###

    STATIC_ROOT = BASE_DIR / 'staticfiles' # new
    WHITENOISE_STATIC_ROOT = BASE_DIR / 'staticfiles' # new

    ```

12. `cd` into the `full-stack` folder and create a React + Typescript + @vite project: `npm create vite@latest` or with the [latest recommendation by @vite](https://vitejs.dev/guide/), name it `frontend`, choose the React + SWC and Typescript options.
13. Install `dotenv` with `npm install dotenv`.
14. Move the content of the `for-frontend` folder into your new `frontend` folder. You can now delete the original downloaded folder, you won't need it anymore.
15. In your new `vite.config.ts` file, add the server configuration to `defineConfig`:
    ```js
    import { defineConfig } from 'vite';
    import react from '@vitejs/plugin-react-swc';
    import dotenv from 'dotenv';

    // Load environment variables
    dotenv.config();

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
