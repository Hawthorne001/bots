FROM python:3.13.0b4-slim as python-base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

FROM python-base as builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential
RUN curl -sSL https://install.python-poetry.org | python3 -

WORKDIR $PYSETUP_PATH
COPY ./poetry.lock ./pyproject.toml ./
RUN poetry install --only main

FROM builder-base as test

COPY --from=builder-base $VENV_PATH $VENV_PATH

COPY . /app
WORKDIR /app

RUN poetry install --only dev
RUN pip install --upgrade nox
RUN poetry run nox

FROM python-base as runtime

COPY --from=builder-base $VENV_PATH $VENV_PATH

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY ./bots /app/bots
WORKDIR /app

ENTRYPOINT /docker-entrypoint.sh $0 $@

CMD [ "python", "-m", "bots.__main__"]
