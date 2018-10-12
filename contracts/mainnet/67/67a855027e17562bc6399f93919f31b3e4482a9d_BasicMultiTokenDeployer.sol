pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/network/AbstractDeployer.sol

contract AbstractDeployer is Ownable {
    function title() public view returns(string);

    function deploy(bytes data)
        external onlyOwner returns(address result)
    {
        // solium-disable-next-line security/no-low-level-calls
        require(address(this).call(data), "Arbitrary call failed");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            returndatacopy(0, 0, 32)
            result := mload(0)
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


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
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
  function allowance(
    address _owner,
    address _spender
   )
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
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: contracts/ext/CheckedERC20.sol

library CheckedERC20 {
    using SafeMath for uint;

    function isContract(address addr) internal view returns(bool result) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := gt(extcodesize(addr), 0)
        }
    }

    function handleReturnBool() internal pure returns(bool result) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function handleReturnBytes32() internal pure returns(bytes32 result) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            if eq(returndatasize(), 32) { // not a std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            if gt(returndatasize(), 32) { // std erc20
                returndatacopy(0, 64, 32)
                result := mload(0)
            }
            if lt(returndatasize(), 32) { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address token, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
        // solium-disable-next-line security/no-low-level-calls
        require(token.call(bytes4(keccak256("transfer(address,uint256)")), to, value));
        return handleReturnBool();
    }

    function asmTransferFrom(address token, address from, address to, uint256 value) internal returns(bool) {
        require(isContract(token));
        // solium-disable-next-line security/no-low-level-calls
        require(token.call(bytes4(keccak256("transferFrom(address,address,uint256)")), from, to, value));
        return handleReturnBool();
    }

    function asmApprove(address token, address spender, uint256 value) internal returns(bool) {
        require(isContract(token));
        // solium-disable-next-line security/no-low-level-calls
        require(token.call(bytes4(keccak256("approve(address,uint256)")), spender, value));
        return handleReturnBool();
    }

    //

    function checkedTransfer(ERC20 token, address to, uint256 value) internal {
        if (value > 0) {
            uint256 balance = token.balanceOf(this);
            asmTransfer(token, to, value);
            require(token.balanceOf(this) == balance.sub(value), "checkedTransfer: Final balance didn&#39;t match");
        }
    }

    function checkedTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        if (value > 0) {
            uint256 toBalance = token.balanceOf(to);
            asmTransferFrom(token, from, to, value);
            require(token.balanceOf(to) == toBalance.add(value), "checkedTransfer: Final balance didn&#39;t match");
        }
    }

    //

    function asmName(address token) internal view returns(bytes32) {
        require(isContract(token));
        // solium-disable-next-line security/no-low-level-calls
        require(token.call(bytes4(keccak256("name()"))));
        return handleReturnBytes32();
    }

    function asmSymbol(address token) internal view returns(bytes32) {
        require(isContract(token));
        // solium-disable-next-line security/no-low-level-calls
        require(token.call(bytes4(keccak256("symbol()"))));
        return handleReturnBytes32();
    }
}

// File: contracts/ext/ERC1003Token.sol

contract ERC1003Caller is Ownable {
    function makeCall(address target, bytes data) external payable onlyOwner returns (bool) {
        // solium-disable-next-line security/no-call-value
        return target.call.value(msg.value)(data);
    }
}


contract ERC1003Token is ERC20 {
    ERC1003Caller private _caller = new ERC1003Caller();
    address[] internal _sendersStack;

    function caller() public view returns(ERC1003Caller) {
        return _caller;
    }

    function approveAndCall(address to, uint256 value, bytes data) public payable returns (bool) {
        _sendersStack.push(msg.sender);
        approve(to, value);
        require(_caller.makeCall.value(msg.value)(to, data));
        _sendersStack.length -= 1;
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes data) public payable returns (bool) {
        transfer(to, value);
        require(_caller.makeCall.value(msg.value)(to, data));
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = (from != address(_caller)) ? from : _sendersStack[_sendersStack.length - 1];
        return super.transferFrom(spender, to, value);
    }
}

// File: contracts/interface/IBasicMultiToken.sol

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    function tokensCount() public view returns(uint256);
    function tokens(uint i) public view returns(ERC20);
    
    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;

    function disableBundling() public;
    function enableBundling() public;
}

// File: contracts/BasicMultiToken.sol

