// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract McTestingContract {

    uint8 public constant SOME_CONST = 100;
    
    uint256 public counter;
    mapping(uint256 =>  address) private someMapping;

    constructor()
    public
    {
        counter = 0;
    }

    function doNothing() pure public {

    }

    function doNothingReadParameter(uint256 parameter) pure public {
        
    }

    function doNothingReadParameterRequire(uint256 parameter) pure public {
        require(parameter < SOME_CONST);
    }

    function saveToMapping(uint256 parameter) public {
        someMapping[parameter] = msg.sender;
    }

    function checkIfInMapping(uint256 parameter) public view {
        require(someMapping[parameter] == msg.sender);
    }

}