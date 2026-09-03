FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["SafeVoice.API/SafeVoice.API.csproj", "SafeVoice.API/"]
COPY ["SafeVoice.Core/SafeVoice.Core.csproj", "SafeVoice.Core/"]
COPY ["SafeVoice.Infrastructure/SafeVoice.Infrastructure.csproj", "SafeVoice.Infrastructure/"]
RUN dotnet restore "SafeVoice.API/SafeVoice.API.csproj"
COPY . .
RUN dotnet publish "SafeVoice.API/SafeVoice.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "SafeVoice.API.dll"]
