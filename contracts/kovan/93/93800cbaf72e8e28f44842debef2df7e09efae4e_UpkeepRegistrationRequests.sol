/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {
    address public owner;
    address private pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address _to) external onlyOwner() {
        pendingOwner = _to;

        emit OwnershipTransferRequested(owner, _to);
    }

    /**
     * @dev Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external {
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

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, KeeperRegistry owner registers manually on KeeperRegistry,
 * this contract owner then calls `approved` on this contract to let UI and others know that the upkeep has now been registered.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on keeper registry
 * and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract UpkeepRegistrationRequests is Owned {
    bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

    uint256 private s_minLINKWei;

    address public immutable LINK_ADDRESS;

    //are registrations allowed to be auto approved
    bool private s_autoApproveRegistrations;

    //auto-approve registration window size in number of blocks
    uint256 private s_autoApproveWindowSizeInBlocks;

    //number of registrations allowed to auto-approve per window
    uint256 private s_autoApproveAllowedPerWindow;

    //block number when current registration window started
    uint256 private s_currentAutoApproveWindowStart;

    //number of registrations auto approved in current window
    uint256 private s_autoApprovedRegistrationsInCurrentWindow;

    KeeperRegistryBaseInterface public s_keeperRegistry;

    event MinLINKChanged(uint256 from, uint256 to);

    event RegistrationRequested(
        bytes32 indexed hash,
        string name,
        bytes encryptedEmail,
        address indexed upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes checkData,
        uint8 indexed source
    );

    event RegistrationApproved(
        bytes32 indexed hash,
        string displayName,
        uint256 indexed upkeepId
    );

    constructor(address LINKAddress, uint256 minimumLINKWei) {
        LINK_ADDRESS = LINKAddress;
        s_minLINKWei = minimumLINKWei;
    }

    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name name of the upkeep to be registered
     * @param encryptedEmail Amount of LINK sent (specified in wei)
     * @param upkeepContract address to peform upkeep on
     * @param gasLimit amount of gas to provide the target contract when
     * performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param source application sending this request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint8 source
    ) external onlyLINK() {
        bytes32 hash = keccak256(msg.data);
        emit RegistrationRequested(
            hash,
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            source
        );

        // if auto approve is true send registration request to the Keeper Registry contract
        if (s_autoApproveRegistrations) {
            //reset auto approve window if passed end of current window
            if (
                (block.number - s_currentAutoApproveWindowStart) >=
                s_autoApproveWindowSizeInBlocks
            ) {
                s_currentAutoApproveWindowStart = block.number;
                s_autoApprovedRegistrationsInCurrentWindow = 0;
            }

            //auto register only if max number of allowed registrations are not already completed for this auto approve window
            if (
                s_autoApprovedRegistrationsInCurrentWindow <
                s_autoApproveAllowedPerWindow
            ) {
                //call register on keeper Registry
                uint256 upkeepId =
                    s_keeperRegistry.registerUpkeep(
                        upkeepContract,
                        gasLimit,
                        adminAddress,
                        checkData
                    );
                s_autoApprovedRegistrationsInCurrentWindow++;

                // emit approve event
                emit RegistrationApproved(hash, name, upkeepId);
            }
        }
    }

    /**
     * @notice this function is called after registering upkeep on the Registry contract
     * @param hash hash of the message data of the registration request that is being approved
     * @param displayName display name for the upkeep being approved
     * @param upkeepId id of the upkeep that has been registered
     */
    function approved(
        bytes32 hash,
        string memory displayName,
        uint256 upkeepId
    ) public onlyOwner() {
        emit RegistrationApproved(hash, displayName, upkeepId);
    }

    /**
     * @notice owner calls this function to set minimum LINK required to send registration request
     * @param minimumLINKWei minimum LINK required to send registration request
     */
    function setMinLINKWei(uint256 minimumLINKWei) external onlyOwner() {
        emit MinLINKChanged(s_minLINKWei, minimumLINKWei);
        s_minLINKWei = minimumLINKWei;
    }

    /**
     * @notice read the minimum LINK required to send registration request
     */
    function getMinLINKWei() external view returns (uint256) {
        return s_minLINKWei;
    }

    /**
     * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
     * @param autoApproveRegistrations setting for autoapprove registrations
     * @param autoApproveWindowSizeInBlocks window size defined in number of blocks
     * @param autoApproveAllowedPerWindow number of registrations that can be auto approved in above window
     * @param keeperRegistry new keeper registry address
     */
    function setRegistrationConfig(
        bool autoApproveRegistrations,
        uint256 autoApproveWindowSizeInBlocks,
        uint256 autoApproveAllowedPerWindow,
        address keeperRegistry
    ) external onlyOwner() {
        s_autoApproveRegistrations = autoApproveRegistrations;
        s_autoApproveWindowSizeInBlocks = autoApproveWindowSizeInBlocks;
        s_autoApproveAllowedPerWindow = autoApproveAllowedPerWindow;
        s_keeperRegistry = KeeperRegistryBaseInterface(keeperRegistry);
    }
    
  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
        bool autoApproveRegistrations,
        uint256 autoApproveWindowSizeInBlocks,
        uint256 autoApproveAllowedPerWindow,
        address keeperRegistry,
        uint256 currentAutoApproveWindowStart,
        uint256 autoApprovedRegistrationsInCurrentWindow
    )
  {
    return (
      s_autoApproveRegistrations,
      s_autoApproveWindowSizeInBlocks,
      s_autoApproveAllowedPerWindow,
      address(s_keeperRegistry),
      s_currentAutoApproveWindowStart,
      s_autoApprovedRegistrationsInCurrentWindow
    );
  }

    /**
     * @notice Called when LINK is sent to the contract via `transferAndCall`
     * @param amount Amount of LINK sent (specified in wei)
     * @param data Payload of the transaction
     */
    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    ) external onlyLINK() permittedFunctionsForLINK(data) {
        require(amount >= s_minLINKWei, "Insufficient payment");
        (bool success, ) = address(this).delegatecall(data); // calls register
        require(success, "Unable to create request");
    }

    /**
     * @dev Reverts if not sent from the LINK token
     */
    modifier onlyLINK() {
        require(msg.sender == LINK_ADDRESS, "Must use LINK token");
        _;
    }

    /**
     * @dev Reverts if the given data does not begin with the `register` function selector
     * @param _data The data payload of the request
     */
    modifier permittedFunctionsForLINK(bytes memory _data) {
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
}


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
      int256 fallbackGasPrice,
      int256 fallbackLinkPrice
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
      int256 gasWei,
      int256 linkEth
    );
}