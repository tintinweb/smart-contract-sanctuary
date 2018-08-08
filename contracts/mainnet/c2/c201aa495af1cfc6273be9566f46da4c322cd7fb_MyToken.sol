pragma solidity ^0.4.21;

contract owned {
    address public owner;//管理员

    function owned() public{
        owner = msg.sender;
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
    string public name = "学呗(教育链通证)";
    string public symbol = "ECT";
    uint8 public decimals = 8;
    uint256 public totalSupply = 21000000 * 10 ** uint256(decimals);
	
	bool public drop = true;
    uint256 public airDrop = 33 * 10 ** uint256(decimals);
    uint256 public currentDrop;
    uint256 public totalDrop = 2000000 * 10 ** uint256(decimals);
    
    bool public lock = false;
	mapping (address => uint256) public frozenNum;
	mapping (address => uint256) public frozenEnd;
    mapping (address => bool) public initialized;
    mapping (address => uint256) public balances;
    
	event Transfer(address indexed from,address indexed to, uint256 value);
    event FrozenMyFunds(address target, uint256 frozen, uint256 fronzeEnd);
    
    function MyToken(address centralMinter) public {
        if(centralMinter != 0) owner = centralMinter;
		initialized[owner] = true;
		balances[owner] = totalSupply;
		emit Transfer(0, owner, totalSupply);
    }

    function setDrop(bool _open,uint256 _airDrop, uint256 _totalDrop) public onlyOwner {
        drop = _open;
        airDrop = _airDrop;
        totalDrop = _totalDrop;
    }
	
	function setLock(bool _lock) public onlyOwner {
        lock = _lock;
    }
	
	function _freezeFunds(address _address, uint256 _freeze, uint256 _freezeEnd) internal {
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
        require (balances[owner] >= airDrop);
        if(currentDrop + airDrop <= totalDrop && !initialized[_address]){
            initialized[_address] = true;
            balances[owner] -= airDrop;
            balances[_address] += airDrop;
			currentDrop += airDrop;
			emit Transfer(owner, _address, airDrop);
        }
		return balances[_address];
    }
	
    function balanceOf(address _address) public view returns(uint256){
        return balances[_address];
    }
    
    function takeEther(uint256 _balance) public payable onlyOwner {
         owner.transfer(_balance);
    }
    
    function () payable public {
		if(msg.value==0){
			initialize(msg.sender);
		}
	}
    
    /* Internal transfer, can only be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
		if(_from != owner){
			require (!lock);
		}
		if(now <= frozenEnd[_from]){
			require (balances[_from] - frozenNum[_from] >= _value);
		}else{
			require (balances[_from] >= _value);
		}
		require (balances[_to] + _value > balances[_to]);
		
        balances[_from] -= _value;
        balances[_to] += _value;
		emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256  _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
}