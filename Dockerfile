FROM python:3.8

COPY . /road_finder
RUN pip install -r /road_finder/src/requirements.txt

RUN apt update && apt-get install -y r-base libgdal-dev libproj-dev libgeos++-dev libudunits2-dev
RUN Rscript /road_finder/src/requirements.R

WORKDIR /road_finder/
CMD /bin/bash