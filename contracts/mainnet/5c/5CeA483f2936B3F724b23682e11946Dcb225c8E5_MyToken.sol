pragma solidity ^0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
    address public owner;
    address public contractAddress;

    function owned() public{
        owner = msg.sender;
        contractAddress = this;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract MyToken is owned {
    /* the rest of the contract as usual */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
	uint256 public exchangeStart;
	uint256 public exchangeEnd;
    uint256 public sellPrice;
    uint256 public buyPrice;
	
	bool public drop;
    uint256 public airDrop;
    uint256 public currentDrop;
    uint256 public totalDrop;
	uint256 public dropStart;
	uint256 public dropEnd;
	
    uint256 public minEtherForAccounts;
	uint8 public powers;
	uint256 public users;
	uint256 public minToken;
	uint256 public count;
	
	bool public lock;
	bool public sellToContract;
    
    mapping (address=> bool) public initialized;
    mapping (address => uint256) public balances;
	mapping (address => uint256) public frozens;
    mapping (address => uint256) public frozenNum;
	mapping (address => uint256) public frozenEnd;
    mapping (address => mapping (address => uint256)) public allowance;
	mapping (uint256 => mapping (address => bool)) public monthPower;
	mapping (uint256 => bool) public monthOpen;
    
	event FrozenFunds(address target, uint256 frozen);
    event FrozenMyFunds(address target, uint256 frozen, uint256 fronzeEnd);
    event Transfer(address indexed from,address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function MyToken(address centralMinter) public {
        name = "共享通";
        symbol = "SCD";
        decimals = 2;
        totalSupply = 31000000 * 3 * 10 ** uint256(decimals);
        sellPrice = 1 * 10 ** 14;
        buyPrice = 2 * 10 ** 14;
		drop = true;
        airDrop = 88 * 10 ** uint256(decimals);
		currentDrop = 0;
        totalDrop = 2000000 * 10 ** uint256(decimals);
        minEtherForAccounts = 5 * 10 ** 14;
		powers = 2;
		users = 1;
		count = 1000;
		lock = true;
        if(centralMinter != 0) owner = centralMinter;
		initialized[owner] = true;
		balances[owner] = totalSupply;
    }

    function setDrop(bool _open) public onlyOwner {
        drop = _open;
    }
	
    function setAirDrop(uint256 _dropStart, uint256 _dropEnd, uint256 _airDrop, uint256 _totalDrop) public onlyOwner {
		dropStart = _dropStart;
		dropEnd = _dropEnd;
        airDrop = _airDrop;
        totalDrop = _totalDrop;
    }
	
	function setExchange(uint256 _exchangeStart, uint256 _exchangeEnd, uint256 _sellPrice, uint256 _buyPrice) public onlyOwner {
        exchangeStart = _exchangeStart;
		exchangeEnd = _exchangeEnd;
		sellPrice = _sellPrice;
        buyPrice = _buyPrice;
    }
	
	function setLock(bool _lock) public onlyOwner {
        lock = _lock;
    }
	
	function setSellToContract(bool _sellToContract) public onlyOwner {
        sellToContract = _sellToContract;
    }
	
	function setMinEther(uint256 _minimumEtherInFinney) public onlyOwner {
		minEtherForAccounts = _minimumEtherInFinney * 1 finney;
	}
	
	function setMonthClose(uint256 _month, bool _value) public onlyOwner {
		monthOpen[_month] = _value;
    }
	
	function setMonthOpen(uint256 _month, uint256 _users, uint8 _powers, uint256 _minToken, uint256 _count) public onlyOwner {
        monthOpen[_month] = true;
		users = _users;
		minToken = _minToken;
		count = _count;
        if(_powers > 0){
            powers = _powers;
        }
    }
	    
    function lockAccount(address _address, uint256 _lockEnd) public onlyOwner {
        frozens[_address] = _lockEnd;
        emit FrozenFunds(_address, _lockEnd);
    }
		
	function _freezeFunds(address _address, uint256 _freeze, uint256 _freezeEnd) internal {
		if(drop){
		    initialize(_address);
		}
        frozenNum[_address] = _freeze;
		frozenEnd[_address] = _freezeEnd;
        emit FrozenMyFunds(_address, _freeze, _freezeEnd);
    }
	
	function freezeUserFunds(address _address, uint256 _freeze, uint256 _freezeEnd) public onlyOwner {
        _freezeFunds(_address, _freeze, _freezeEnd);
    }
	
	function freezeMyFunds(uint256 _freeze, uint256 _freezeEnd) public {
        _freezeFunds(msg.sender, _freeze, _freezeEnd);
    }
    
    function initialize(address _address) internal returns (uint256) {
		require (drop);
		require (now > frozens[_address]);
		if(dropStart != dropEnd && dropEnd > 0){
			require (now >= dropStart && now <=dropEnd);
		}
        require (balances[owner] > airDrop);
        if(currentDrop + airDrop < totalDrop && !initialized[_address]){
            initialized[_address] = true;
            _transfer(owner, msg.sender, airDrop);
            currentDrop += airDrop;
            return balances[_address];
        }
    }
	
	function getMonth(uint256 _month) public returns (uint256) {
		require (count > 0);
		require (now > frozens[msg.sender]);
		require (balances[msg.sender] >= minToken);
	    require (monthOpen[_month]);
	    require (!monthPower[_month][msg.sender]);
		if(drop){
		    initialize(msg.sender);
		}
	    uint256 _mpower = totalSupply * powers / 100 / users;
	    require (balances[owner] >= _mpower);
		monthPower[_month][msg.sender] = true;
		_transfer(owner, msg.sender, _mpower);
		count -= 1;
        return _mpower;
    }
    
    function balanceOf(address _address) public view returns(uint256){
        return getBalances(_address);
    }
    
    function getBalances(address _address) view internal returns (uint256) {
        if (drop && now > frozens[_address] && currentDrop + airDrop < totalDrop && !initialized[_address]) {
            return balances[_address] + airDrop;
        }else {
            return balances[_address];
        }
    }
    
    function takeEther(uint256 _balance) public payable onlyOwner {
         owner.transfer(_balance);
    }
    
    function () payable public {}
    
    function giveEther() public payable {
    }
    
    function getEther(address _address) public view returns(uint256){
        return _address.balance;
    }
	
	function getTime() public view returns(uint256){
        return now;
    }
    
    function mintToken(address _address, uint256 _mintedAmount) public onlyOwner {
        require(balances[_address] + _mintedAmount > balances[_address]);
        require(totalSupply + _mintedAmount > totalSupply);
        balances[_address] += _mintedAmount;
        totalSupply += _mintedAmount;
        emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _address, _mintedAmount);
    }
    
    /* Internal transfer, can only be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
		if(_from != owner){
			require (!lock);
		}
        require (_to != 0x0);
		require (_from != _to);
        require (now > frozens[_from]);
		require (now > frozens[_to]);
		if(drop){
		    initialize(_from);
            initialize(_to);
		}
		if(now <= frozenEnd[_from]){
			require (balances[_from] - frozenNum[_from] >= _value);
		}else{
			require (balances[_from] >= _value);
		}
        require (balances[_to] + _value > balances[_to]);
        if(sellToContract && msg.sender.balance < minEtherForAccounts){
            sell((minEtherForAccounts - msg.sender.balance) / sellPrice);
        }
        balances[_from] -= _value;
        balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
    }
    
    function transfer(address _to, uint256  _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
		require (now > frozens[msg.sender]);
        require(_value <= allowance[_from][msg.sender]);
		_transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
		require (!lock);
		if(drop){
    		initialize(msg.sender);
            initialize(_spender);
		}
        require(msg.sender != _spender);
		require (now > frozens[msg.sender]);
		if(now <= frozenEnd[msg.sender]){
			require (balances[msg.sender] - frozenNum[msg.sender] >= _value);
		}else{
			require (balances[msg.sender] >= _value);
		}
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
		require (!lock);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
		require (!lock);
        require(_value > 0);
		require (now > frozens[msg.sender]);
		if(now <= frozenEnd[msg.sender]){
			require (balances[msg.sender] - frozenNum[msg.sender] >= _value);
		}else{
			require (balances[msg.sender] >= _value);
		}
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require (!lock);
        require(_value > 0);
		require (now > frozens[msg.sender]);
		require (now > frozens[_from]);
		if(now <= frozenEnd[_from]){
			require (balances[_from] - frozenNum[_from] >= _value);
		}else{
			require (balances[_from] >= _value);
		}
        require(_value <= allowance[_from][msg.sender]);
        balances[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function buy() public payable{
        require (!lock);
        if(drop){
            initialize(msg.sender);
        }
		if(exchangeStart != exchangeEnd && exchangeEnd > 0){
			require (now >= exchangeStart && now <=exchangeEnd);
		}
        uint256 _amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, _amount);
    }
    
    function sell(uint256 _amount) public {
		require (!lock);
		require (sellToContract);
		require (now > frozens[msg.sender]);
        require(_amount > 0);
		if(exchangeStart != exchangeEnd && exchangeEnd > 0){
			require (now >= exchangeStart && now <=exchangeEnd);
		}
		if(now <= frozenEnd[msg.sender]){
			require (balances[msg.sender] - frozenNum[msg.sender] >= _amount);
		}else{
			require (balances[msg.sender] >= _amount);
		}
        require(contractAddress.balance >= _amount * sellPrice);
        _transfer(msg.sender, contractAddress, _amount);
        msg.sender.transfer(_amount * sellPrice);
    }
    
}