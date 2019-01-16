/* file: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol */
pragma solidity ^0.4.24;

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

/* eof (openzeppelin-solidity/contracts/token/ERC20/IERC20.sol) */
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
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;

/**
 * @title ERC1400 security token standard
 * @dev ERC1400 logic
 */
interface IERC1400  {

    // Document Management
    function getDocument(bytes32 name) external view returns (string, bytes32); // 1/9
    function setDocument(bytes32 name, string uri, bytes32 documentHash) external; // 2/9
    event Document(bytes32 indexed name, string uri, bytes32 documentHash);

    // Controller Operation
    function isControllable() external view returns (bool); // 3/9

    // Token Issuance
    function isIssuable() external view returns (bool); // 4/9
    function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes data) external; // 5/9
    event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);

    // Token Redemption
    function redeemByPartition(bytes32 partition, uint256 value, bytes data) external; // 6/9
    function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes data, bytes operatorData) external; // 7/9
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Transfer Validity
    function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes data) external view returns (byte, bytes32, bytes32); // 8/9
    function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes data, bytes operatorData) external view returns (byte, bytes32, bytes32); // 9/9

}

/**
 * Reason codes - ERC1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the EIP-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 *
 * Code	Reason
 * 0xA0	Transfer Verified - Unrestricted
 * 0xA1	Transfer Verified - On-Chain approval for restricted token
 * 0xA2	Transfer Verified - Off-Chain approval for restricted token
 * 0xA3	Transfer Blocked - Sender lockup period not ended
 * 0xA4	Transfer Blocked - Sender balance insufficient
 * 0xA5	Transfer Blocked - Sender not eligible
 * 0xA6	Transfer Blocked - Receiver not eligible
 * 0xA7	Transfer Blocked - Identity restriction
 * 0xA8	Transfer Blocked - Token restriction
 * 0xA9	Transfer Blocked - Token granularity
 */

/* eof (./contracts/IERC1400.sol) */
/* file: ./contracts/token/ERC1410/IERC1410.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;

/**
 * @title IERC1410 partially fungible token standard
 * @dev ERC1410 interface
 */
interface IERC1410 {

    // Token Information
    function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256); // 1/10
    function partitionsOf(address tokenHolder) external view returns (bytes32[]); // 2/10

    // Token Transfers
    function transferByPartition(bytes32 partition, address to, uint256 value, bytes data) external returns (bytes32); // 3/10
    function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes data, bytes operatorData) external returns (bytes32); // 4/10

    // Default Partition Management
    function getDefaultPartitions(address tokenHolder) external view returns (bytes32[]); // 5/10
    function setDefaultPartitions(bytes32[] partitions) external; // 6/10

    // Operators
    function controllersByPartition(bytes32 partition) external view returns (address[]); // 7/10
    function authorizeOperatorByPartition(bytes32 partition, address operator) external; // 8/10
    function revokeOperatorByPartition(bytes32 partition, address operator) external; // 9/10
    function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool); // 10/10

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed fromPartition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    event ChangedPartition(
        bytes32 indexed fromPartition,
        bytes32 indexed toPartition,
        uint256 value
    );

    // Operator Events
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

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
/* file: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol */
pragma solidity ^0.4.24;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1c6e79717f735c2e">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ec8d8089948995ac8185948e9598899fc28583">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  constructor() internal {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

/* eof (openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol) */
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
/* file: contract-certificate-controller/contracts/CertificateController.sol */
pragma solidity ^0.4.24;


contract CertificateController {

  // Address used by off-chain controller service to sign certificate
  mapping(address => bool) internal _certificateSigners;

  // A nonce used to ensure a certificate can be used only once
  mapping(address => uint256) internal _checkCount;

  event Checked(address sender);

  constructor(address _certificateSigner) public {
    _setCertificateSigner(_certificateSigner, true);
  }

  /**
   * @dev Modifier to protect methods with certificate control
   */
  modifier isValidCertificate(bytes data) {

    require(_checkCertificate(data, msg.value, 0x00000000), "A3: Transfer Blocked - Sender lockup period not ended");

    _checkCount[msg.sender] += 1; // Increment sender check count

    emit Checked(msg.sender);
    _;
  }

  /**
   * @dev Get number of transations already sent to this contract by the sender
   * @param sender Address whom to check the counter of.
   * @return uint256 Number of transaction already sent to this contract.
   */
  function checkCount(address sender) external view returns (uint256) {
    return _checkCount[sender];
  }

  /**
   * @dev Get certificate signer authorization for an operator.
   * @param operator Address whom to check the certificate signer authorization for.
   * @return bool &#39;true&#39; if operator is authorized as certificate signer, &#39;false&#39; if not.
   */
  function certificateSigners(address operator) external view returns (bool) {
    return _certificateSigners[operator];
  }

  /**
   * @dev Set signer authorization for operator.
   * @param operator Address to add/remove as a certificate signer.
   * @param authorized &#39;true&#39; if operator shall be accepted as certificate signer, &#39;false&#39; if not.
   */
  function _setCertificateSigner(address operator, bool authorized) internal {
    require(operator != address(0), "Action Blocked - Not a valid address");
    _certificateSigners[operator] = authorized;
  }

  /**
   * @dev Checks if a certificate is correct
   * @param data Certificate to control
   */
  function _checkCertificate(
    bytes data,
    uint256 amount,
    bytes4 functionID
  )
    internal
    view
    returns(bool)
  {
    uint256 counter = _checkCount[msg.sender];

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
        calldatacopy(add(add(payload, 0x20), 4), 4, sub(payloadsize, 4))
      }

      if(functionID == 0x00000000) {
        assembly {
          calldatacopy(add(payload, 0x20), 0, 4)
        }
      } else {
        for (uint i = 0; i < 4; i++) { // replace 4 bytes corresponding to function selector
          payload[i] = functionID[i];
        }
      }

      // Pack and hash
      bytes memory pack = abi.encodePacked(
        msg.sender,
        this,
        amount,
        payload,
        e,
        counter
      );
      bytes32 hash = keccak256(pack);

      // Check if certificate match expected transactions parameters
      if (_certificateSigners[ecrecover(hash, v, r, s)]) {
        return true;
      }
    }
    return false;
  }
}

