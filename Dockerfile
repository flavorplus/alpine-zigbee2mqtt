FROM node:16.13-alpine

RUN apk add --no-cache git python3 make && \
    wget -q http://musl.cc/armv6-linux-musleabihf-cross.tgz && \
    mkdir -p /usr/xcc && \
    tar -C /usr/xcc -xvf armv6-linux-musleabihf-cross.tgz && \
    rm armv6-linux-musleabihf-cross.tgz


WORKDIR /app

COPY ./zigbee2mqtt/npm-shrinkwrap.json ./zigbee2mqtt/tsconfig.json ./
COPY ./zigbee2mqtt/package.json ./zigbee2mqtt/index.js ./
COPY ./zigbee2mqtt/lib ./lib

RUN mkdir /app/output
COPY ./zigbee2mqtt/LICENSE ./zigbee2mqtt/data/configuration.yaml /app/output/
COPY ./zigbee2mqtt/package.json ./zigbee2mqtt/index.js /app/output/


ENV TOOL_PREFIX="armv6-linux-musleabihf"
ENV AS="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-as"
ENV CPP="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-cpp"
ENV LD="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-ld"
ENV FC="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-gfortran"
ENV CC="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-gcc"
ENV CXX="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-g++"
ENV AR="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-ar"
ENV RANLIB="/usr/xcc/${TOOL_PREFIX}-cross/bin/${TOOL_PREFIX}-ranlib"
ENV LINK="${CXX}"
ENV CCFLAGS="-march=armv6j -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
ENV CFLAGS="-march=armv6j -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
ENV CXXFLAGS="-march=armv6j -mfpu=vfp -mfloat-abi=hard -DUSE_EABI_HARDFLOAT"
ENV OPENSSL_armcap=6
ENV GYPFLAGS="-Darmeabi=hard -Dv8_use_arm_eabi_hardfloat=true -Dv8_can_use_vfp3_instructions=false -Dv8_can_use_vfp2_instructions=true -Darm7=0 -Darm_vfp=vfp"
ENV GYP_CROSSCOMPILE=1
ENV GYP_DEFINES="target_arch=arm arm_float_abi=hard"
ENV VFP3=off
ENV VFP2=on
ENV CROSS_COMPILE="${TOOL_PREFIX}-"
ENV npm_config_arch="arm"


RUN npm ci --no-audit --no-optional --no-update-notifier && \
    npm run build && \
    rm -rf node_modules && \
    npm ci --production --no-audit --no-optional --no-update-notifier

ARG COMMIT
RUN echo "$COMMIT" > dist/.hash

RUN cp -r ./node_modules /app/output/node_modules && \
    cp -r ./dist /app/output/dist

RUN tar -czf zigbee2mqtt.tar.gz /app/output/*

CMD [ "/bin/sh"]