/* file: openzeppelin-solidity/contracts/access/Roles.sol */
pragma solidity ^0.4.24;

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

/* eof (openzeppelin-solidity/contracts/access/Roles.sol) */
/* file: openzeppelin-solidity/contracts/access/roles/MinterRole.sol */
pragma solidity ^0.4.24;


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

/* eof (openzeppelin-solidity/contracts/access/roles/MinterRole.sol) */
/* file: ./contracts/IERC1400.sol */
pragma solidity ^0.4.24;

/// @title IERC1400 Security Token Standard (EIP 1400)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1400  {

    // Document Management
    function getDocument(bytes32 name) external view returns (string, bytes32); // 1/8
    function setDocument(bytes32 name, string uri, bytes32 documentHash) external; // 2/8

    // Controller Operation
    function isControllable() external view returns (bool); // 3/8

    // Token Issuance
    function isIssuable() external view returns (bool); // 4/8
    function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data) external; // 5/8
    event IssuedByTranche(bytes32 indexed tranche, address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    // Token Redemption
    function redeemByTranche(bytes32 tranche, uint256 amount, bytes data) external; // 6/8
    function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData) external; // 7/8
    event RedeemedByTranche(bytes32 indexed tranche, address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    // Transfer Validity
    function canSend(address from, address to, bytes32 tranche, uint256 amount, bytes data) external view returns (byte, bytes32, bytes32); // 8/8

}


/*
Reason codes - ERC1066

To improve the token holder experience, canSend MUST return a reason byte code
on success or failure based on the EIP-1066 application-specific status codes specified below.
An implementation can also return arbitrary data as a bytes32 to provide additional
information not captured by the reason code.

Code	Reason
0xA0	Transfer Verified - Unrestricted
0xA1	Transfer Verified - On-Chain approval for restricted token
0xA2	Transfer Verified - Off-Chain approval for restricted token
0xA3	Transfer Blocked - Sender lockup period not ended
0xA4	Transfer Blocked - Sender balance insufficient
0xA5	Transfer Blocked - Sender not eligible
0xA6	Transfer Blocked - Receiver not eligible
0xA7	Transfer Blocked - Identity restriction
0xA8	Transfer Blocked - Token restriction
0xA9	Transfer Blocked - Token granularity
*/

/* eof (./contracts/IERC1400.sol) */
/* file: ./contracts/token/ERC1410/IERC1410.sol */
pragma solidity ^0.4.24;

/// @title ERC-1410 Partially Fungible Token Standard
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec


//TODO: fix interface cannot inherit interface - interface IERC1410 is IERC777
interface IERC1410 {

    // Token Information
    function balanceOfByTranche(bytes32 tranche, address tokenHolder) external view returns (uint256); // 1/12
    function tranchesOf(address tokenHolder) external view returns (bytes32[]); // 2/12

    // Token Transfers
    function sendByTranche(bytes32 tranche, address to, uint256 amount, bytes data) external returns (bytes32); // 3/12
    function sendByTranches(bytes32[] tranches, address to, uint256[] amounts, bytes data) external returns (bytes32[]); // 4/12
    function operatorSendByTranche(bytes32 tranche, address from, address to, uint256 amount, bytes data, bytes operatorData) external returns (bytes32); // 5/12
    function operatorSendByTranches(bytes32[] tranches, address from, address to, uint256[] amounts, bytes data, bytes operatorData) external returns (bytes32[]); // 6/12

    // Default Tranche Management
    function getDefaultTranches(address tokenHolder) external view returns (bytes32[]); // 7/12 [OPTIONAL]
    function setDefaultTranches(bytes32[] tranches) external; // 8/12 [OPTIONAL]

    // Operators
    function defaultOperatorsByTranche(bytes32 tranche) external view returns (address[]); // 9/12
    function authorizeOperatorByTranche(bytes32 tranche, address operator) external; // 10/12
    function revokeOperatorByTranche(bytes32 tranche, address operator) external; // 11/12
    function isOperatorForTranche(bytes32 tranche, address operator, address tokenHolder) external view returns (bool); // 12/12

    // Transfer Events
    event SentByTranche(
        bytes32 indexed fromTranche,
        address operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event ChangedTranche(
        bytes32 indexed fromTranche,
        bytes32 indexed toTranche,
        uint256 amount
    );

    // Operator Events
    /* event AuthorizedOperator(address indexed operator, address indexed tokenHolder); --> ERC777 */
    /* event RevokedOperator(address indexed operator, address indexed tokenHolder); --> ERC777 */

    event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);

}

/* eof (./contracts/token/ERC1410/IERC1410.sol) */
/* file: openzeppelin-solidity/contracts/math/SafeMath.sol */
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

/* eof (openzeppelin-solidity/contracts/math/SafeMath.sol) */
/* file: openzeppelin-solidity/contracts/ownership/Ownable.sol */
pragma solidity ^0.4.24;

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

/* eof (openzeppelin-solidity/contracts/ownership/Ownable.sol) */
/* file: contract-certificate-controller/contracts/CertificateController.sol */
pragma solidity ^0.4.24;


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
/* eof (contract-certificate-controller/contracts/CertificateController.sol) */
/* file: erc820/contracts/ERC820Client.sol */
pragma solidity ^0.4.24;


