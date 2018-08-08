pragma solidity ^0.4.24;
//
// Odin Browser Token
// Author: Odin browser group
// Contact: support@odinlink.com
// Home page: https://www.odinlink.com
// Telegram:  https://t.me/OdinChain666666
//
library SafeMath{
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract OdinToken {
	using SafeMath for uint256;
    string public constant name         = "OdinBrowser";
    string public constant symbol       = "ODIN";
    uint public constant decimals       = 18;
    
    uint256 OdinEthRate                  = 10 ** decimals;
    uint256 OdinSupply                   = 15000000000;
    uint256 public totalSupply          = OdinSupply * OdinEthRate;
    uint256 public minInvEth            = 0.1 ether;
    uint256 public maxInvEth            = 1000.0 ether;
    uint256 public sellStartTime        = 1533052800;           // 2018/8/1
    uint256 public sellDeadline1        = sellStartTime + 30 days;
    uint256 public sellDeadline2        = sellDeadline1 + 30 days;
    uint256 public freezeDuration       = 30 days;
    uint256 public ethOdinRate1          = 3600;
    uint256 public ethOdinRate2          = 3600;

    bool public running                 = true;
    bool public buyable                 = true;
    
    address owner;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public whitelist;
    mapping (address =>  uint256) whitelistLimit;

    struct BalanceInfo {
        uint256 balance;
        uint256[] freezeAmount;
        uint256[] releaseTime;
    }
    mapping (address => BalanceInfo) balances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event BeginRunning();
    event Pause();
    event BeginSell();
    event PauseSell();
    event Burn(address indexed burner, uint256 val);
    event Freeze(address indexed from, uint256 value);
    
    constructor () public{
        owner = msg.sender;
        balances[owner].balance = totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true);
        _;
    }
    
    modifier isRunning(){
        require(running);
        _;
    }
    modifier isNotRunning(){
        require(!running);
        _;
    }
    modifier isBuyable(){
        require(buyable && now >= sellStartTime && now <= sellDeadline2);
        _;
    }
    modifier isNotBuyable(){
        require(!buyable || now < sellStartTime || now > sellDeadline2);
        _;
    }
    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    // 1eth = newRate tokens
    function setPublicOfferPrice(uint256 _rate1, uint256 _rate2) onlyOwner public {
        ethOdinRate1 = _rate1;
        ethOdinRate2 = _rate2;       
    }

    //
    function setPublicOfferLimit(uint256 _minVal, uint256 _maxVal) onlyOwner public {
        minInvEth   = _minVal;
        maxInvEth   = _maxVal;
    }
    
    function setPublicOfferDate(uint256 _startTime, uint256 _deadLine1, uint256 _deadLine2) onlyOwner public {
        sellStartTime = _startTime;
        sellDeadline1   = _deadLine1;
        sellDeadline2   = _deadLine2;
    }
        
    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner !=    address(0)) {
            owner = _newOwner;
        }
    }
    
    function pause() onlyOwner isRunning    public   {
        running = false;
        emit Pause();
    }
    
    function start() onlyOwner isNotRunning public   {
        running = true;
        emit BeginRunning();
    }

    function pauseSell() onlyOwner  isBuyable isRunning public{
        buyable = false;
        emit PauseSell();
    }
    
    function beginSell() onlyOwner  isNotBuyable isRunning  public{
        buyable = true;
        emit BeginSell();
    }

    //
    // _amount in Odin, 
    //
    function airDeliver(address _to,    uint256 _amount)  onlyOwner public {
        require(owner != _to);
        require(_amount > 0);
        require(balances[owner].balance >= _amount);
        
        // take big number as wei
        if(_amount < OdinSupply){
            _amount = _amount * OdinEthRate;
        }
        balances[owner].balance = balances[owner].balance.sub(_amount);
        balances[_to].balance = balances[_to].balance.add(_amount);
        emit Transfer(owner, _to, _amount);
    }
    
    
    function airDeliverMulti(address[]  _addrs, uint256 _amount) onlyOwner public {
        require(_addrs.length <=  255);
        
        for (uint8 i = 0; i < _addrs.length; i++)   {
            airDeliver(_addrs[i],   _amount);
        }
    }
    
    function airDeliverStandalone(address[] _addrs, uint256[] _amounts) onlyOwner public {
        require(_addrs.length <=  255);
        require(_addrs.length ==     _amounts.length);
        
        for (uint8 i = 0; i < _addrs.length;    i++) {
            airDeliver(_addrs[i],   _amounts[i]);
        }
    }

    //
    // _amount, _freezeAmount in Odin
    //
    function  freezeDeliver(address _to, uint _amount, uint _freezeAmount, uint _freezeMonth, uint _unfreezeBeginTime ) onlyOwner public {
        require(owner != _to);
        require(_freezeMonth > 0);
        
        uint average = _freezeAmount / _freezeMonth;
        BalanceInfo storage bi = balances[_to];
        uint[] memory fa = new uint[](_freezeMonth);
        uint[] memory rt = new uint[](_freezeMonth);

        if(_amount < OdinSupply){
            _amount = _amount * OdinEthRate;
            average = average * OdinEthRate;
            _freezeAmount = _freezeAmount * OdinEthRate;
        }
        require(balances[owner].balance > _amount);
        uint remainAmount = _freezeAmount;
        
        if(_unfreezeBeginTime == 0)
            _unfreezeBeginTime = now + freezeDuration;
        for(uint i=0;i<_freezeMonth-1;i++){
            fa[i] = average;
            rt[i] = _unfreezeBeginTime;
            _unfreezeBeginTime += freezeDuration;
            remainAmount = remainAmount.sub(average);
        }
        fa[i] = remainAmount;
        rt[i] = _unfreezeBeginTime;
        
        bi.balance = bi.balance.add(_amount);
        bi.freezeAmount = fa;
        bi.releaseTime = rt;
        balances[owner].balance = balances[owner].balance.sub(_amount);
        emit Transfer(owner, _to, _amount);
        emit Freeze(_to, _freezeAmount);
    }
    
    
    // buy tokens directly
    function () external payable {
        buyTokens();
    }

    //
    function buyTokens() payable isRunning isBuyable onlyWhitelist  public {
        uint256 weiVal = msg.value;
        address investor = msg.sender;
        require(investor != address(0) && weiVal >= minInvEth && weiVal <= maxInvEth);
        require(weiVal.add(whitelistLimit[investor]) <= maxInvEth);
        
        uint256 amount = 0;
        if(now > sellDeadline1)
            amount = msg.value.mul(ethOdinRate2);
        else
            amount = msg.value.mul(ethOdinRate1);   

        whitelistLimit[investor] = weiVal.add(whitelistLimit[investor]);
        
        balances[owner].balance = balances[owner].balance.sub(amount);
        balances[investor].balance = balances[investor].balance.add(amount);
        emit Transfer(owner, investor, amount);
    }

    function addWhitelist(address[] _addrs) public onlyOwner {
        require(_addrs.length <=  255);

        for (uint8 i = 0; i < _addrs.length; i++) {
            if (!whitelist[_addrs[i]]){
                whitelist[_addrs[i]] = true;
            }
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner].balance;
    }
    
    function freezeOf(address _owner) constant  public returns (uint256) {
        BalanceInfo storage bi = balances[_owner];
        uint freezeAmount = 0;
        uint t = now;
        
        for(uint i=0;i< bi.freezeAmount.length;i++){
            if(t < bi.releaseTime[i])
                freezeAmount += bi.freezeAmount[i];
        }
        return freezeAmount;
    }
    
    function transfer(address _to, uint256 _amount)  isRunning onlyPayloadSize(2 *  32) public returns (bool success) {
        require(_to != address(0));
        uint freezeAmount = freezeOf(msg.sender);
        uint256 _balance = balances[msg.sender].balance.sub(freezeAmount);
        require(_amount <= _balance);
        
        balances[msg.sender].balance = balances[msg.sender].balance.sub(_amount);
        balances[_to].balance = balances[_to].balance.add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) isRunning onlyPayloadSize(3 * 32) public returns (bool   success) {
        require(_from   != address(0) && _to != address(0));
        require(_amount <= allowed[_from][msg.sender]);
        uint freezeAmount = freezeOf(_from);
        uint256 _balance = balances[_from].balance.sub(freezeAmount);
        require(_amount <= _balance);
        
        balances[_from].balance = balances[_from].balance.sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to].balance = balances[_to].balance.add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning public returns (bool   success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { 
            return  false; 
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        require(myAddress.balance > 0);
        owner.transfer(myAddress.balance);
        emit Transfer(this, owner, myAddress.balance);    
    }
    
    function burn(address burner, uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender].balance);

        balances[burner].balance = balances[burner].balance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        OdinSupply = totalSupply / OdinEthRate;
        emit Burn(burner, _value);
    }
}