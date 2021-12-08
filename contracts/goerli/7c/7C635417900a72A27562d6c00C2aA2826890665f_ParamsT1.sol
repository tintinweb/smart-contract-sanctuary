/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8.0;

contract ParamsT1 {
    uint public num;

    function setVars(address _contract, uint _num) public returns (address contractAddress, uint numF) {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        contractAddress = _contract;
        numF = num;
    }

    function setVars2(address _contract, uint _num) public {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(num>10,"num is low");
    }
}