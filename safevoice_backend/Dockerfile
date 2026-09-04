FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src

# Copy project files first for layer caching
COPY ["SafeVoice.API/SafeVoice.API.csproj", "SafeVoice.API/"]
COPY ["SafeVoice.Core/SafeVoice.Core.csproj", "SafeVoice.Core/"]
COPY ["SafeVoice.Infrastructure/SafeVoice.Infrastructure.csproj", "SafeVoice.Infrastructure/"]
COPY ["SafeVoice.Tests/SafeVoice.Tests.csproj", "SafeVoice.Tests/"]

# Restore with limited parallelism to avoid OOM on free tier
RUN dotnet restore "SafeVoice.API/SafeVoice.API.csproj" \
    --runtime linux-musl-x64 \
    -p:PublishReadyToRun=false

# Copy everything else
COPY . .

# Publish — single-threaded to stay within 512MB RAM
RUN dotnet publish "SafeVoice.API/SafeVoice.API.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore \
    --runtime linux-musl-x64 \
    --self-contained false \
    -p:PublishReadyToRun=false \
    -p:TieredCompilation=false \
    /maxcpucount:1

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "SafeVoice.API.dll"]
