pragma solidity 0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

interface ERC20Interface {
    function totalSupply() external view returns(uint);
    function balanceOf(address owner)  external view returns(uint256 balance);
    function transfer(address to, uint value) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 value)  external returns(bool success);
    function approve(address spender, uint256 value)  external returns(bool success);
    function allowance(address owner, address spender)  external view returns(uint256 remaining);
    
    function Exchange_Price() external view returns(uint256 actual_Price); 
    
    function isUser_Frozen(address _user) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//Wealth Builder Club Loyalty Token

contract WBCT {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public _totalSupply;
    bool public paused = false;
    uint256 adminCount;
    uint256 TOKEN_PRICE;
    address public EXCHNG;
    address public TOKEN_ATM;
    
    address[] public adminListed;
    
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => bool) public frozenUser;
    mapping (address => bool) public isBlackListed;
    mapping (address => bool) public registeredUser;

    event Transfer(address indexed from, address indexed to, uint value, uint _time);
    event Approval(address indexed owner, address indexed spender, uint256 value, uint _time);
    
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance, uint _time);
    event AddedBlackList(address _user, uint _time);
    event RemovedBlackList(address _user, uint _time);

    event Received(address, uint _value, uint _time);
    event Issue(uint amount, uint _time);
    event Redeem(uint amount, uint _time);

    event Registered_User(address _user, uint _time);
    event UserFrozen(address _user, address _admin, uint _time);
    event UserUnfrozen(address _user, address _admin, uint _time);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    event AddedAdminList(address _adminUser);
    event RemovedAdminList(address _clearedAdmin);
    
    event Pause();
    event Unpause();

    function init_Token(uint256 _initialSupply, string memory _name, string memory _symbol, uint256 _decimals) public onlyOwner {
        _totalSupply = _initialSupply* (10 ** _decimals);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        registeredUser[msg.sender]=true;
        frozenUser[msg.sender]=false;
        balanceOf[msg.sender] = _initialSupply * (10 ** _decimals);
    }

    constructor () public {
        adminListed.push(msg.sender);
        adminCount=1;
        TOKEN_PRICE = 0.001 ether;
    }  
      
    modifier onlyOwner() {
        require(isAdminListed(msg.sender));
        _;
    }    

    /**
    * @dev Fix for the ERC20 short address attack.
    */

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
  
      function isAdminListed(address _maker) public view returns (bool) {
        require(_maker != address(0));
        bool status = false;
        for(uint256 i=0;i<adminCount;i++){
            if(adminListed[i] == _maker) { status = true; }
        }
        return status;
    }

     function getOwner() public view returns (address[] memory) {
        address[] memory _adminList = new address[](adminCount);
        for(uint i=0;i<adminCount;i++){
            _adminList[i]=adminListed[i];
        }
    return _adminList;
    }

    function addAdminList (address _adminUser) public onlyOwner {
        require(_adminUser != address(0));
        require(!isAdminListed(_adminUser));
        adminListed.push(_adminUser);
        adminCount++;
        emit AddedAdminList(_adminUser);
    }

    function removeAdminList (address _clearedAdmin) public onlyOwner {
        require(isAdminListed(_clearedAdmin) && _clearedAdmin != msg.sender);
        for(uint256 i=0;i<adminCount;i++){
            if(adminListed[i] == _clearedAdmin) { 
                adminListed[i]=adminListed[adminListed.length-1];
                delete adminListed[adminListed.length-1];
                adminCount--;
            }
        }
        emit RemovedAdminList(_clearedAdmin);
    }

    function isUser_Frozen(address _user) public view returns (bool) {
        return frozenUser[_user];
    }
    
    function setUser_Frozen(address _user) public onlyOwner{
        frozenUser[_user] = true;
        emit UserFrozen(_user, msg.sender, now);
    }
    
    function setUser_unFrozen(address _user) public onlyOwner{
        frozenUser[_user] = false;
        emit UserUnfrozen(_user, msg.sender, now);
    }
    
    function getBlackListStatus(address _user) public view returns (bool) {
        return isBlackListed[_user];
    }
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser,now);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser,now);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds,now);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozenUser[_to]);
        require(!frozenUser[msg.sender]);
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to,_value,now);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(!frozenUser[_from]);
        require(!frozenUser[_to]);
        require(!frozenUser[msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value,now);
    }    

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool success) {
        require(_value > 0);
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender] || _to == EXCHNG || _to == TOKEN_ATM);
        require(!frozenUser[_from]);
        require(!frozenUser[_to]);
        require(!frozenUser[msg.sender]);
        if( _to != TOKEN_ATM && _to != EXCHNG ) allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool success) {
        require(!frozenUser[_spender]);
        require(!frozenUser[msg.sender]);
        require(_value != 0);
        require(_spender != address(0));
        require( balanceOf[msg.sender] >= _value );
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value,now);
        return true;
    }
    
    function freeze(uint256 _value) public returns (bool success) {
        require(!frozenUser[msg.sender]);
        require(balanceOf[msg.sender] >= _value);
		require(_value >= 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);
        emit Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public returns (bool success) {
	    require(!frozenUser[msg.sender]);
        require(freezeOf[msg.sender] >= _value);
		require (_value >= 0);
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);
		balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balanceOf[msg.sender] + amount > balanceOf[msg.sender]);
        _totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Issue(amount,now);
    }

    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balanceOf[msg.sender] >= amount);
        _totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Redeem(amount,now);
    }

	function withdrawEther(uint256 amount) public onlyOwner  {
	    require(isAdminListed(msg.sender));
	    msg.sender.transfer(amount);
	}

	function getETHBalance() public view onlyOwner returns (uint256 _ETHBalance) {
	return address(this).balance;
    }

	function () external payable onlyPayloadSize(2 * 32) { 
        emit Received(msg.sender, msg.value,now);
    }
    
    function setEXCHNGAddress (address _exchngSCAddress) public onlyOwner { 
        EXCHNG = _exchngSCAddress;
    }
    
    function set_ATMAddress (address _ATMSCAddress) public onlyOwner { 
        TOKEN_ATM = _ATMSCAddress;
    }
    
    function set_TokenName (string memory _name,string memory _symbol) public onlyOwner { 
        name = _name;
        symbol = _symbol;
    }
    
    function Exchange_Price() public view returns (uint256 actual_Price) {
        return TOKEN_PRICE;
    }
    
    function set_Exchange_Price() public onlyOwner {
        ERC20Interface ERC20Exchng = ERC20Interface(EXCHNG);
        TOKEN_PRICE = ERC20Exchng.Exchange_Price();
    }
}