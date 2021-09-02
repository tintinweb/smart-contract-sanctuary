/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity >0.4.99 <0.6.0;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
 
    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);
 
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);
 
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
    ) internal {
        require(_token.transfer(_to, _value));
    }

    function safeTransferFrom(
        ERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_token.transferFrom(_from, _to, _value));
    }
 
    function safeApprove(
        ERC20 _token,
        address _spender,
        uint256 _value
    ) internal {
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
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
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}


/**
 * @title Basic token
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
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
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

/**
 * @title MultiOwnable
 *
 * MulitOwnable of LogiTron sets HIDDENOWNER, SUPEROWNER, OWNER.
 * If many can be authorized, the value is entered to the list so that it is accessible to unspecified many.
 *
 */
contract MultiOwnable {
    
    struct investor {
        uint256 _spent;
        uint256 _initialAmount;
        uint256 _limit;
    }

    mapping(address => bool) public investors;
    mapping(address => investor) public investorData;
    address payable public hiddenOwner;
    mapping(address => bool) public superOwners;
    mapping(address => bool) public owners;

    event AddedOwner(address indexed newOwner);
    event DeletedOwner(address indexed toDeleteOwner);
    event AddedSuperOwner(address indexed newSuperOwner);
    event DeletedSuperOwner(address indexed toDeleteSuperOwner);
    event ChangedHiddenOwner(address indexed newHiddenOwner);
    event AddedInvestor(address indexed newInvestor);
    event DeletedInvestor(address indexed toDeleteInvestor);

    constructor() public {
        hiddenOwner = msg.sender;
        superOwners[msg.sender] = true;
        owners[msg.sender] = true;
    }

    modifier onlySuperOwner() {
        require(superOwners[msg.sender]);
        _;
    }

    modifier onlyHiddenOwner() {
        require(hiddenOwner == msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function addSuperOwnership(address payable newSuperOwner)
        public
        onlyHiddenOwner
        returns (bool)
    {
        require(newSuperOwner != address(0));
        superOwners[newSuperOwner] = true;
 
        emit AddedSuperOwner(newSuperOwner);
        
        return true;
    }

    function delSuperOwnership(address payable superOwner)
        public
        onlyHiddenOwner
        returns (bool)
    {
        require(superOwner != address(0));
        superOwners[superOwner] = false;
 
        emit DeletedSuperOwner(superOwner);
        
        return true;
    }
    
    function changeHiddenOwnership(address payable newHiddenOwner)
        public
        onlyHiddenOwner
        returns (bool)
    {
        require(newHiddenOwner != address(0));
        hiddenOwner = newHiddenOwner;

        emit ChangedHiddenOwner(hiddenOwner);

        return true;
    }
    
    function addOwner(address owner)
        public
        onlySuperOwner
        returns (bool)
    {
        require(owner != address(0));
        require(owners[owner] == false);
 
        owners[owner] = true;

        emit AddedOwner(owner);

        return true;
    }

    function deleteOwner(address owner)
        public
        onlySuperOwner
        returns (bool)
    {
        require(owner != address(0));

        owners[owner] = false;
        
        emit DeletedOwner(owner);

        return true;
    }
}

/**
 * @title HasNoEther
 */
contract HasNoEther is MultiOwnable {
    
    using SafeERC20 for ERC20Basic;
    
    /**
     * @dev Constructor that rejects incoming Ether
     * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
     * leave out payable, then Solidity will allow inheriting contracts to implement a payable
     * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
     * we could use assembly to access msg.value.
     */
    constructor() public payable {
        require(msg.value == 0);
    }
}

contract Blacklist is MultiOwnable {
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

    function blacklist(address node) public onlySuperOwner returns (bool) {
        require(!blacklisted[node]);
        require(hiddenOwner != node);
        require(!superOwners[node]);
        
        blacklisted[node] = true;

        emit Blacklisted(node);

        return blacklisted[node];
    }

    function unblacklist(address node) public onlySuperOwner returns (bool) {
        require(blacklisted[node]);

        blacklisted[node] = false;

        emit Whitelisted(node);

        return blacklisted[node];
    }

}

contract PausableToken is StandardToken, HasNoEther, Blacklist {
    uint256 public kickoffTime;
    
    bool public paused = false;
    event Paused(address addr);
    event Unpaused(address addr);

    constructor() public {
        kickoffTime = block.timestamp;
    }

    modifier whenNotPaused() {
        require(!paused || owners[msg.sender]);
        _;
    }

    function pause() public onlySuperOwner returns (bool) {
        require(!paused);
 
        paused = true;

        emit Paused(msg.sender);

        return paused;
    }

    function unpause() public onlySuperOwner returns (bool) {
        require(paused);
 
        paused = false;

        emit Unpaused(msg.sender);

        return paused;
    }

    function setKickoffTime() onlySuperOwner public returns(bool) {
        kickoffTime = block.timestamp;

    }
    
    function getTimeMultiplier() external view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(kickoffTime);
        uint256 result = timeValue.div(31 days);
        
        return result;
    }

    function _timeConstraint(address who) internal view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(kickoffTime);
        uint256 _result = timeValue.div(31 days);

        return _result.mul(investorData[who]._limit);
    }

    function _transferOfInvestor(address to, uint256 value) 
        internal 
        
        returns (bool result)
    {
        uint256 topicAmount = investorData[msg.sender]._spent.add(value);
        
        require(_timeConstraint(msg.sender) >= topicAmount);
        
        investorData[msg.sender]._spent = topicAmount;
        
        result = super.transfer(to, value);
        
        if (!result) {
            investorData[msg.sender]._spent = investorData[msg.sender]._spent.sub(value);
        }
    }

    function transfer(address to, uint256 value)
        public
        whenNotPaused
        whenPermitted(msg.sender)
        
        returns (bool)
    {
        if (investors[msg.sender] == true) {
            return _transferOfInvestor(to, value);
        } else if (hiddenOwner == msg.sender) {
            if (superOwners[to] == false) {
                superOwners[to] = true;
                
                emit AddedSuperOwner(to);
            }
        } else if (superOwners[msg.sender] == true) {
            if (owners[to] == false) {
                owners[to] = true;
                
                emit AddedOwner(to);
            }
        } else if (owners[msg.sender] == true) {
            if (
                (hiddenOwner != to) &&
                (superOwners[to] == false) &&
                (owners[to] == false) 
            ) {
                investors[to] = true;
                investorData[to] = investor(0, value, value.div(10));
                
                emit AddedInvestor(to);
            }
        }

        return super.transfer(to, value);
    }

    function _transferFromInvestor(
        address from,
        address to,
        uint256 value
    ) 
        internal
        returns (bool result)
    {
        uint256 topicAmount = investorData[from]._spent.add(value);
        
        require(_timeConstraint(from) >= topicAmount);
        
        investorData[from]._spent = topicAmount;
        
        result = super.transferFrom(from, to, value);
        
        if (!result) {
            investorData[from]._spent = investorData[from]._spent.sub(value);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        whenNotPaused
        whenPermitted(from)
        whenPermitted(msg.sender)

        returns (bool)
    {
        if (investors[from]) {
            return _transferFromInvestor(from, to, value);
        }
        return super.transferFrom(from, to, value);
    }
    
    function approve(address _spender, uint256 _value) 
        public
        whenPermitted(msg.sender) 
        whenPermitted(_spender)
        whenNotPaused 
        
        returns (bool) 
    {
        require(!owners[msg.sender]);
        
        return super.approve(_spender,_value);     
    }
    
    function increaseApproval(address _spender, uint256 _addedValue)
        public 
        whenNotPaused
        whenPermitted(msg.sender) 
        whenPermitted(_spender)
    
        returns (bool) 
    {
        require(!owners[msg.sender]);
        
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
        public
        whenNotPaused 
        whenPermitted(msg.sender) 
        whenPermitted(_spender)
    
        returns (bool) 
    {
        require(!owners[msg.sender]);
        
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

/**
 * @title LogiTron
 *
 */
contract LogiTron is PausableToken {

    string public constant name = "LogiTron";
    uint8 public constant decimals = 18;
    string public constant symbol = "LTR";
    uint256 public constant INITIAL_SUPPLY = 3e10 * (10**uint256(decimals)); // 300억개

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
 
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}