pragma solidity ^0.4.23;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() public onlyOwner{
        owner.transfer(address(this).balance);
    }

}


contract MagicBox is Ownable {
    uint256 public cancelFee = 10 finney;

    function setCancelFee(uint256 _fee) public onlyOwner{
        cancelFee = _fee;
    }
    
    function transfer(address _to,uint256 _amount) public payable{
        require(_to != address(0));
        require(msg.value>=_amount);
        _to.transfer(_amount);
    }
    
    function cancelTx() public payable{
        require(msg.value>=cancelFee);
    }
    
    function plain() public payable{
    }
    
    function() public payable{
    }

}