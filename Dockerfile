FROM centos:latest

MAINTAINER Ilia Shakitko <ilia.shakitko@accenture.com>

# Java Env Variables
ENV JAVA_VERSION=1.8.0_152
ENV JAVA_TARBALL=server-jre-8u152-linux-x64.tar.gz
ENV JAVA_HOME=/opt/java/jdk${JAVA_VERSION}

# Making MyBatis version an argument (in case a snapshot version needs to be built)
# --------------------
ARG VERSION="3.3.2-SNAPSHOT"
ARG REPOSITORY="snapshots"
ARG PROTOCOL="https"
ARG USERNAME="##USE_ARGUMENTS##"
ARG PASSWORD="##USE_ARGUMENTS##"
ARG HOSTNAME="##USE_ARGUMENTS##"

RUN yum -y install net-utils ldap-utils htop telnet nc \
    git \
    wget \
    tar \
    zip \
    unzip \
    openldap-clients \
    openssl \
    python-pip \
    libxslt && \
    yum clean all

# Install Java
RUN wget -q --no-check-certificate --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
            http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/${JAVA_TARBALL} && \
          mkdir -p /opt/java && \
              tar -xzf /tmp/${JAVA_TARBALL} -C /opt/java/ && \
            alternatives --install /usr/bin/java java /opt/java/jdk${JAVA_VERSION}/bin/java 100 && \
                rm -rf /tmp/* && rm -rf /var/log/*

# Adding (downloading) the archive
# --------------------
# ADD https://github.com/mybatis/migrations/releases/download/mybatis-migrations-"$VERSION"/mybatis-migrations-"$VERSION".zip /tmp/mybatis-migrations-"$VERSION".zip
ADD https://oss.sonatype.org/content/repositories/snapshots/org/mybatis/mybatis-migrations/3.3.2-SNAPSHOT/mybatis-migrations-3.3.2-20180118.183255-24-bundle.zip /tmp/mybatis-migrations-"$VERSION".zip


# Will store the binaries in "opt" for optional software
# --------------------
RUN mkdir -p /opt


# Unzipping, creating symlink to the migrations binaries
# --------------------
RUN unzip /tmp/mybatis-migrations-"$VERSION".zip -d /opt/ && \
	rm -f /tmp/mybatis-migrations-"$VERSION".zip && \
	chmod +x /opt/mybatis-migrations-"$VERSION"/bin/migrate && \
	ln -s /opt/mybatis-migrations-"$VERSION" /opt/mybatis-migrations


# Creating database workspace folders
# --------------------
RUN mkdir -p /migration/drivers && \
	mkdir -p /migration/environments && \
	mkdir -p /migration/scripts

# Add oracle jdbc driver
# --------------------
ADD "$PROTOCOL"://"$USERNAME":"$PASSWORD"@"$HOSTNAME"/nexus/service/local/repositories/thirdparty/content/com/oracle/ojdbc7/12.1.0.1/ojdbc7-12.1.0.1.jar /migration/drivers/ojdbc7.jar


# Add script that builds migration environment file and launches the binary
ADD sql /migration/scripts
ADD container-scripts/migrate.sh /opt/migrate.sh
RUN chmod +x /opt/migrate.sh


# Setting up working directory to the folder with migration database (scripts, drivers, environments)
# --------------------
WORKDIR /migration

# Execute migrate.sh on "docker run"
# --------------------
ENTRYPOINT ["/opt/migrate.sh"]
