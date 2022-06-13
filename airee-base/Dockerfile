# Latest LTS version
FROM apache/airflow:2.2.5
ENV AIRFLOW_HOME /opt/airflow
USER root
RUN chown -R airflow:root ${AIRFLOW_HOME}
USER airflow
RUN pip install --upgrade pip
RUN pip install 'apache-airflow[google,postgres]==2.2.5'
RUN pip install 'plyvel==1.4.0'