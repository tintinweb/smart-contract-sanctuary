/*
* This code has not been reviewed.
* Do not use or deploy this code before reviewing it personally first.
*/
pragma solidity ^0.4.24;


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


contract ozs_Ownable {
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
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}


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



contract ERC820Registry {
  function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
  function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
  function setManager(address _addr, address _newManager) external;
  function getManager(address _addr) public view returns(address);
}


/// Base client to interact with the registry.
contract ERC820Client {
  ERC820Registry erc820Registry = ERC820Registry(0x820c4597Fc3E4193282576750Ea4fcfe34DdF0a7);

  function setInterfaceImplementation(string _interfaceLabel, address _implementation) internal {
    bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
    erc820Registry.setInterfaceImplementer(this, interfaceHash, _implementation);
  }

  function interfaceAddr(address addr, string _interfaceLabel) internal view returns(address) {
    bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
    return erc820Registry.getInterfaceImplementer(addr, interfaceHash);
  }

  function delegateManagement(address _newManager) internal {
    erc820Registry.setManager(this, _newManager);
  }
}


contract CertificateController {

    // Address used by off-chain controller service to sign certificate
    mapping(address => bool) public certificateSigners;

    // A nonce used to ensure a certificate can be used only once
    mapping(address => uint) public checkCount;

    event Checked(address sender);

    constructor
    (
        address _certificateSigner
    )
        public
    {
        require(_certificateSigner != address(0), "Valid address required");
        certificateSigners[_certificateSigner] = true;
    }

    /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier isValidCertificate(
        bytes data
    ) {
        require(checkCertificate(data), "Certificate is invalid");
        _;
    }

    /**
     * @dev Check if a certificate is correct
     * @param data Certificate to control
     */
    function checkCertificate(
        bytes data
    )
        public
        returns(bool)
    {
        uint256 e;
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Certificate should be 97 bytes long
        if (data.length != 97) {
            return false;
        }

        // Extract certificate information and expiration time from payload
        assembly {
            // Retrieve expirationTime & ECDSA elements from certificate which is a 97 long bytes
            // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
            e := mload(add(data, 0x20))
            r := mload(add(data, 0x40))
            s := mload(add(data, 0x60))
            v := byte(0, mload(add(data, 0x80)))
        }

        // Certificate should not be expired
        if (e < now) {
            return false;
        }

        if (v < 27) {
            v += 27;
        }

        // Perform ecrecover to ensure message information corresponds to certificate
        if (v == 27 || v == 28) {
            // Extract payload and remove data argument
            bytes memory payload;
            assembly {
                let payloadsize := sub(calldatasize, 160)
                payload := mload(0x40) // allocate new memory
                mstore(0x40, add(payload, and(add(add(payloadsize, 0x20), 0x1f), not(0x1f)))) // boolean trick for padding to 0x40
                mstore(payload, payloadsize) // set length
                calldatacopy(add(payload, 0x20), 0, payloadsize)
            }

            // Pack and hash
            bytes memory pack = abi.encodePacked(
                msg.sender,
                this,
                msg.value,
                payload,
                e,
                checkCount[msg.sender]
            );
            bytes32 hash = keccak256(pack);

            // Check if certificate match expected transactions parameters
            if (certificateSigners[ecrecover(hash, v, r, s)]) {
                // Increment sender check count
                checkCount[msg.sender] += 1;

                emit Checked(msg.sender);

                return true;
            }
        }
        return false;
    }
}


interface IERC777TokensRecipient {
  function canReceive(
    address from,
    address to,
    uint amount,
    bytes userData
  ) external view returns(bool);

  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}


interface IERC777TokensSender {
  function canSend(
    address from,
    address to,
    uint amount,
    bytes userData
  ) external view returns(bool);

  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) external;
}



interface IERC777 {
  function name() external view returns (string); // 1/13
  function symbol() external view returns (string); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function defaultOperators() external view returns (address[]); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool); // 9/13

  function sendTo(address to, uint256 amount, bytes data) external; // 10/13
  function operatorSendTo(address from, address to, uint256 amount, bytes data, bytes operatorData) external; // 11/13

  function burn(uint256 amount, bytes data) external; // 12/13
  function operatorBurn(address from, uint256 amount, bytes operatorData) external; // 13/13

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}


