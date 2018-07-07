pragma solidity 0.4.24;
/**
* @title TECH Token Contract
* @dev ERC-20 Token Standar Compliant
* Contact: WorkChainCenters@gmail.com  www.WorkChainCenters.io
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
* @title ERC20 Token minimal interface for external tokens handle
*/
contract token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    bool public lockSupply; //Supply Lock flag

    /**
    * @dev Contract constructor, define initial administrator
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() { //A modifier to lock supply change transactions
        require(lockSupply == false);
        _;
    }

    /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

   /**
    * @dev Function to set supply locks
    * @param _set boolean flag (true | false)
    */
    function setSupplyLock(bool _set) onlyAdmin public { //Only the admin can set a lock on supply
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

    //All admin actions have a log for public review
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
 * @title ERC20TokenInterface
 * @dev Token contract interface for external use
 */
contract ERC20TokenInterface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined,ERC20TokenInterface { //Standard definition of an ERC20Token
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances
    mapping (address => bool) frozen; //A mapping of all frozen status

    /**
    * @dev Get the balance of an specified address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

    /**
    * @dev transfer token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev transfer token from an address to another specified address using allowance
    * @param _from The address where token comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[_from]==false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Assign allowance to an specified address to use the owner balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Burn token of an specified address.
    * @param _burnedAmount amount to burn.
    */
    function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

    /**
    * @dev Frozen account.
    * @param _target The address to being frozen.
    * @param _flag The frozen status to set.
    */
    function setFrozen(address _target,bool _flag) onlyAdmin public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }

    /**
    * @dev Special only admin function for batch tokens assignments.
    * @param _target Array of target addresses.
    * @param _amount Array of target values.
    */
    function batch(address[] _target,uint256[] _amount) onlyAdmin public { //It takes an array of addresses and an amount
        require(_target.length == _amount.length); //data must be same size
        uint256 size = _target.length;
        for (uint i=0; i<size; i++) { //It moves over the array
            transfer(_target[i],_amount[i]); //Caller must hold needed tokens, if not it will revert
        }
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);

}

/**
* @title TECH
* @notice TECH Token creation.
* @dev ERC20 Token compliant
*/
contract TECH is ERC20Token {
    string public name = &#39;TECH&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;TECH&#39;;
    string public version = &#39;0.3&#39;;

    /**
    * @notice token contructor.
    */
    constructor() public {
        totalSupply = 41600000 * 10 ** uint256(decimals); //41.600.000 tokens initial supply;
        balances[msg.sender] = totalSupply;
        emit Transfer(0, msg.sender, totalSupply);
    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function externalTokensRecovery(token _address) onlyAdmin public {
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin
    }


    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}