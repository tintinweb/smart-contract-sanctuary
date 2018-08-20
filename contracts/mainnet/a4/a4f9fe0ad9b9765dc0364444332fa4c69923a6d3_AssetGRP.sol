pragma solidity 0.4.24;
/**
* GRP TOKEN Contract
* ERC-20 Token Standard Compliant
* @author Fares A. Akel C. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6b0d450a051f04050204450a000e072b0c060a020745080406">[email&#160;protected]</a>
*/

/**
* @title SafeMath by OpenZeppelin
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
* Token contract interface for external use
*/
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Master address is public
    mapping(address => uint256) public level; //Admin level
    bool public lockSupply; //Burn Lock flag

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    constructor() public {
        admin = 0x6585b849371A40005F9dCda57668C832a5be1777; //Set initial admin
        level[admin] = 2;
        emit Admined(admin);
    }

    modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
        require(msg.sender == admin || level[msg.sender] >= _level);
        _;
    }

    modifier supplyLock() { //A modifier to lock burn transactions
        require(lockSupply == false);
        _;
    }

   /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin(2) public { //Admin can be transfered
        require(_newAdmin != address(0));
        admin = _newAdmin;
        level[_newAdmin] = 2;
        emit TransferAdminship(admin);
    }

    function setAdminLevel(address _target, uint8 _level) onlyAdmin(2) public {
        level[_target] = _level;
        emit AdminLevelSet(_target,_level);
    }

   /**
    * @dev Function to set burn lock
    * @param _set boolean flag (true | false)
    */
    function setSupplyLock(bool _set) onlyAdmin(2) public { //Only the admin can set a lock on supply
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

    //All admin actions have a log for public review
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);
    event AdminLevelSet(address _target,uint8 _level);

}

/**
* @title Token definition
* @dev Define token paramters including ERC20 ones
*/
contract ERC20Token is ERC20TokenInterface, admined { //Standard definition of a ERC20Token
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances

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
    * @param _target The address of the holder of the tokens.
    * @param _burnedAmount amount to burn.
    */
    function burnToken(address _target, uint256 _burnedAmount) onlyAdmin(2) supplyLock public {
        balances[_target] = SafeMath.sub(balances[_target], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(_target, _burnedAmount);
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
* @title AssetGRP
* @dev Initial supply creation
*/
contract AssetGRP is ERC20Token {
    string public name = &#39;Gripo&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;GRP&#39;;
    string public version = &#39;1&#39;;

    address writer = 0xA6bc924715A0B63C6E0a7653d3262D26F254EcFd;

    constructor() public {
        totalSupply = 200000000 * (10**uint256(decimals)); //initial token creation
        balances[writer] = totalSupply / 10000; //0.01%
        balances[admin] = totalSupply.sub(balances[writer]);

        emit Transfer(address(0), writer, balances[writer]);
        emit Transfer(address(0), admin, balances[admin]);
    }

    /**
    *@dev Function to handle callback calls
    */
    function() public {
        revert();
    }

}