/* eof (contract-certificate-controller/contracts/CertificateController.sol) */
/* file: ./contracts/token/ERC777/IERC777.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;

/**
 * @title IERC777 token standard
 * @dev ERC777 interface
 */
interface IERC777 {

  function name() external view returns (string); // 1/13
  function symbol() external view returns (string); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[]); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes data) external; // 10/13
  function transferFromWithData(address from, address to, uint256 value, bytes data, bytes operatorData) external; // 11/13

  function redeem(uint256 value, bytes data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes data, bytes operatorData) external; // 13/13

  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
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

/**
 * @title IERC777TokensSender
 * @dev ERC777TokensSender interface
 */
interface IERC777TokensSender {

  function canTransfer(
    bytes32 partition,
    address from,
    address to,
    uint value,
    bytes data,
    bytes operatorData
  ) external view returns(bool);

  function tokensToTransfer(
    address operator,
    address from,
    address to,
    uint value,
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

/**
 * @title IERC777TokensRecipient
 * @dev ERC777TokensRecipient interface
 */
interface IERC777TokensRecipient {

  function canReceive(
    bytes32 partition,
    address from,
    address to,
    uint value,
    bytes data,
    bytes operatorData
  ) external view returns(bool);

  function tokensReceived(
    address operator,
    address from,
    address to,
    uint value,
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




/**
 * @title ERC777
 * @dev ERC777 logic
 */
contract ERC777 is IERC777, Ownable, ERC820Client, CertificateController, ReentrancyGuard {
  using SafeMath for uint256;

  string internal _name;
  string internal _symbol;
  uint256 internal _granularity;
  uint256 internal _totalSupply;

  // Indicate whether the token can still be controlled by operators or not anymore.
  bool internal _isControllable;

  // Mapping from tokenHolder to balance.
  mapping(address => uint256) internal _balances;

  /******************** Mappings related to operator **************************/
  // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
  mapping(address => mapping(address => bool)) internal _authorizedOperator;

  // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  address[] internal _controllers;

  // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
  mapping(address => bool) internal _isController;
  /****************************************************************************/

  /**
   * [ERC777 CONSTRUCTOR]
   * @dev Initialize ERC777 and CertificateController parameters + register
   * the contract implementation in ERC820Registry.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param certificateSigner Address of the off-chain service which signs the
   * conditional ownership certificates required for token transfers, issuance,
   * redemption (Cf. CertificateController.sol).
   */
  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] controllers,
    address certificateSigner
  )
    public
    CertificateController(certificateSigner)
  {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1, "Constructor Blocked - Token granularity can not be lower than 1");
    _granularity = granularity;

    _setControllers(controllers);

    setInterfaceImplementation("ERC777Token", this);
  }

  /********************** ERC777 EXTERNAL FUNCTIONS ***************************/

  /**
   * [ERC777 INTERFACE (1/13)]
   * @dev Get the name of the token, e.g., "MyToken".
   * @return Name of the token.
   */
  function name() external view returns(string) {
    return _name;
  }

  /**
   * [ERC777 INTERFACE (2/13)]
   * @dev Get the symbol of the token, e.g., "MYT".
   * @return Symbol of the token.
   */
  function symbol() external view returns(string) {
    return _symbol;
  }

  /**
   * [ERC777 INTERFACE (3/13)]
   * @dev Get the total number of issued tokens.
   * @return Total supply of tokens currently in circulation.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * [ERC777 INTERFACE (4/13)]
   * @dev Get the balance of the account with address &#39;tokenHolder&#39;.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token held by &#39;tokenHolder&#39; in the token contract.
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
   * @dev Get the list of controllers as defined by the token contract.
   * @return List of addresses of all the controllers.
   */
  function controllers() external view returns (address[]) {
    return _controllers;
  }

  /**
   * [ERC777 INTERFACE (7/13)]
   * @dev Set a third party operator address as an operator of &#39;msg.sender&#39; to transfer
   * and redeem tokens on its behalf.
   * @param operator Address to set as an operator for &#39;msg.sender&#39;.
   */
  function authorizeOperator(address operator) external {
    _authorizedOperator[operator][msg.sender] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }

  /**
   * [ERC777 INTERFACE (8/13)]
   * @dev Remove the right of the operator address to be an operator for &#39;msg.sender&#39;
   * and to transfer and redeem tokens on its behalf.
   * @param operator Address to rescind as an operator for &#39;msg.sender&#39;.
   */
  function revokeOperator(address operator) external {
    _authorizedOperator[operator][msg.sender] = false;
    emit RevokedOperator(operator, msg.sender);
  }

  /**
   * [ERC777 INTERFACE (9/13)]
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return &#39;true&#39; if operator is an operator of &#39;tokenHolder&#39; and &#39;false&#39; otherwise.
   */
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorFor(operator, tokenHolder);
  }

  /**
   * [ERC777 INTERFACE (10/13)]
   * @dev Transfer the amount of tokens from the address &#39;msg.sender&#39; to the address &#39;to&#39;.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function transferWithData(address to, uint256 value, bytes data)
    external
    isValidCertificate(data)
  {
    _transferWithData(msg.sender, msg.sender, to, value, data, "", true);
  }

  /**
   * [ERC777 INTERFACE (11/13)]
   * @dev Transfer the amount of tokens on behalf of the address &#39;from&#39; to the address &#39;to&#39;.
   * @param from Token holder (or &#39;address(0)&#39; to set from to &#39;msg.sender&#39;).
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder (&#39;from&#39;).
   * @param operatorData Information attached to the transfer by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function transferFromWithData(address from, address to, uint256 value, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _transferWithData(msg.sender, _from, to, value, data, operatorData, true);
  }

  /**
   * [ERC777 INTERFACE (12/13)]
   * @dev Redeem the amount of tokens from the address &#39;msg.sender&#39;.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function redeem(uint256 value, bytes data)
    external
    isValidCertificate(data)
  {
    _redeem(msg.sender, msg.sender, value, data, "");
  }

  /**
   * [ERC777 INTERFACE (13/13)]
   * @dev Redeem the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function redeemFrom(address from, uint256 value, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _redeem(msg.sender, _from, value, data, operatorData);
  }

  /********************** ERC777 INTERNAL FUNCTIONS ***************************/