contract ERC820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns(address);
}


/// Base client to interact with the registry.
contract ERC820Client {
    ERC820Registry constant ERC820REGISTRY = ERC820Registry(0x820b586C8C28125366C998641B09DCbE7d4cBF06);

    function setInterfaceImplementation(string _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC820REGISTRY.setInterfaceImplementer(this, interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC820REGISTRY.setManager(this, _newManager);
    }
}

/* eof (erc820/contracts/ERC820Client.sol) */
/* file: ./contracts/token/ERC777/IERC777.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 *
 * Potential issues:
 * - Presence of &#39;data&#39; field in burn and operatorBurn
 */
pragma solidity ^0.4.24;


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
  function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) external; // 13/13

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

/* eof (./contracts/token/ERC777/IERC777.sol) */
/* file: ./contracts/token/ERC777/IERC777TokensSender.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;


interface IERC777TokensSender {
  function canSend(
    address from,
    address to,
    bytes32 tranche,
    uint amount,
    bytes data
  ) external view returns(bool);

  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes data,
    bytes operatorData
  ) external;
}

/* eof (./contracts/token/ERC777/IERC777TokensSender.sol) */
/* file: ./contracts/token/ERC777/IERC777TokensRecipient.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;


interface IERC777TokensRecipient {
  function canReceive(
    address from,
    address to,
    bytes32 tranche,
    uint amount,
    bytes data
  ) external view returns(bool);

  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes data,
    bytes operatorData
  ) external;
}

/* eof (./contracts/token/ERC777/IERC777TokensRecipient.sol) */
/* file: ./contracts/token/ERC777/ERC777.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;





contract ERC777 is IERC777, Ownable, ERC820Client, CertificateController {
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

  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] defaultOperators,
    address certificateSigner
  )
    public
    CertificateController(certificateSigner)
  {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1);
    _granularity = granularity;

    for (uint i = 0; i < defaultOperators.length; i++) {
      _addDefaultOperator(defaultOperators[i]);
    }

    setInterfaceImplementation("ERC777Token", this);
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
    return _getDefaultOperators(true);
  }

  /**
   * @dev Get the list of default operators as defined by the token contract.
   * @param isControllable &#39;true&#39; if token can have default operators, &#39;false&#39; if not.
   * @return List of addresses of all the default operators.
   */
  function _getDefaultOperators(bool isControllable) internal view returns (address[]) {
    if (isControllable) {
      return _defaultOperators;
    } else {
      return new address[](0);
    }
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
    return _isOperatorFor(operator, tokenHolder, false);
  }

  /**
   * [ERC777 INTERFACE (10/13)]
   * @dev Send the amount of tokens from the address msg.sender to the address to.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, by the token holder [contains the conditional ownership certificate].
   */
  function sendTo(address to, uint256 amount, bytes data)
    external
    isValidCertificate(data)
  {
    _sendTo(msg.sender, msg.sender, to, amount, data, "", true);
  }

  /**
   * [ERC777 INTERFACE (11/13)]
   * @dev Send the amount of tokens on behalf of the address from to the address to.
   * @param from Token holder (or address(0) to set from to msg.sender).
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from).
   * @param operatorData Information attached to the send by the operator [contains the conditional ownership certificate].
   */
  function operatorSendTo(address from, address to, uint256 amount, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from, false));

    _sendTo(msg.sender, _from, to, amount, data, operatorData, true);
  }

  /**
   * [ERC777 INTERFACE (12/13)]
   * @dev Burn the amount of tokens from the address msg.sender.
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, by the token holder [contains the conditional ownership certificate].
   */
  function burn(uint256 amount, bytes data)
    external
    isValidCertificate(data)
  {
    _burn(msg.sender, msg.sender, amount, data, "");
  }

  /**
   * [ERC777 INTERFACE (13/13)]
   * @dev Burn the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be burned (or address(0) to set from to msg.sender).
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, and intended for the token holder (from).
   * @param operatorData Information attached to the burn by the operator [contains the conditional ownership certificate].
   */
  function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from, false));

    _burn(msg.sender, _from, amount, data, operatorData);
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
  function _isOperatorFor(address operator, address tokenHolder, bool isControllable) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorized[operator][tokenHolder]
      || (_isDefaultOperator[operator] && !_revokedDefaultOperator[operator][tokenHolder])
      || (_isDefaultOperator[operator] && isControllable)
    );
  }

   /**
    * @dev Helper function actually performing the sending of tokens.
    * @param operator The address performing the send.
    * @param from Token holder.
    * @param to Token recipient.
    * @param amount Number of tokens to send.
    * @param data Information attached to the send, and intended for the token holder (from).
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
  }

  /**
   * @dev Helper function actually performing the burning of tokens.
   * @param operator The address performing the burn.
   * @param from Token holder whose tokens will be burned.
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, and intended for the token holder (from).
   * @param operatorData Information attached to the burn by the operator (if any).
   */
  function _burn(address operator, address from, uint256 amount, bytes data, bytes operatorData)
    internal
  {
    require(_isMultiple(amount));
    require(from != address(0));
    require(_balances[from] >= amount);

    _callSender(operator, from, address(0), amount, data, operatorData);

    _balances[from] = _balances[from].sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Burned(operator, from, amount, data, operatorData);
  }

  /**
   * @dev Helper function that checks for ERC777TokensSender on the sender and calls it.
   *  May throw according to `preventLocking`
   * @param operator Address which triggered the balance decrease (through sending or burning).
   * @param from Token holder.
   * @param to Token recipient for a send and 0x for a burn.
   * @param amount Number of tokens the token holder balance is decreased by.
   * @param data Extra information, intended for the token holder (from).
   * @param operatorData Extra information attached by the operator (if any).
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
    senderImplementation = interfaceAddr(from, "ERC777TokensSender");

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
   * @param data Extra information, intended for the token holder (from).
   * @param operatorData Extra information attached by the operator (if any).
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
    recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

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

    for (uint i = 0; i<_defaultOperators.length; i++){
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
   * @dev Helper function actually performing the minting of tokens.
   * @param operator Address which triggered the mint.
   * @param to Token recipient.
   * @param amount Number of tokens minted.
   * @param data Information attached to the mint, and intended for the recipient (to).
   * @param operatorData Information attached to the mint by the operator (if any).
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
  }


}

/* eof (./contracts/token/ERC777/ERC777.sol) */
/* file: ./contracts/token/ERC1410/ERC1410.sol */
/*
* This code has not been reviewed.
* Do not use or deploy this code before reviewing it personally first.
*/
pragma solidity ^0.4.24;



