/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

pragma solidity ^0.4.24;

// interface Aion
contract Aion {
    uint256 public serviceFee;
    function ScheduleCall(uint256 blocknumber, address to, uint256 value, uint256 gaslimit, uint256 gasprice, bytes data, bool schedType) public payable returns (uint,address);

}

contract Barns {
    function harvest() public;
}

// Main contract
contract Harvestor{
    Aion aion;
    Barns barn;

    constructor() public payable {}

    function scheduleMyfucntion() public {
        aion = Aion(0x690f3b5Ef80940a461Fbc40cC6ac12Af0a5A5b49);
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('myfucntion()')));
        uint callCost = 200000*1e9 + aion.serviceFee();
        aion.ScheduleCall.value(callCost)( block.timestamp + 30 minutes, address(this), 0, 200000, 1e9, data, true);
    }

    function myfucntion() public {
        barn = Barns(0x7885A1be4cF467b5209Da30C72454860614eac26);
        barn.harvest();
        scheduleMyfucntion();
    }

    function () public payable {}

}