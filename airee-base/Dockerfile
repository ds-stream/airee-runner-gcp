# Latest LTS version
FROM apache/airflow:2.4.3
ENV AIRFLOW_HOME /opt/airflow
USER root
RUN chown -R airflow:root ${AIRFLOW_HOME}
USER airflow
RUN pip install --upgrade pip
RUN pip install 'apache-airflow[google,postgres]==2.4.3'
RUN pip install 'plyvel==1.5.0' 