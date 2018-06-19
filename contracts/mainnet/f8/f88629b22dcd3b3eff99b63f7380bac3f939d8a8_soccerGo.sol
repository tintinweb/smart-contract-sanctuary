pragma solidity ^0.4.20;

// v.1.0.0  2018.04.02
contract soccerGo {
    address private owner;
    mapping (address => bool) private admins;
    
    uint256 gameId = 0;
    address callAddr = 0x0;
    
    event showPlayerAddress(address);
    event showPlayerBet(uint256);
    event showBetLeft(uint256);
    event showBetRight(uint256);
    event showResult(uint256);
    event showCount(uint256);
    event showTimeStamp(uint256);
    event showWinValue(uint256);
    
    // Win limit
    uint[] private slot_limit;
    
    // Dev fee
    uint256 fee = 99;
    
    // Slot 1~10 win limit settings
    function SetLimit(uint _slot, uint win_limit) onlyAdmins() public {
        require(_slot > 0 && _slot < 12);
        slot_limit[_slot - 1] = win_limit;
    }
    
    function soccerGo() public {
        owner = msg.sender;
        admins[owner] = true;
        
        // RTP 97% ~ 98%
        slot_limit.length = 11;
        slot_limit[0] = 1170;
        slot_limit[1] = 611;
        slot_limit[2] = 416;
        slot_limit[3] = 315;
        slot_limit[4] = 253;
        slot_limit[5] = 212;
        slot_limit[6] = 182;
        slot_limit[7] = 159;
        slot_limit[8] = 141;
        slot_limit[9] = 127;
        slot_limit[10] = 115;
    }
    
    function contractBalance() public view returns (uint256) {
        return this.balance;
    }
    
    // Bet limit
    uint256 private min_value = 0.1 ether;
    uint256 private max_value = 0.3 ether;
    
    // SetBetLimit
    function setBetLimit(uint256 min, uint256 max) public onlyAdmins() {
        uint256 base_bet = 0.1 ether;
        min_value = base_bet * min;
        max_value = base_bet * max;
    }
    
    function setCalleeContract(address _caller) public onlyAdmins() {
        callAddr = _caller;
    }
    
    function playTypes(uint _slot_count) internal returns (uint) {
        return (slot_limit[_slot_count - 1]);
    }
    
    function getRandom(address _call) internal returns(uint) {
        Callee c = Callee(_call);
        return c.random(contractBalance(), msg.value, msg.sender);
    }
    
    function setDevfee(uint256 _value) internal onlyAdmins() {
        fee = _value;
    }
    
    function buy(uint256 _left, uint256 _right)
    public
    payable
    {
        require(_left >= 1 && _left <= 13);
        require(_right >= 1 && _right <= 13);
        require(_right - _left >= 1);
        require(msg.value >= min_value);
        require(msg.value <= max_value);
        
        uint256 betValue = msg.value;
        uint256 result = getRandom(callAddr);
        uint256 types = playTypes(_right - _left - 1);
        uint256 winValue = 0;
        gameId++;
        
        if (result > _left && result < _right) {
            winValue = betValue * types / 100;
            msg.sender.transfer((winValue * fee) / 100);
        }

        showPlayerAddress(msg.sender);
        showPlayerBet(betValue);
        showBetLeft(_left);
        showBetRight(_right);
        showResult(result);
        showCount(gameId);
        showTimeStamp(now);
        showWinValue(winValue);
    }
    
    /* Depoit */
    function() payable public { }
    
    /* Withdraw */
    function withdrawAll() onlyOwner() 
    public 
    {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner() 
    public 
    {
        uint256 value = 1.0 ether;
        owner.transfer(_amount * value);
    }
    
    /* Modifiers */
    modifier onlyOwner() 
    {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmins() 
    {
        require(admins[msg.sender]);
        _;
    }
  
    /* Owner */
    function setOwner (address _owner) onlyOwner() 
    public 
    {
        owner = _owner;
    }
    
    function addAdmin (address _admin) onlyOwner() 
    public 
    {
        admins[_admin] = true;
    }

    function removeAdmin (address _admin) onlyOwner() 
    public 
    {
        delete admins[_admin];
    }
}


contract Callee {
    function random(uint256 _balance, uint256 _value, address _player) returns(uint);
}