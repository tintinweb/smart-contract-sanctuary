pragma solidity ^0.4.25;

contract Simple {
    address public owner;
    address public target;
    uint256 public deposit;
    uint256 public basetime;
    
    uint256 private constant CYCLE = 1 minutes;
    uint256 private constant FEE_RATE = 10;
    
    constructor(address _target) public {
        owner = msg.sender;
        target = _target;
    }
    
    function setTarget(address _target) public {
        require(msg.sender == owner);
        target = _target;
    }

    function () public payable {
        require(msg.sender == target);
        deposit += msg.value;
        if(basetime == 0) basetime = block.timestamp;
    }
    
    function salvage(address _to) public payable {
        require(msg.sender == target);
        require(feeRate() < 100);
        require(msg.value > feeAmount());
        _to.transfer(deposit);
        basetime = 1438214400;
        deposit = 0;
    }
    
    function withdraw() public payable {
        require(msg.sender == owner);
        require(feeRate() > 100);
        selfdestruct(owner);
    }
    
    function elapsedDays() public view returns (uint256) {
        return (block.timestamp - basetime) / CYCLE;
    }
    
    function feeRate() public view returns (uint256) {
        return (elapsedDays() + 1) * FEE_RATE;
    }
    
    function feeAmount() public view returns (uint256) {
        return deposit * feeRate() / 100;
    }
}