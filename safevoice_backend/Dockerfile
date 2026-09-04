FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
WORKDIR /app
COPY publish/ .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
ENTRYPOINT ["dotnet", "SafeVoice.API.dll"]
