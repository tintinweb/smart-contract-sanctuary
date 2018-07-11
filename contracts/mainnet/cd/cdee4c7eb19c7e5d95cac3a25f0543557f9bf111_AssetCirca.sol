pragma solidity 0.4.24;
/**
* @title Circa Token Contract
* @dev Circa is an ERC-20 Standar Compliant Token
* @author Fares A. Akel C. f.antonio.akel@gmail.com
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
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    address public allowedAddress; //An allowed address
    bool public lockSupply; //Burn Lock flag
    bool public lockTransfer = true; //Global transfers flag

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    constructor() internal {
        admin = 0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B; //Set initial admin
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    modifier onlyAllowed() { //A modifier to let allowedAddress work
        require(msg.sender == allowedAddress || msg.sender == admin || lockTransfer == false);
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
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    /**
    * @dev Function to set new allowed address
    * @param _newAllowed The address to transfer rights to
    */
    function setAllowed(address _newAllowed) onlyAdmin public { //Admin can be transfered
        allowedAddress = _newAllowed;
        emit SetAllowedAddress(allowedAddress);
    }

    /**
    * @dev Function to set burn lock
    * This function will be used after the burn process finish
    */
    function setSupplyLock(bool _flag) onlyAdmin public { //Only the admin can set a lock on supply
        lockSupply = _flag;
        emit SetSupplyLock(lockSupply);
    }

    /**
    * @dev Function to set transfer lock
    */
    function setTransferLock(bool _flag) onlyAdmin public { //Only the admin can set a lock on transfers
        lockTransfer = _flag;
        emit SetTransferLock(lockTransfer);
    }

    //All admin actions have a log for public review
    event SetSupplyLock(bool _set);
    event SetTransferLock(bool _set);
    event SetAllowedAddress(address newAllowed);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined, ERC20 { //Standar definition of an ERC20Token
    using SafeMath for uint256; //SafeMath is used for uint256 operations
    mapping (address => uint256) internal balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) internal allowed; //A mapping of all allowances
    uint256 internal totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @notice Get the balance of an _who address.
    * @param _who The address to be query.
    */
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

    /**
    * @notice transfer _value tokens to address _to
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transfer(address _to, uint256 _value) onlyAllowed() public returns (bool) {
        require(_to != address(0)); //Invalid transfer
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    * @return remaining with the allowance value
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @notice Transfer _value tokens from address _from to address _to using allowance msg.sender allowance on _from
    * @param _from The address where tokens comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transferFrom(address _from, address _to, uint256 _value) onlyAllowed() public returns (bool) {
        require(_to != address(0)); //Invalid transfer
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
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Burn token of an specified address.
    * @param _burnedAmount amount to burn.
    */
    function burnToken(uint256 _burnedAmount) supplyLock() onlyAllowed() public returns (bool){
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply_ = SafeMath.sub(totalSupply_, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
        return true;
    }

    event Burned(address indexed _target, uint256 _value);

}

/**
* @title AssetCirca
* @notice Circa Token creation.
* @dev ERC20 Token compliant
*/
contract AssetCirca is ERC20Token {
    string public name = &#39;Circa&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;CIR&#39;;
    string public version = &#39;1&#39;;

    /**
    * @notice token contructor.
    */
    constructor() public {
        totalSupply_ = 1000000000 * 10 ** uint256(decimals); //Initial tokens supply 1,000,000,000;
        //Writer&#39;s equity
        balances[0xEB53AD38f0C37C0162E3D1D4666e63a55EfFC65f] = totalSupply_ / 1000; //0.1%
        balances[0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B] = totalSupply_.sub(balances[0xEB53AD38f0C37C0162E3D1D4666e63a55EfFC65f]); //99.9%

        emit Transfer(0, this, totalSupply_);
        emit Transfer(this, 0xEB53AD38f0C37C0162E3D1D4666e63a55EfFC65f, balances[0xEB53AD38f0C37C0162E3D1D4666e63a55EfFC65f]);
        emit Transfer(this, 0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B, balances[0xEFfea09df22E0B25655BD3f23D9B531ba47d2A8B]);
    }


    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}