pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

contract ModernaVaccine{

    struct TemperatureReading{
        int timestamp; // Solidity does not support the long type
        string sensorId;
        int temperature; // Fixed point numbers are not fully supported by Solidity yet. They can be declared, but cannot be assigned to or from. So, for example, a temperature value of 37.5 will be stored as 375.
    }
    
    struct TemperatureWarning{
        int timestamp; 
        string sensorId;
        int temperature;
    }   
    
    // In this smart contract, variables are used for storing the detected complex events 
    TemperatureReading[] private temperatureReadingEvents;
    TemperatureWarning[] private temperatureWarningEvents;

    constructor() public {} // ¿El constructor se quedara vacio? Si no tenemos nada que hacer cuando se invoque se puede eliminar
    
    function registerTemperatureReading(int receivedTimestamp, string memory receivedSensorId, int receivedTemperature) public{
        
        temperatureReadingEvents.push(TemperatureReading({timestamp : receivedTimestamp, sensorId : receivedSensorId, temperature : receivedTemperature}));
        detectTemperatureWarning(receivedTimestamp, receivedSensorId, receivedTemperature);
        
    }   
    
    function detectTemperatureWarning(int receivedTimestamp, string memory receivedSensorId, int receivedTemperature) private{ // aqui llegaria el evento simple creado en la funcion anterior
        
        if(receivedTemperature < -25 || receivedTemperature > -15){ // no habria bucle for porque la comprobacion se haria unicamente para el evento simple recibido por parametro
            temperatureWarningEvents.push(TemperatureWarning({timestamp : receivedTimestamp, sensorId : receivedSensorId, temperature : receivedTemperature})); 
        }
    }
    
    
    function getTemperatureReadings() public view returns(TemperatureReading[] memory) { // poner una funcion Get por cada uno de los tipos de eventos (TemperatureReading, TemperatureWarning, TemperatureWarningStatistic y TemperatureAlert)
        // Devolver todos los eventos simples de tipo TemperatureReading, como si hiceramos un select *, SIN agrupar por contenedor.
        return temperatureReadingEvents;
    }
    
    function getTemperatureWarnings() public view returns(TemperatureWarning[] memory) { // poner una funcion Get por cada uno de los tipos de eventos (TemperatureReading, TemperatureWarning, TemperatureWarningStatistic y TemperatureAlert)
        
        // Devolver todos los eventos simples de tipo TemperatureReading, como si hiceramos un select *, SIN agrupar por contenedor. 
        return temperatureWarningEvents;
    }
 
}

