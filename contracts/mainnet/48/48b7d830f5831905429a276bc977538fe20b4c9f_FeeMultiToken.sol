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

// File: contracts/registry/IDeployer.sol

contract IDeployer is Ownable {
    function deploy(bytes data) external returns(address mtkn);
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

    function asmTransfer(address _token, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(_token.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        return handleReturnBool();
    }

    function asmTransferFrom(address _token, address _from, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(_token.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));
        return handleReturnBool();
    }

    function asmApprove(address _token, address _spender, uint256 _value) internal returns(bool) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(_token.call(bytes4(keccak256("approve(address,uint256)")), _spender, _value));
        return handleReturnBool();
    }

    //

    function checkedTransfer(ERC20 _token, address _to, uint256 _value) internal {
        if (_value > 0) {
            uint256 balance = _token.balanceOf(this);
            asmTransfer(_token, _to, _value);
            require(_token.balanceOf(this) == balance.sub(_value), "checkedTransfer: Final balance didn&#39;t match");
        }
    }

    function checkedTransferFrom(ERC20 _token, address _from, address _to, uint256 _value) internal {
        if (_value > 0) {
            uint256 toBalance = _token.balanceOf(_to);
            asmTransferFrom(_token, _from, _to, _value);
            require(_token.balanceOf(_to) == toBalance.add(_value), "checkedTransfer: Final balance didn&#39;t match");
        }
    }

    //

    function asmName(address _token) internal view returns(bytes32) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(_token.call(bytes4(keccak256("name()"))));
        return handleReturnBytes32();
    }

    function asmSymbol(address _token) internal view returns(bytes32) {
        require(isContract(_token));
        // solium-disable-next-line security/no-low-level-calls
        require(_token.call(bytes4(keccak256("symbol()"))));
        return handleReturnBytes32();
    }
}

// File: contracts/interface/IBasicMultiToken.sol

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    ERC20[] public tokens;

    function tokensCount() public view returns(uint256);

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;

    function disableBundling() public;
    function enableBundling() public;
}

// File: contracts/interface/IMultiToken.sol

contract IMultiToken is IBasicMultiToken {
    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);

    mapping(address => uint256) public weights;

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 returnAmount);

    function disableChanges() public;
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

// File: contracts/ext/ERC1003Token.sol

contract ERC1003Caller is Ownable {
    function makeCall(address _target, bytes _data) external payable onlyOwner returns (bool) {
        // solium-disable-next-line security/no-call-value
        return _target.call.value(msg.value)(_data);
    }
}


contract ERC1003Token is ERC20 {
    ERC1003Caller public caller_ = new ERC1003Caller();
    address[] internal sendersStack_;

    function approveAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        sendersStack_.push(msg.sender);
        approve(_to, _value);
        require(caller_.makeCall.value(msg.value)(_to, _data));
        sendersStack_.length -= 1;
        return true;
    }

    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        transfer(_to, _value);
        require(caller_.makeCall.value(msg.value)(_to, _data));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        address from = (_from != address(caller_)) ? _from : sendersStack_[sendersStack_.length - 1];
        return super.transferFrom(from, _to, _value);
    }
}

// File: contracts/BasicMultiToken.sol

