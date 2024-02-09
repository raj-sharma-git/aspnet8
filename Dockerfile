FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
EXPOSE 2222
EXPOSE 8080
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["OrleansURLShortener.csproj", "."]
RUN dotnet restore "./././OrleansURLShortener.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./OrleansURLShortener.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./OrleansURLShortener.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app

COPY init_container.sh /app/
COPY sshd_config /etc/ssh/

# Start and enable SSH
RUN apt-get update \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd \
    && chmod u+x /app/init_container.sh

COPY --from=publish /app/publish .
ENTRYPOINT ["/app/init_container.sh"]