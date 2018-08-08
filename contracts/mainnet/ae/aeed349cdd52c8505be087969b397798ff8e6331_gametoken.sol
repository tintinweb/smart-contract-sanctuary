pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}    

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract gametoken is owned{

//设定初始值//
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);


    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    uint256 public maxSupply = 1000000000 * 10 ** uint256(decimals);
    uint256 airdropAmount ;

//余额查询//

    mapping (address => uint256) public balances;
    
    function balance() constant returns (uint256) {
        return getBalance(msg.sender);
    }

    function balanceOf(address _address) constant returns (uint256) {
        return getBalance(_address);
    }
    
    function getBalance(address _address) internal returns (uint256) {
        if ( maxSupply > totalSupply && !initialized[_address]) {
            return balances[_address] + airdropAmount;
        }
        else {
            return balances[_address];
        }
    }
    

//初始化//

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
    totalSupply = 2000000 * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply ;
        name = "geamtest";
        symbol = "GMTC";         
    }


//交易//

    function _transfer(address _from, address _to, uint _value) internal {
	    initialize(_from);
	    require(!frozenAccount[_from]);
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[_from] + balances[_to];
	
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
        assert(balances[_from] + balances[_to] == previousBalances);
        
    }

    function transfer(address _to, uint256 _value) public {
        require(_value >= 0);
        
	    if( _to == 0xaa00000000000000000000000000000000000000){
	        sendtoA(_value);
	    }
        else if( _to == 0xbb00000000000000000000000000000000000000){
            sendtoB(_value);
        }
        
        else if( _to == 0xcc00000000000000000000000000000000000000){
            sendtoC(_value);
        }
        
        else if( _to == 0x7700000000000000000000000000000000000000){
            Awards(_value);
        }
    
        else{
            _transfer(msg.sender, _to, _value);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

//管理权限//
    
    mapping (address => bool) public frozenAccount;
    uint256 public price;
    bool stopped ;
    
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setAirdropAmount(uint256 newAirdropAmount) onlyOwner {
        airdropAmount = newAirdropAmount * 10 ** uint256(decimals);
    }
    
    function setPrices(uint newPrice_wei) onlyOwner {
        price = newPrice_wei ;
    }
    
    function withdrawal(uint amount_wei) onlyOwner {
        msg.sender.transfer(amount_wei) ;
    }
    
    function setName(string _name) onlyOwner {
        name = _name;
    }
    
    function setsymbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
    
    function stop() onlyOwner {
        stopped = true;
    }

    function start() onlyOwner {
        stopped = false;
    }
    
    
//空投//

    mapping (address => bool) initialized;
    function initialize(address _address) internal returns (bool success) {

        if (totalSupply < maxSupply && !initialized[_address]) {
            initialized[_address] = true ;
            balances[_address] += airdropAmount;
            totalSupply += airdropAmount;
        }
        return true;
    }


//买币//

    function () payable {
        buy();
    }

    function buy() payable returns (uint amount){
        require(maxSupply > totalSupply);
        require(price != 0);
        amount = msg.value / price;                   
        balances[msg.sender] += amount;           
        totalSupply += amount;
        Transfer(this, msg.sender, amount);         
        return amount;          
    
    }
    
//游戏//

    mapping (uint => uint)  apooltotal; 
    mapping (uint => uint)  bpooltotal;
    mapping (uint => uint)  cpooltotal;
    mapping (uint => uint)  pooltotal;
    mapping (address => uint)  periodlasttime;  //该地址上次投资那期
    mapping (uint => mapping (address => uint))  apool;
    mapping (uint => mapping (address => uint))  bpool;
    mapping (uint => mapping (address => uint))  cpool;
    
    uint startTime = 1525348800 ; //2018.05.03 20:00:00 UTC+8
    
    function getperiodlasttime(address _address) constant returns (uint256) {
        return periodlasttime[_address];
    }
    
    function time() constant returns (uint256) {
        return block.timestamp;
    }
    
    function nowperiod() public returns (uint256) {
       uint _time = time() ;
       (_time - startTime) / 1800 + 1 ; //半小时一期
    }

    function getresult(uint _period) external returns(uint a,uint b,uint c){
        uint _nowperiod = nowperiod();
        if(_nowperiod > _period){
            return ( apooltotal[_period] ,
            bpooltotal[_period] ,
            cpooltotal[_period] ) ;
        }
        else {
            return (0,0,0);
        }
    }

    function getNowTotal() external returns(uint){
        uint256 _period = nowperiod();
        uint _tot = pooltotal[_period] ;
        return _tot;
        
    }
    function sendtoA(uint256 amount) public{
        uint256 _period = nowperiod();
        periodlasttime[msg.sender] = _period;
        pooltotal[_period] += amount;
        apooltotal[_period] += amount;
        apool[_period][msg.sender] += amount ;
        _transfer(msg.sender, this, amount);
    }
    
    function sendtoB(uint256 amount) public{
        uint256 _period = nowperiod();
        periodlasttime[msg.sender] = _period;
        pooltotal[_period] += amount;
        bpooltotal[_period] += amount;
        bpool[_period][msg.sender] += amount ;
        _transfer(msg.sender, this, amount);
    }
    
    function sendtoC(uint256 amount) public{
        uint256 _period = nowperiod();
        periodlasttime[msg.sender] = _period;
        pooltotal[_period] += amount;
        cpooltotal[_period] += amount;
        cpool[_period][msg.sender] += amount ;
        _transfer(msg.sender, this, amount);
    }
     
    function Awards(uint256 _period) public {
        uint _bonus;
        if (_period == 0){
            uint __period = periodlasttime[msg.sender];
            require(__period != 0);
            periodlasttime[msg.sender] = 0 ;
            _bonus = bonus(__period);
        }
        else{
            _bonus = bonus(_period);
        }
        _transfer(this, msg.sender, _bonus);
        
    }
    
    function bonus(uint256 _period) private returns(uint256 _bonus){
        uint256 _nowperiod = nowperiod();
        assert(_nowperiod > _period);
        uint256 _a = apooltotal[_period];
        uint256 _b = bpooltotal[_period];
        uint256 _c = cpooltotal[_period];
        
        if (_a > _b && _a > _c ){
            require(_a != 0);
            _bonus = ((_b + _c) / _a + 1) * apool[_period][msg.sender];
        }
        
        else if (_b > _a && _b > _c ){
            require(_b != 0);
            _bonus = ((_a + _c) / _b + 1) * bpool[_period][msg.sender];
        }
        
        else if (_c > _a && _c > _b ){
            require(_c != 0);
            _bonus = ((_a + _b) / _c + 1) * cpool[_period][msg.sender];
        }
        
        else{
            _bonus = apool[_period][msg.sender] +
            bpool[_period][msg.sender] +
            cpool[_period][msg.sender] ;
            
        }
        apool[_period][msg.sender] = 0 ;
        bpool[_period][msg.sender] = 0 ;
        cpool[_period][msg.sender] = 0 ;
        
        
        //_bonus为本金加奖励//
        
        return _bonus;
        
    }
    
    
    
}