pragma solidity ^0.4.23;

// @author: Ghilia Weldesselasie
// An experiment in using contracts as public DBs on the blockchain

contract Database {

    address public owner;

    constructor() public {
      owner = msg.sender;
    }
    
    function withdraw() public {
      require(msg.sender == owner);
      owner.transfer(address(this).balance);
    }

    // Here the &#39;Table&#39; event is treated as an SQL table
    // Each property is indexed and can be retrieved easily via web3.js
    event Table(uint256 indexed _row, bytes32 indexed _column, bytes32 indexed _value);
    /*
    _______
    |||Table|||
    -----------
    | row |    _column    |    _column2   |
    |  1  |    _value     |    _value     |
    |  2  |    _value     |    _value     |
    |  3  |    _value     |    _value     |
    */

    function put(uint256 _row, string _column, string _value) public {
        emit Table(_row, keccak256(_column), keccak256(_value));
    }
}