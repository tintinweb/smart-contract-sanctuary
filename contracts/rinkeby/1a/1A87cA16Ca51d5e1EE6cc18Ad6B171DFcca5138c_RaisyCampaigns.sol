/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// File: contracts/interfaces/IRaisyTokenRegistry.sol



pragma solidity ^0.8.0;

interface IRaisyTokenRegistry {
    function enabled(address) external view returns (bool);

    function getEnabledTokens() external view returns (address[] memory);
}

// File: contracts/interfaces/IRaisyAddressRegistry.sol



pragma solidity ^0.8.0;

interface IRaisyAddressRegistry {
    function raisyChef() external view returns (address);

    function tokenRegistry() external view returns (address);

    function priceFeed() external view returns (address);

    function raisyNFT() external view returns (address);

    function raisyToken() external view returns (address);

    function raisyCampaigns() external view returns (address);

    function feeAddress() external view returns (address);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol



pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol



pragma solidity ^0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: contracts/RaisyFundsRelease.sol



pragma solidity ^0.8.0;





interface IRaisyNFT {
    struct DonationInfo {
        uint256 amount;
        address tokenUsed;
        uint256 campaignId;
        address recipient;
        uint256 creationTimestamp;
    }

    function balanceOf(address) external view returns (uint256);

    function getDonationInfo(uint256)
        external
        view
        returns (DonationInfo memory);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);

    function mint(DonationInfo calldata) external returns (uint256);
}

