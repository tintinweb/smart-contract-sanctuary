/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @chainlink/contracts/src/v0.7/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


// File contracts/vendor/Owned.sol

pragma solidity ^0.7.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}


// File contracts/KeeperRegistryInterface.sol

pragma solidity 0.7.6;

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (
      uint256 id
    );
  function performUpkeep(
    uint256 id,
    bytes calldata performData
  ) external returns (
      bool success
    );
  function cancelUpkeep(
    uint256 id
  ) external;
  function addFunds(
    uint256 id,
    uint96 amount
  ) external;

  function getUpkeep(uint256 id)
    external view returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );
  function getUpkeepCount()
    external view returns (uint256);
  function getCanceledUpkeepList()
    external view returns (uint256[] memory);
  function getKeeperList()
    external view returns (address[] memory);
  function getKeeperInfo(address query)
    external view returns (
      address payee,
      bool active,
      uint96 balance
    );
  function getConfig()
    external view returns (
      uint32 paymentPremiumPPB,
      uint24 checkFrequencyBlocks,
      uint32 checkGasLimit,
      uint24 stalenessSeconds,
      uint16 gasCeilingMultiplier,
      uint256 fallbackGasPrice,
      uint256 fallbackLinkPrice
    );
}

/**
  * @dev The view methods are not actually marked as view in the implementation
  * but we want them to be easily queried off-chain. Solidity will not compile
  * if we actually inherrit from this interface, so we document it here.
  */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId,
    address from
  )
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId,
    address from
  )
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}


// File contracts/SafeMath96.sol

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 96 bit integers.
 */
library SafeMath96 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint96 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint96 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint96 a, uint96 b) internal pure returns (uint96) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint96 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint96 a, uint96 b) internal pure returns (uint96) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


// File contracts/UpkeepRegistrationRequests.sol

pragma solidity 0.7.6;




