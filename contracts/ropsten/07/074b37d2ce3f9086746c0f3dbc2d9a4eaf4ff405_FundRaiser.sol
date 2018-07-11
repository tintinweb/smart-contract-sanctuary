pragma solidity ^0.4.24;

contract FundRaiser {
    
    modifier notOwner {
        require(msg.sender != _owner);
        _;
    }
    
    modifier isOwner {
        require(msg.sender == _owner);
        _;
    }
    
    modifier isExpired {
        require(now > _expires);
        _;
    }
    
    modifier open {
        require(now <= _expires);
        _;
    }
    
    modifier goalReached {
        require(_goal <= _raised);
        _;
    }
    
    modifier goalNotReached {
        require(_goal > _raised);
        _;
    }
    
    /**
     * Donation event
     **/
    event Donation(address sender, uint256 amount);
    
    /**
     * Withdrawl event
     **/
    event Withdrawl(address sender, uint amount);
    
    /**
     * If this event is emited with a &#39;success&#39; = false, this means that the
     * funding event has expired and the funds were not raised.
     **/
    event FundsRaised(bool success);
    
    address private _owner;
    uint256 private _expires;
    mapping (address => uint256) private donations;
    uint256 private _goal;
    uint256 private _raised;
    
    constructor(uint256 goal, uint256 expires) public {
        _owner = msg.sender;
        _goal = goal;
        _expires = expires + now;
    }
    
    function donate() public payable notOwner open goalNotReached {
        require(donations[msg.sender] + msg.value >= msg.value);
        donations[msg.sender] += msg.value;
        _raised += msg.value;
        emit Donation(msg.sender, msg.value);
    }
    
    function withdrawl(uint256 amount) public payable isOwner goalReached {
        _owner.transfer(amount);
    }
    
    function refund() public payable isExpired notOwner goalNotReached {
        msg.sender.transfer(donations[msg.sender]);
        emit Withdrawl(msg.sender, donations[msg.sender]);
        donations[msg.sender] = 0;
    }
    
    function getMyDonations() public view returns(address, uint256){
        return (msg.sender, donations[msg.sender]);
    }
    
    function getDonationByAddress(address _address) public view returns(address, uint256) {
        return (_address, donations[_address]);
    }
    
    function getGoal() public view returns (uint256 raised, uint256 goal) {
        return (_raised, _goal);
    }
    
    function getBalacne() public view returns (uint256) {
        return address(this).balance;
    }
    
    function timeLeft() public view returns (bool expired, bool raised, uint256 timeRemaining) {
        if(now > _expires){
            return (true, _raised < _goal, 0);
        }
        return (false, _raised < _goal, _expires - now);
    }
}