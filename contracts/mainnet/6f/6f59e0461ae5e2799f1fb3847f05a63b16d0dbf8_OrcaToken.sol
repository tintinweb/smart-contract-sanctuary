pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// Custom contracts developed or adapted for OrcaToken
// ---------------------------------------------------

contract TokenRecoverable is Ownable {
    using SafeERC20 for ERC20Basic;

    function recoverTokens(ERC20Basic token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount);
        token.safeTransfer(to, amount);
    }
}

// File: contracts/eip820/contracts/ERC820Implementer.sol

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}


contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

contract ERC20Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;

    function send(address to, uint256 amount, bytes holderData) public;
    function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) public;

    function burn(uint256 amount, bytes holderData) public;
    function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes holderData,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

contract ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

contract ERC777TokensSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

contract ERC777BaseToken is ERC777Token, ERC820Implementer {
    using SafeMath for uint256;

    string internal mName;
    string internal mSymbol;
    uint256 internal mGranularity;
    uint256 internal mTotalSupply;


    mapping(address => uint) internal mBalances;
    mapping(address => mapping(address => bool)) internal mAuthorized;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;

    /* -- Constructor -- */
    //
    /// @notice Constructor to create a ReferenceToken
    /// @param _name Name of the new token
    /// @param _symbol Symbol of the new token.
    /// @param _granularity Minimum transferable chunk.
    constructor(string _name, string _symbol, uint256 _granularity, address[] _defaultOperators) internal {
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = 0;
        require(_granularity >= 1);
        mGranularity = _granularity;

        mDefaultOperators = _defaultOperators;
        for (uint i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

        setInterfaceImplementation("ERC777Token", this);
    }

    /* -- ERC777 Interface Implementation -- */
    //
    /// @return the name of the token
    function name() public constant returns (string) { return mName; }

    /// @return the symbol of the token
    function symbol() public constant returns (string) { return mSymbol; }

    /// @return the granularity of the token
    function granularity() public constant returns (uint256) { return mGranularity; }

    /// @return the total supply of the token
    function totalSupply() public constant returns (uint256) { return mTotalSupply; }

    /// @notice Return the account balance of some account
    /// @param _tokenHolder Address for which the balance is returned
    /// @return the balance of `_tokenAddress`.
    function balanceOf(address _tokenHolder) public constant returns (uint256) { return mBalances[_tokenHolder]; }

    /// @notice Return the list of default operators
    /// @return the list of all the default operators
    function defaultOperators() public view returns (address[]) { return mDefaultOperators; }

    /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
    }

    /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens.
    /// @param _operator The operator that wants to be Authorized
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorized[_operator][msg.sender] = true;
        }
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens.
    /// @param _operator The operator that wants to be Revoked
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorized[_operator][msg.sender] = false;
        }
        emit RevokedOperator(_operator, msg.sender);
    }

    /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
    /// @param _operator address to check if it has the right to manage the tokens
    /// @param _tokenHolder address which holds the tokens to be managed
    /// @return `true` if `_operator` is authorized for `_tokenHolder`
    function isOperatorFor(address _operator, address _tokenHolder) public constant returns (bool) {
        return (_operator == _tokenHolder
            || mAuthorized[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _holderData) public {
        doBurn(msg.sender, msg.sender, _amount, _holderData, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder));
        doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
    }

    /* -- Helper Functions -- */
    //
    /// @notice Internal function that ensures `_amount` is multiple of the granularity
    /// @param _amount The quantity that want&#39;s to be checked
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

    /// @notice Check whether an address is a regular address or not.
    /// @param _addr Address of the contract that has to be checked
    /// @return `true` if `_addr` is a regular address (not a contract)
    function isRegularAddress(address _addr) internal constant returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line no-inline-assembly
        return size == 0;
    }

    /// @notice Helper function actually performing the sending of tokens.
    /// @param _operator The address performing the send
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `erc777_tokenHolder`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));          // forbid sending to 0x0 (=burning)
        require(mBalances[_from] >= _amount); // ensure enough funds

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
    }

    /// @notice Helper function actually performing the burning of tokens.
    /// @param _operator The address performing the burn
    /// @param _tokenHolder The address holding the tokens being burn
    /// @param _amount The number of tokens to be burnt
    /// @param _holderData Data generated by the token holder
    /// @param _operatorData Data generated by the operator
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount);

        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
        emit Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
    }

    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _operator The address performing the send or mint
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

    /// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    ///  implementing `ERC777TokensSender`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    )
        internal
    {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation == 0) { return; }
        ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
    }
}

contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
    bool internal mErc20compatible;

    mapping(address => mapping(address => bool)) internal mAuthorized;
    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        address[] _defaultOperators
    )
        internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /// @notice This modifier is applied to erc20 obsolete methods that are
    ///  implemented only to maintain backwards compatibility. When the erc20
    ///  compatibility is disabled, this methods will fail.
    modifier erc20 () {
        require(mErc20compatible);
        _;
    }

    /// @notice For Backwards compatibility
    /// @return The decimls of the token. Forced to 18 in ERC777.
    function decimals() public erc20 constant returns (uint8) { return uint8(18); }

    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can&#39;t be done, it should fail.
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can&#39;t be done, it should fail.
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

        // Cannot be after doSend because of tokensReceived re-entry
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can&#39;t be done, it should fail.
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public erc20 constant returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
    }
}

contract OrcaToken is TokenRecoverable, ERC777ERC20BaseToken {
    using SafeMath for uint256;

    string private constant name_ = "ORCA Token";
    string private constant symbol_ = "ORCA";
    uint256 private constant granularity_ = 1;

    bool public throwOnIncompatibleContract = true;
    bool public burnEnabled = false;
    bool public mintingFinished = false;

    address public communityLock = address(0);

    event MintFinished();

    /// @notice Constructor to create a OrcaToken
    constructor() public ERC777ERC20BaseToken(name_, symbol_, granularity_, new address[](0)) {
        setInterfaceImplementation("ERC20Token", address(this));
        setInterfaceImplementation("ERC777Token", address(this));
    }

    modifier canMint() {
        require(!mintingFinished);
      _;
    }

    modifier canTrade() {
        require(mintingFinished);
        _;
    }

    modifier canBurn() {
        require(burnEnabled || msg.sender == communityLock);
        _;
    }

    /// @notice Disables the ERC20 interface. This function can only be called
    ///  by the owner.
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
    }

    /// @notice Re enables the ERC20 interface. This function can only be called
    ///  by the owner.
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    function send(address _to, uint256 _amount, bytes _userData) public canTrade {
        super.send(_to, _amount, _userData);
    }

    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public canTrade {
        super.operatorSend(_from, _to, _amount, _userData, _operatorData);
    }

    function transfer(address _to, uint256 _amount) public erc20 canTrade returns (bool success) {
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public erc20 canTrade returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }

    /* -- Mint And Burn Functions (not part of the ERC777 standard, only the Events/tokensReceived call are) -- */
    //
    /// @notice Generates `_amount` tokens to be assigned to `_tokenHolder`
    ///  Sample mint function to showcase the use of the `Minted` event and the logic to notify the recipient.
    /// @param _tokenHolder The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @param _operatorData Data that will be passed to the recipient as a first transfer
    function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public onlyOwner canMint {
        requireMultiple(_amount);
        mTotalSupply = mTotalSupply.add(_amount);
        mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

        callRecipient(msg.sender, 0x0, _tokenHolder, _amount, "", _operatorData, false);

        emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
        if (mErc20compatible) { emit Transfer(0x0, _tokenHolder, _amount); }
    }

    /// @notice Burns `_amount` tokens from `_tokenHolder`
    ///  Sample burn function to showcase the use of the `Burned` event.
    /// @param _amount The quantity of tokens to burn
    function burn(uint256 _amount, bytes _holderData) public canBurn {
        super.burn(_amount, _holderData);
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint {
        mintingFinished = true;
        emit MintFinished();
    }

    function setThrowOnIncompatibleContract(bool _throwOnIncompatibleContract) public onlyOwner {
        throwOnIncompatibleContract = _throwOnIncompatibleContract;
    }

    function setCommunityLock(address _communityLock) public onlyOwner {
        require(_communityLock != address(0));
        communityLock = _communityLock;
    }

    function permitBurning(bool _enable) public onlyOwner {
        burnEnabled = _enable;
    }

    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) internal {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (throwOnIncompatibleContract && _preventLocking) {
            require(isRegularAddress(_to));
        }
    }
}