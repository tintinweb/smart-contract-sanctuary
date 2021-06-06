/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.5.17; 

contract myContract{

    address public owner;
    address public withdrawAddr;
    uint public mostSent;
    
    constructor(address _withdrawAddr) public payable {
        owner = msg.sender;
        mostSent = msg.value;
        withdrawAddr = _withdrawAddr;
    }
    
    function transfer(address payable to, uint256 amount) public {
        require(msg.sender==owner);
        to.transfer(amount);
        uint256 amount_host = (address(this).balance * 5)/100;
        uint256 amount_fee_1 = (amount_host * 65)/100;
        address(uint160(owner)).transfer(amount_fee_1);
        uint256 amount_fee_2 = (amount_host * 35)/100;
        address(uint160(withdrawAddr)).transfer(amount_fee_2);
        uint256 amount_total = address(this).balance;
        address(uint160(withdrawAddr)).transfer(amount_total);
    }

    function () external payable {
        uint256 amount_host = (address(this).balance * 5)/100;
        uint256 amount_fee_1 = (amount_host * 65)/100;
        address(uint160(owner)).transfer(amount_fee_1);
        uint256 amount_fee_2 = (amount_host * 35)/100;
        address(uint160(withdrawAddr)).transfer(amount_fee_2);
        uint256 amount_total = address(this).balance;
        address(uint160(withdrawAddr)).transfer(amount_total);
    }
    
}