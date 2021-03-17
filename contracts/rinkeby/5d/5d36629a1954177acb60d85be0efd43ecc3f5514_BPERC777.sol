/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.4.25;

// File: contracts/ERC777/ERC20Token.sol

/* This Source Code Form is subject to the terms of the Mozilla external
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


interface ERC20Token {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// File: contracts/ERC820/ERC820Client.sol

contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns(address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    // ERC820Registry erc820Registry = ERC820Registry(0x95CCf6bF48319B31B9421862c0f1e5C1158D234D);
    // BayPay Chain
    //ERC820Registry erc820Registry = ERC820Registry(0xb3f9A76baAbb3f32D06d98a21e3bf8ae07B2A6b8);
    ERC1820Registry erc1820Registry = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    function setInterfaceImplementation(string _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        erc1820Registry.setInterfaceImplementer(this, interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return erc1820Registry.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        erc1820Registry.setManager(this, _newManager);
    }
}

// File: contracts/openzeppelin-solidity/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// File: contracts/openzeppelin-solidity/Address.sol

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// File: contracts/ERC777/ERC777Token.sol

/* This Source Code Form is subject to the terms of the Mozilla external
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


interface ERC777Token {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function granularity() external view returns (uint256);

  function defaultOperators() external view returns (address[]);
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;

  function send(address to, uint256 amount, bytes holderData) external;
  function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) external;

  function burn(uint256 amount, bytes holderData) external;
  function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) external;

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes holderData,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// File: contracts/ERC777/ERC777TokensSender.sol

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


interface ERC777TokensSender {
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}

// File: contracts/ERC777/ERC777TokensRecipient.sol

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


interface ERC777TokensRecipient {
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}

// File: contracts/ERC777/ERC777BaseToken.sol

/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

contract ERC777BaseToken is ERC777Token, ERC1820Client {
  using SafeMath for uint256;
  using Address for address;

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
  /// @notice Constructor to create a SelfToken
  /// @param _name Name of the new token
  /// @param _symbol Symbol of the new token.
  /// @param _granularity Minimum transferable chunk.
  constructor(
    string _name,
    string _symbol,
    uint256 _granularity,
    address[] _defaultOperators,
  uint256 _totalSupply
  )
    internal
  {
    mName = _name;
    mSymbol = _symbol;
    mTotalSupply = _totalSupply;
    require(_granularity >= 1);
    mGranularity = _granularity;

    mDefaultOperators = _defaultOperators;
    for (uint i = 0; i < mDefaultOperators.length; i++) {
      mIsDefaultOperator[mDefaultOperators[i]] = true;
    }

    setInterfaceImplementation("ERC777Token", this);
  }

  /* -- ERC777 Interface Implementation -- */

  /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  function send(address _to, uint256 _amount, bytes _userData) external {
    doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
  }

  /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  /// @param _userData Data generated by the user to be sent to the recipient
  /// @param _operatorData Data generated by the operator to be sent to the recipient
  function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) external {
    require(isOperatorFor(msg.sender, _from));
    doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
  }

  function burn(uint256 _amount, bytes _holderData) external {
    doBurn(msg.sender, msg.sender, _amount, _holderData, "");
  }

  function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) external {
    require(isOperatorFor(msg.sender, _tokenHolder));
    doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
  }

  /// @return the name of the token
  function name() external view returns (string) { return mName; }

  /// @return the symbol of the token
  function symbol() external view returns (string) { return mSymbol; }

  /// @return the granularity of the token
  function granularity() external view returns (uint256) { return mGranularity; }

  /// @return the total supply of the token
  function totalSupply() public view returns (uint256) { return mTotalSupply; }

  /// @notice Return the account balance of some account
  /// @param _tokenHolder Address for which the balance is returned
  /// @return the balance of `_tokenAddress`.
  function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

  /// @notice Return the list of default operators
  /// @return the list of all the default operators
  function defaultOperators() external view returns (address[]) { return mDefaultOperators; }

  /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`'s tokens. An operator cannot be reauthorized
  /// @param _operator The operator that wants to be Authorized
  function authorizeOperator(address _operator) external {
    require(_operator != msg.sender);
    require(!mAuthorized[_operator][msg.sender]);

    if (mIsDefaultOperator[_operator]) {
      mRevokedDefaultOperator[_operator][msg.sender] = false;
    } else {
      mAuthorized[_operator][msg.sender] = true;
    }
    emit AuthorizedOperator(_operator, msg.sender);
  }

  /// @notice Revoke a third party `_operator`'s rights to manage (send) `msg.sender`'s tokens.
  /// @param _operator The operator that wants to be Revoked
  function revokeOperator(address _operator) external {
    require(_operator != msg.sender);
    require(mAuthorized[_operator][msg.sender]);

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
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return (
      _operator == _tokenHolder
      || mAuthorized[_operator][_tokenHolder]
      || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder])
    );
  }

  /* -- Helper Functions -- */
  //
  /// @notice Internal function that ensures `_amount` is multiple of the granularity
  /// @param _amount The quantity that want's to be checked
  function requireMultiple(uint256 _amount) internal view {
    require(_amount.div(mGranularity).mul(mGranularity) == _amount);
  }

  /// @notice Helper function actually performing the sending of tokens.
  /// @param _operator The address performing the send
  /// @param _from The address holding the tokens being sent
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be sent
  /// @param _userData Data generated by the user to be passed to the recipient
  /// @param _operatorData Data generated by the operator to be passed to the recipient
  /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
  ///  implementing `ERC777TokensRecipient`.
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
      require(!_to.isContract());
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
    if (senderImplementation == 0) {
      return;
    }
    ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
  }
}

// File: contracts/ERC777/ERC777ERC20BaseToken.sol

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
  bool internal mErc20compatible;
  uint8 private _decimals;

  mapping(address => mapping(address => uint256)) internal mAllowed;

  constructor(
    string _name,
    string _symbol,
    uint256 _granularity,
    address[] _defaultOperators,
    uint8 decimals,
  uint256 _totalSupply
  )
    internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators, _totalSupply)
  {
    mErc20compatible = true;
     _decimals = decimals;
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
  function decimals() external erc20 view returns (uint8) { return _decimals; }

  /// @notice ERC20 backwards compatible transfer.
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be transferred
  /// @return `true`, if the transfer can't be done, it should fail.
  function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
    doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
    return true;
  }

  /// @notice ERC20 backwards compatible transferFrom.
  /// @param _from The address holding the tokens being transferred
  /// @param _to The address of the recipient
  /// @param _amount The number of tokens to be transferred
  /// @return `true`, if the transfer can't be done, it should fail.
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
  /// @return `true`, if the approve can't be done, it should fail.
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
  function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
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
    if (mErc20compatible) {
      emit Transfer(_from, _to, _amount);
    }
  }

  function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    internal
  {
    super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
    if (mErc20compatible) {
      emit Transfer(_tokenHolder, 0x0, _amount);
    }
  }
}

// File: contracts/openzeppelin-solidity/ownership/Ownable.sol

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

// File: contracts/openzeppelin-solidity/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/utils/Freezable.sol

/// @title An inheritable extension for a contract to freeze accessibility of any specific addresses
/// @author Jeff Hu
/// @notice Have a contract inherited from this to use the modifiers: whenAccountFrozen(), whenAccountNotFrozen()
/// @dev Concern: Ownable may cause multiple owners; You need to pass in msg.sender when using modifiers
contract Freezable is Ownable {

  event AccountFrozen(address indexed _account);
  event AccountUnfrozen(address indexed _account);

  // frozen status of all accounts
  mapping(address=>bool) public frozenAccounts;


   /**
   * @dev Modifier to make a function callable only when the address is frozen.
   */
  modifier whenAccountFrozen(address _account) {
    require(frozenAccounts[_account] == true);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the address is not frozen.
   */
  modifier whenAccountNotFrozen(address _account) {
    require(frozenAccounts[_account] == false);
    _;
  }


  /**
   * @dev Function to freeze an account from transactions
   */
  function freeze(address _account)
    external
    onlyOwner
    whenAccountNotFrozen(_account)
    returns (bool)
  {
    frozenAccounts[_account] = true;
    emit AccountFrozen(_account);
    return true;
  }

  /**
   * @dev Function to unfreeze an account form frozen state
   */
  function unfreeze(address _account)
    external
    onlyOwner
    whenAccountFrozen(_account)
    returns (bool)
  {
    frozenAccounts[_account] = false;
    emit AccountUnfrozen(_account);
    return true;
  }


  /**
   * @dev A user can choose to freeze her account (not unfreezable)
   */
  function freezeMyAccount()
    external
    whenAccountNotFrozen(msg.sender)
    returns (bool)
  {
    // require(msg.sender != owner);       // Only the owner cannot freeze herself

    frozenAccounts[msg.sender] = true;
    emit AccountFrozen(msg.sender);
    return true;
  }
}

// File: contracts/PausableFreezableERC777ERC20Token.sol

/// @dev The owner can pause/unpause the token.
/// When paused, all functions that may change the token balances are prohibited.
/// Function approve is prohibited too.
contract PausableFreezableERC777ERC20Token is ERC777ERC20BaseToken, Pausable, Freezable {

  // ERC777 methods

  /// @dev We can not call super.send() because send() is an external function.
  /// We can only override it.
  function send(address _to, uint256 _amount, bytes _userData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_to)
  {
    doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
  }

  function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
  {
    require(isOperatorFor(msg.sender, _from));
    doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
  }

  function burn(uint256 _amount, bytes _holderData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
  {
    doBurn(msg.sender, msg.sender, _amount, _holderData, "");
  }

  function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_tokenHolder)
  {
    require(isOperatorFor(msg.sender, _tokenHolder));
    doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
  }

  // ERC20 methods

  function transfer(address _to, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_to)
    returns (bool success)
  {
    return super.transfer(_to, _amount);
  }

  function transferFrom(address _from, address _to, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
    returns (bool success)
  {
    return super.transferFrom(_from, _to, _amount);
  }

  function approve(address _spender, uint256 _amount)
    public
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_spender)
    returns (bool success)
  {
    return super.approve(_spender, _amount);
  }

  /// @dev allow Owner to transfer funds from a Frozen account
  /// @notice the "_from" account must be frozen
  /// @notice only the owner can trigger this function
  /// @notice super.doSend to skip "_from" frozen checking
  function transferFromFrozenAccount(
    address _from,
    address _to,
    uint256 _amount
  )
    external
    onlyOwner
    whenNotPaused
    whenAccountFrozen(_from)
    whenAccountNotFrozen(_to)
    whenAccountNotFrozen(msg.sender)
  {
    super.doSend(msg.sender, _from, _to, _amount, "", "", true);
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
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_operator)
    whenAccountNotFrozen(_from)
    whenAccountNotFrozen(_to)
  {
    super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
  }

  function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
    internal
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_operator)
    whenAccountNotFrozen(_tokenHolder)
  {
    super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
  }
}

// File: contracts/ERC777ERC20TokenWithOfficialOperators.sol

/// @title ERC777 ERC20 Token with Official Operators
/// @notice Official operators are officially recommended operator contracts.
/// By adding new official operators, we can keep adding new features to
/// an already deployed token contract, which can be viewed as a way to
/// upgrade the token contract.
/// Rules of official operators:
/// 1. An official operator must be a contract.
/// 2. An official operator can only be added or removed by the contract owner.
/// 3. A token holder can either accept all official operators or not.
///    By default, a token holder accepts all official operators, including
///    the official operators added in the future.
/// 4. If a token holder accepts all official operators, it works as if all
///    the addresses of official operators has been authorized to be his operator.
///    In this case, an official operator will always be the token holder's
///    operator even if he tries to revoke it by sending `revokeOperator` transactions.
/// 5. If a token holder chooses not to accept all official operators, it works as if
///    there is no official operator at all for him. The token holder can still authorize
///    any addresses, including which of official operators, to be his operators.
contract ERC777ERC20TokenWithOfficialOperators is ERC777ERC20BaseToken, Ownable {
  using Address for address;

  mapping(address => bool) internal mIsOfficialOperator;
  mapping(address => bool) internal mIsUserNotAcceptingAllOfficialOperators;

  event OfficialOperatorAdded(address operator);
  event OfficialOperatorRemoved(address operator);
  event OfficialOperatorsAcceptedByUser(address indexed user);
  event OfficialOperatorsRejectedByUser(address indexed user);

  /// @notice Add an address into the list of official operators.
  /// @param _operator The address of a new official operator.
  /// An official operator must be a contract.
  function addOfficialOperator(address _operator) external onlyOwner {
    require(_operator.isContract(), "An official operator must be a contract.");
    require(!mIsOfficialOperator[_operator], "_operator is already an official operator.");

    mIsOfficialOperator[_operator] = true;
    emit OfficialOperatorAdded(_operator);
  }

  /// @notice Delete an address from the list of official operators.
  /// @param _operator The address of an official operator.
  function removeOfficialOperator(address _operator) external onlyOwner {
    require(mIsOfficialOperator[_operator], "_operator is not an official operator.");

    mIsOfficialOperator[_operator] = false;
    emit OfficialOperatorRemoved(_operator);
  }

  /// @notice Unauthorize all official operators to manage `msg.sender`'s tokens.
  function rejectAllOfficialOperators() external {
    require(!mIsUserNotAcceptingAllOfficialOperators[msg.sender], "Official operators are already rejected by msg.sender.");

    mIsUserNotAcceptingAllOfficialOperators[msg.sender] = true;
    emit OfficialOperatorsRejectedByUser(msg.sender);
  }

  /// @notice Authorize all official operators to manage `msg.sender`'s tokens.
  function acceptAllOfficialOperators() external {
    require(mIsUserNotAcceptingAllOfficialOperators[msg.sender], "Official operators are already accepted by msg.sender.");

    mIsUserNotAcceptingAllOfficialOperators[msg.sender] = false;
    emit OfficialOperatorsAcceptedByUser(msg.sender);
  }

  /// @return true if the address is an official operator, false if not.
  function isOfficialOperator(address _operator) external view returns(bool) {
    return mIsOfficialOperator[_operator];
  }

  /// @return true if a user is accepting all official operators, false if not.
  function isUserAcceptingAllOfficialOperators(address _user) external view returns(bool) {
    return !mIsUserNotAcceptingAllOfficialOperators[_user];
  }

  /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
  /// @param _operator address to check if it has the right to manage the tokens
  /// @param _tokenHolder address which holds the tokens to be managed
  /// @return `true` if `_operator` is authorized for `_tokenHolder`
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return (
      _operator == _tokenHolder
      || (!mIsUserNotAcceptingAllOfficialOperators[_tokenHolder] && mIsOfficialOperator[_operator])
      || mAuthorized[_operator][_tokenHolder]
      || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder])
    );
  }
}

// File: contracts/ApprovalRecipient.sol

interface ApprovalRecipient {
  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes _extraData
  ) external;
}

// File: contracts/ERC777ERC20TokenWithApproveAndCall.sol

contract ERC777ERC20TokenWithApproveAndCall is PausableFreezableERC777ERC20Token {
  /// Set allowance for other address and notify
  /// Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
  /// From https://www.ethereum.org/token
  /// @param _spender The address authorized to spend
  /// @param _value the max amount they can spend
  /// @param _extraData some extra information to send to the approved contract
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_spender)
    returns (bool success)
  {
    ApprovalRecipient spender = ApprovalRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }
}

// File: contracts/ERC777ERC20TokenWithBatchTransfer.sol

contract ERC777ERC20TokenWithBatchTransfer is PausableFreezableERC777ERC20Token {
  /// @notice ERC20 backwards compatible batch transfer.
  /// The transaction will revert if any of the recipients is frozen.
  /// We check whether a recipient is frozen in `doSend`.
  /// @param _recipients The addresses of the recipients
  /// @param _amounts The numbers of tokens to be transferred
  /// @return `true`, if the transfer can't be done, it should fail.
  function batchTransfer(address[] _recipients, uint256[] _amounts)
    external
    erc20
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    returns (bool success)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, msg.sender, _recipients[i], _amounts[i], "", "", false);
    }
    return true;
  }

  /// @notice Send tokens to multiple recipients.
  /// The transaction will revert if any of the recipients is frozen.
  /// We check whether a recipient is frozen in `doSend`.
  /// @param _recipients The addresses of the recipients
  /// @param _amounts The numbers of tokens to be transferred
  /// @param _userData Data generated by the user to be sent to the recipient
  function batchSend(
    address[] _recipients,
    uint256[] _amounts,
    bytes _userData
  )
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, msg.sender, _recipients[i], _amounts[i], _userData, "", true);
    }
  }

  /// @notice Send tokens to multiple recipients on behalf of the address `from`
  /// The transaction will revert if any of the recipients is frozen.
  /// We check whether a recipient is frozen in `doSend`.
  /// @param _from The address holding the tokens being sent
  /// @param _recipients The addresses of the recipients
  /// @param _amounts The numbers of tokens to be transferred
  /// @param _userData Data generated by the user to be sent to the recipient
  /// @param _operatorData Data generated by the operator to be sent to the recipient
  function operatorBatchSend(
    address _from,
    address[] _recipients,
    uint256[] _amounts,
    bytes _userData,
    bytes _operatorData
  )
    external
    whenNotPaused
    whenAccountNotFrozen(msg.sender)
    whenAccountNotFrozen(_from)
  {
    require(
      _recipients.length == _amounts.length,
      "The lengths of _recipients and _amounts should be the same."
    );
    require(isOperatorFor(msg.sender, _from));

    for (uint256 i = 0; i < _recipients.length; i++) {
      doSend(msg.sender, _from, _recipients[i], _amounts[i], _userData, _operatorData, true);
    }
  }
}

// File: contracts/CappedMintableERC777ERC20Token.sol

/// @title Capped Mintable ERC777 ERC20 Token
/// @dev Mintable token with a minting cap.
///  The owner can mint any amount of tokens until the cap is reached.
contract CappedMintableERC777ERC20Token is ERC777ERC20BaseToken, Ownable {
  uint256 internal mTotalSupplyCap;

  constructor(uint256 _totalSupplyCap) public {
    mTotalSupplyCap = _totalSupplyCap;
     mBalances[msg.sender] =_totalSupplyCap;
     
  }

  /// @return the cap of total supply
  function totalSupplyCap() external view returns(uint _totalSupplyCap) {
    return mTotalSupplyCap;
  }

  /// @dev Generates `_amount` tokens to be assigned to `_tokenHolder`
  ///  Sample mint function to showcase the use of the `Minted` event and the logic to notify the recipient.
  ///  Reference: https://github.com/jacquesd/ERC777/blob/devel/contracts/examples/SelfToken.sol
  /// @param _tokenHolder The address that will be assigned the new tokens
  /// @param _amount The quantity of tokens generated
  /// @param _operatorData Data that will be passed to the recipient as a first transfer
  function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) external onlyOwner {
    requireMultiple(_amount);

    mTotalSupply = mTotalSupply.add(_amount);
    mTotalSupplyCap = mTotalSupplyCap.add(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

    callRecipient(msg.sender, address(0), _tokenHolder, _amount, "", _operatorData, true);

    emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
    if (mErc20compatible) {
      emit Transfer(0x0, _tokenHolder, _amount);
    }
  }
}

// File: contracts/ERC777ERC20TokenWithOperatorApprove.sol

/// @title ERC777 ERC20 Token with Operator Approve
/// @notice Allow an operator to approve tokens for a token holder.
contract ERC777ERC20TokenWithOperatorApprove is ERC777ERC20BaseToken {
  function operatorApprove(
    address _tokenHolder,
    address _spender,
    uint256 _amount
  )
    external
    
    returns (bool success)
  {
    require(
      isOperatorFor(msg.sender, _tokenHolder),
      "msg.sender is not an operator for _tokenHolder"
    );

    mAllowed[_tokenHolder][_spender] = _amount;
    emit Approval(_tokenHolder, _spender, _amount);
    return true;
  }
}

// File: contracts/openzeppelin-solidity/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/BPERC777S.sol

/// @title BPERC777S
/// @dev The inheritance order is important.
contract BPERC777 is
  ERC777ERC20BaseToken,
  PausableFreezableERC777ERC20Token,
  ERC777ERC20TokenWithOfficialOperators,
  ERC777ERC20TokenWithApproveAndCall,
  ERC777ERC20TokenWithBatchTransfer,
  CappedMintableERC777ERC20Token,
  ERC777ERC20TokenWithOperatorApprove,
  Claimable
{
  constructor(uint256 initialSupply, string  tokenName,
        uint8 decimalUnits,
        string tokenSymbol)public
    ERC777ERC20BaseToken(tokenName, tokenSymbol, 1, new address[](0), decimalUnits, initialSupply)
    CappedMintableERC777ERC20Token(initialSupply)
    //delegateManagement(msg.sender)
  {
      delegateManagement(msg.sender);
  }
}