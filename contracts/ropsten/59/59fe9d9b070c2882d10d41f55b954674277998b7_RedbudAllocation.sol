pragma solidity ^0.4.24;

contract RedbudToken{
    uint totalRedbud = 10**50;
    mapping(address => uint256) public balances;
    address keeper;
    
     constructor() public {
         keeper = msg.sender;
     }
      
      function mint(address _to, uint256 _amount) public returns(bool) {
          require(_to != 0x0);
          require(_amount > 0);
          require(msg.sender == keeper);
          require(_amount <= totalRedbud);
          totalRedbud -= _amount;
          balances[_to] += _amount;
          assert(balances[_to] < 10**7);
          return true;
      }
      
      function balanceOf(address _who) public constant returns(uint256) {
          return balances[_who];
      }
}

contract RedbudAllocation{
    
    uint256 numbers;
    address owner;
    mapping(address => uint256) public luckyChips;
    mapping(address => uint256) public lockedAmount;
    mapping(address => uint256) public lockedTime;
    uint256 public initTime;
    RedbudToken public token;
    luckyMan[] luckyLog;

    struct luckyMan{
        uint256 _amount;
        address _who;
    }
    
    constructor() public {
        owner=msg.sender;
        initTime = now;
        token = new RedbudToken();
    }
    
    modifier onlyOwner {
        if (msg.sender != owner)
            revert();
        _;
    }
    
    function welcomeBonus() public returns(bool) {
        require(token.balanceOf(msg.sender) < 10);
        luckyChips[msg.sender] = 10;
        if(token.mint(msg.sender, 10)){
            numbers += 1;
            return true;
        }
        return false;
    }
    
    function luckyBonus(uint guess) public returns(bool) {
        require(luckyChips[msg.sender] > 0);
        luckyChips[msg.sender] -= 1;
        uint random = uint(keccak256(now, msg.sender, numbers)) % 10;
        if (guess == random){
            token.mint(msg.sender, 100);
            luckyMan lucky;
            lucky._amount = 100;
            lucky._who = msg.sender;
            luckyLog.push(lucky);
            return true;
        }
        return false;   
    }

    function diamondBonus(uint256 _locktime) public onlyOwner returns(bool) {
        require(_locktime > 1 years);
        lockedAmount[msg.sender] = 10**6;
        lockedTime[msg.sender] = _locktime;
        return true;
    }

    function unlock() public returns(bool) {
        require(now >= initTime + lockedTime[msg.sender]);
        return token.mint(msg.sender, lockedAmount[msg.sender]);
    } 

    function balanceOfToken(address _who) public constant returns(uint256) {
        return token.balanceOf(_who);
    }
    
}