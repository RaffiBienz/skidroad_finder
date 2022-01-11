FROM python:3.8

COPY . /skidroad_finder
RUN pip install -r /skidroad_finder/src/requirements.txt

RUN apt update && apt-get install -y r-base libgdal-dev libproj-dev libgeos++-dev libudunits2-dev
RUN Rscript /skidroad_finder/src/requirements.R

WORKDIR /skidroad_finder/
ENTRYPOINT Rscript src/main.R