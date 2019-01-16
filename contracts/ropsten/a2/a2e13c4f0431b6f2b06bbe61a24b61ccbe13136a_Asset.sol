pragma solidity 0.4.25;
/**
* @notice VSTER TOKEN CONTRACT
* @dev ERC-20 Token Standar Compliant
* @author Fares A. Akel C. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8fe9a1eee1fbe0e1e6e0a1eee4eae3cfe8e2eee6e3a1ece0e2">[email&#160;protected]</a>
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/**
* @title ERC20 Token minimal interface
*/
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public;

}

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public owner; //owner address is public
    bool public lockTransfer; //Transfer Lock flag
    address public allowedAddress; //an address that can override lock condition

    /**
    * @dev Contract constructor
    * define initial owner
    */
    constructor() internal {
        owner = msg.sender; //Set initial owner to contract creator
        emit Admined(owner);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == owner);
        _;
    }

   /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        owner = _newAdmin;
        emit TransferAdminship(owner);
    }

    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
 * @title ERC20TokenInterface
 * @dev Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined, ERC20TokenInterface { //Standar definition of an ERC20Token
    using SafeMath for uint256; //SafeMath is used for uint256 operations
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances
    mapping (address => bool) frozen; //A mapping of all frozen accounts
    uint256 public totalSupply;

    /**
    * @notice Get the balance of an _owner address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 bal) {
        return balances[_owner];
    }

    /**
    * @notice transfer _value tokens to address _to
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(frozen[msg.sender] == false);
        require(_to != address(0)); //If you dont want that people destroy token
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice Transfer _value tokens from address _from to address _to using allowance msg.sender allowance on _from
    * @param _from The address where tokens comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(frozen[_from] == false && frozen[msg.sender] == false);
        require(_to != address(0)); //If you dont want that people destroy token
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @notice Assign allowance _value to _spender address to use the msg.sender balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    * @return success with boolean value true
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @notice Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    * @return remaining with the allowance value
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function setFrozen(address _owner, bool _flag) public onlyAdmin returns (bool success) {
      frozen[_owner] = _flag;
      emit Frozen(_owner,_flag);
      return true;
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Frozen(address indexed _owner, bool _flag);

}

/**
* @title Asset
* @dev Initial supply creation
*/
contract Asset is ERC20Token {
    string public name = &#39;VSTER&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;VAPP&#39;;
    string public version = &#39;1&#39;;

    constructor() public {
        totalSupply = 100000000 * (10**uint256(decimals)); //initial token creation
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, balances[msg.sender]);
    }

    /**
    * @notice Function to claim ANY token stuck on contract accidentally
    * In case of claim of stuck tokens please contact contract owners
    */
    function claimTokens(token _address, address _to) onlyAdmin public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(_to,remainder); //Transfer tokens to creator
    }


    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}