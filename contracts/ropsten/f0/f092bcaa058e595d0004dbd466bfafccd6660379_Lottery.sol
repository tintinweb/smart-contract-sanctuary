pragma solidity ^0.4.24;

contract Ownable {
    
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

contract Lottery is Ownable{
    uint private point = 100;
    mapping(address => bytes32) public keys;
    mapping(address => uint) public balances;
    
    constructor(uint _point) {
        point = _point;
    }
    
    function getKey(address index) public returns(uint) {
        return uint(keys[index]) % point;
    }
    
    function mod(uint a, uint b) returns (uint){
        return a % b;
    }
    
    function draw(address[] addresses) public returns (address) {
        uint sum = 0;
        uint balance = 0;
        for (uint i = 0; i < addresses.length; i++) {
            sum += uint(keys[addresses[i]]) % point;
            balance += balances[addresses[i]];
        }
        return addresses[sum % addresses.length];
    }
    
    function () payable{
        if (msg.value == 0) {
            revert();
        }
        keys[msg.sender] = sha3(owner, msg.sender, blockhash(block.number));
        balances[msg.sender] = msg.value;
    }
}