contract ERC777 is IERC777, IERC20, ERC820Client, MinterRole, ozs_Ownable {
  using SafeMath for uint256;

  string internal _name;
  string internal _symbol;
  uint256 internal _granularity;
  uint256 internal _totalSupply;

  // Mapping from investor to balance [OVERRIDES ERC20]
  mapping(address => uint256) internal _balances;

  // Mapping from (investor, spender) to allowed amount [NOT MANDATORY FOR ERC777 STANDARD][OVERRIDES ERC20]
  mapping (address => mapping (address => uint256)) internal _allowed;



  /******************** Mappings to find operator *****************************/
  // Mapping from (operator, investor) to authorized status [INVESTOR-SPECIFIC]
  mapping(address => mapping(address => bool)) internal _authorized;

  // Mapping from (operator, investor) to revoked status [INVESTOR-SPECIFIC]
  mapping(address => mapping(address => bool)) internal _revokedDefaultOperator;

  // Array of default operators [NOT INVESTOR-SPECIFIC]
  address[] internal _defaultOperators;

  // Mapping from operator to defaultOperator status [NOT INVESTOR-SPECIFIC]
  mapping(address => bool) internal _isDefaultOperator;
  /****************************************************************************/



  bool internal _erc20compatible;
  bool internal _erc820compatible;

  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] defaultOperators
  )
    public
  {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1);
    _granularity = granularity;

    for (uint i = 0; i < defaultOperators.length; i++) {
      _addDefaultOperator(defaultOperators[i]);
    }

    _setERC20compatibility(true);
    // _setERC820compatibility(true); // COMMENT FOR TESTING REASONS ONLY - TO BE REMOVED
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Registers/Unregisters the ERC20Token interface with its own address via ERC820
   * @param erc20compatible &#39;true&#39; to register the ERC20Token interface, &#39;false&#39; to unregister
   */
  function setERC20compatibility(bool erc20compatible) external onlyOwner {
    _setERC20compatibility(erc20compatible);
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Helper function to registers/unregister the ERC20Token interface
   * @param erc20compatible &#39;true&#39; to register the ERC20Token interface, &#39;false&#39; to unregister
   */
  function _setERC20compatibility(bool erc20compatible) internal {
    _erc20compatible = erc20compatible;
    if(_erc20compatible) {
      if(_erc820compatible) { setInterfaceImplementation("ERC20Token", this); }
    } else {
      if(_erc820compatible) { setInterfaceImplementation("ERC20Token", address(0)); }
    }
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev egisters/Unregisters the ERC20Token interface with its own address via ERC820
   * @param erc820compatible &#39;true&#39; to register the ERC820Token interface, &#39;false&#39; to unregister
   */
  function setERC820compatibility(bool erc820compatible) external onlyOwner {
    _setERC820compatibility(erc820compatible);
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Helper function to register/Unregister the ERC777Token interface with its own address via ERC820
   *  and allows/disallows the ERC820 methods
   * @param erc820compatible &#39;true&#39; to register the ERC777Token interface, &#39;false&#39; to unregister
   */
  function _setERC820compatibility(bool erc820compatible) internal {
    _erc820compatible = erc820compatible;
    if(_erc820compatible) {
      setInterfaceImplementation("ERC777Token", this);
      _setERC20compatibility(_erc20compatible);
    } else {
      setInterfaceImplementation("ERC777Token", address(0));
    }
  }

  /**
   * [ERC777 INTERFACE (1/13)]
   * @dev Returns the name of the token, e.g., "MyToken".
   * @return Name of the token.
   */
  function name() external view returns(string) {
    return _name;
  }

  /**
   * [ERC777 INTERFACE (2/13)]
   * @dev Returns the symbol of the token, e.g., "MYT".
   * @return Symbol of the token.
   */
  function symbol() external view returns(string) {
    return _symbol;
  }

  /**
   * [ERC777 INTERFACE (3/13)][OVERRIDES ERC20 METHOD] - Required since &#39;_totalSupply&#39; is private in ERC20
   * @dev Get the total number of minted tokens.
   * @return Total supply of tokens currently in circulation.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * [ERC777 INTERFACE (4/13)] [OVERRIDES ERC20 METHOD] - Required since &#39;_balances&#39; is private in ERC20
   * @dev Get the balance of the account with address tokenHolder.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token held by tokenHolder in the token contract.
   */
  function balanceOf(address tokenHolder) external view returns (uint256) {
    return _balances[tokenHolder];
  }

  /**
   * [ERC777 INTERFACE (5/13)]
   * @dev Get the smallest part of the token that’s not divisible.
   * @return The smallest non-divisible part of the token.
   */
  function granularity() external view returns(uint256) {
    return _granularity;
  }

  /**
   * [ERC777 INTERFACE (6/13)]
   * @dev Get the list of default operators as defined by the token contract.
   * @return List of addresses of all the default operators.
   */
  function defaultOperators() external view returns (address[]) {
    return _defaultOperators;
  }

  /**
   * [ERC777 INTERFACE (7/13)]
   * @dev Set a third party operator address as an operator of msg.sender to send and burn tokens on its
   * behalf.
   * @param operator Address to set as an operator for msg.sender.
   */
  function authorizeOperator(address operator) external {
    _revokedDefaultOperator[operator][msg.sender] = false;
    _authorized[operator][msg.sender] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }

  /**
   * [ERC777 INTERFACE (8/13)]
   * @dev Remove the right of the operator address to be an operator for msg.sender and to send
   * and burn tokens on its behalf.
   * @param operator Address to rescind as an operator for msg.sender.
   */
  function revokeOperator(address operator) external {
    _revokedDefaultOperator[operator][msg.sender] = true;
    _authorized[operator][msg.sender] = false;
    emit RevokedOperator(operator, msg.sender);
  }

  /**
   * [ERC777 INTERFACE (9/13)]
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return true if operator is an operator of tokenHolder and false otherwise.
   */
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorFor(operator, tokenHolder);
  }

  /**
   * [ERC777 INTERFACE (10/13)]
   * @dev Send the amount of tokens from the address msg.sender to the address to.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, by the token holder.
   */
  function sendTo(address to, uint256 amount, bytes data) external {
    _sendTo(msg.sender, msg.sender, to, amount, data, "", true);
  }

  /**
   * [ERC777 INTERFACE (11/13)]
   * @dev Send the amount of tokens on behalf of the address from to the address to.
   * @param from Token holder (or address(0) to set from to msg.sender).
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, by the token holder.
   * @param operatorData Information attached to the send by the operator.
   */
  function operatorSendTo(address from, address to, uint256 amount, bytes data, bytes operatorData) external {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from));

    _sendTo(msg.sender, _from, to, amount, data, operatorData, true);
  }

  /**
   * [ERC777 INTERFACE (12/13)]
   * @dev Burn the amount of tokens from the address msg.sender.
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, by the token holder.
   */
  function burn(uint256 amount, bytes data) external {
    _burn(msg.sender, msg.sender, amount, data);
  }

  /**
   * [ERC777 INTERFACE (13/13)]
   * @dev Burn the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be burned (or address(0) to set from to msg.sender).
   * @param amount Number of tokens to burn.
   * @param operatorData Information attached to the burn by the operator.
   */
  function operatorBurn(address from, uint256 amount, bytes operatorData) external {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from));

    _burn(msg.sender, _from, amount, operatorData);
  }

  /**
   * @dev Internal function that checks if `amount` is multiple of the granularity.
   * @param amount The quantity that want&#39;s to be checked.
   * @return `true` if `amount` is a multiple of the granularity.
   */
  function _isMultiple(uint256 amount) internal view returns(bool) {
    return(amount.div(_granularity).mul(_granularity) == amount);
  }

  /**
   * @dev Check whether an address is a regular address or not.
   * @param addr Address of the contract that has to be checked.
   * @return `true` if `addr` is a regular address (not a contract).
   */
  function _isRegularAddress(address addr) internal view returns(bool) {
    if (addr == address(0)) { return false; }
    uint size;
    assembly { size := extcodesize(addr) } // solhint-disable-line no-inline-assembly
    return size == 0;
  }

  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return true if operator is an operator of tokenHolder and false otherwise.
   */
  function _isOperatorFor(address operator, address tokenHolder) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorized[operator][tokenHolder]
      || (_isDefaultOperator[operator] && !_revokedDefaultOperator[operator][tokenHolder])
    );
  }

   /**
    * @dev Helper function actually performing the sending of tokens.
    * @param operator The address performing the send.
    * @param from Token holder.
    * @param to Token recipient.
    * @param amount Number of tokens to send.
    * @param data Information attached to the send, by the token holder.
    * @param operatorData Information attached to the send by the operator.
    * @param preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    *  implementing `erc777tokenHolder`.
    *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    *  functions SHOULD set this parameter to `false`.
    */
  function _sendTo(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData,
    bool preventLocking
  )
    internal
  {
    require(_isMultiple(amount));
    require(to != address(0));          // forbid sending to address(0) (=burning)
    require(_balances[from] >= amount); // ensure enough funds

    _callSender(operator, from, to, amount, data, operatorData);

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount);

    _callRecipient(operator, from, to, amount, data, operatorData, preventLocking);

    emit Sent(operator, from, to, amount, data, operatorData);

    if(_erc20compatible) {
      emit Transfer(from, to, amount);
    }
  }

  /**
   * @dev Helper function actually performing the burning of tokens.
   * @param operator The address performing the burn.
   * @param from Token holder whose tokens will be burned.
   * @param amount Number of tokens to burn.
   * @param operatorData Information attached to the burn by the operator.
   */
  function _burn(address operator, address from, uint256 amount, bytes operatorData)
    internal
  {
    require(_isMultiple(amount));
    require(from != address(0));
    require(_balances[from] >= amount);

    _callSender(operator, from, address(0), amount, "", operatorData);

    _balances[from] = _balances[from].sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Burned(operator, from, amount, operatorData);

    if(_erc20compatible) {
      emit Transfer(from, address(0), amount);  //  ERC20 backwards compatibility
    }
  }

  /**
   * @dev Helper function that checks for ERC777TokensSender on the sender and calls it.
   *  May throw according to `preventLocking`
   * @param operator Address which triggered the balance decrease (through sending or burning).
   * @param from Token holder.
   * @param to Token recipient for a send and 0x for a burn.
   * @param amount Number of tokens the token holder balance is decreased by.
   * @param data Extra information provided by the token holder.
   * @param operatorData Extra information provided by the address which triggered the balance decrease.
   */
  function _callSender(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
  {
    address senderImplementation;
    if(_erc820compatible) { senderImplementation = interfaceAddr(from, "ERC777TokensSender"); }

    if (senderImplementation != address(0)) {
      IERC777TokensSender(senderImplementation).tokensToSend(operator, from, to, amount, data, operatorData);
    }
  }

  /**
   * @dev Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
   *  May throw according to `preventLocking`
   * @param operator Address which triggered the balance increase (through sending or minting).
   * @param from Token holder for a send and 0x for a mint.
   * @param to Token recipient.
   * @param amount Number of tokens the recipient balance is increased by.
   * @param data Extra information provided by the token holder for a send and nothing (empty bytes) for a mint.
   * @param operatorData Extra information provided by the address which triggered the balance increase.
   * @param preventLocking `true` if you want this function to throw when tokens are sent to a contract not
   *  implementing `ERC777TokensRecipient`.
   *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
   *  functions SHOULD set this parameter to `false`.
   */
  function _callRecipient(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData,
    bool preventLocking
  )
    internal
  {
    address recipientImplementation;
    if(_erc820compatible) { recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient"); }

    if (recipientImplementation != address(0)) {
      IERC777TokensRecipient(recipientImplementation).tokensReceived(operator, from, to, amount, data, operatorData);
    } else if (preventLocking) {
      require(_isRegularAddress(to));
    }
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
   * @dev Internal function to add a default operator for the token.
   * @param operator Address to set as a default operator.
   */
  function _addDefaultOperator(address operator) internal {
    require(!_isDefaultOperator[operator]);
    _defaultOperators.push(operator);
    _isDefaultOperator[operator] = true;
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
   * @dev Internal function to add a default operator for the token.
   * @param operator Address to set as a default operator.
   */
  function _removeDefaultOperator(address operator) internal {
    require(_isDefaultOperator[operator]);

    for (uint i = 0; i<_defaultOperators.length - 1; i++){
      if(_defaultOperators[i] == operator) {
        _defaultOperators[i] = _defaultOperators[_defaultOperators.length - 1];
        delete _defaultOperators[_defaultOperators.length-1];
        _defaultOperators.length--;
        break;
      }
    }
    _isDefaultOperator[operator] = false;
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Mint the amout of tokens for the recipient &#39;to&#39;.
   * @param to Token recipient.
   * @param amount Number of tokens minted.
   * @param data Information attached to the minting, and intended for the recipient (to).
   */
  function mint(address to, uint256 amount, bytes data)
    external
    onlyMinter
    returns (bool)
  {
    _mint(msg.sender, to, amount, data, "");

    return true;
  }


  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Helper function actually performing the minting of tokens.
   * @param operator Address which triggered the mint.
   * @param to Token recipient.
   * @param amount Number of tokens minted.
   * @param data Information attached to the minting, and intended for the recipient (to).
   * @param operatorData Information attached to the minting by the operator.
   */
  function _mint(address operator, address to, uint256 amount, bytes data, bytes operatorData)
  internal
  {
    require(_isMultiple(amount));
    require(to != address(0));      // forbid sending to 0x0 (=burning)

    _totalSupply = _totalSupply.add(amount);
    _balances[to] = _balances[to].add(amount);

    _callRecipient(operator, address(0), to, amount, data, operatorData, true);

    emit Minted(operator, to, amount, data, operatorData);

    if(_erc20compatible) {
      emit Transfer(address(0), to, amount);  //  ERC20 backwards compatibility
    }
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Returns the number of decimals of the token.
   * @return The number of decimals of the token. For Backwards compatibility, decimals are forced to 18 in ERC777.
   */
  function decimals() external view returns(uint8) {
    require(_erc20compatible);
    return uint8(18);
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][OVERRIDES ERC20 METHOD]
   * @dev ERC20 function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
  )
  external
  view
  returns (uint256)
  {
    require(_erc20compatible);

    return _allowed[owner][spender];
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][OVERRIDES ERC20 METHOD]
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) external returns (bool) {
    require(_erc20compatible);

    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][OVERRIDES ERC20 METHOD]
   * @dev Transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) external returns (bool) {
    require(_erc20compatible);

    _sendTo(msg.sender, msg.sender, to, value, "", "", false);
    return true;
  }

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD][OVERRIDES ERC20 METHOD]
   * @dev Transfer tokens from one address to another
   * @param from The address which you want to send tokens from
   * @param to The address which you want to transfer to
   * @param value The amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (bool)
  {
    require(_erc20compatible);

    address _from = (from == address(0)) ? msg.sender : from;
    require( _isOperatorFor(msg.sender, _from)
      || (value <= _allowed[_from][msg.sender])
    );

    if(_allowed[_from][msg.sender] >= value) {
      _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(value);
    } else {
      _allowed[_from][msg.sender] = 0;
    }

    _sendTo(msg.sender, _from, to, value, "", "", false);
    return true;
  }

}



contract ERC777Reservable is CertificateController, ERC777 {
  using SafeMath for uint256;

  enum Status { Created, Validated, Cancelled }

  struct Reservation {
    Status status;
    uint256 amount;
    uint256 validUntil;
  }

  struct ReservationCoordinates {
    address owner;
    uint256 index;
  }

  uint256 public _minShares;
  bool public _burnLeftOver;

  bool public _saleEnded;
  uint256 public _reservedTotal;
  uint256 public _validatedTotal;

  mapping(address => Reservation[]) public _reservations;

  ReservationCoordinates[] public _validatedReservations;

  event TokensReserved(address investor, uint256 index, uint256 amount);
  event ReservationValidated(address investor, uint256 index);
  event SaleEnded();

  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] defaultOperators,
    uint256 minShares,
    uint256 maxShares,
    bool burnLeftOver,
    address certificateSigner //0xe31C41f0f70C5ff39f73B4B94bcCD767b3071630
  )
    public
    CertificateController(certificateSigner)
    ERC777(name, symbol, granularity, defaultOperators)
  {
    _minShares = minShares;
    _burnLeftOver = burnLeftOver;
    _saleEnded = false;
    _reservedTotal = 0;
    _validatedTotal = 0;

    _mint(msg.sender, this, maxShares, "", "");
  }

  modifier onlySale() {
    require(!_saleEnded, "0x45: Sale no longer available");
    _;
  }

  function reserveTokens(uint256 amount, uint256 validUntil, bytes data)
    external
    onlySale
    isValidCertificate(data)
    returns (uint256)
  {
    require(amount != 0, "0xA0: Amount should not be 0");

    uint256 index = _reservations[msg.sender].push(
      Reservation({
        status: Status.Created,
        amount: amount,
        validUntil: validUntil
      })
    );

    _reservedTotal = _reservedTotal.add(amount);

    require(_reservedTotal <= _totalSupply, "0xA0: The total reserved exceeds the total supply");

    emit TokensReserved(msg.sender, index, amount);

    return index;
  }

  function validateReservation(address owner, uint8 index)
    external
    onlySale
    onlyOwner
  {
    require(_reservations[owner].length > 0 && _reservations[owner][index].status == Status.Created, "0x20: Invalid reservation");

    Reservation storage reservation = _reservations[owner][index];
    require(reservation.validUntil != 0 && reservation.validUntil < block.number, "0x05: Reservation has expired");

    reservation.status = Status.Validated;
    _validatedReservations.push(
      ReservationCoordinates({
        owner: owner,
        index: index
      })
    );

    _validatedTotal = _validatedTotal.add(reservation.amount);

    emit ReservationValidated(owner, index);
  }

  function endSale()
    external
    onlySale
    onlyOwner
  {
    require(_minShares < _validatedTotal, "0xA0: The minimum validated has been reached");

    for (uint256 i = 0; i < _validatedReservations.length; i++) {
      Reservation storage reservation = _reservations[_validatedReservations[i].owner][_validatedReservations[i].index];
      _sendTo(this, this, _validatedReservations[i].owner, reservation.amount, "", "", true);
    }

    if (_burnLeftOver) {
      _burn(this, this, _balances[this], "");
    }

    _saleEnded = true;

    emit SaleEnded();
  }

}