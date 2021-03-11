/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.5.4;

/**
 * @notice The Issuer issues claims for TENX tokens which users can claim to receive tokens.
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
     * @dev remove an account's access to this role
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

interface IHasIssuership {
    event IssuershipTransferred(address indexed from, address indexed to);

    function transferIssuership(address newIssuer) external;
}

contract IssuerStaffRole {
    using Roles for Roles.Role;

    event IssuerStaffAdded(address indexed account);
    event IssuerStaffRemoved(address indexed account);

    Roles.Role internal _issuerStaffs;

    modifier onlyIssuerStaff() {
        require(isIssuerStaff(msg.sender), "Only IssuerStaffs can execute this function.");
        _;
    }

    constructor() internal {
        _addIssuerStaff(msg.sender);
    }

    function isIssuerStaff(address account) public view returns (bool) {
        return _issuerStaffs.has(account);
    }

    function addIssuerStaff(address account) public onlyIssuerStaff {
        _addIssuerStaff(account);
    }

    function renounceIssuerStaff() public {
        _removeIssuerStaff(msg.sender);
    }

    function _addIssuerStaff(address account) internal {
        _issuerStaffs.add(account);
        emit IssuerStaffAdded(account);
    }

    function _removeIssuerStaff(address account) internal {
        _issuerStaffs.remove(account);
        emit IssuerStaffRemoved(account);
    }
}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface IERC1594 {
    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Issuance
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function isIssuable() external view returns (bool);

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
}

interface IIssuer {
    event Issued(address indexed payee, uint amount);
    event Claimed(address indexed payee, uint amount);
    event FinishedIssuing(address indexed issuer);

    function issue(address payee, uint amount) external;
    function claim() external;
    function airdrop(address payee, uint amount) external;
    function isRunning() external view returns (bool);
}


contract Issuer is IIssuer, IHasIssuership, IssuerStaffRole, Ownable, Pausable, ReentrancyGuard {
    struct Claim {
        address issuer;
        ClaimState status;
        uint amount;
    }

    enum ClaimState { NONE, ISSUED, CLAIMED }
    mapping(address => Claim) public claims;

    bool public isRunning = true;
    IERC1594 public token; // Mints tokens to payee's address

    event Issued(address indexed payee, address indexed issuer, uint amount);
    event Claimed(address indexed payee, uint amount);

    /**
    * @notice Modifier to check that the Issuer contract is currently running.
    */
    modifier whenRunning() {
        require(isRunning, "Issuer contract has stopped running.");
        _;
    }    

    /**
    * @notice Modifier to check the status of a claim.
    * @param _payee Payee address
    * @param _state Claim status    
    */
    modifier atState(address _payee, ClaimState _state) {
        Claim storage c = claims[_payee];
        require(c.status == _state, "Invalid claim source state.");
        _;
    }

    /**
    * @notice Modifier to check the status of a claim.
    * @param _payee Payee address
    * @param _state Claim status
    */
    modifier notAtState(address _payee, ClaimState _state) {
        Claim storage c = claims[_payee];
        require(c.status != _state, "Invalid claim source state.");
        _;
    }

    constructor(IERC1594 _token) public {
        token = _token;
    }

    /**
     * @notice Transfer the token's Issuer role from this contract to another address. Decommissions this Issuer contract.
     */
    function transferIssuership(address _newIssuer) 
        external onlyOwner whenRunning 
    {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        isRunning = false;
        IHasIssuership t = IHasIssuership(address(token));
        t.transferIssuership(_newIssuer);
    }

    /**
    * @notice Issue a new claim.
    * @param _payee The address of the _payee.
    * @param _amount The amount of tokens the payee will receive.
    */
    function issue(address _payee, uint _amount) 
        external onlyIssuerStaff whenRunning whenNotPaused notAtState(_payee, ClaimState.CLAIMED) 
    {
        require(_payee != address(0), "Payee must not be a zero address.");
        require(_payee != msg.sender, "Issuers cannot issue for themselves");
        require(_amount > 0, "Claim amount must be positive.");
        claims[_payee] = Claim({
            status: ClaimState.ISSUED,
            amount: _amount,
            issuer: msg.sender
        });
        emit Issued(_payee, msg.sender, _amount);
    }

    /**
    * @notice Function for users to redeem a claim of tokens.
    * @dev To claim, users must call this contract from their claim address. Tokens equal to the claim amount will be minted to the claim address.
    */
    function claim() 
        external whenRunning whenNotPaused atState(msg.sender, ClaimState.ISSUED) 
    {
        address payee = msg.sender;
        Claim storage c = claims[payee];
        c.status = ClaimState.CLAIMED; // Marks claim as claimed
        emit Claimed(payee, c.amount);

        token.issue(payee, c.amount, ""); // Mints tokens to payee's address
    }

    /**
    * @notice Function to mint tokens to users directly in a single step. Skips the issued state.
    * @param _payee The address of the _payee.
    * @param _amount The amount of tokens the payee will receive.    
    */
    function airdrop(address _payee, uint _amount) 
        external onlyIssuerStaff whenRunning whenNotPaused atState(_payee, ClaimState.NONE) nonReentrant 
    {
        require(_payee != address(0), "Payee must not be a zero address.");
        require(_payee != msg.sender, "Issuers cannot airdrop for themselves");
        require(_amount > 0, "Claim amount must be positive.");
        claims[_payee] = Claim({
            status: ClaimState.CLAIMED,
            amount: _amount,
            issuer: msg.sender
        });
        emit Claimed(_payee, _amount);

        token.issue(_payee, _amount, ""); // Mints tokens to payee's address
    }
}