pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract POPKOIN is ERC20, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal initialSupply;
    uint256 internal _totalSupply;
    
                                 
    uint256 internal LOCKUP_TERM = 6 * 30 * 24 * 3600;

    mapping(address => uint256) internal _balances;    
    mapping(address => mapping(address => uint256)) internal _allowed;

    mapping(address => uint256) internal _lockupBalances;
    mapping(address => uint256) internal _lockupExpireTime;

    function POPKOIN() public {
        name = "POPKOIN";
        symbol = "POPK";
        decimals = 18;


        //Total Supply  2,000,000,000
        initialSupply = 2000000000;
        _totalSupply = initialSupply * 10 ** uint(decimals);
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(msg.sender != address(0));
        require(_value <= _balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _holder The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _holder) public view returns (uint256 balance) {
        return _balances[_holder].add(_lockupBalances[_holder]);
    }

    /**
    * @dev Gets the locked balance of the specified address.
    * @param _holder The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */   
    function lockupBalanceOf(address _holder) public view returns (uint256 balance) {
        return _lockupBalances[_holder];
    }

    /**
    * @dev Gets the unlocked time of the specified address.
    * @param _holder The address to query the the balance of.
    * @return An uint256 representing the Locktime owned by the passed address.
    */   
    function unlockTimeOf(address _holder) public view returns (uint256 lockTime) {
        return _lockupExpireTime[_holder];
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _holder address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _holder, address _spender) public view returns (uint256) {
        return _allowed[_holder][_spender];
    }

    /**
    * @dev Do not allow contracts to accept Ether.
    */
    function () public payable {
        revert();
    }

    /**
    * @dev The Owner destroys his own token.
    * @param _value uint256 The quantity that needs to be destroyed.
    */
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= _balances[msg.sender]);
        address burner = msg.sender;
        _balances[burner] = _balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        return true;
    }

    /**
    * @dev Function is used to distribute tokens and confirm the lock time.
    * @param _to address The address which you want to transfer to
    * @param _value uint256 The amount of tokens to be transferred
    * @param _lockupRate uint256 The proportion of tokens that are expected to be locked.
    * @notice If you lock 50%, the lockout time is six months.
    *         If you lock 100%, the lockout time is one year.
    */
    function distribute(address _to, uint256 _value, uint256 _lockupRate) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        //Do not allow multiple distributions of the same address. Avoid locking time reset.
        require(_lockupBalances[_to] == 0);     
        require(_value <= _balances[owner]);
        require(_lockupRate == 50 || _lockupRate == 100);

        _balances[owner] = _balances[owner].sub(_value);

        uint256 lockupValue = _value.mul(_lockupRate).div(100);
        uint256 givenValue = _value.sub(lockupValue);
        uint256 ExpireTime = now + LOCKUP_TERM; //six months

        if (_lockupRate == 100) {
            ExpireTime += LOCKUP_TERM;          //one year.
        }
        
        _balances[_to] = _balances[_to].add(givenValue);
        _lockupBalances[_to] = _lockupBalances[_to].add(lockupValue);
        _lockupExpireTime[_to] = ExpireTime;

        emit Transfer(owner, _to, _value);
        return true;
    }

    /**
    * @dev When the lock time expires, the user unlocks his own token.
    */
    function unlock() public returns(bool) {
        address tokenHolder = msg.sender;
        require(_lockupBalances[tokenHolder] > 0);
        require(_lockupExpireTime[tokenHolder] <= now);

        uint256 value = _lockupBalances[tokenHolder];

        _balances[tokenHolder] = _balances[tokenHolder].add(value);  
        _lockupBalances[tokenHolder] = 0;

        return true;
    }

    /**
    * @dev The new owner accepts the contract transfer request.
    */
    function acceptOwnership() public onlyNewOwner returns(bool) {
        uint256 ownerAmount = _balances[owner];
        _balances[owner] = _balances[owner].sub(ownerAmount);
        _balances[newOwner] = _balances[newOwner].add(ownerAmount);
        emit Transfer(owner, newOwner, ownerAmount);   
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, newOwner);

        return true;
    }
}