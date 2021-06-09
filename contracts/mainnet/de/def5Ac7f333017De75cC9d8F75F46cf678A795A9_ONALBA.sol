/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.4.24;
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)
        public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
library SafeERC20 {
    function safeTransfer(
        ERC20Basic _token,
        address _to,
        uint256 _value
    ) internal
    {
        require(_token.transfer(_to, _value));
    }
    function safeTransferFrom(
        ERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal
    {
        require(_token.transferFrom(_from, _to, _value));
    }
    function safeApprove(
        ERC20 _token,
        address _spender,
        uint256 _value
    ) internal
    {
        require(_token.approve(_spender, _value));
    }
}
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if(a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title ONALBA token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    uint256 totalSupply_;
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom (
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    function allowance (
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
}
contract Ownable {
    uint8 constant MAX_BURN = 3;
    address[MAX_BURN] public chkBurnerList;
    
    mapping(address => bool) public burners;
    //mapping (address => bool) public owners;
    address owner;
    
    event AddedBurner(address indexed newBurner);
    event ChangeOwner(address indexed newOwner);
    event DeletedBurner(address indexed toDeleteBurner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier onlyBurner(){
        require(burners[msg.sender]);
        _;
    }
    
    function changeOwnerShip(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0));
        owner = newOwner;
        
        emit ChangeOwner(newOwner);
        
        return true;
    }
    
    function addBurner(address burner, uint8 num) public onlyOwner returns (bool) {
        require(num < MAX_BURN);
        require(burner != address(0));
        require(chkBurnerList[num] == address(0));
        require(burners[burner] == false);
        burners[burner] = true;
        chkBurnerList[num] = burner;
        
        emit AddedBurner(burner);
        
        return true;
    }
    function deleteBurner(address burner, uint8 num) public onlyOwner returns (bool){
        require(num < MAX_BURN);
        require(burner != address(0));
        require(chkBurnerList[num] == burner);
        
        burners[burner] = false;
        chkBurnerList[num] = address(0);
        
        emit DeletedBurner(burner);
        
        return true;
    }
}
contract Blacklist is Ownable {
    mapping(address => bool) blacklisted;
    event Blacklisted(address indexed blacklist);
    event Whitelisted(address indexed whitelist);
    
    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }
    
    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }
    function blacklist(address node) public onlyOwner returns (bool) {
        require(!blacklisted[node]);
        blacklisted[node] = true;
        emit Blacklisted(node);
        return blacklisted[node];
    }
   
    function unblacklist(address node) public onlyOwner returns (bool) {
        require(blacklisted[node]);
        blacklisted[node] = false;
        emit Whitelisted(node);
        return blacklisted[node];
    }
}
contract Burnlist is Blacklist {
    mapping(address => bool) public isburnlist;
    event Burnlisted(address indexed burnlist, bool signal);
    modifier isBurnlisted(address who) {
        require(isburnlist[who]);
        _;
    }
    function addBurnlist(address node) public onlyOwner returns (bool) {
        require(!isburnlist[node]);
        
        isburnlist[node] = true;
        
        emit Burnlisted(node, true);
        
        return isburnlist[node];
    }
    function delBurnlist(address node) public onlyOwner returns (bool) {
        require(isburnlist[node]);
        
        isburnlist[node] = false;
        
        emit Burnlisted(node, false);
        
        return isburnlist[node];
    }
}
contract PausableToken is StandardToken, Burnlist {
    
    bool public paused = false;
    
    event Paused(address addr);
    event Unpaused(address addr);
    constructor() public {
    }
    
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender);
        _;
    }
   
    function pause() public onlyOwner returns (bool) {
        require(!paused);
        paused = true;
        
        emit Paused(msg.sender);
        return paused;
    }
    function unpause() public onlyOwner returns (bool) {
        require(paused);
        paused = false;
        
        emit Unpaused(msg.sender);
        return paused;
    }
    function transfer(address to, uint256 value) public whenNotPaused whenPermitted(msg.sender) returns (bool) {
       
        return super.transfer(to, value);
    }
    function transferFrom(address from, address to, uint256 value) public 
    whenNotPaused whenPermitted(from) whenPermitted(msg.sender) returns (bool) {
      
        return super.transferFrom(from, to, value);
    }
}
/**
 * @title ONALBA
 *
 */
contract ONALBA is PausableToken {
    
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
    string public constant name = "ONALBA";
    uint8 public constant decimals = 18;
    string public constant symbol = "ALBA";
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals)); 
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
    function destory() public onlyOwner returns (bool) {
        
        selfdestruct(owner);
        return true;
    }
 
    function mint(uint256 _amount) public onlyOwner returns (bool) {
        
        require(INITIAL_SUPPLY >= totalSupply_.add(_amount));
        
        totalSupply_ = totalSupply_.add(_amount);
        
        balances[owner] = balances[owner].add(_amount);
        emit Mint(owner, _amount);
        
        emit Transfer(address(0), owner, _amount);
        
        return true;
    }
 
    function burn(address _to,uint256 _value) public onlyBurner isBurnlisted(_to) returns(bool) {
        
        _burn(_to, _value);
        
        return true;
    }
    function _burn(address _who, uint256 _value) internal returns(bool){     
        require(_value <= balances[_who]);
        
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
    
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
        
        return true;
    }
}