contract ERC1410 is IERC1410, ERC777 {

  // Indicates whether the token can still be controlled by operators or not anymore
  bool internal _isControllable;

  /******************** Mappings to find tranche ******************************/
  // List of tranches
  bytes32[] internal _totalTranches;

  // Mapping from tranche to global balance of corresponding tranche
  mapping (bytes32 => uint256) internal _totalSupplyByTranche;

  // Mapping from investor to their tranches
  mapping (address => bytes32[]) internal _tranchesOf;

  // Mapping from (investor, tranche) to balance of corresponding tranche
  mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByTranche;

  // Mapping from investor to their default tranches (for ERC777 and ERC20 backwards compatibility)
  mapping (address => bytes32[]) internal _defaultTranches;
  /****************************************************************************/



  /**************** Mappings to find operator by tranche **********************/
  // Mapping from (investor, tranche, operator) to &#39;approved for tranche&#39; status [INVESTOR-SPECIFIC]
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _trancheAuthorized;

  // Mapping from (investor, tranche, operator) to &#39;revoked for tranche&#39; status [INVESTOR-SPECIFIC]
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _trancheRevokedDefaultOperator;

  // Mapping from tranche to default operators for the tranche [NOT INVESTOR-SPECIFIC]
  mapping (bytes32 => address[]) internal _defaultOperatorsByTranche;

  // Mapping from (tranche, operator) to defaultOperatorByTranche status [NOT INVESTOR-SPECIFIC]
  mapping (bytes32 => mapping (address => bool)) internal _isDefaultOperatorByTranche;
  /****************************************************************************/

  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] defaultOperators,
    address certificateSigner
  )
    public
    ERC777(name, symbol, granularity, defaultOperators, certificateSigner)
  {
    setInterfaceImplementation("ERC1410Token", this);
  }


  /**
   * [ERC1410 INTERFACE (1/12)]
   * @dev View function that returns the balance of a tokenholder for a specific tranche
   * @param tranche Name of the tranche.
   * @param tokenHolder Address for which the balance is returned.
   */
  function balanceOfByTranche(bytes32 tranche, address tokenHolder) external view returns (uint256) {
    return _balanceOfByTranche[tokenHolder][tranche];
  }

  /**
   * [ERC1410 INTERFACE (2/12)]
   * @dev View function that returns the tranches index of a tokenholder
   * @param tokenHolder Address for which the tranches index are returned.
   */
  function tranchesOf(address tokenHolder) external view returns (bytes32[]) {
    return _tranchesOf[tokenHolder];
  }

  /**
   * [ERC1410 INTERFACE (3/12)]
   * @dev External function to send tokens from a specific tranche
   * @param tranche Name of the tranche.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, by the token holder [contains the conditional ownership certificate].
   * @return destination tranche.
   */
  function sendByTranche(
    bytes32 tranche,
    address to,
    uint256 amount,
    bytes data
  )
    external
    isValidCertificate(data)
    returns (bytes32)
  {
    return _sendByTranche(tranche, msg.sender, msg.sender, to, amount, data, "");
  }

  /**
   * [ERC1410 INTERFACE (4/12)]
   * @dev External function to send tokens from specific tranches
   * @param tranches Name of the tranches.
   * @param to Token recipient.
   * @param amounts Number of tokens to send.
   * @param data Information attached to the send, by the token holder [contains the conditional ownership certificate].
   * @return destination tranches.
   */
  function sendByTranches(
    bytes32[] tranches,
    address to,
    uint256[] amounts,
    bytes data
  )
    external
    isValidCertificate(data)
    returns (bytes32[])
  {
    require(tranches.length == amounts.length);
    bytes32[] memory destinationTranches = new bytes32[](tranches.length);

    for (uint i = 0; i < tranches.length; i++) {
      destinationTranches[i] = _sendByTranche(tranches[i], msg.sender, msg.sender, to, amounts[i], data, "");
    }

    return destinationTranches;
  }

  /**
   * [ERC1410 INTERFACE (5/12)]
   * @dev External function to send tokens from a specific tranche through an operator
   * @param tranche Name of the tranche.
   * @param from Token holder.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from) [contains the destination tranche].
   * @param operatorData Information attached to the send by the operator [contains the conditional ownership certificate].
   * @return destination tranche.
   */
  function operatorSendByTranche(
    bytes32 tranche,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    external
    isValidCertificate(operatorData)
    returns (bytes32) // Return destination tranche
  {
    address _from = (from == address(0)) ? msg.sender : from;
    require(_isOperatorFor(msg.sender, _from, _isControllable) || _isOperatorForTranche(tranche, msg.sender, _from));

    return _sendByTranche(tranche, msg.sender, _from, to, amount, data, operatorData);
  }

  /**
   * [ERC1410 INTERFACE (6/12)]
   * @dev External function to send tokens from specific tranches through an operator
   * @param tranches Name of the tranches.
   * @param from Token holder.
   * @param to Token recipient.
   * @param amounts Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from) [contains the destination tranche].
   * @param operatorData Information attached to the send by the operator [contains the conditional ownership certificate].
   * @return destination tranches.
   */
  function operatorSendByTranches(
    bytes32[] tranches,
    address from,
    address to,
    uint256[] amounts,
    bytes data,
    bytes operatorData
  )
    external
    isValidCertificate(operatorData)
    returns (bytes32[]) // Return destination tranches
  {
    require(tranches.length == amounts.length);
    bytes32[] memory destinationTranches = new bytes32[](tranches.length);
    address _from = (from == address(0)) ? msg.sender : from;

    for (uint i = 0; i < tranches.length; i++) {
      require(_isOperatorFor(msg.sender, _from, _isControllable) || _isOperatorForTranche(tranches[i], msg.sender, _from));

      destinationTranches[i] = _sendByTranche(tranches[i], msg.sender, _from, to, amounts[i], data, operatorData);
    }

    return destinationTranches;
  }

  /**
   * [ERC1410 INTERFACE (7/12)][OPTIONAL]
   * For ERC777 and ERC20 backwards compatibility.
   * @dev View function to get default tranches to send from.
   *  For example, a security token may return the bytes32("unrestricted").
   * @param tokenHolder Address for which we want to know the default tranches.
   */
  function getDefaultTranches(address tokenHolder) external view returns (bytes32[]) {
    return _defaultTranches[tokenHolder];
  }

  /**
   * [ERC1410 INTERFACE (8/12)][OPTIONAL]
   * For ERC777 and ERC20 backwards compatibility.
   * @dev External function to set default tranches to send from.
   * @param tranches tranches to use by default when not specified.
   */
  function setDefaultTranches(bytes32[] tranches) external {
    _defaultTranches[msg.sender] = tranches;
  }

  /**
   * [ERC1410 INTERFACE (9/12)]
   * For ERC777 and ERC20 backwards compatibility.
   * @dev External function to get default operators for a given tranche.
   * @param tranche Name of the tranche.
   */
  function defaultOperatorsByTranche(bytes32 tranche) external view returns (address[]) {
    if (_isControllable) {
      return _defaultOperatorsByTranche[tranche];
    } else {
      return new address[](0);
    }
  }

  /**
   * [ERC1410 INTERFACE (10/12)]
   * @dev External function to set as an operator for msg.sender for a given tranche.
   * @param tranche Name of the tranche.
   * @param operator Address to set as an operator for msg.sender.
   */
  function authorizeOperatorByTranche(bytes32 tranche, address operator) external {
    _trancheRevokedDefaultOperator[msg.sender][tranche][operator] = false;
    _trancheAuthorized[msg.sender][tranche][operator] = true;
    emit AuthorizedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * [ERC1410 INTERFACE (11/12)]
   * @dev External function to remove the right of the operator address to be an operator
   *  on a given tranche for msg.sender and to send and burn tokens on its behalf.
   * @param tranche Name of the tranche.
   * @param operator Address to rescind as an operator on given tranche for msg.sender.
   */
  function revokeOperatorByTranche(bytes32 tranche, address operator) external {
    _trancheRevokedDefaultOperator[msg.sender][tranche][operator] = true;
    _trancheAuthorized[msg.sender][tranche][operator] = false;
    emit RevokedOperatorByTranche(tranche, operator, msg.sender);
  }

  /**
   * [ERC1410 INTERFACE (12/12)]
   * @dev External function to indicate whether the operator address is an operator
   *  of the tokenHolder address for the given tranche.
   * @param tranche Name of the tranche.
   * @param operator Address which may be an operator of tokenHolder for the given tranche.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given tranche.
   */
  function isOperatorForTranche(bytes32 tranche, address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorForTranche(tranche, operator, tokenHolder);
  }

  /**
   * @dev Internal function to indicate whether the operator address is an operator
   *  of the tokenHolder address for the given tranche.
   * @param tranche Name of the tranche.
   * @param operator Address which may be an operator of tokenHolder for the given tranche.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given tranche.
   */
   function _isOperatorForTranche(bytes32 tranche, address operator, address tokenHolder) internal view returns (bool) {
     return (_trancheAuthorized[tokenHolder][tranche][operator]
       || (_isDefaultOperatorByTranche[tranche][operator] && !_trancheRevokedDefaultOperator[tokenHolder][tranche][operator])
       || (_isDefaultOperatorByTranche[tranche][operator] && _isControllable)
     );
   }


  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
   * @dev Internal function to add a default operator for the token.
   * @param tranche Name of the tranche.
   * @param operator Address to set as a default operator.
   */
  function _addDefaultOperatorByTranche(bytes32 tranche, address operator) internal {
    require(!_isDefaultOperatorByTranche[tranche][operator]);
    _defaultOperatorsByTranche[tranche].push(operator);
    _isDefaultOperatorByTranche[tranche][operator] = true;
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
   * @dev Internal function to add a default operator for the token.
   * @param tranche Name of the tranche.
   * @param operator Address to set as a default operator.
   */
  function _removeDefaultOperatorByTranche(bytes32 tranche, address operator) internal {
    require(_isDefaultOperatorByTranche[tranche][operator]);

    for (uint i = 0; i<_defaultOperatorsByTranche[tranche].length; i++){
      if(_defaultOperatorsByTranche[tranche][i] == operator) {
        _defaultOperatorsByTranche[tranche][i] = _defaultOperatorsByTranche[tranche][_defaultOperatorsByTranche[tranche].length - 1];
        delete _defaultOperatorsByTranche[tranche][_defaultOperatorsByTranche[tranche].length-1];
        _defaultOperatorsByTranche[tranche].length--;
        break;
      }
    }
    _isDefaultOperatorByTranche[tranche][operator] = false;
  }

  /**
   * @dev Internal function to send tokens from a specific tranche
   * @param fromTranche Tranche of the tokens to send.
   * @param operator The address performing the send.
   * @param from Token holder.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from) [can contain the destination tranche].
   * @param operatorData Information attached to the send by the operator.
   * @return destination tranche.
   */
  function _sendByTranche(
    bytes32 fromTranche,
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
    returns (bytes32)
  {
    require(_balanceOfByTranche[from][fromTranche] >= amount); // ensure enough funds

    bytes32 toTranche = fromTranche;
    if(operatorData.length != 0 && data.length != 0) {
      toTranche = _getDestinationTranche(data);
    }

    _removeTokenFromTranche(from, fromTranche, amount);
    _sendTo(operator, from, to, amount, data, operatorData, true);
    _addTokenToTranche(to, toTranche, amount);

    emit SentByTranche(fromTranche, operator, from, to, amount, data, operatorData);

    if(toTranche != fromTranche) {
      emit ChangedTranche(fromTranche, toTranche, amount);
    }

    return toTranche;
  }

  /**
   * @dev Internal function to remove a token from a tranche
   * @param from Token holder.
   * @param tranche Name of the tranche.
   * @param amount Number of tokens to send.
   */
  function _removeTokenFromTranche(address from, bytes32 tranche, uint256 amount) internal {
    _balanceOfByTranche[from][tranche] = _balanceOfByTranche[from][tranche].sub(amount);
    _totalSupplyByTranche[tranche] = _totalSupplyByTranche[tranche].sub(amount);

    if(_balanceOfByTranche[from][tranche] == 0) {
      for (uint i = 0; i < _tranchesOf[from].length; i++) {
        if(_tranchesOf[from][i] == tranche) {
          _tranchesOf[from][i] = _tranchesOf[from][_tranchesOf[from].length - 1];
          delete _tranchesOf[from][_tranchesOf[from].length - 1];
          _tranchesOf[from].length--;
        }
      }
    }
    if(_totalSupplyByTranche[tranche] == 0) {
      for (i = 0; i < _totalTranches.length; i++) {
        if(_totalTranches[i] == tranche) {
          _totalTranches[i] = _totalTranches[_totalTranches.length - 1];
          delete _totalTranches[_totalTranches.length - 1];
          _totalTranches.length--;
        }
      }
    }
  }

  /**
   * @dev Internal function to add a token to a tranche
   * @param to Token recipient.
   * @param tranche Name of the tranche.
   * @param amount Number of tokens to send.
   */
  function _addTokenToTranche(address to, bytes32 tranche, uint256 amount) internal {
    if(_balanceOfByTranche[to][tranche] == 0 && amount != 0) {
      _tranchesOf[to].push(tranche);
    }
    _balanceOfByTranche[to][tranche] = _balanceOfByTranche[to][tranche].add(amount);

    if(_totalSupplyByTranche[tranche] == 0 && amount != 0) {
      _totalTranches.push(tranche);
    }
    _totalSupplyByTranche[tranche] = _totalSupplyByTranche[tranche].add(amount);
  }

  /**
   * @dev Internal function to retrieve the destination tranche from the &#39;data&#39; field.
   *  Basically, this function only converts the bytes variable into a bytes32 variable.
   * @param data Information attached to the send [contains the destination tranche].
   */
  function _getDestinationTranche(bytes data) internal pure returns(bytes32) {
    bytes32 toTranche;
    for (uint i = 0; i < 32; i++) {
      toTranche |= bytes32(data[i] & 0xFF) >> (i * 8); // Keeps the 8 first bits of data[i] and shifts them from (i * 8 places)
    }
    return toTranche;
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Get the list of default operators as defined by the token contract.
   * @return List of addresses of all the default operators.
   */
  function defaultOperators() external view returns (address[]) {
    return _getDefaultOperators(_isControllable);
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Send the amount of tokens from the address msg.sender to the address to.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, by the token holder [contains the conditional ownership certificate].
   */
  function sendTo(address to, uint256 amount, bytes data)
    external
    isValidCertificate(data)
  {
    _sendByDefaultTranches(msg.sender, msg.sender, to, amount, data, "");
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Send the amount of tokens on behalf of the address from to the address to.
   * @param from Token holder (or address(0) to set from to msg.sender).
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from) [can contain the destination tranche].
   * @param operatorData Information attached to the send by the operator [contains the conditional ownership certificate].
   */
  function operatorSendTo(address from, address to, uint256 amount, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from, _isControllable));

    _sendByDefaultTranches(msg.sender, _from, to, amount, data, operatorData);
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev Internal function to send tokens from a default tranches
   * @param operator The address performing the send.
   * @param from Token holder.
   * @param to Token recipient.
   * @param amount Number of tokens to send.
   * @param data Information attached to the send, and intended for the token holder (from) [can contain the destination tranche].
   * @param operatorData Information attached to the send by the operator.
   */
  function _sendByDefaultTranches(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
  {
    require(_defaultTranches[from].length != 0);

    uint256 _remainingAmount = amount;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultTranches[from].length; i++) {
      _localBalance = _balanceOfByTranche[from][_defaultTranches[from][i]];
      if(_remainingAmount <= _localBalance) {
        _sendByTranche(_defaultTranches[from][i], operator, from, to, _remainingAmount, data, operatorData);
        _remainingAmount = 0;
        break;
      } else {
        _sendByTranche(_defaultTranches[from][i], operator, from, to, _localBalance, data, operatorData);
        _remainingAmount = _remainingAmount - _localBalance;
      }
    }

    require(_remainingAmount == 0);
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Empty function to erase ERC777 burn() function since it doesn&#39;t handle tranches.
   */
  function burn(uint256 amount, bytes data) external {}

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Empty function to erase ERC777 operatorBurn() function since it doesn&#39;t handle tranches.
   */
  function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) external {}

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev View function that returns an array of all exisiting tranches.
   */
  function totalTranches() external view returns (bytes32[]) {
    return _totalTranches;
  }


}

/* eof (./contracts/token/ERC1410/ERC1410.sol) */
/* file: ./contracts/ERC1400.sol */
/*
* This code has not been reviewed.
* Do not use or deploy this code before reviewing it personally first.
*/
pragma solidity ^0.4.24;




contract ERC1400 is IERC1400, ERC1410, MinterRole {

  struct Document {
    string docURI;
    bytes32 docHash;
  }

  // Mapping for token URIs
  mapping(bytes32 => Document) internal _documents;

  // Indicates whether the token can still be minted/issued by the minter or not anymore
  bool internal _isIssuable;

  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] defaultOperators,
    address certificateSigner
  )
    public
    ERC1410(name, symbol, granularity, defaultOperators, certificateSigner)
  {
    setInterfaceImplementation("ERC1400Token", this);
    _isControllable = true;
    _isIssuable = true;
  }

  /**
   * [ERC1400 INTERFACE (1/8)]
   * @dev External function to access a document associated with the token.
   * @param name short name (represented as a bytes32) associated to the document.
   * @return Requested document + document hash
   */
  function getDocument(bytes32 name) external view returns (string, bytes32) {
    require(bytes(_documents[name].docURI).length != 0);
    return (
      _documents[name].docURI,
      _documents[name].docHash
    );
  }

  /**
   * [ERC1400 INTERFACE (2/8)]
   * @dev External function to accociate a document with the token.
   * @param name short name (represented as a bytes32) associated to the document.
   * @param uri document content.
   * @param documentHash hash of the document [optional parameter].
   */
  function setDocument(bytes32 name, string uri, bytes32 documentHash) external onlyOwner {
    _documents[name] = Document({
      docURI: uri,
      docHash: documentHash
    });
  }

  /**
   * [ERC1400 INTERFACE (3/8)]
   * @dev External function to know if the token can be controlled by operators.
   * If a token returns FALSE for isControllable() then it MUST:
   *  - always return FALSE in the future.
   *  - return empty lists for defaultOperators and defaultOperatorsByTranche.
   *  - never add addresses for defaultOperators and defaultOperatorsByTranche.
   * @return bool TRUE if the token can still be controlled by operators, FALSE if it can&#39;t anymore.
   */
  function isControllable() external view returns (bool) {
    return _isControllable;
  }

  /**
   * [ERC1400 INTERFACE (4/8)]
   * @dev External function to know if new tokens can be minted/issued in the future.
   * @return bool TRUE if tokens can still be minted/issued by the minter, FALSE if they can&#39;t anymore.
   */
  function isIssuable() external view returns (bool) {
    return _isIssuable;
  }

  /**
   * [ERC1400 INTERFACE (5/8)]
   * @dev External to mint/issue tokens from a specific tranche.
   * @param tranche Name of the tranche.
   * @param tokenHolder Address for which we want to mint/issue tokens.
   * @param amount Number of tokens minted.
   * @param data Information attached to the minting, and intended for the token holder (to) [contains the conditional ownership certificate].
   */
  function issueByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data)
    external
    onlyMinter
    isValidCertificate(data)
  {
    _issueByTranche(tranche, msg.sender, tokenHolder, amount, data, "");
  }

  /**
   * [ERC1400 INTERFACE (6/8)]
   * @dev External to redeem tokens of a specific tranche.
   * @param tranche Name of the tranche.
   * @param amount Number of tokens minted.
   * @param data Information attached to the redeem, and intended for the token holder (from) [contains the conditional ownership certificate].
   */
  function redeemByTranche(bytes32 tranche, uint256 amount, bytes data)
    external
    isValidCertificate(data)
  {
    _redeemByTranche(tranche, msg.sender, msg.sender, amount, data, "");
  }

  /**
   * [ERC1400 INTERFACE (7/8)]
   * @dev External to redeem tokens of a specific tranche.
   * @param tranche Name of the tranche.
   * @param tokenHolder Address for which we want to redeem tokens.
   * @param amount Number of tokens minted.
   * @param data Information attached to the redeem, and intended for the token holder (from).
   * @param operatorData Information attached to the redeem by the operator [contains the conditional ownership certificate].
   */
  function operatorRedeemByTranche(bytes32 tranche, address tokenHolder, uint256 amount, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (tokenHolder == address(0)) ? msg.sender : tokenHolder;
    require(_isOperatorFor(msg.sender, _from, _isControllable) || _isOperatorForTranche(tranche, msg.sender, _from));

    _redeemByTranche(tranche, msg.sender, _from, amount, data, operatorData);
  }

  /** [TODO - TO BE REVIEWED]
   * [ERC1400 INTERFACE (8/8)]
   * @dev External function to know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param from Token holder whose tokens will be transferred.
   * @param to Token recipient.
   * @param tranche Name of the tranche.
   * @param amount Number of tokens to send.
   * @param data Information attached to the transfer, and intended for the token holder (from) [can contain the destination tranche].
   * @return byte ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return bytes32 additional bytes32 parameter that can be used to define
   *  application specific reason codes with additional details (for example the
   *  transfer restriction rule responsible for making the send operation invalid).
   * @return bytes32 destination tranche.
   */
  function canSend(address from, address to, bytes32 tranche, uint256 amount, bytes data)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    byte reasonCode;
    /* address _from = (from == address(0)) ? msg.sender : from;

    address recipientImplementation;
    address senderImplementation;

    recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");
    senderImplementation = interfaceAddr(from, "ERC777TokensSender");

    if(!_isMultiple(amount)) {
      reasonCode = hex"A9";   // 0xA9	Transfer Blocked - Token granularity
    } else if (false) {
      reasonCode = hex"A8";   // 0xA8	Transfer Blocked - Token restriction
    } else if (false) {
      reasonCode = hex"A7";   // 0xA7	Transfer Blocked - Identity restriction
    } else if (
      (recipientImplementation != address(0))
      && !IERC777TokensRecipient(recipientImplementation).canReceive(from, to, tranche, amount, data)
    ) {
      reasonCode = hex"A6";   // 0xA6	Transfer Blocked - Receiver not eligible
    } else if (to == address(0)) {
        reasonCode = hex"A6";   // 0xA6	Transfer Blocked - Receiver not eligible
    } else if (
      (senderImplementation != address(0))
      && !IERC777TokensSender(senderImplementation).canSend(from, to, tranche, amount, data)
    ) {
      reasonCode = hex"A5";   // 0xA5	Transfer Blocked - Sender not eligible
    } else if (
      ((tranche == "") && (_balances[from] < amount))
      || ((tranche != "") && (_balanceOfByTranche[from][tranche] < amount))
    ) {
      reasonCode = hex"A4";   // 0xA4	Transfer Blocked - Sender balance insufficient
    } else if (false) {
      reasonCode = hex"A3";   // 0xA3	Transfer Blocked - Sender lockup period not ended
    } else if (false) {
      reasonCode = hex"A2";   // 0xA2	Transfer Verified - Off-Chain approval for restricted token
    } else if (true) {
      reasonCode = hex"A1";   // 0xA1	Transfer Verified - On-Chain approval for restricted token
    } else {
      reasonCode = hex"A0";   // 0xA0	Transfer Verified - Unrestricted
    } */

    return(reasonCode, "", _getDestinationTranche(data));
  }

  /**
   * @dev Internal function to mint/issue tokens from a specific tranche.
   * @param toTranche Name of the tranche.
   * @param operator The address performing the mint/issuance.
   * @param to Token recipient.
   * @param amount Number of tokens to mint/issue.
   * @param data Information attached to the mint/issuance, and intended for the token holder (to) [contains the destination tranche].
   * @param operatorData Information attached to the mint/issuance by the operator [contains the conditional ownership certificate].
   */
  function _issueByTranche(
    bytes32 toTranche,
    address operator,
    address to,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
  {
    require(_isIssuable);

    _mint(operator, to, amount, data, operatorData);
    _addTokenToTranche(to, toTranche, amount);

    emit IssuedByTranche(toTranche, operator, to, amount, data, operatorData);
  }

  /**
   * @dev Internal function to redeem tokens of a specific tranche.
   * @param fromTranche Name of the tranche.
   * @param operator The address performing the mint/issuance.
   * @param from Token holder whose tokens will be redeemed.
   * @param amount Number of tokens to redeem.
   * @param data Information attached to the burn/redeem, and intended for the token holder (from).
   * @param operatorData Information attached to the burn/redeem by the operator.
   */
  function _redeemByTranche(
    bytes32 fromTranche,
    address operator,
    address from,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
  {
    require(_balanceOfByTranche[from][fromTranche] >= amount); // ensure enough funds

    _removeTokenFromTranche(from, fromTranche, amount);
    _burn(operator, from, amount, data, operatorData);

    emit RedeemedByTranche(fromTranche, operator, from, amount, data, operatorData);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to definitely renounce the possibility to control tokens
   * on behalf of investors.
   * Once set to false, &#39;_isControllable&#39; can never be set to TRUE again.
   */
  function renounceControl() external onlyOwner {
    _isControllable = false;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to definitely renounce the possibility to issue new tokens.
   * Once set to false, &#39;_isIssuable&#39; can never be set to TRUE again.
   */
  function renounceIssuance() external onlyOwner {
    _isIssuable = false;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return true if operator is an operator of tokenHolder and false otherwise.
   */
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorFor(operator, tokenHolder, _isControllable);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Burn the amount of tokens from the address msg.sender.
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, by the token holder [contains the conditional ownership certificate].
   */
  function burn(uint256 amount, bytes data)
    external
    isValidCertificate(data)
  {
    _redeemByDefaultTranches(msg.sender, msg.sender, amount, data, "");
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Burn the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be burned (or address(0) to set from to msg.sender).
   * @param amount Number of tokens to burn.
   * @param data Information attached to the burn, and intended for the token holder (from).
   * @param operatorData Information attached to the burn by the operator [contains the conditional ownership certificate].
   */
  function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from, _isControllable));

    _redeemByDefaultTranches(msg.sender, _from, amount, data, operatorData);
  }

  /**
  * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev Internal function to redeem tokens from a default tranches
   * @param operator The address performing the redeem.
   * @param from Token holder.
   * @param amount Number of tokens to redeem.
   * @param data Information attached to the burn/redeem, and intended for the token holder (from).
   * @param operatorData Information attached to the burn/redeem by the operator.
   */
  function _redeemByDefaultTranches(
    address operator,
    address from,
    uint256 amount,
    bytes data,
    bytes operatorData
  )
    internal
  {
    require(_defaultTranches[from].length != 0);

    uint256 _remainingAmount = amount;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultTranches[from].length; i++) {
      _localBalance = _balanceOfByTranche[from][_defaultTranches[from][i]];
      if(_remainingAmount <= _localBalance) {
        _redeemByTranche(_defaultTranches[from][i], operator, from, _remainingAmount, data, operatorData);
        _remainingAmount = 0;
        break;
      } else {
        _redeemByTranche(_defaultTranches[from][i], operator, from, _localBalance, data, operatorData);
        _remainingAmount = _remainingAmount - _localBalance;
      }
    }

    require(_remainingAmount == 0);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to add a default operator for the token.
   * @param operator Address to set as a default operator.
   */
  function addDefaultOperator(address operator) external onlyOwner {
    require(_isControllable);
    _addDefaultOperator(operator);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to remove a default operator for the token.
   * @param operator Address to set as a default operator.
   */
  function removeDefaultOperator(address operator) external onlyOwner {
    _removeDefaultOperator(operator);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to add a default operator for the token.
   * @param tranche Name of the tranche.
   * @param operator Address to set as a default operator.
   */
  function addDefaultOperatorByTranche(bytes32 tranche, address operator) external onlyOwner {
    require(_isControllable);
    _addDefaultOperatorByTranche(tranche, operator);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev External function to remove a default operator for the token.
   * @param tranche Name of the tranche.
   * @param operator Address to set as a default operator.
   */
  function removeDefaultOperatorByTranche(bytes32 tranche, address operator) external onlyOwner {
    _removeDefaultOperatorByTranche(tranche, operator);
  }

}

/* eof (./contracts/ERC1400.sol) */