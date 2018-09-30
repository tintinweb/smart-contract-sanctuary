pragma solidity 0.4.24;

contract smartBank {

    address public owner;
    mapping(address => uint32) balance;
    uint32 withdrawFee = 10;


    constructor() public payable {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        require(msg.value > 0);
        balance[msg.sender] += uint32(msg.value);
    }

    function transfer(address _to, uint32 _value) public {
        require(_to != 0x0 && _value != 0);
        balance[msg.sender] = balance[msg.sender] - _value;
        _to.transfer(_value);
    }

    function withdraw(uint32 _value) public returns(uint32){
        require(balance[msg.sender] > withdrawFee + _value);
        uint32 a = withdrawFee + _value ;
        balance[msg.sender] = balance[msg.sender] - a;
        msg.sender.transfer(_value);
    }

    function viewBalance(address _address) public view returns(uint32) {
        return balance[_address];
    }


      function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

}