/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract UpkeepRegistrationRequests is Owned {
    using SafeMath96 for uint96;

    bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

    uint256 private s_minLINKJuels;
    mapping(bytes32 => PendingRequest) private s_pendingRequests;

    LinkTokenInterface public immutable LINK;

    struct AutoApprovedConfig {
        bool enabled;
        uint16 allowedPerWindow;
        uint32 windowSizeInBlocks;
        uint64 windowStart;
        uint16 approvedInCurrentWindow;
    }

    struct PendingRequest {
        address admin;
        uint96 balance;
    }

    AutoApprovedConfig private s_config;
    KeeperRegistryBaseInterface private s_keeperRegistry;

    event RegistrationRequested(
        bytes32 indexed hash,
        string name,
        bytes encryptedEmail,
        address indexed upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes checkData,
        uint96 amount,
        uint8 indexed source
    );

    event RegistrationApproved(
        bytes32 indexed hash,
        string displayName,
        uint256 indexed upkeepId
    );

    event ConfigChanged(
        bool enabled,
        uint32 windowSizeInBlocks,
        uint16 allowedPerWindow,
        address keeperRegistry,
        uint256 minLINKJuels
    );

    constructor(
        address LINKAddress,
        uint256 minimumLINKJuels
    ) {
        LINK = LinkTokenInterface(LINKAddress);
        s_minLINKJuels = minimumLINKJuels;
    }

    //EXTERNAL

    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name string of the upkeep to be registered
     * @param encryptedEmail email address of upkeep contact
     * @param upkeepContract address to peform upkeep on
     * @param gasLimit amount of gas to provide the target contract when performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param amount quantity of LINK upkeep is funded with (specified in Juels)
     * @param source application sending this request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    )
      external
      onlyLINK()
    {
        require(adminAddress != address(0), "invalid admin address");
        bytes32 hash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData));

        emit RegistrationRequested(
            hash,
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source
        );

        AutoApprovedConfig memory config = s_config;
        if (config.enabled && _underApprovalLimit(config)) {
            _incrementApprovedCount(config);

            _approve(
                name,
                upkeepContract,
                gasLimit,
                adminAddress,
                checkData,
                amount,
                hash
            );
        } else {
            uint96 newBalance = s_pendingRequests[hash].balance.add(amount);
            s_pendingRequests[hash] = PendingRequest({
                admin: adminAddress,
                balance: newBalance
            });
        }
    }

    /**
     * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
     */
    function approve(
        string memory name,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes32 hash
    )
      external
      onlyOwner()
    {
        PendingRequest memory request = s_pendingRequests[hash];
        require(request.admin != address(0), "request not found");
        bytes32 expectedHash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData));
        require(hash == expectedHash, "hash and payload do not match");
        delete s_pendingRequests[hash];
        _approve(
            name,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            request.balance,
            hash
        );
    }

    /**
     * @notice cancel will remove a registration request and return the refunds to the msg.sender
     * @param hash the request hash
     */
    function cancel(
        bytes32 hash
    )
      external
    {
        PendingRequest memory request = s_pendingRequests[hash];
        require(msg.sender == request.admin || msg.sender == owner, "only admin / owner can cancel");
        require(request.admin != address(0), "request not found");
        delete s_pendingRequests[hash];
        require(LINK.transfer(msg.sender, request.balance), "LINK token transfer failed");
    }

    /**
     * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
     * @param enabled setting for autoapprove registrations
     * @param windowSizeInBlocks window size defined in number of blocks
     * @param allowedPerWindow number of registrations that can be auto approved in above window
     * @param keeperRegistry new keeper registry address
     */
    function setRegistrationConfig(
        bool enabled,
        uint32 windowSizeInBlocks,
        uint16 allowedPerWindow,
        address keeperRegistry,
        uint256 minLINKJuels
    )
      external
      onlyOwner()
    {
        s_config = AutoApprovedConfig({
            enabled: enabled,
            allowedPerWindow: allowedPerWindow,
            windowSizeInBlocks: windowSizeInBlocks,
            windowStart: 0,
            approvedInCurrentWindow: 0
        });
        s_minLINKJuels = minLINKJuels;
        s_keeperRegistry = KeeperRegistryBaseInterface(keeperRegistry);

        emit ConfigChanged(
          enabled,
          windowSizeInBlocks,
          allowedPerWindow,
          keeperRegistry,
          minLINKJuels
        );
    }

    /**
     * @notice read the current registration configuration
     */
    function getRegistrationConfig()
        external
        view
        returns (
            bool enabled,
            uint32 windowSizeInBlocks,
            uint16 allowedPerWindow,
            address keeperRegistry,
            uint256 minLINKJuels,
            uint64 windowStart,
            uint16 approvedInCurrentWindow
        )
    {
        AutoApprovedConfig memory config = s_config;
        return (
            config.enabled,
            config.windowSizeInBlocks,
            config.allowedPerWindow,
            address(s_keeperRegistry),
            s_minLINKJuels,
            config.windowStart,
            config.approvedInCurrentWindow
        );
    }

    /**
     * @notice gets the admin address and the current balance of a registration request
     */
    function getPendingRequest(bytes32 hash) external view returns(address, uint96) {
        PendingRequest memory request = s_pendingRequests[hash];
        return (request.admin, request.balance);
    }

    /**
     * @notice Called when LINK is sent to the contract via `transferAndCall`
     * @param amount Amount of LINK sent (specified in Juels)
     * @param data Payload of the transaction
     */
    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    )
      external
      onlyLINK()
      permittedFunctionsForLINK(data)
      isActualAmount(amount, data)
    {
        require(amount >= s_minLINKJuels, "Insufficient payment");
        (bool success, ) = address(this).delegatecall(data); // calls register
        require(success, "Unable to create request");
    }

    //PRIVATE

    /**
     * @dev reset auto approve window if passed end of current window
     */
    function _resetWindowIfRequired(
        AutoApprovedConfig memory config
    )
      private
    {
        uint64 blocksPassed = uint64(block.number - config.windowStart);
        if (blocksPassed >= config.windowSizeInBlocks) {
            config.windowStart = uint64(block.number);
            config.approvedInCurrentWindow = 0;
            s_config = config;
        }
    }

    /**
     * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
     */
    function _approve(
        string memory name,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        bytes32 hash
    )
      private
    {
        KeeperRegistryBaseInterface keeperRegistry = s_keeperRegistry;

        // register upkeep
        uint256 upkeepId = keeperRegistry.registerUpkeep(
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData
        );
        // fund upkeep
        bool success = LINK.transferAndCall(
          address(keeperRegistry),
          amount,
          abi.encode(upkeepId)
        );
        require(success, "failed to fund upkeep");

        emit RegistrationApproved(hash, name, upkeepId);
    }

    /**
     * @dev determine approval limits and check if in range
     */
    function _underApprovalLimit(
      AutoApprovedConfig memory config
    )
      private
      returns (bool)
    {
        _resetWindowIfRequired(config);
        if (config.approvedInCurrentWindow < config.allowedPerWindow) {
            return true;
        }
        return false;
    }

    /**
     * @dev record new latest approved count
     */
    function _incrementApprovedCount(
      AutoApprovedConfig memory config
    )
      private
    {
        config.approvedInCurrentWindow++;
        s_config = config;
    }

    //MODIFIERS

    /**
     * @dev Reverts if not sent from the LINK token
     */
    modifier onlyLINK() {
        require(msg.sender == address(LINK), "Must use LINK token");
        _;
    }

    /**
     * @dev Reverts if the given data does not begin with the `register` function selector
     * @param _data The data payload of the request
     */
    modifier permittedFunctionsForLINK(
        bytes memory _data
    ) {
        bytes4 funcSelector;
        assembly {
            // solhint-disable-next-line avoid-low-level-calls
            funcSelector := mload(add(_data, 32))
        }
        require(
            funcSelector == REGISTER_REQUEST_SELECTOR,
            "Must use whitelisted functions"
        );
        _;
    }

   /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(
    uint256 expected,
    bytes memory data
  ) {
      uint256 actual;
      assembly{
          actual := mload(add(data, 228))
      }
      require(expected == actual, "Amount mismatch");
      _;
  }
}