/// @title RaisyFundsRelease
/// @author RaisyFunding
/// @notice Smart contract responsible for managing the campaigns' schedule as well as the voting system
/// @dev Parent of RaisyCampaigns, Will be an implementation of a proxy and therefore upgradeable
/// Owner is the ProxyAdmin hence the governance (gnosis-snap-safe)
contract RaisyFundsRelease is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Events of the contract
    event ScheduleRegistered(
        uint256 campaignId,
        uint256 nbMilestones,
        uint256[] pctReleasePerMilestone
    );

    event AddressRegistryUpdated(address indexed newAddressRegistry);

    event VoteSessionDurationUpdated(uint256 newAddressRegistry);

    event VoteSessionInitialized(uint256 campaignId, uint256 id);

    event NewVote(
        uint256 campaignId,
        uint256 id,
        address indexed voter,
        int256 voteRatio
    );

    event VoteRefund(
        uint256 campaignId,
        address indexed voter,
        uint256 wantsRefundTotal
    );

    /// @notice Stages Enum
    enum Stages {
        Nothing,
        Release,
        AllReleased,
        Refund
    }

    /// @notice Schedule Structure
    struct Schedule {
        uint256 campaignId;
        uint256 nbMilestones;
        uint256[] pctReleasePerMilestone;
        uint256 pctReleased;
        uint256 wantsRefund;
        uint8 currentMilestone;
        Stages releaseStage;
    }

    /// @notice Vote Structure
    struct VoteSession {
        uint256 id;
        uint256 startBlock;
        int256 voteRatio;
        bool inProgress;
        uint8 numUnsuccessfulVotes;
    }

    /// @notice Campaign ID -> Schedule
    mapping(uint256 => Schedule) public campaignSchedule;

    /// @notice Campaign ID -> bool
    mapping(uint256 => bool) public scheduleExistence;

    /// @notice Campaign ID -> Vote Session
    mapping(uint256 => VoteSession) public voteSession;

    /// @notice Campaign ID -> VoteSession ID -> address -> bool
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public hasVoted;

    /// @notice Campaign ID -> user -> wants refund
    mapping(uint256 => mapping(address => bool)) public refundVotes;

    /// @notice Campaign ID -> Number of donors
    mapping(uint256 => uint256) public nbDonors;

    /// @notice Campaign ID -> user address -> Proof of Donation claimed
    mapping(uint256 => mapping(address => bool)) public podClaimed;

    /// @notice Maximum number of milestones
    uint256 public MAX_NB_MILESTONES = 5;

    /// @notice Maximum release percentage at start
    uint256 public MAX_PCT_RELEASE_START = 10000;

    /// @notice Minimum release percentage at start
    uint256 public MIN_PCT_RELEASE_START = 2000;

    /// @notice Vote sessions duration (in blocks)
    uint256 public VOTE_SESSION_DURATION = 84200;

    /// @notice Vote refund treshold (BP)
    uint256 public REFUND_TRESHOLD = 5000;

    /// @notice Address registry
    IRaisyAddressRegistry public addressRegistry;

    /// @notice Modifiers
    modifier atStage(uint256 _campaignId, Stages _stage) {
        require(
            campaignSchedule[_campaignId].releaseStage == _stage,
            "Not at correct stage."
        );
        _;
    }

    modifier hasProofOfDonation(uint256 _campaignId) {
        // IRaisyNFT raisyNFT = IRaisyNFT(addressRegistry.raisyNFT());

        // uint256 userBalance = raisyNFT.balanceOf(msg.sender);

        // /// Checks if msg.sender has a proof of donation
        // require(userBalance > 0, "Proof Of Donation needed.");

        // bool _hasProofOfDonation = false;

        // for (uint256 index = 0; index < userBalance; index++) {
        //     uint256 tokenId = raisyNFT.tokenOfOwnerByIndex(msg.sender, index);

        //     // Gets the donation info for the tokenId
        //     IRaisyNFT.DonationInfo memory donationInfo = raisyNFT
        //         .getDonationInfo(tokenId);

        //     if (donationInfo.campaignId == _campaignId)
        //         _hasProofOfDonation = true;
        // }

        // require(_hasProofOfDonation, "No POD for this campaign.");

        require(
            podClaimed[_campaignId][msg.sender],
            "No PoD for this campaign."
        );

        _;
    }

    /// @notice This function allows to register a schedule for a given campaignId
    /// @dev Internal function called in RaisyCampaigns.sol when the capaign is created
    /// @param _campaignId Id of the campaign
    /// @param _nbMilestones The number of milestones the project owner wants to add
    /// @param _pctReleasePerMilestone The percentage of funds released at each milestone
    function register(
        uint256 _campaignId,
        uint256 _nbMilestones,
        uint256[] calldata _pctReleasePerMilestone
    ) internal {
        require(_nbMilestones > 0, "Needs at least 1 milestone.");
        require(_nbMilestones <= MAX_NB_MILESTONES, "Too many milestones.");
        require(
            _pctReleasePerMilestone.length == _nbMilestones,
            "Only one percent per milestone."
        );
        require(
            _pctReleasePerMilestone[0] >= MIN_PCT_RELEASE_START,
            "Start release pct too low."
        );
        require(
            _pctReleasePerMilestone[0] <= MAX_PCT_RELEASE_START,
            "Start release pct too high."
        );

        uint256 pctSum = 0;
        for (uint256 index = 0; index < _nbMilestones; index++) {
            pctSum += _pctReleasePerMilestone[index];
        }

        require(pctSum == 10000, "Pcts should add up to 100%");

        require(
            !scheduleExistence[_campaignId],
            "Campaign already has a schedule."
        );

        scheduleExistence[_campaignId] = true;

        // Add the schedule to the mapping
        campaignSchedule[_campaignId] = Schedule(
            _campaignId,
            _nbMilestones,
            _pctReleasePerMilestone,
            0,
            0,
            0,
            Stages.Release
        );

        // Emit the register event
        emit ScheduleRegistered(
            _campaignId,
            _nbMilestones,
            _pctReleasePerMilestone
        );
    }

    /**
     * @notice Gives the next percentage of total funds to be released
     * @dev Internal function called in RaisyCampaigns.sol to release funds
     * @param _campaignId Id of the campaign
     */
    function getNextPctFunds(uint256 _campaignId)
        internal
        atStage(_campaignId, Stages.Release)
        returns (uint256)
    {
        require(scheduleExistence[_campaignId], "No schedule registered.");

        uint8 current = campaignSchedule[_campaignId].currentMilestone;

        uint256 pctToRelease = campaignSchedule[_campaignId]
            .pctReleasePerMilestone[current];

        campaignSchedule[_campaignId].currentMilestone++;
        campaignSchedule[_campaignId].pctReleased += pctToRelease;

        if (
            campaignSchedule[_campaignId].currentMilestone >=
            campaignSchedule[_campaignId].nbMilestones
        ) {
            campaignSchedule[_campaignId].releaseStage = Stages.AllReleased;
        }

        return pctToRelease;
    }

    /// @notice Starts a vote session to release the next porition of funds
    /// @dev Internal function called by the campaign's owner in RaisyCampaigns.sol to ask for more funds
    /// @param _campaignId Id of the campaign
    function initializeVoteSession(uint256 _campaignId)
        internal
        atStage(_campaignId, Stages.Release)
    {
        require(
            !voteSession[_campaignId].inProgress,
            "Vote session already in progress."
        );

        // Adds the vote session to the mapping

        VoteSession storage _voteSession = voteSession[_campaignId];

        _voteSession.inProgress = true;
        _voteSession.startBlock = _getBlock();
        _voteSession.voteRatio = 0;
        _voteSession.numUnsuccessfulVotes = 0;

        emit VoteSessionInitialized(_campaignId, _voteSession.id);
    }

    /**
     * @notice Funders can vote whether they give more funds or not
     * @param _campaignId Id of the campaign
     * @param _vote Vote yes or no
     */
    function vote(uint256 _campaignId, bool _vote)
        external
        atStage(_campaignId, Stages.Release)
        hasProofOfDonation(_campaignId)
        nonReentrant
    {
        require(
            voteSession[_campaignId].inProgress,
            "No vote session in progress."
        );
        require(
            !hasVoted[_campaignId][voteSession[_campaignId].id][msg.sender],
            "Can only vote once."
        );
        require(
            _getBlock() <
                voteSession[_campaignId].startBlock + VOTE_SESSION_DURATION,
            "Vote session finished."
        );

        if (_vote) voteSession[_campaignId].voteRatio++;
        else voteSession[_campaignId].voteRatio--;

        hasVoted[_campaignId][voteSession[_campaignId].id][msg.sender] = true;

        emit NewVote(
            _campaignId,
            voteSession[_campaignId].id,
            msg.sender,
            voteSession[_campaignId].voteRatio
        );
    }

    function voteRefund(uint256 _campaignId)
        external
        atStage(_campaignId, Stages.Release)
        hasProofOfDonation(_campaignId)
    {
        require(!refundVotes[_campaignId][msg.sender], "Only 1 vote per user.");

        refundVotes[_campaignId][msg.sender] = true;

        campaignSchedule[_campaignId].wantsRefund++;

        // Go to Refund state if more than 50% of donors ask for a refund
        if (
            campaignSchedule[_campaignId].wantsRefund >
            (nbDonors[_campaignId] * REFUND_TRESHOLD) / 10000
        ) {
            campaignSchedule[_campaignId].releaseStage = Stages.Refund;
        }

        emit VoteRefund(
            _campaignId,
            msg.sender,
            campaignSchedule[_campaignId].wantsRefund
        );
    }

    /**
     * @notice Update AgoraAddressRegistry contract
     * @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IRaisyAddressRegistry(_registry);

        emit AddressRegistryUpdated(_registry);
    }

    /**
     * @notice Update VOTE_SESSION_DURATION (in blocks)
     * @dev Only admin
     */
    function updateVoteSessionDuration(uint256 _duration) external onlyOwner {
        VOTE_SESSION_DURATION = _duration;

        emit VoteSessionDurationUpdated(_duration);
    }

    /// @notice View, gives the current block
    /// @dev Function to override for the tests (mockRaisyChef)
    /// @return Current block
    function _getBlock() internal view virtual returns (uint256) {
        return block.number;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/RaisyCampaigns.sol



pragma solidity ^0.8.0;







///@notice Interfaces declaration
interface IRaisyChef {
    function add(uint256, uint256) external;

    function deposit(
        address,
        uint256,
        uint256
    ) external;

    function claimRewards(address, uint256) external;
}

interface IRaisyPriceFeed {
    function wMATIC() external view returns (address);

    function getPrice(address) external view returns (int256, uint8);
}

/// @title Main Smart Contract of the architecture
/// @author Raisy Funding
/// @notice Main Contract handling the campaigns' creation and donations
/// @dev Inherits of upgradeable versions of OZ libraries
/// interacts with the AddressRegistry / RaisyNFTFactory / RaisyFundsRelease
contract RaisyCampaigns is RaisyFundsRelease {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;

    /// @notice Events for the contract
    event CampaignCreated(
        uint256 id,
        address indexed creator,
        uint256 duration,
        uint256 startBlock,
        uint256 amountToRaise,
        bool hasReleaseSchedule
    );

    event NewDonation(
        uint256 campaignId,
        address indexed donor,
        uint256 amount,
        address indexed payToken
    );

    event ProofOfDonationClaimed(
        uint256 campaignId,
        address indexed donor,
        uint256 tokenId
    );

    event FundsClaimed(uint256 campaignId, address indexed creator);

    event PlatformFeeUpdated(uint256 platformFee);

    event Refund(
        uint256 campaignId,
        address indexed user,
        uint256 refundAmount,
        address payToken
    );

    event WithdrawFunds(
        uint256 campaignId,
        address indexed user,
        uint256 amount,
        address payToken
    );

    event MoreFundsAsked(uint256 campaignId, address indexed creator);

    event EndVoteSession(
        uint256 campaignId,
        uint256 id,
        uint256 numUnsuccessfulVotes
    );

    /// @notice Structure for a campaign
    struct Campaign {
        uint256 id; // ID of the campaign automatically set by the counter
        address creator; // Creator of the campaign
        uint256 duration;
        uint256 startBlock;
        uint256 amountToRaise; // IN USD w/ 18 decimals e.g 25 USD = 25 * 10 ** 18
        uint256 amountRaised; // IN USD w/ 18 decimals e.g 25 USD = 25 * 10 ** 18
        mapping(address => uint256) amountRaisedPerToken;
        bool isOver;
        bool hasReleaseSchedule;
    }

    /// @notice Structure for a donation
    struct Donation {
        uint256 amountInUSD; // Total amount given in USD
        mapping(address => uint256) amountPerToken;
    }

    /// @notice Maximum and Minimum campaigns' duration
    uint256 public maxDuration = 200000;
    uint256 public minDuration = 40;

    // @notice Platform Fee
    uint256 public platformFee = 250;

    /// @notice Latest campaign ID
    CountersUpgradeable.Counter private _campaignIdCounter;

    /// @notice Campaign ID -> Campaign
    mapping(uint256 => Campaign) public allCampaigns;

    /// @notice Campaign ID -> bool
    mapping(uint256 => bool) public campaignExistence;

    /// @notice address -> Campaign ID -> Donation
    mapping(address => mapping(uint256 => Donation)) public userDonations;

    /// @notice Campaign ID -> funds already claimed
    mapping(uint256 => uint256) public campaignFundsClaimed;

    /// @notice Modifiers
    modifier isNotOver(uint256 _campaignId) {
        require(
            allCampaigns[_campaignId].startBlock +
                allCampaigns[_campaignId].duration >=
                _getBlock(),
            "Campaign is over."
        );
        _;
    }

    modifier isOver(uint256 _campaignId) {
        require(
            allCampaigns[_campaignId].startBlock +
                allCampaigns[_campaignId].duration <=
                _getBlock(),
            "Campaign is not over."
        );
        _;
    }

    modifier exists(uint256 _campaignId) {
        require(campaignExistence[_campaignId], "Campaign does not exist.");
        _;
    }

    modifier isSuccess(uint256 _campaignId) {
        require(
            allCampaigns[_campaignId].amountRaised >=
                allCampaigns[_campaignId].amountToRaise,
            "Campaign hasn't been successful."
        );
        _;
    }

    modifier onlyCreator(uint256 _campaignId) {
        require(
            allCampaigns[_campaignId].creator == msg.sender,
            "You're not the creator ."
        );
        _;
    }

    /// @notice Contract initializer
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Add a campaign without any release schedule
    /// @param _duration Duration of the campaign
    /// @param _amountToRaise Amount needed by the creator
    function addCampaign(uint256 _duration, uint256 _amountToRaise) external {
        require(_duration <= maxDuration, "duration too long");
        require(_duration >= minDuration, "duration too short");
        require(_amountToRaise > 0, "amount to raise null");

        uint256 campaignId = _campaignIdCounter.current();

        // Add a new campaign to the mapping
        Campaign storage campaign = allCampaigns[campaignId];

        campaign.id = campaignId;
        campaign.creator = msg.sender;
        campaign.amountToRaise = _amountToRaise;
        campaign.isOver = false;
        campaign.hasReleaseSchedule = false;
        campaign.duration = _duration;
        campaign.amountRaised = 0;
        campaign.startBlock = _getBlock();

        // Add new pool to the RaisyChef
        IRaisyChef raisyChef = IRaisyChef(addressRegistry.raisyChef());
        raisyChef.add(campaignId, _getBlock() + _duration);

        // Inrease the counter
        _campaignIdCounter.increment();

        // Note that it now exists
        campaignExistence[campaignId] = true;

        // Emit creation event
        emit CampaignCreated(
            campaignId,
            msg.sender,
            _duration,
            _getBlock(),
            _amountToRaise,
            false
        );
    }

    /// @notice Add campaign with a release schedule
    /// @param _duration Duration of the campaign
    /// @param _amountToRaise Amount needed by the creator
    /// @param _nbMilestones Number of milestones for the release schedule
    /// @param _pctReleasePerMilestone Array of the corresponding percentage of the funds released per milestone
    function addCampaign(
        uint256 _duration,
        uint256 _amountToRaise,
        uint256 _nbMilestones,
        uint256[] calldata _pctReleasePerMilestone
    ) external {
        require(_duration <= maxDuration, "duration too long");
        require(_duration >= minDuration, "duration too short");
        require(_amountToRaise > 0, "amount to raise null");

        uint256 campaignId = _campaignIdCounter.current();

        // Add a new campaign to the mapping
        Campaign storage campaign = allCampaigns[campaignId];

        campaign.id = campaignId;
        campaign.creator = msg.sender;
        campaign.amountToRaise = _amountToRaise;
        campaign.isOver = false;
        campaign.hasReleaseSchedule = true;
        campaign.duration = _duration;
        campaign.amountRaised = 0;
        campaign.startBlock = _getBlock();

        // Add new pool to the RaisyChef
        IRaisyChef raisyChef = IRaisyChef(addressRegistry.raisyChef());
        raisyChef.add(campaignId, _getBlock() + _duration);

        // Register the schedule
        register(campaignId, _nbMilestones, _pctReleasePerMilestone);

        // Inrease the counter
        _campaignIdCounter.increment();

        // Note that it now exists
        campaignExistence[campaignId] = true;

        // Emit creation event
        emit CampaignCreated(
            campaignId,
            msg.sender,
            _duration,
            _getBlock(),
            _amountToRaise,
            true
        );
    }

    /// @notice Enable the users to make a donation
    /// @param _campaignId Id of the campaign
    /// @param _amount Amount of the donation
    /// @param _payToken Currency used to pay
    function donate(
        uint256 _campaignId,
        uint256 _amount,
        address _payToken
    ) external exists(_campaignId) isNotOver(_campaignId) nonReentrant {
        require(_amount > 0, "Donation must be positive.");

        _validPayToken(_payToken);

        IERC20 payToken = IERC20(_payToken);

        // If the donation is in $RSY then deposit in the pool
        if (_payToken == addressRegistry.raisyToken()) {
            IRaisyChef raisyChef = IRaisyChef(addressRegistry.raisyChef());
            raisyChef.deposit(msg.sender, _campaignId, _amount);
        }

        // Transfer the donation to the contract
        payToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update the mappings
        (int256 _tokenPrice, uint8 _decimals) = getPrice(_payToken);

        // E.g : _amount = 10 WBTC = 10 * 1e8
        // WBTC Price is 100 USD => amountInUSD = 100 * 1e18 * 10 * 1e8 / 1e18 = 1000 * 1e18
        uint256 amountInUSD = (uint256(_tokenPrice) * _amount) /
            (uint256(10)**_decimals);

        allCampaigns[_campaignId].amountRaised += amountInUSD;

        allCampaigns[_campaignId].amountRaisedPerToken[_payToken] += _amount;

        // If it's the first time the user is donating increment the number of donors
        if (userDonations[msg.sender][_campaignId].amountInUSD == 0)
            nbDonors[_campaignId]++;

        userDonations[msg.sender][_campaignId].amountPerToken[
            _payToken
        ] += _amount;
        userDonations[msg.sender][_campaignId].amountInUSD += amountInUSD;

        // Emit donation event
        emit NewDonation(_campaignId, msg.sender, amountInUSD, _payToken);
    }

    /// @notice enable the user to claim his proof of donation
    /// @param _campaignId Id of the campaign.
    function claimProofOfDonation(uint256 _campaignId)
        external
        exists(_campaignId)
        nonReentrant
    {
        require(allCampaigns[_campaignId].isOver, "Campaign is not over.");
        require(
            userDonations[msg.sender][_campaignId].amountInUSD > 0,
            "No PoD to claim."
        );
        require(!podClaimed[_campaignId][msg.sender], "PoD already claimed.");

        // Mint Raisy NFT
        IRaisyNFT raisyNFT = IRaisyNFT(addressRegistry.raisyNFT());

        IRaisyNFT.DonationInfo memory donationInfo = IRaisyNFT.DonationInfo(
            userDonations[msg.sender][_campaignId].amountInUSD,
            addressRegistry.raisyToken(),
            _campaignId,
            msg.sender,
            block.timestamp
        );

        uint256 tokenId = raisyNFT.mint(donationInfo);

        podClaimed[_campaignId][msg.sender] = true;

        // Emit the claim event
        emit ProofOfDonationClaimed(_campaignId, msg.sender, tokenId);
    }

    ///@notice Claim initial funds, changes the stage of the campaign and enable proof of donation.
    ///@param _campaignId Id of the campaign.
    function claimInitialFunds(uint256 _campaignId)
        external
        exists(_campaignId)
        isOver(_campaignId)
        isSuccess(_campaignId)
        nonReentrant
    {
        require(
            !allCampaigns[_campaignId].isOver,
            "Initial funds already claimed."
        );

        IRaisyTokenRegistry tokenRegistry = IRaisyTokenRegistry(
            addressRegistry.tokenRegistry()
        );
        address[] memory enabledTokens = tokenRegistry.getEnabledTokens();

        if (allCampaigns[_campaignId].hasReleaseSchedule) {
            // Trigger state change on RaisyFundsRelease
            uint256 toReleasePct = getNextPctFunds(_campaignId);

            for (uint256 index = 0; index < enabledTokens.length; index++) {
                IERC20 payToken = IERC20(enabledTokens[index]);

                uint256 toReleaseAmount = (allCampaigns[_campaignId]
                    .amountRaisedPerToken[enabledTokens[index]] *
                    toReleasePct) / 10000;

                uint256 _fee = (toReleaseAmount * platformFee) / 10000;
                address _feeAddress = addressRegistry.feeAddress();

                // Transfer the platform fee to the fee address
                payToken.safeTransfer(_feeAddress, _fee);

                // Transfer the funds to the campaign's creator
                payToken.safeTransfer(
                    allCampaigns[_campaignId].creator,
                    toReleaseAmount - _fee
                );
            }

            uint256 toReleaseAmountUSD = (allCampaigns[_campaignId]
                .amountRaised * toReleasePct) / 10000;
            campaignFundsClaimed[_campaignId] += toReleaseAmountUSD;
        } else {
            campaignFundsClaimed[_campaignId] += allCampaigns[_campaignId]
                .amountRaised;

            for (uint256 index = 0; index < enabledTokens.length; index++) {
                IERC20 payToken = IERC20(enabledTokens[index]);

                uint256 toReleaseAmount = allCampaigns[_campaignId]
                    .amountRaisedPerToken[enabledTokens[index]];

                uint256 _fee = (toReleaseAmount * platformFee) / 10000;
                address _feeAddress = addressRegistry.feeAddress();

                // Transfer the platform fee to the fee address
                payToken.safeTransfer(_feeAddress, _fee);

                // Transfer the funds to the campaign's creator
                payToken.safeTransfer(
                    allCampaigns[_campaignId].creator,
                    toReleaseAmount - _fee
                );
            }
        }

        // Enable Proof of Donation
        allCampaigns[_campaignId].isOver = true;

        // Emit the claim event
        emit FundsClaimed(_campaignId, allCampaigns[_campaignId].creator);
    }

    /// @notice Transfer the tokens to the Campaign owner
    /// @dev private function called by ensVoteSession only if the participants voted yes in majority
    /// @param _campaignId Id of the campaign
    /// @param _campaignCreator Address of the owner of the campaign
    function claimNextFunds(uint256 _campaignId, address _campaignCreator)
        private
        exists(_campaignId)
        isOver(_campaignId)
        isSuccess(_campaignId)
        nonReentrant
    {
        require(
            campaignFundsClaimed[_campaignId] <
                allCampaigns[_campaignId].amountRaised,
            "No more funds to claim."
        );
        require(allCampaigns[_campaignId].isOver, "Initial funds not claimed.");

        IRaisyTokenRegistry tokenRegistry = IRaisyTokenRegistry(
            addressRegistry.tokenRegistry()
        );
        address[] memory enabledTokens = tokenRegistry.getEnabledTokens();

        // Trigger state change on RaisyFundsRelease
        uint256 toReleasePct = getNextPctFunds(_campaignId);

        for (uint256 index = 0; index < enabledTokens.length; index++) {
            IERC20 payToken = IERC20(enabledTokens[index]);

            uint256 toReleaseAmount = (allCampaigns[_campaignId]
                .amountRaisedPerToken[enabledTokens[index]] * toReleasePct) /
                10000;

            uint256 _fee = (toReleaseAmount * platformFee) / 10000;
            address _feeAddress = addressRegistry.feeAddress();

            // Transfer the platform fee to the fee address
            payToken.safeTransfer(_feeAddress, _fee);

            // Transfer the funds to the campaign's creator
            payToken.safeTransfer(_campaignCreator, toReleaseAmount);
        }

        campaignFundsClaimed[_campaignId] +=
            (allCampaigns[_campaignId].amountRaised * toReleasePct) /
            10000;

        // Emit the claim event
        emit FundsClaimed(_campaignId, _campaignCreator);
    }

    /**
     * @notice Ends the vote session, pays the campaign owner or increase the number of unsuccessful votes.
     * @param _campaignId Id of the campaign
     */
    function endVoteSession(uint256 _campaignId)
        external
        atStage(_campaignId, Stages.Release)
    {
        require(
            voteSession[_campaignId].inProgress,
            "Vote session not in progress."
        );
        require(
            _getBlock() >=
                voteSession[_campaignId].startBlock + VOTE_SESSION_DURATION,
            "Vote session not ended."
        );

        voteSession[_campaignId].inProgress = false;
        voteSession[_campaignId].id++;

        if (voteSession[_campaignId].voteRatio >= 0) {
            voteSession[_campaignId].numUnsuccessfulVotes = 0;
            claimNextFunds(_campaignId, allCampaigns[_campaignId].creator);
        } else {
            voteSession[_campaignId].numUnsuccessfulVotes++;

            if (voteSession[_campaignId].numUnsuccessfulVotes == 3) {
                campaignSchedule[_campaignId].releaseStage = Stages.Refund;
            }
        }

        emit EndVoteSession(
            _campaignId,
            voteSession[_campaignId].id,
            voteSession[_campaignId].numUnsuccessfulVotes
        );
    }

    /// @notice The creator can come up at anytime during his campaign to ask for more funds
    /// @dev This initializes a vote session in the RaisyFundsRelease contract
    /// @param _campaignId Id of the campaign
    function askMoreFunds(uint256 _campaignId)
        external
        exists(_campaignId)
        isOver(_campaignId)
        isSuccess(_campaignId)
        onlyCreator(_campaignId)
        nonReentrant
    {
        require(
            campaignFundsClaimed[_campaignId] <
                allCampaigns[_campaignId].amountRaised,
            "No more funds to claim."
        );
        require(allCampaigns[_campaignId].isOver, "Initial funds not claimed.");

        initializeVoteSession(_campaignId);

        emit MoreFundsAsked(_campaignId, msg.sender);
    }

    /// @notice Enables an user to get their funds back if the majority voted so.
    /// @param _campaignId Id of the campaign
    /// @param _payToken Address of the token
    function getFundsBack(uint256 _campaignId, address _payToken)
        external
        exists(_campaignId)
        isOver(_campaignId)
        isSuccess(_campaignId)
        atStage(_campaignId, Stages.Refund)
        hasProofOfDonation(_campaignId)
        nonReentrant
    {
        require(
            userDonations[msg.sender][_campaignId].amountPerToken[_payToken] >
                0,
            "Nothing to withdraw."
        );

        _validPayToken(_payToken);

        IERC20 payToken = IERC20(_payToken);

        uint256 refundAmount = (userDonations[msg.sender][_campaignId]
            .amountPerToken[_payToken] *
            (10000 - campaignSchedule[_campaignId].pctReleased)) / 10000;

        if (refundAmount > 0) {
            userDonations[msg.sender][_campaignId].amountPerToken[
                _payToken
            ] = 0;

            // Transfer the funds back to the user
            payToken.safeTransfer(msg.sender, refundAmount);
        }

        emit Refund(_campaignId, msg.sender, refundAmount, _payToken);
    }

    /// @notice The campaign didn't reach its objective -> the donor can withdraw his funds and claim rewards
    /// @param _campaignId Id of the campaign
    /// @param _payToken Address of the token
    function withdrawFunds(uint256 _campaignId, address _payToken)
        external
        exists(_campaignId)
        isOver(_campaignId)
        nonReentrant
    {
        require(
            allCampaigns[_campaignId].amountRaised <
                allCampaigns[_campaignId].amountToRaise,
            "Campaign has been successful."
        );
        _validPayToken(_payToken);
        require(
            userDonations[msg.sender][_campaignId].amountPerToken[_payToken] >
                0,
            "No more funds to withdraw."
        );

        uint256 refundAmount = userDonations[msg.sender][_campaignId]
            .amountPerToken[_payToken];

        IERC20 payToken = IERC20(_payToken);

        if (refundAmount > 0) {
            userDonations[msg.sender][_campaignId].amountPerToken[
                _payToken
            ] = 0;

            // Transfer the funds back to the user
            payToken.safeTransfer(msg.sender, refundAmount);
        }

        // Claim rewards from the RaisyChef
        IRaisyChef raisyChef = IRaisyChef(addressRegistry.raisyChef());
        raisyChef.claimRewards(msg.sender, _campaignId);

        emit WithdrawFunds(_campaignId, msg.sender, refundAmount, _payToken);
    }

    /**
     * @notice Update platformFee
     * @dev Only admin
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;

        emit PlatformFeeUpdated(_platformFee);
    }

    ///
    /// INTERNAL & VIEW FUNCTIONS
    ///

    // function _sendPayToken(address _to, uint256 _amount, address _payToken) internal {

    // }

    /// @notice Sees if the Token address is valid
    /// @param _payToken Address of the token
    function _validPayToken(address _payToken) internal view {
        require(
            _payToken == address(0) ||
                (addressRegistry.tokenRegistry() != address(0) &&
                    IRaisyTokenRegistry(addressRegistry.tokenRegistry())
                        .enabled(_payToken)),
            "invalid pay token"
        );
    }

    /**
     @notice Method for getting price for pay token
     @param _payToken Address of the token
     */
    function getPrice(address _payToken) public view returns (int256, uint8) {
        int256 unitPrice;
        uint8 decimals;
        IRaisyPriceFeed priceFeed = IRaisyPriceFeed(
            addressRegistry.priceFeed()
        );

        if (_payToken == address(0)) {
            (unitPrice, decimals) = priceFeed.getPrice(priceFeed.wMATIC());
        } else {
            (unitPrice, decimals) = priceFeed.getPrice(_payToken);
        }
        if (decimals < 18) {
            unitPrice = unitPrice * (int256(10)**(18 - decimals));
        } else {
            unitPrice = unitPrice / (int256(10)**(decimals - 18));
        }

        return (unitPrice, 18);
    }

    /// @notice Returns the amount Donated by an address for a given token and campaign.
    /// @param _donor Address of the donor
    /// @param _campaignId Id of the campaign
    /// @param _payToken Address of the token
    function getAmountDonated(
        address _donor,
        uint256 _campaignId,
        address _payToken
    ) external view returns (uint256) {
        return userDonations[_donor][_campaignId].amountPerToken[_payToken];
    }
}