contract BasicMultiToken is Ownable, StandardToken, DetailedERC20, ERC1003Token, IBasicMultiToken {
    using CheckedERC20 for ERC20;
    using CheckedERC20 for DetailedERC20;

    uint internal inLendingMode;
    bool public bundlingEnabled = true;

    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);
    event BundlingStatus(bool enabled);

    modifier notInLendingMode {
        require(inLendingMode == 0, "Operation can&#39;t be performed while lending");
        _;
    }

    modifier whenBundlingEnabled {
        require(bundlingEnabled, "Bundling is disabled");
        _;
    }

    constructor() public DetailedERC20("", "", 0) {
    }

    function init(ERC20[] _tokens, string _name, string _symbol, uint8 _decimals) public {
        require(decimals == 0, "init: contract was already initialized");
        require(_decimals > 0, "init: _decimals should not be zero");
        require(bytes(_name).length > 0, "init: _name should not be empty");
        require(bytes(_symbol).length > 0, "init: _symbol should not be empty");
        require(_tokens.length >= 2, "Contract do not support less than 2 inner tokens");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tokens = _tokens;
    }

    function tokensCount() public view returns(uint) {
        return tokens.length;
    }

    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ == 0, "bundleFirstTokens: This method can be used with zero total supply only");
        _bundle(_beneficiary, _amount, _tokenAmounts);
    }

    function bundle(address _beneficiary, uint256 _amount) public whenBundlingEnabled notInLendingMode {
        require(totalSupply_ != 0, "This method can be used with non zero total supply only");
        uint256[] memory tokenAmounts = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenAmounts[i] = tokens[i].balanceOf(this).mul(_amount).div(totalSupply_);
        }
        _bundle(_beneficiary, _amount, tokenAmounts);
    }

    function unbundle(address _beneficiary, uint256 _value) public notInLendingMode {
        unbundleSome(_beneficiary, _value, tokens);
    }

    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public notInLendingMode {
        require(_tokens.length > 0, "Array of tokens can&#39;t be empty");

        uint256 totalSupply = totalSupply_;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply.sub(_value);
        emit Unbundle(msg.sender, _beneficiary, _value);
        emit Transfer(msg.sender, 0, _value);

        for (uint i = 0; i < _tokens.length; i++) {
            for (uint j = 0; j < i; j++) {
                require(_tokens[i] != _tokens[j], "unbundleSome: should not unbundle same token multiple times");
            }
            uint256 tokenAmount = _tokens[i].balanceOf(this).mul(_value).div(totalSupply);
            _tokens[i].checkedTransfer(_beneficiary, tokenAmount);
        }
    }

    // Admin methods

    function disableBundling() public onlyOwner {
        require(bundlingEnabled, "Bundling is already disabled");
        bundlingEnabled = false;
        emit BundlingStatus(false);
    }

    function enableBundling() public onlyOwner {
        require(!bundlingEnabled, "Bundling is already enabled");
        bundlingEnabled = true;
        emit BundlingStatus(true);
    }

    // Internal methods

    function _bundle(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) internal {
        require(_amount != 0, "Bundling amount should be non-zero");
        require(tokens.length == _tokenAmounts.length, "Lenghts of tokens and _tokenAmounts array should be equal");

        for (uint i = 0; i < tokens.length; i++) {
            require(_tokenAmounts[i] != 0, "Token amount should be non-zero");
            tokens[i].checkedTransferFrom(msg.sender, this, _tokenAmounts[i]);
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_beneficiary] = balances[_beneficiary].add(_amount);
        emit Bundle(msg.sender, _beneficiary, _amount);
        emit Transfer(0, _beneficiary, _amount);
    }

    // Instant Loans

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        _token.asmTransfer(_to, _amount);
        inLendingMode += 1;
        require(caller_.makeCall.value(msg.value)(_target, _data), "lend: arbitrary call failed");
        inLendingMode -= 1;
        require(_token.balanceOf(this) >= prevBalance, "lend: lended token must be refilled");
    }
}

// File: contracts/MultiToken.sol

