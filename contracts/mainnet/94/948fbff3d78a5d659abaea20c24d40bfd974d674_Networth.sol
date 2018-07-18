pragma solidity 0.4.24;
/**
* @title Networth Token Contract
* @dev ERC-20 Token Standar Compliant
* Contact: networthlabs.com
* Airdrop service provided by f.antonio.akel@gmail.com
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
    address public allowed; //Allowed address is public
    bool public transferLock; //global transfer lock

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

    modifier onlyAllowed() { //A modifier to define allowed only function during transfer locks
        require(msg.sender == admin || msg.sender == allowed || transferLock == false);
        _;
    }

    /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(_newAdmin);
    }

    /**
    * @dev Function to set new allowed address
    * @param _newAllowed The address to allow
    */
    function SetAllow(address _newAllowed) onlyAdmin public {
        allowed = _newAllowed;
        emit SetAllowed(_newAllowed);
    }

   /**
    * @dev Function to set transfer locks
    * @param _set boolean flag (true | false)
    */
    function setTransferLock(bool _set) onlyAdmin public { //Only the admin can set a lock on transfers
        transferLock = _set;
        emit SetTransferLock(_set);
    }

    //All admin actions have a log for public review
    event SetTransferLock(bool _set);
    event SetAllowed(address _allowed);
    event TransferAdminship(address _newAdminister);
    event Admined(address _administer);

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
    function transfer(address _to, uint256 _value) onlyAllowed public returns (bool success) {
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
    function transferFrom(address _from, address _to, uint256 _value) onlyAllowed public returns (bool success) {
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
    * @param _amount Targets value.
    */
    function batch(address[] _target,uint256 _amount) onlyAdmin public { //It takes an array of addresses and an amount
        uint256 size = _target.length;
        require( balances[msg.sender] >= size.mul(_amount));
        balances[msg.sender] = balances[msg.sender].sub(size.mul(_amount));

        for (uint i=0; i<size; i++) { //It moves over the array
            balances[_target[i]] = balances[_target[i]].add(_amount);
            emit Transfer(msg.sender, _target[i], _amount);
        }
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenStatus(address _target,bool _flag);

}

/**
* @title Networth
* @notice Networth Token creation.
* @dev ERC20 Token compliant
*/
contract Networth is ERC20Token {
    string public name = &#39;Networth&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;Googol&#39;;
    string public version = &#39;1&#39;;

    /**
    * @notice token contructor.
    */
    constructor() public {
        totalSupply = 250000000 * 10 ** uint256(decimals); //250.000.000 tokens initial supply;
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