contract BasicMultiToken is Ownable, StandardToken, DetailedERC20, ERC1003Token, IBasicMultiToken {
    using CheckedERC20 for ERC20;
    using CheckedERC20 for DetailedERC20;

    ERC20[] private _tokens;
    uint private _inLendingMode;
    bool private _bundlingEnabled = true;

    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);
    event BundlingStatus(bool enabled);

    modifier notInLendingMode {
        require(_inLendingMode == 0, "Operation can&#39;t be performed while lending");
        _;
    }

    modifier whenBundlingEnabled {
        require(_bundlingEnabled, "Bundling is disabled");
        _;
    }

    constructor(ERC20[] tokens, string name, string symbol, uint8 decimals)
        public DetailedERC20(name, symbol, decimals)
    {
        require(decimals > 0, "constructor: _decimals should not be zero");
        require(bytes(name).length > 0, "constructor: name should not be empty");
        require(bytes(symbol).length > 0, "constructor: symbol should not be empty");
        require(tokens.length >= 2, "Contract does not support less than 2 inner tokens");

        _tokens = tokens;
    }

    function tokensCount() public view returns(uint) {
        return _tokens.length;
    }

    function tokens(uint i) public view returns(ERC20) {
        return _tokens[i];
    }

    function inLendingMode() public view returns(uint) {
        return _inLendingMode;
    }

    function bundlingEnabled() public view returns(bool) {
        return _bundlingEnabled;
    }

    function bundleFirstTokens(address beneficiary, uint256 amount, uint256[] tokenAmounts) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ == 0, "bundleFirstTokens: This method can be used with zero total supply only");
        _bundle(beneficiary, amount, tokenAmounts);
    }

    function bundle(address beneficiary, uint256 amount) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            tokenAmounts[i] = _tokens[i].balanceOf(this).mul(amount).div(totalSupply_);
        }
        _bundle(beneficiary, amount, tokenAmounts);
    }

    function unbundle(address beneficiary, uint256 value) public notInLendingMode {
        unbundleSome(beneficiary, value, _tokens);
    }

    function unbundleSome(address beneficiary, uint256 value, ERC20[] someTokens) public notInLendingMode {
        _unbundle(beneficiary, value, someTokens);
    }

    // Admin methods

    function disableBundling() public onlyOwner {
        require(_bundlingEnabled, "Bundling is already disabled");
        _bundlingEnabled = false;
        emit BundlingStatus(false);
    }

    function enableBundling() public onlyOwner {
        require(!_bundlingEnabled, "Bundling is already enabled");
        _bundlingEnabled = true;
        emit BundlingStatus(true);
    }

    // Internal methods

    function _bundle(address beneficiary, uint256 amount, uint256[] tokenAmounts) internal {
        require(amount != 0, "Bundling amount should be non-zero");
        require(_tokens.length == tokenAmounts.length, "Lenghts of _tokens and tokenAmounts array should be equal");

        for (uint i = 0; i < _tokens.length; i++) {
            require(tokenAmounts[i] != 0, "Token amount should be non-zero");
            _tokens[i].checkedTransferFrom(msg.sender, this, tokenAmounts[i]);
        }

        totalSupply_ = totalSupply_.add(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit Bundle(msg.sender, beneficiary, amount);
        emit Transfer(0, beneficiary, amount);
    }

    function _unbundle(address beneficiary, uint256 value, ERC20[] someTokens) internal {
        require(someTokens.length > 0, "Array of someTokens can&#39;t be empty");

        uint256 totalSupply = totalSupply_;
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply_ = totalSupply.sub(value);
        emit Unbundle(msg.sender, beneficiary, value);
        emit Transfer(msg.sender, 0, value);

        for (uint i = 0; i < someTokens.length; i++) {
            for (uint j = 0; j < i; j++) {
                require(someTokens[i] != someTokens[j], "unbundleSome: should not unbundle same token multiple times");
            }
            uint256 tokenAmount = someTokens[i].balanceOf(this).mul(value).div(totalSupply);
            someTokens[i].checkedTransfer(beneficiary, tokenAmount);
        }
    }

    // Instant Loans

    function lend(address to, ERC20 token, uint256 amount, address target, bytes data) public payable {
        uint256 prevBalance = token.balanceOf(this);
        token.asmTransfer(to, amount);
        _inLendingMode += 1;
        require(caller().makeCall.value(msg.value)(target, data), "lend: arbitrary call failed");
        _inLendingMode -= 1;
        require(token.balanceOf(this) >= prevBalance, "lend: lended token must be refilled");
    }
}

// File: contracts/network/BasicMultiTokenDeployer.sol

contract BasicMultiTokenDeployer is AbstractDeployer {
    function title() public view returns(string) {
        return "BasicMultiTokenDeployer";
    }

    function create(ERC20[] tokens, string name, string symbol, uint8 decimals)
        external returns(address)
    {
        require(msg.sender == address(this), "Should be called only from deployer itself");
        BasicMultiToken mtkn = new BasicMultiToken(tokens, name, symbol, decimals);
        mtkn.transferOwnership(msg.sender);
        return mtkn;
    }
}