contract MultiToken is IMultiToken, BasicMultiToken {
    using CheckedERC20 for ERC20;

    uint256 internal minimalWeight;
    bool public changesEnabled = true;

    event ChangesDisabled();

    modifier whenChangesEnabled {
        require(changesEnabled, "Operation can&#39;t be performed because changes are disabled");
        _;
    }

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        super.init(_tokens, _name, _symbol, _decimals);
        require(_weights.length == tokens.length, "Lenghts of _tokens and _weights array should be equal");
        for (uint i = 0; i < tokens.length; i++) {
            require(_weights[i] != 0, "The _weights array should not contains zeros");
            require(weights[tokens[i]] == 0, "The _tokens array have duplicates");
            weights[tokens[i]] = _weights[i];
            if (minimalWeight == 0 || _weights[i] < minimalWeight) {
                minimalWeight = _weights[i];
            }
        }
    }

    function init2(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 _decimals) public {
        init(_tokens, _weights, _name, _symbol, _decimals);
    }

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns(uint256 returnAmount) {
        if (weights[_fromToken] > 0 && weights[_toToken] > 0 && _fromToken != _toToken) {
            uint256 fromBalance = ERC20(_fromToken).balanceOf(this);
            uint256 toBalance = ERC20(_toToken).balanceOf(this);
            returnAmount = _amount.mul(toBalance).mul(weights[_fromToken]).div(
                _amount.mul(weights[_fromToken]).div(minimalWeight).add(fromBalance).mul(weights[_toToken])
            );
        }
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public whenChangesEnabled notInLendingMode returns(uint256 returnAmount) {
        returnAmount = getReturn(_fromToken, _toToken, _amount);
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= _minReturn, "The return amount is less than _minReturn value");

        ERC20(_fromToken).checkedTransferFrom(msg.sender, this, _amount);
        ERC20(_toToken).checkedTransfer(msg.sender, returnAmount);

        emit Change(_fromToken, _toToken, msg.sender, _amount, returnAmount);
    }

    // Admin methods

    function disableChanges() public onlyOwner {
        require(changesEnabled, "Changes are already disabled");
        changesEnabled = false;
        emit ChangesDisabled();
    }
}

// File: contracts/FeeMultiToken.sol

contract FeeMultiToken is Ownable, MultiToken {
    using CheckedERC20 for ERC20;

    uint256 public constant TOTAL_PERCRENTS = 1000000;
    uint256 public lendFee;
    uint256 public changeFee;
    uint256 public refferalFee;

    function init(ERC20[] _tokens, uint256[] _weights, string _name, string _symbol, uint8 /*_decimals*/) public {
        super.init(_tokens, _weights, _name, _symbol, 18);
    }

    function setLendFee(uint256 _lendFee) public onlyOwner {
        require(_lendFee <= 30000, "setLendFee: fee should be not greater than 3%");
        lendFee = _lendFee;
    }

    function setChangeFee(uint256 _changeFee) public onlyOwner {
        require(_changeFee <= 30000, "setChangeFee: fee should be not greater than 3%");
        changeFee = _changeFee;
    }

    function setRefferalFee(uint256 _refferalFee) public onlyOwner {
        require(_refferalFee <= 500000, "setChangeFee: fee should be not greater than 50% of changeFee");
        refferalFee = _refferalFee;
    }

    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns(uint256 returnAmount) {
        returnAmount = super.getReturn(_fromToken, _toToken, _amount).mul(TOTAL_PERCRENTS.sub(changeFee)).div(TOTAL_PERCRENTS);
    }

    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns(uint256 returnAmount) {
        returnAmount = changeWithRef(_fromToken, _toToken, _amount, _minReturn, 0);
    }

    function changeWithRef(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn, address _ref) public returns(uint256 returnAmount) {
        returnAmount = super.change(_fromToken, _toToken, _amount, _minReturn);
        uint256 refferalAmount = returnAmount
            .mul(changeFee).div(TOTAL_PERCRENTS.sub(changeFee))
            .mul(refferalFee).div(TOTAL_PERCRENTS);

        ERC20(_toToken).checkedTransfer(_ref, refferalAmount);
    }

    function lend(address _to, ERC20 _token, uint256 _amount, address _target, bytes _data) public payable {
        uint256 prevBalance = _token.balanceOf(this);
        super.lend(_to, _token, _amount, _target, _data);
        require(_token.balanceOf(this) >= prevBalance.mul(TOTAL_PERCRENTS.add(lendFee)).div(TOTAL_PERCRENTS), "lend: tokens must be returned with lend fee");
    }
}