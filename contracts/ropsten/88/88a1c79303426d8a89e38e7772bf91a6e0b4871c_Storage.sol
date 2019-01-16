pragma solidity ^0.5.2;


contract Storage {

    uint[] private _numberStorage;

    event AddedNewNumber(uint position);
    event EventOnNumber(uint position);

    function addNumber(uint newNumber) public returns (uint) {
        _numberStorage.push(newNumber);

        uint numberPosition = _numberStorage.length;

        emit AddedNewNumber(numberPosition);
        emit EventOnNumber(numberPosition);
        return numberPosition;
    }

    function getNumberCount() public returns (uint) {
        uint numberPosition = _numberStorage.length;
        emit EventOnNumber(numberPosition);
        return _numberStorage.length;
    }

    function getNumber(uint position) public returns (uint) {
        uint numberPosition = _numberStorage.length;
        emit EventOnNumber(numberPosition);
        return _numberStorage[position];
    }

}