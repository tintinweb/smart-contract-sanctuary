pragma solidity ^0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Operated
 * @dev The Operated contract has a list of ops addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Operated {
    mapping(address => bool) private _ops;

    event OperatorChanged(
        address indexed operator,
        bool active
    );

    /**
     * @dev The Operated constructor sets the original ops account of the contract to the sender
     * account.
     */
    constructor() internal {
        _ops[msg.sender] = true;
        emit OperatorChanged(msg.sender, true);
    }

    /**
     * @dev Throws if called by any account other than the operations accounts.
     */
    modifier onlyOps() {
        require(isOps(), "only operations accounts are allowed to call this function");
        _;
    }

    /**
     * @return true if `msg.sender` is an operator.
     */
    function isOps() public view returns(bool) {
        return _ops[msg.sender];
    }

    /**
     * @dev Allows the current operations accounts to give control of the contract to new accounts.
     * @param _account The address of the new account
     * @param _active Set active (true) or inactive (false)
     */
    function setOps(address _account, bool _active) public onlyOps {
        _ops[_account] = _active;
        emit OperatorChanged(_account, _active);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title WHISKY TOKEN
 * @author WHYTOKEN GmbH
 * @notice WHISKY TOKEN (WHY) stands for a disruptive new possibility in the crypto currency market
 * due to the combination of High-End Whisky and Blockchain technology.
 * WHY is a german based token, which lets everyone participate in the lucrative crypto market
 * with minimal risk and effort through a high-end whisky portfolio as security.
 */
contract WhiskyToken is IERC20, Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

    // ERC20 standard variables
    string public name = "Whisky Token";
    string public symbol = "WHY";
    uint8 public decimals = 18;
    uint256 public initialSupply = 28100000 * (10 ** uint256(decimals));
    uint256 public totalSupply;

    // Address of the ICO contract
    address public crowdSaleContract;

    // The asset value of the whisky in EUR cents
    uint64 public assetValue;

    // Fee to charge on every transfer (e.g. 15 is 1,5%)
    uint64 public feeCharge;

    // Global freeze of all transfers
    bool public freezeTransfer;

    // Flag to make all token available
    bool private tokenAvailable;

    // Maximum value for feeCharge
    uint64 private constant feeChargeMax = 20;

    // Address of the account/wallet which should receive the fees
    address private feeReceiver;

    // Mappings of addresses for balances, allowances and frozen accounts
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

    // Event definitions
    event Fee(address indexed payer, uint256 fee);
    event FeeCharge(uint64 oldValue, uint64 newValue);
    event AssetValue(uint64 oldValue, uint64 newValue);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address indexed target, bool frozen);
    event FreezeTransfer(bool frozen);

    // Constructor which gets called once on contract deployment
    constructor(address _tokenOwner) public {
        transferOwnership(_tokenOwner);
        setOps(_tokenOwner, true);
        crowdSaleContract = msg.sender;
        feeReceiver = _tokenOwner;
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        assetValue = 0;
        feeCharge = 15;
        freezeTransfer = true;
        tokenAvailable = true;
    }

    /**
     * @notice Returns the total supply of tokens.
     * @dev The total supply is the amount of tokens which are currently in circulation.
     * @return Amount of tokens in Sip.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice Gets the balance of the specified address.
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount of tokens owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (!tokenAvailable) {
            return 0;
        }
        return balances[_owner];
    }

    /**
     * @dev Internal transfer, can only be called by this contract.
     * Will throw an exception to rollback the transaction if anything is wrong.
     * @param _from The address from which the tokens should be transfered from.
     * @param _to The address to which the tokens should be transfered to.
     * @param _value The amount of tokens which should be transfered in Sip.
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "zero address is not allowed");
        require(_value >= 1000, "must transfer more than 1000 sip");
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(!frozenAccount[_from], "sender address is frozen");
        require(!frozenAccount[_to], "receiver address is frozen");

        uint256 transferValue = _value;
        if (msg.sender != owner() && msg.sender != crowdSaleContract) {
            uint256 fee = _value.div(1000).mul(feeCharge);
            transferValue = _value.sub(fee);
            balances[feeReceiver] = balances[feeReceiver].add(fee);
            emit Fee(msg.sender, fee);
        }

        // SafeMath.sub will throw if there is not enough balance.
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(transferValue);
        if (tokenAvailable) {
            emit Transfer(_from, _to, transferValue);
        }
    }

    /**
     * @notice Transfer tokens to a specified address. The message sender has to pay the fee.
     * @dev Calls _transfer with message sender address as _from parameter.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred in Sip.
     * @return Indicates if the transfer was successful.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another. The message sender has to pay the fee.
     * @dev Calls _transfer with the addresses provided by the transactor.
     * @param _from The address which you want to send tokens from.
     * @param _to The address which you want to transfer to.
     * @param _value The amount of tokens to be transferred in Sip.
     * @return Indicates if the transfer was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "requesting more token than allowed");

        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of the transactor.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _value The amount of tokens to be spent in Sip.
     * @return Indicates if the approval was successful.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_value >= 1000, "must approve more than 1000 sip");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Returns the amount of tokens that the owner allowed to the spender.
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner The address which owns the tokens.
     * @param _spender The address which is allowed to retrieve the tokens.
     * @return The amount of tokens still available for the spender in Sip.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @dev Approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _addedValue The amount of tokens to increase the allowance by in Sip.
     * @return Indicates if the approval was successful.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_addedValue >= 1000, "must approve more than 1000 sip");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender. 
     * @dev Approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _subtractedValue The amount of tokens to decrease the allowance by in Sip.
     * @return Indicates if the approval was successful.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_subtractedValue >= 1000, "must approve more than 1000 sip");

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    } 

    /**
     * @notice Burns a specific amount of tokens.
     * @dev Tokens get technically destroyed by this function and are therefore no longer in circulation afterwards.
     * @param _value The amount of token to be burned in Sip.
     */
    function burn(uint256 _value) public {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_value <= balances[msg.sender], "address has not enough token to burn");
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

    /**
     * @notice Not for public use!
     * @dev Modifies the assetValue which represents the monetized value (in EUR) of the whisky baking the token.
     * @param _value The new value of the asset in EUR cents.
     */
    function setAssetValue(uint64 _value) public onlyOwner {
        uint64 oldValue = assetValue;
        assetValue = _value;
        emit AssetValue(oldValue, _value);
    }

    /**
     * @notice Not for public use!
     * @dev Modifies the feeCharge which calculates the fee for each transaction.
     * @param _value The new value of the feeCharge as fraction of 1000 (e.g. 15 is 1,5%).
     */
    function setFeeCharge(uint64 _value) public onlyOwner {
        require(_value <= feeChargeMax, "can not increase fee charge over it&#39;s limit");
        uint64 oldValue = feeCharge;
        feeCharge = _value;
        emit FeeCharge(oldValue, _value);
    }


    /**
     * @notice Not for public use!
     * @dev Prevents/Allows target from sending & receiving tokens.
     * @param _target Address to be frozen.
     * @param _freeze Either to freeze or unfreeze it.
     */
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        require(_target != address(0), "zero address is not allowed");

        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    /**
     * @notice Not for public use!
     * @dev Globally freeze all transfers for the token.
     * @param _freeze Freeze or unfreeze every transfer.
     */
    function setFreezeTransfer(bool _freeze) public onlyOwner {
        freezeTransfer = _freeze;
        emit FreezeTransfer(_freeze);
    }

    /**
     * @notice Not for public use!
     * @dev Allows the owner to set the address which receives the fees.
     * @param _feeReceiver the address which should receive fees.
     */
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0), "zero address is not allowed");
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice Not for public use!
     * @dev Make all tokens available for ERC20 wallets.
     * @param _available Activate or deactivate all tokens
     */
    function setTokenAvailable(bool _available) public onlyOwner {
        tokenAvailable = _available;
    }
}