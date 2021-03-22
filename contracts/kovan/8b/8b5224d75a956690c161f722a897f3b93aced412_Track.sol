/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.7.1;
/**
 * Cexar SAS
 **/

contract Track {
    
    /* 
     * El numero de posision
     */
    uint256 public position_number;

    /*
     * Evento que se dispara cuando hay un cambio de posicion
     */
    event PositionChange(
        int256 lat,
        int256 lon
    );


    /*
     * Estructura donde se muestra la ultima ubicacion
     */
    struct LatLon {
        int256 lat;
        int256 lon;
        uint256 blocknumber;
    }


    mapping(uint256=>LatLon) history;

    /* Consulta la posicion actual */
    function actualPosition() external view returns(int256 lat, int256 lon, uint256 blocknumber) {
        lat = history[position_number].lat;
        lon = history[position_number].lon;
        blocknumber = history[position_number].blocknumber;
    }

    /* Consulta una posicion historica */
    function historicalPosition(uint256 number) external view returns(int256 lat, int256 lon, uint256 blocknumber) {
        lat = history[number].lat;
        lon = history[number].lon;
        blocknumber = history[number].blocknumber;
    }

    /* Cambia la posicion actual */
    function setPosition(int256 lat, int256 lon) external {
        position_number = position_number + 1;
        history[position_number].lat = lat;
        history[position_number].lon = lon;
        history[position_number].blocknumber = block.number;
        emit PositionChange(lat,lon);
    }

}