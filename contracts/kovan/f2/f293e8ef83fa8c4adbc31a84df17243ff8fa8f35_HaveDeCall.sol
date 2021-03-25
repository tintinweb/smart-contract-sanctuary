/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.8.0;

contract HaveDeCall {
    address public owner;
    address public goodContract;
    
    constructor() payable {
        owner = msg.sender;
    }
    
    function goodFunction(uint256 goodMoney) public payable {
        (bool success, bytes memory data) = goodContract.delegatecall(
            abi.encodeWithSignature("transfer(uint256)", goodMoney)
        );
    }
    
    function setGoodContract(address _contract) public {
        require(owner == msg.sender);
        goodContract = _contract;
    }
    
}