  /**
   * [INTERNAL]
   * @dev Check if &#39;value&#39; is multiple of the granularity.
   * @param value The quantity that want&#39;s to be checked.
   * @return &#39;true&#39; if &#39;value&#39; is a multiple of the granularity.
   */
  function _isMultiple(uint256 value) internal view returns(bool) {
    return(value.div(_granularity).mul(_granularity) == value);
  }

  /**
   * [INTERNAL]
   * @dev Check whether an address is a regular address or not.
   * @param addr Address of the contract that has to be checked.
   * @return &#39;true&#39; if &#39;addr&#39; is a regular address (not a contract).
   */
  function _isRegularAddress(address addr) internal view returns(bool) {
    if (addr == address(0)) { return false; }
    uint size;
    assembly { size := extcodesize(addr) } // solhint-disable-line no-inline-assembly
    return size == 0;
  }

  /**
   * [INTERNAL]
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of &#39;tokenHolder&#39;.
   * @param tokenHolder Address of a token holder which may have the &#39;operator&#39; address as an operator.
   * @return &#39;true&#39; if &#39;operator&#39; is an operator of &#39;tokenHolder&#39; and &#39;false&#39; otherwise.
   */
  function _isOperatorFor(address operator, address tokenHolder) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorizedOperator[operator][tokenHolder]
      || (_isControllable && _isController[operator])
    );
  }

   /**
    * [INTERNAL]
    * @dev Perform the transfer of tokens.
    * @param operator The address performing the transfer.
    * @param from Token holder.
    * @param to Token recipient.
    * @param value Number of tokens to transfer.
    * @param data Information attached to the transfer.
    * @param operatorData Information attached to the transfer by the operator (if any)..
    * @param preventLocking &#39;true&#39; if you want this function to throw when tokens are sent to a contract not
    * implementing &#39;erc777tokenHolder&#39;.
    * ERC777 native transfer functions MUST set this parameter to &#39;true&#39;, and backwards compatible ERC20 transfer
    * functions SHOULD set this parameter to &#39;false&#39;.
    */
  function _transferWithData(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData,
    bool preventLocking
  )
    internal
    nonReentrant
  {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");
    require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _callSender(operator, from, to, value, data, operatorData);

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    _callRecipient(operator, from, to, value, data, operatorData, preventLocking);

    emit TransferWithData(operator, from, to, value, data, operatorData);
  }

  /**
   * [INTERNAL]
   * @dev Perform the token redemption.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator (if any).
   */
  function _redeem(address operator, address from, uint256 value, bytes data, bytes operatorData)
    internal
    nonReentrant
  {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(from != address(0), "A5: Transfer Blocked - Sender not eligible");
    require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _callSender(operator, from, address(0), value, data, operatorData);

    _balances[from] = _balances[from].sub(value);
    _totalSupply = _totalSupply.sub(value);

    emit Redeemed(operator, from, value, data, operatorData);
  }

  /**
   * [INTERNAL]
   * @dev Check for &#39;ERC777TokensSender&#39; hook on the sender and call it.
   * May throw according to &#39;preventLocking&#39;.
   * @param operator Address which triggered the balance decrease (through transfer or redemption).
   * @param from Token holder.
   * @param to Token recipient for a transfer and 0x for a redemption.
   * @param value Number of tokens the token holder balance is decreased by.
   * @param data Extra information.
   * @param operatorData Extra information, attached by the operator (if any).
   */
  function _callSender(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
  {
    address senderImplementation;
    senderImplementation = interfaceAddr(from, "ERC777TokensSender");

    if (senderImplementation != address(0)) {
      IERC777TokensSender(senderImplementation).tokensToTransfer(operator, from, to, value, data, operatorData);
    }
  }

  /**
   * [INTERNAL]
   * @dev Check for &#39;ERC777TokensRecipient&#39; hook on the recipient and call it.
   * May throw according to &#39;preventLocking&#39;.
   * @param operator Address which triggered the balance increase (through transfer or issuance).
   * @param from Token holder for a transfer and 0x for an issuance.
   * @param to Token recipient.
   * @param value Number of tokens the recipient balance is increased by.
   * @param data Extra information, intended for the token holder (&#39;from&#39;).
   * @param operatorData Extra information attached by the operator (if any).
   * @param preventLocking &#39;true&#39; if you want this function to throw when tokens are sent to a contract not
   * implementing &#39;ERC777TokensRecipient&#39;.
   * ERC777 native transfer functions MUST set this parameter to &#39;true&#39;, and backwards compatible ERC20 transfer
   * functions SHOULD set this parameter to &#39;false&#39;.
   */
  function _callRecipient(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData,
    bool preventLocking
  )
    internal
  {
    address recipientImplementation;
    recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

    if (recipientImplementation != address(0)) {
      IERC777TokensRecipient(recipientImplementation).tokensReceived(operator, from, to, value, data, operatorData);
    } else if (preventLocking) {
      require(_isRegularAddress(to), "A6: Transfer Blocked - Receiver not eligible");
    }
  }

  /**
   * [INTERNAL]
   * @dev Perform the issuance of tokens.
   * @param operator Address which triggered the issuance.
   * @param to Token recipient.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, and intended for the recipient (to).
   * @param operatorData Information attached to the issuance by the operator (if any).
   */
  function _issue(address operator, address to, uint256 value, bytes data, bytes operatorData) internal nonReentrant {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");

    _totalSupply = _totalSupply.add(value);
    _balances[to] = _balances[to].add(value);

    _callRecipient(operator, address(0), to, value, data, operatorData, true);

    emit Issued(operator, to, value, data, operatorData);
  }

  /********************** ERC777 OPTIONAL FUNCTIONS ***************************/

  /**
   * [NOT MANDATORY FOR ERC777 STANDARD]
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function _setControllers(address[] operators) internal onlyOwner {
    for (uint i = 0; i<_controllers.length; i++){
      _isController[_controllers[i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isController[operators[j]] = true;
    }
    _controllers = operators;
  }

}

/* eof (./contracts/token/ERC777/ERC777.sol) */
/* file: ./contracts/token/ERC1410/ERC1410.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;


/**
 * @title ERC1410
 * @dev ERC1410 logic
 */
contract ERC1410 is IERC1410, ERC777 {

  /******************** Mappings to find partition ******************************/
  // List of partitions.
  bytes32[] internal _totalPartitions;

  // Mapping from partition to global balance of corresponding partition.
  mapping (bytes32 => uint256) internal _totalSupplyByPartition;

  // Mapping from tokenHolder to their partitions.
  mapping (address => bytes32[]) internal _partitionsOf;

  // Mapping from (tokenHolder, partition) to balance of corresponding partition.
  mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByPartition;

  // Mapping from tokenHolder to their default partitions (for ERC777 and ERC20 compatibility).
  mapping (address => bytes32[]) internal _defaultPartitionsOf;

  // List of token default partitions (for ERC20 compatibility).
  bytes32[] internal _tokenDefaultPartitions;
  /****************************************************************************/

  /**************** Mappings to find partition operators ************************/
  // Mapping from (tokenHolder, partition, operator) to &#39;approved for partition&#39; status. [TOKEN-HOLDER-SPECIFIC]
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;

  // Mapping from partition to controllers for the partition. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => address[]) internal _controllersByPartition;

  // Mapping from (partition, operator) to PartitionController status. [NOT TOKEN-HOLDER-SPECIFIC]
  mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;
  /****************************************************************************/

  /**
   * [ERC1410 CONSTRUCTOR]
   * @dev Initialize ERC1410 parameters + register
   * the contract implementation in ERC820Registry.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param certificateSigner Address of the off-chain service which signs the
   * conditional ownership certificates required for token transfers, issuance,
   * redemption (Cf. CertificateController.sol).
   */
  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] controllers,
    address certificateSigner,
    bytes32[] tokenDefaultPartitions
  )
    public
    ERC777(name, symbol, granularity, controllers, certificateSigner)
  {
    _tokenDefaultPartitions = tokenDefaultPartitions;
  }

  /********************** ERC1410 EXTERNAL FUNCTIONS **************************/

  /**
   * [ERC1410 INTERFACE (1/10)]
   * @dev Get balance of a tokenholder for a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token of partition &#39;partition&#39; held by &#39;tokenHolder&#39; in the token contract.
   */
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256) {
    return _balanceOfByPartition[tokenHolder][partition];
  }

  /**
   * [ERC1410 INTERFACE (2/10)]
   * @dev Get partitions index of a tokenholder.
   * @param tokenHolder Address for which the partitions index are returned.
   * @return Array of partitions index of &#39;tokenHolder&#39;.
   */
  function partitionsOf(address tokenHolder) external view returns (bytes32[]) {
    return _partitionsOf[tokenHolder];
  }

  /**
   * [ERC1410 INTERFACE (3/10)]
   * @dev Transfer tokens from a specific partition.
   * @param partition Name of the partition.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return Destination partition.
   */
  function transferByPartition(
    bytes32 partition,
    address to,
    uint256 value,
    bytes data
  )
    external
    isValidCertificate(data)
    returns (bytes32)
  {
    return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "");
  }

  /**
   * [ERC1410 INTERFACE (4/10)]
   * @dev Transfer tokens from a specific partition through an operator.
   * @param partition Name of the partition.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return Destination partition.
   */
  function operatorTransferByPartition(
    bytes32 partition,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    external
    isValidCertificate(operatorData)
    returns (bytes32)
  {
    address _from = (from == address(0)) ? msg.sender : from;
    require(_isOperatorForPartition(partition, msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    return _transferByPartition(partition, msg.sender, _from, to, value, data, operatorData);
  }

  /**
   * [ERC1410 INTERFACE (5/10)]
   * @dev Get default partitions to transfer from.
   * Function used for ERC777 and ERC20 backwards compatibility.
   * For example, a security token may return the bytes32("unrestricted").
   * @param tokenHolder Address for which we want to know the default partitions.
   * @return Array of default partitions.
   */
  function getDefaultPartitions(address tokenHolder) external view returns (bytes32[]) {
    return _defaultPartitionsOf[tokenHolder];
  }

  /**
   * [ERC1410 INTERFACE (6/10)]
   * @dev Set default partitions to transfer from.
   * Function used for ERC777 and ERC20 backwards compatibility.
   * @param partitions partitions to use by default when not specified.
   */
  function setDefaultPartitions(bytes32[] partitions) external {
    _defaultPartitionsOf[msg.sender] = partitions;
  }

  /**
   * [ERC1410 INTERFACE (7/10)]
   * @dev Get controllers for a given partition.
   * Function used for ERC777 and ERC20 backwards compatibility.
   * @param partition Name of the partition.
   * @return Array of controllers for partition.
   */
  function controllersByPartition(bytes32 partition) external view returns (address[]) {
    return _controllersByPartition[partition];
  }

  /**
   * [ERC1410 INTERFACE (8/10)]
   * @dev Set &#39;operator&#39; as an operator for &#39;msg.sender&#39; for a given partition.
   * @param partition Name of the partition.
   * @param operator Address to set as an operator for &#39;msg.sender&#39;.
   */
  function authorizeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = true;
    emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
  }

  /**
   * [ERC1410 INTERFACE (9/10)]
   * @dev Remove the right of the operator address to be an operator on a given
   * partition for &#39;msg.sender&#39; and to transfer and redeem tokens on its behalf.
   * @param partition Name of the partition.
   * @param operator Address to rescind as an operator on given partition for &#39;msg.sender&#39;.
   */
  function revokeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = false;
    emit RevokedOperatorByPartition(partition, operator, msg.sender);
  }

  /**
   * [ERC1410 INTERFACE (10/10)]
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return &#39;true&#39; if &#39;operator&#39; is an operator of &#39;tokenHolder&#39; for partition &#39;partition&#39; and &#39;false&#39; otherwise.
   */
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorForPartition(partition, operator, tokenHolder);
  }

  /********************** ERC1410 INTERNAL FUNCTIONS **************************/

  /**
   * [INTERNAL]
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return &#39;true&#39; if &#39;operator&#39; is an operator of &#39;tokenHolder&#39; for partition &#39;partition&#39; and &#39;false&#39; otherwise.
   */
   function _isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) internal view returns (bool) {
     return (_isOperatorFor(operator, tokenHolder)
       || _authorizedOperatorByPartition[tokenHolder][partition][operator]
       || (_isControllable && _isControllerByPartition[partition][operator])
     );
   }

  /**
   * [INTERNAL]
   * @dev Transfer tokens from a specific partition.
   * @param fromPartition Partition of the tokens to transfer.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator (if any).
   * @return Destination partition.
   */
  function _transferByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
    returns (bytes32)
  {
    require(_balanceOfByPartition[from][fromPartition] >= value, "A4: Transfer Blocked - Sender balance insufficient"); // ensure enough funds

    bytes32 toPartition = fromPartition;

    if(operatorData.length != 0 && data.length != 0) {
      toPartition = _getDestinationPartition(fromPartition, data);
    }

    _removeTokenFromPartition(from, fromPartition, value);
    _transferWithData(operator, from, to, value, data, operatorData, true);
    _addTokenToPartition(to, toPartition, value);

    emit TransferByPartition(fromPartition, operator, from, to, value, data, operatorData);

    if(toPartition != fromPartition) {
      emit ChangedPartition(fromPartition, toPartition, value);
    }

    return toPartition;
  }

  /**
   * [INTERNAL]
   * @dev Remove a token from a specific partition.
   * @param from Token holder.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _removeTokenFromPartition(address from, bytes32 partition, uint256 value) internal {
    _balanceOfByPartition[from][partition] = _balanceOfByPartition[from][partition].sub(value);
    _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].sub(value);

    // If the balance of the TokenHolder&#39;s partition is zero, finds and deletes the partition.
    if(_balanceOfByPartition[from][partition] == 0) {
      for (uint i = 0; i < _partitionsOf[from].length; i++) {
        if(_partitionsOf[from][i] == partition) {
          _partitionsOf[from][i] = _partitionsOf[from][_partitionsOf[from].length - 1];
          delete _partitionsOf[from][_partitionsOf[from].length - 1];
          _partitionsOf[from].length--;
          break;
        }
      }
    }

    // If the total supply is zero, finds and deletes the partition.
    if(_totalSupplyByPartition[partition] == 0) {
      for (i = 0; i < _totalPartitions.length; i++) {
        if(_totalPartitions[i] == partition) {
          _totalPartitions[i] = _totalPartitions[_totalPartitions.length - 1];
          delete _totalPartitions[_totalPartitions.length - 1];
          _totalPartitions.length--;
          break;
        }
      }
    }
  }

  /**
   * [INTERNAL]
   * @dev Add a token to a specific partition.
   * @param to Token recipient.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _addTokenToPartition(address to, bytes32 partition, uint256 value) internal {
    if(value != 0) {
      if(_balanceOfByPartition[to][partition] == 0) {
        _partitionsOf[to].push(partition);
      }
      _balanceOfByPartition[to][partition] = _balanceOfByPartition[to][partition].add(value);

      if(_totalSupplyByPartition[partition] == 0) {
        _totalPartitions.push(partition);
      }
      _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].add(value);
    }
  }

  /**
   * [INTERNAL]
   * @dev Retrieve the destination partition from the &#39;data&#39; field.
   * By convention, a partition change is requested ONLY when &#39;data&#39; starts
   * with the flag: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
   * When the flag is detected, the destination tranche is ewtracted from the
   * 32 bytes following the flag.
   * @param fromPartition Partition of the tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @return Destination partition.
   */
  function _getDestinationPartition(bytes32 fromPartition, bytes data) internal pure returns(bytes32 toPartition) {
    bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bytes32 flag;
    assembly {
      flag := mload(add(data, 32))
    }
    if(flag == changePartitionFlag) {
      assembly {
        toPartition := mload(add(data, 64))
      }
    } else {
      toPartition = fromPartition;
    }
  }

  /**
   * [INTERNAL]
   * @dev Get the sender&#39;s default partition if setup, or the global default partition if not.
   * @param tokenHolder Address for which the default partition is returned.
   * @return Default partition.
   */
  function _getDefaultPartitions(address tokenHolder) internal view returns(bytes32[]) {
    if(_defaultPartitionsOf[tokenHolder].length != 0) {
      return _defaultPartitionsOf[tokenHolder];
    } else {
      return _tokenDefaultPartitions;
    }
  }


  /********************* ERC1410 OPTIONAL FUNCTIONS ***************************/

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev Get list of existing partitions.
   * @return Array of all exisiting partitions.
   */
  function totalPartitions() external view returns (bytes32[]) {
    return _totalPartitions;
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][SHALL BE CALLED ONLY FROM ERC1400]
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function _setPartitionControllers(bytes32 partition, address[] operators) internal onlyOwner {
     for (uint i = 0; i<_controllersByPartition[partition].length; i++){
       _isControllerByPartition[partition][_controllersByPartition[partition][i]] = false;
     }
     for (uint j = 0; j<operators.length; j++){
       _isControllerByPartition[partition][operators[j]] = true;
     }
     _controllersByPartition[partition] = operators;
   }

  /************** ERC777 BACKWARDS RETROCOMPATIBILITY *************************/

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Transfer the value of tokens from the address &#39;msg.sender&#39; to the address &#39;to&#39;.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function transferWithData(address to, uint256 value, bytes data)
    external
    isValidCertificate(data)
  {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, data, "");
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Transfer the value of tokens on behalf of the address from to the address to.
   * @param from Token holder (or &#39;address(0)&#39;&#39; to set from to &#39;msg.sender&#39;).
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder (&#39;from&#39;). [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function transferFromWithData(address from, address to, uint256 value, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _transferByDefaultPartitions(msg.sender, _from, to, value, data, operatorData);
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Empty function to erase ERC777 redeem() function since it doesn&#39;t handle partitions.
   */
  function redeem(uint256 /*value*/, bytes /*data*/) external { // Comments to avoid compilation warnings for unused variables.
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD][OVERRIDES ERC777 METHOD]
   * @dev Empty function to erase ERC777 redeemFrom() function since it doesn&#39;t handle partitions.
   */
  function redeemFrom(address /*from*/, uint256 /*value*/, bytes /*data*/, bytes /*operatorData*/) external { // Comments to avoid compilation warnings for unused variables.
  }

  /**
   * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev Transfer tokens from default partitions.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder (&#39;from&#39;) [CAN CONTAIN THE DESTINATION PARTITION].
   * @param operatorData Information attached to the transfer by the operator (if any).
   */
  function _transferByDefaultPartitions(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
  {
    bytes32[] memory _partitions = _getDefaultPartitions(from);
    require(_partitions.length != 0, "A8: Transfer Blocked - Token restriction");

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _partitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_partitions[i]];
      if(_remainingValue <= _localBalance) {
        _transferByPartition(_partitions[i], operator, from, to, _remainingValue, data, operatorData);
        _remainingValue = 0;
        break;
      } else {
        _transferByPartition(_partitions[i], operator, from, to, _localBalance, data, operatorData);
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "A8: Transfer Blocked - Token restriction");
  }
}

/* eof (./contracts/token/ERC1410/ERC1410.sol) */
/* file: ./contracts/ERC1400.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;




/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400 is IERC1400, ERC1410, MinterRole {

  struct Doc {
    string docURI;
    bytes32 docHash;
  }

  // Mapping for token URIs.
  mapping(bytes32 => Doc) internal _documents;

  // Indicate whether the token can still be issued by the issuer or not anymore.
  bool internal _isIssuable;

  /**
   * @dev Modifier to verify if token is issuable.
   */
  modifier issuableToken() {
    require(_isIssuable, "A8, Transfer Blocked - Token restriction");
    _;
  }

  /**
   * [ERC1400 CONSTRUCTOR]
   * @dev Initialize ERC1400 + register
   * the contract implementation in ERC820Registry.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param certificateSigner Address of the off-chain service which signs the
   * conditional ownership certificates required for token transfers, issuance,
   * redemption (Cf. CertificateController.sol).
   */
  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] controllers,
    address certificateSigner,
    bytes32[] tokenDefaultPartitions
  )
    public
    ERC1410(name, symbol, granularity, controllers, certificateSigner, tokenDefaultPartitions)
  {
    setInterfaceImplementation("ERC1400Token", this);
    _isControllable = true;
    _isIssuable = true;
  }

  /********************** ERC1400 EXTERNAL FUNCTIONS **************************/

  /**
   * [ERC1400 INTERFACE (1/9)]
   * @dev Access a document associated with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @return Requested document + document hash.
   */
  function getDocument(bytes32 name) external view returns (string, bytes32) {
    require(bytes(_documents[name].docURI).length != 0, "Action Blocked - Empty document");
    return (
      _documents[name].docURI,
      _documents[name].docHash
    );
  }

  /**
   * [ERC1400 INTERFACE (2/9)]
   * @dev Associate a document with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @param uri Document content.
   * @param documentHash Hash of the document [optional parameter].
   */
  function setDocument(bytes32 name, string uri, bytes32 documentHash) external onlyOwner {
    _documents[name] = Doc({
      docURI: uri,
      docHash: documentHash
    });
    emit Document(name, uri, documentHash);
  }

  /**
   * [ERC1400 INTERFACE (3/9)]
   * @dev Know if the token can be controlled by operators.
   * If a token returns &#39;false&#39; for &#39;isControllable()&#39;&#39; then it MUST always return &#39;false&#39; in the future.
   * @return bool &#39;true&#39; if the token can still be controlled by operators, &#39;false&#39; if it can&#39;t anymore.
   */
  function isControllable() external view returns (bool) {
    return _isControllable;
  }

  /**
   * [ERC1400 INTERFACE (4/9)]
   * @dev Know if new tokens can be issued in the future.
   * @return bool &#39;true&#39; if tokens can still be issued by the issuer, &#39;false&#39; if they can&#39;t anymore.
   */
  function isIssuable() external view returns (bool) {
    return _isIssuable;
  }

  /**
   * [ERC1400 INTERFACE (5/9)]
   * @dev Issue tokens from a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to issue tokens.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, by the issuer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes data)
    external
    onlyMinter
    issuableToken
    isValidCertificate(data)
  {
    _issueByPartition(partition, msg.sender, tokenHolder, value, data, "");
  }

  /**
   * [ERC1400 INTERFACE (6/9)]
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param value Number of tokens redeemed.
   * @param data Information attached to the redemption, by the redeemer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function redeemByPartition(bytes32 partition, uint256 value, bytes data)
    external
    isValidCertificate(data)
  {
    _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
  }

  /**
   * [ERC1400 INTERFACE (7/9)]
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to redeem tokens.
   * @param value Number of tokens redeemed.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (tokenHolder == address(0)) ? msg.sender : tokenHolder;
    require(_isOperatorForPartition(partition, msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _redeemByPartition(partition, msg.sender, _from, value, data, operatorData);
  }

  /**
   * [ERC1400 INTERFACE (8/9)]
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param partition Name of the partition.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
  function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes data)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    if(!_checkCertificate(data, 0, 0xf3d490db)) { // 4 first bytes of keccak256(transferByPartition(bytes32,address,uint256,bytes))
      return(hex"A3", "", partition); // Transfer Blocked - Sender lockup period not ended
    } else {
      return _canTransfer(partition, msg.sender, msg.sender, to, value, data, "");
    }
  }

  /**
   * [ERC1400 INTERFACE (9/9)]
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param partition Name of the partition.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
  function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes data, bytes operatorData)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    if(!_checkCertificate(operatorData, 0, 0x8c0dee9c)) { // 4 first bytes of keccak256(operatorTransferByPartition(bytes32,address,address,uint256,bytes,bytes))
      return(hex"A3", "", partition); // Transfer Blocked - Sender lockup period not ended
    } else {
      address _from = (from == address(0)) ? msg.sender : from;
      return _canTransfer(partition, msg.sender, _from, to, value, data, operatorData);
    }
  }

  /********************** ERC1400 INTERNAL FUNCTIONS **************************/

  /**
   * [INTERNAL]
   * @dev Know the reason on success or failure based on the EIP-1066 application-specific status codes.
   * @param partition Name of the partition.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator (if any).
   * @return ESC (Ethereum Status Code) following the EIP-1066 standard.
   * @return Additional bytes32 parameter that can be used to define
   * application specific reason codes with additional details (for example the
   * transfer restriction rule responsible for making the transfer operation invalid).
   * @return Destination partition.
   */
   function _canTransfer(bytes32 partition, address operator, address from, address to, uint256 value, bytes data, bytes operatorData)
     internal
     view
     returns (byte, bytes32, bytes32)
   {
     if(!_isOperatorForPartition(partition, operator, from))
       return(hex"A7", "", partition); // "Transfer Blocked - Identity restriction"

     if((_balances[from] < value) || (_balanceOfByPartition[from][partition] < value))
       return(hex"A4", "", partition); // Transfer Blocked - Sender balance insufficient

     if(to == address(0))
       return(hex"A6", "", partition); // Transfer Blocked - Receiver not eligible

     address senderImplementation;
     address recipientImplementation;
     senderImplementation = interfaceAddr(from, "ERC777TokensSender");
     recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

     if((senderImplementation != address(0))
       && !IERC777TokensSender(senderImplementation).canTransfer(partition, from, to, value, data, operatorData))
       return(hex"A5", "", partition); // Transfer Blocked - Sender not eligible

     if((recipientImplementation != address(0))
       && !IERC777TokensRecipient(recipientImplementation).canReceive(partition, from, to, value, data, operatorData))
       return(hex"A6", "", partition); // Transfer Blocked - Receiver not eligible

     if(!_isMultiple(value))
       return(hex"A9", "", partition); // Transfer Blocked - Token granularity

     return(hex"A2", "", partition);  // Transfer Verified - Off-Chain approval for restricted token
   }

  /**
   * [INTERNAL]
   * @dev Issue tokens from a specific partition.
   * @param toPartition Name of the partition.
   * @param operator The address performing the issuance.
   * @param to Token recipient.
   * @param value Number of tokens to issue.
   * @param data Information attached to the issuance.
   * @param operatorData Information attached to the issuance, by the operator (if any).
   */
  function _issueByPartition(
    bytes32 toPartition,
    address operator,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
  {
    _issue(operator, to, value, data, operatorData);
    _addTokenToPartition(to, toPartition, value);

    emit IssuedByPartition(toPartition, operator, to, value, data, operatorData);
  }

  /**
   * [INTERNAL]
   * @dev Redeem tokens of a specific partition.
   * @param fromPartition Name of the partition.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator (if any).
   */
  function _redeemByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
  {
    require(_balanceOfByPartition[from][fromPartition] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _removeTokenFromPartition(from, fromPartition, value);
    _redeem(operator, from, value, data, operatorData);

    emit RedeemedByPartition(fromPartition, operator, from, value, data, operatorData);
  }

  /********************** ERC1400 OPTIONAL FUNCTIONS **************************/

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
   * Once set to false, &#39;_isControllable&#39; can never be set to &#39;true&#39; again.
   */
  function renounceControl() external onlyOwner {
    _isControllable = false;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Definitely renounce the possibility to issue new tokens.
   * Once set to false, &#39;_isIssuable&#39; can never be set to &#39;true&#39; again.
   */
  function renounceIssuance() external onlyOwner {
    _isIssuable = false;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function setControllers(address[] operators) external onlyOwner {
    _setControllers(operators);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function setPartitionControllers(bytes32 partition, address[] operators) external onlyOwner {
     _setPartitionControllers(partition, operators);
   }

   /**
   * @dev Add a certificate signer for the token.
   * @param operator Address to set as a certificate signer.
   * @param authorized &#39;true&#39; if operator shall be accepted as certificate signer, &#39;false&#39; if not.
   */
  function setCertificateSigner(address operator, bool authorized) external onlyOwner {
    _setCertificateSigner(operator, authorized);
  }

  /************* ERC1410/ERC777 BACKWARDS RETROCOMPATIBILITY ******************/

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Get token default partitions to send from.
   * Function used for ERC777 and ERC20 backwards compatibility.
   * For example, a security token may return the bytes32("unrestricted").
   * @return Default partitions.
   */
  function getTokenDefaultPartitions() external view returns (bytes32[]) {
    return _tokenDefaultPartitions;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Set token default partitions to send from.
   * Function used for ERC777 and ERC20 backwards compatibility.
   * @param defaultPartitions Partitions to use by default when not specified.
   */
  function setTokenDefaultPartitions(bytes32[] defaultPartitions) external onlyOwner {
    _tokenDefaultPartitions = defaultPartitions;
  }


  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD][OVERRIDES ERC1410 METHOD]
   * @dev Redeem the value of tokens from the address &#39;msg.sender&#39;.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function redeem(uint256 value, bytes data)
    external
    isValidCertificate(data)
  {
    _redeemByDefaultPartitions(msg.sender, msg.sender, value, data, "");
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD][OVERRIDES ERC1410 METHOD]
   * @dev Redeem the value of tokens on behalf of the address &#39;from&#39;.
   * @param from Token holder whose tokens will be redeemed (or &#39;address(0)&#39; to set from to &#39;msg.sender&#39;).
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
   */
  function redeemFrom(address from, uint256 value, bytes data, bytes operatorData)
    external
    isValidCertificate(operatorData)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _redeemByDefaultPartitions(msg.sender, _from, value, data, operatorData);
  }

  /**
  * [NOT MANDATORY FOR ERC1410 STANDARD]
   * @dev Redeem tokens from a default partitions.
   * @param operator The address performing the redeem.
   * @param from Token holder.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator (if any).
   */
  function _redeemByDefaultPartitions(
    address operator,
    address from,
    uint256 value,
    bytes data,
    bytes operatorData
  )
    internal
  {
    bytes32[] memory _partitions = _getDefaultPartitions(from);
    require(_partitions.length != 0, "A8: Transfer Blocked - Token restriction");

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _partitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_partitions[i]];
      if(_remainingValue <= _localBalance) {
        _redeemByPartition(_partitions[i], operator, from, _remainingValue, data, operatorData);
        _remainingValue = 0;
        break;
      } else {
        _redeemByPartition(_partitions[i], operator, from, _localBalance, data, operatorData);
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "A8: Transfer Blocked - Token restriction");
  }

}

/* eof (./contracts/ERC1400.sol) */
/* file: ./contracts/token/ERC20/ERC1400ERC20.sol */
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.4.24;




/**
 * @title ERC1400ERC20
 * @dev ERC1400 with ERC20 retrocompatibility
 */
contract ERC1400ERC20 is IERC20, ERC1400 {

  bool internal _erc20compatible;

  // Mapping from (tokenHolder, spender) to allowed value.
  mapping (address => mapping (address => uint256)) internal _allowed;

  /**
   * @dev Modifier to verify if ERC20 retrocompatible are locked/unlocked.
   */
  modifier erc20Compatible() {
    require(_erc20compatible, "Action Blocked - Token restriction");
    _;
  }

  /**
   * [ERC1400ERC20 CONSTRUCTOR]
   * @dev Initialize ERC71400ERC20 and CertificateController parameters + register
   * the contract implementation in ERC820Registry.
   * @param name Name of the token.
   * @param symbol Symbol of the token.
   * @param granularity Granularity of the token.
   * @param controllers Array of initial controllers.
   * @param certificateSigner Address of the off-chain service which signs the
   * conditional ownership certificates required for token transfers, issuance,
   * redemption (Cf. CertificateController.sol).
   */
  constructor(
    string name,
    string symbol,
    uint256 granularity,
    address[] controllers,
    address certificateSigner,
    bytes32[] tokenDefaultPartitions
  )
    public
    ERC1400(name, symbol, granularity, controllers, certificateSigner, tokenDefaultPartitions)
  {}

  /**
   * [OVERRIDES ERC1400 METHOD]
   * @dev Perform the transfer of tokens.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer.
   * @param operatorData Information attached to the transfer by the operator (if any).
   * @param preventLocking &#39;true&#39; if you want this function to throw when tokens are sent to a contract not
   * implementing &#39;erc777tokenHolder&#39;.
   * ERC777 native transfer functions MUST set this parameter to &#39;true&#39;, and backwards compatible ERC20 transfer
   * functions SHOULD set this parameter to &#39;false&#39;.
   */
  function _transferWithData(
    address operator,
    address from,
    address to,
    uint256 value,
    bytes data,
    bytes operatorData,
    bool preventLocking
  )
    internal
  {
    ERC777._transferWithData(operator, from, to, value, data, operatorData, preventLocking);

    if(_erc20compatible) {
      emit Transfer(from, to, value);
    }
  }

  /**
   * [OVERRIDES ERC1400 METHOD]
   * @dev Perform the token redemption.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption by the operator (if any).
   */
  function _redeem(address operator, address from, uint256 value, bytes data, bytes operatorData) internal {
    ERC777._redeem(operator, from, value, data, operatorData);

    if(_erc20compatible) {
      emit Transfer(from, address(0), value);  //  ERC20 backwards compatibility
    }
  }

  /**
   * [OVERRIDES ERC1400 METHOD]
   * @dev Perform the issuance of tokens.
   * @param operator Address which triggered the issuance.
   * @param to Token recipient.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance.
   * @param operatorData Information attached to the issuance by the operator (if any).
   */
  function _issue(address operator, address to, uint256 value, bytes data, bytes operatorData) internal {
    ERC777._issue(operator, to, value, data, operatorData);

    if(_erc20compatible) {
      emit Transfer(address(0), to, value); // ERC20 backwards compatibility
    }
  }

  /**
   * [OVERRIDES ERC1400 METHOD]
   * @dev Get the number of decimals of the token.
   * @return The number of decimals of the token. For Backwards compatibility, decimals are forced to 18 in ERC777.
   */
  function decimals() external view erc20Compatible returns(uint8) {
    return uint8(18);
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Check the value of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the value of tokens still available for the spender.
   */
  function allowance(address owner, address spender) external view erc20Compatible returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of &#39;msg.sender&#39;.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @return A boolean that indicates if the operation was successful.
   */
  function approve(address spender, uint256 value) external erc20Compatible returns (bool) {
    require(spender != address(0), "A5: Transfer Blocked - Sender not eligible");
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Transfer token for a specified address.
   * @param to The address to transfer to.
   * @param value The value to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transfer(address to, uint256 value) external erc20Compatible returns (bool) {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, "", "");
    return true;
  }

  /**
   * [NOT MANDATORY FOR ERC1400 STANDARD]
   * @dev Transfer tokens from one address to another.
   * @param from The address which you want to transfer tokens from.
   * @param to The address which you want to transfer to.
   * @param value The amount of tokens to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transferFrom(address from, address to, uint256 value) external erc20Compatible returns (bool) {
    address _from = (from == address(0)) ? msg.sender : from;
    require( _isOperatorFor(msg.sender, _from)
      || (value <= _allowed[_from][msg.sender]), "A7: Transfer Blocked - Identity restriction");

    if(_allowed[_from][msg.sender] >= value) {
      _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(value);
    } else {
      _allowed[_from][msg.sender] = 0;
    }

    _transferByDefaultPartitions(msg.sender, _from, to, value, "", "");
    return true;
  }

  /***************** ERC1400ERC20 OPTIONAL FUNCTIONS **************************/

  /**
   * [NOT MANDATORY FOR ERC1400ERC20 STANDARD]
   * @dev Register/Unregister the ERC20Token interface with its own address via ERC820.
   * @param erc20compatible &#39;true&#39; to register the ERC20Token interface, &#39;false&#39; to unregister.
   */
  function setERC20compatibility(bool erc20compatible) external onlyOwner {
    _setERC20compatibility(erc20compatible);
  }

  /**
   * [NOT MANDATORY FOR ERC1400ERC20 STANDARD]
   * @dev Register/unregister the ERC20Token interface.
   * @param erc20compatible &#39;true&#39; to register the ERC20Token interface, &#39;false&#39; to unregister.
   */
  function _setERC20compatibility(bool erc20compatible) internal {
    _erc20compatible = erc20compatible;
    if(_erc20compatible) {
      setInterfaceImplementation("ERC20Token", this);
    } else {
      setInterfaceImplementation("ERC20Token", address(0));
    }
  }

}

/* eof (./contracts/token/ERC20/ERC1400ERC20.sol) */