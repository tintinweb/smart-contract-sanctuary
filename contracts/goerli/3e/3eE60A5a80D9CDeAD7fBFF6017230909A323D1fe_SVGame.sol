//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SVGameStakable.sol";

contract SVGame is Initializable, SVGameStakable {

    function initialize() external initializer {
        SVGameStakable.__SVGameStakable_init();
    }

    function addCustomers(
        uint256 _clubId,
        uint64 _numberOfCustomers)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    gameHasStarted
    gameHasNotEnded
    validClubId(_clubId)
    isClubOwner(_clubId)
    {
        uint8 _currentDay = getCurrentDay();

        _updateClubActionPoints(_clubId, _currentDay);

        uint64 _availableAP = _availableActionPoints(_clubId);

        require(_availableAP >= _numberOfCustomers, "Not enough AP");

        clubToMetadata[_clubId].customers += _numberOfCustomers;
        clubToMetadata[_clubId].actionPointsSpent += _numberOfCustomers;
    }

    function addThieves(
        uint256 _fromClubId,
        uint256 _toClubId,
        uint64 _numberOfThieves)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    gameHasStarted
    gameHasNotEnded
    validClubId(_fromClubId)
    validClubId(_toClubId)
    isClubOwner(_fromClubId)
    {
        require(_fromClubId != _toClubId, "Can't send thieves to self");
        uint8 _currentDay = getCurrentDay();

        _updateClubActionPoints(_fromClubId, _currentDay);

        uint64 _availableAP = _availableActionPoints(_fromClubId);

        require(_availableAP >= _numberOfThieves, "Not enough AP");

        clubToMetadata[_fromClubId].actionPointsSpent += _numberOfThieves;
        clubToMetadata[_toClubId].thieves += _numberOfThieves;
    }

    function claimRewardClub(
        uint256 _clubId)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    gameHasEnded
    validClubId(_clubId)
    isClubOwner(_clubId)
    {
        require(!clubToMetadata[_clubId].hasClaimedReward, "Already claimed reward");

        clubToMetadata[_clubId].hasClaimedReward = true;

        uint256 _rewardForClubTotal = (prizePool * rankToPercentOfPool[clubIdToFinishedRank[_clubId]]) / 100;

        uint256 _rewardForClubOwner = (_rewardForClubTotal * clubOwnerPercent) / 100;

        strip.transfer(msg.sender, _rewardForClubOwner);
    }

    function claimRewardStrippers(
        uint256[] calldata _tokenIds)
    external
    whenNotPaused
    onlyEOA
    nonZeroLength(_tokenIds)
    gameHasEnded
    contractsAreSet
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            _claimRewardStripper(_tokenIds[i]);
        }
    }

    function _claimRewardStripper(uint256 _tokenId) private {
        require(msg.sender == stripperToMetadata[_tokenId].owner, "Not owner");
        require(!stripperToMetadata[_tokenId].hasClaimedReward, "Already claimed reward");

        stripperToMetadata[_tokenId].hasClaimedReward = true;

        uint256 _clubId = stripperToMetadata[_tokenId].clubId;

        uint256 _rewardForClubTotal = (prizePool * rankToPercentOfPool[clubIdToFinishedRank[_clubId]]) / 100;

        uint256 _rewardForStrippers = (_rewardForClubTotal * (100 - clubOwnerPercent)) / 100;

        uint256 _rewardPerStripper = _rewardForStrippers / clubToMetadata[_clubId].strippers;

        strip.transfer(msg.sender, _rewardPerStripper);
    }

    function setClubOwnerPercent(uint8 _clubOwnerPercent) external onlyAdminOrOwner {
        require(_clubOwnerPercent <= 100, "Bad percent");
        clubOwnerPercent = _clubOwnerPercent;
    }

    function setRankToPercentOfPool(uint8[] calldata _percents) external onlyAdminOrOwner {
        require(_percents.length == getClubIds().length, "Bad number of percents");

        for(uint256 i = 0; i < _percents.length; i++) {
            rankToPercentOfPool[uint8(i + 1)] = _percents[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SVGameContracts.sol";

abstract contract SVGameStakable is Initializable, SVGameContracts {

    function __SVGameStakable_init() internal initializer {
        SVGameContracts.__SVGameContracts_init();
    }

    function startGame()
    external
    onlyAdminOrOwner
    {
        require(gameStartTime == 0, "Game already started");

        gameStartTime = block.timestamp;

        uint256[] memory _clubIds = getClubIds();
        for(uint256 i = 0; i < _clubIds.length; i++) {
            clubToMetadata[_clubIds[i]].dayCalculatedUpTo = 1;
        }
    }

    function endGame()
    external
    onlyAdminOrOwner
    gameHasStarted
    gameHasNotEnded
    {
        gameEndTime = block.timestamp;

        prizePool = strip.balanceOf(address(this));

        require(prizePool > 0, "No prize pool funded");

        _calculateRanks();
    }

    function _calculateRanks() private {
        uint256[] memory _clubIds = getClubIds();
        int128[] memory _scores = new int128[](_clubIds.length);

        for(uint256 i = 0; i < _clubIds.length; i++) {
            _scores[i] = _scoreForClubId(_clubIds[i]);
        }

        for(uint256 i = 0; i < _clubIds.length - 1; i++) {
            for(uint256 j = 0; j < _clubIds.length - i - 1; j++) {
                // Order descending. Rank 1 will be index 0.
                if(_scores[j] < _scores[j + 1]) {
                    int128 _tempScore = _scores[j];
                    _scores[j] = _scores[j + 1];
                    _scores[j + 1] = _tempScore;

                    uint256 _tempClubId = _clubIds[j];
                    _clubIds[j] = _clubIds[j + 1];
                    _clubIds[j + 1] = _tempClubId;
                }
            }
        }

        for(uint256 i = 0; i < _clubIds.length; i++) {
            clubIdToFinishedRank[_clubIds[i]] = uint8(i + 1);
        }
    }

    function stakeStrippers(
        uint256[] calldata _tokenIds,
        uint256 _clubId)
    external
    whenNotPaused
    onlyEOA
    nonZeroLength(_tokenIds)
    gameHasStarted
    canStake
    contractsAreSet
    validClubId(_clubId)
    {
        uint8 _currentDay = getCurrentDay();

        _updateClubActionPoints(_clubId, _currentDay);

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            _stakeStripper(_tokenIds[i], _clubId);
        }
    }

    function _stakeStripper(uint256 _tokenId, uint256 _clubId) private {

        clubToMetadata[_clubId].strippers++;
        stripperToMetadata[_tokenId] = StripperMetadata(_clubId, msg.sender, false);

        // Transfer to contract
        stripperVille.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function _updateClubActionPoints(uint256 _clubId, uint8 _currentDay) internal {
        uint8 _dayCalculatedUpTo = clubToMetadata[_clubId].dayCalculatedUpTo;
        // Everything is up to date.
        if(_dayCalculatedUpTo >= _currentDay) {
            return;
        }

        clubToMetadata[_clubId].actionPointsEarned +=
            (clubToMetadata[_clubId].strippers
                * (_currentDay - _dayCalculatedUpTo));

        clubToMetadata[_clubId].dayCalculatedUpTo = _currentDay;
    }

    function unstakeStrippers(
        uint256[] calldata _tokenIds)
    external
    whenNotPaused
    onlyEOA
    nonZeroLength(_tokenIds)
    gameHasEnded
    contractsAreSet
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == stripperToMetadata[_tokenIds[i]].owner, "Not owner");

            stripperVille.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    // Score can be negative
    function scoreForClubId(
        uint256 _clubId)
    external
    view
    validClubId(_clubId)
    returns(int128) {
        return _scoreForClubId(_clubId);
    }

    function _scoreForClubId(
        uint256 _clubId)
    private
    view
    returns(int128)
    {
        return int64(clubToMetadata[_clubId].customers) - int64(clubToMetadata[_clubId].thieves);
    }

    // Internal and only accurate after _updateClubActionPoints is called.
    function _availableActionPoints(uint256 _clubId) internal view returns(uint64) {
        return clubToMetadata[_clubId].actionPointsEarned - clubToMetadata[_clubId].actionPointsSpent;
    }

    // External method. Handles the case where the internal state hasn't been
    // updated.
    function availableActionPoints(uint256 _clubId)
    external
    view
    validClubId(_clubId)
    returns(uint64)
    {
        uint8 _currentDay = getCurrentDay();

        uint64 _availableAP = _availableActionPoints(_clubId);

        // Take into account any unchanged state.
        uint8 _dayCalculatedUpTo = clubToMetadata[_clubId].dayCalculatedUpTo;
        // Everything is up to date.
        if(_dayCalculatedUpTo < _currentDay) {
            _availableAP += (clubToMetadata[_clubId].strippers
                * (_currentDay - _dayCalculatedUpTo));
        }

        return _availableAP;
    }

    function isValidClubId(uint256 _clubId) public view returns(bool) {
        uint256 _clubCount = stripperVille.clubsCount();
        uint256 _initial = 1000000;
        for(uint i = 0; i < _clubCount; i++) {
            if(_clubId == i + _initial) {
                return true;
            }
        }
        return false;
    }

    function getCurrentDay() public view returns(uint8) {
        // Integer division rounds down. 10 seconds after the game start,
        // the division will round to 0 + 1 = day 1.
        return uint8((block.timestamp - gameStartTime) / (1 days)) + 1;
    }

    function getClubIds() public view contractsAreSet returns (uint[] memory) {
        uint[] memory _ids = new uint[](stripperVille.clubsCount());
        uint _initial = 1000000;
        for(uint i = 0; i < _ids.length; i++) {
            _ids[i] = i + _initial;
        }
        return _ids;
    }

    modifier validClubId(uint256 _clubId) {
        require(isValidClubId(_clubId), "Invalid club ID");

        _;
    }

    modifier gameHasStarted() {
        require(gameStartTime != 0, "Game not started");

        _;
    }

    modifier gameHasNotEnded() {
        require(gameEndTime == 0, "Game has ended");

        _;
    }

    modifier gameHasEnded() {
        require(gameEndTime != 0, "Game has not ended");

        _;
    }

    modifier canStake() {
        require(getCurrentDay() <= lastDayToStake, "Staking is done.");

        _;
    }

    modifier isClubOwner(uint256 _clubId) {
        require(stripperVille.ownerOf(_clubId) == msg.sender, "Do not own club");

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SVGameState.sol";

abstract contract SVGameContracts is Initializable, SVGameState {

    function __SVGameContracts_init() internal initializer {
        SVGameState.__SVGameState_init();
    }

    function setContracts(
        address _stripAddress,
        address _stripperVilleAddress)
    external
    onlyAdminOrOwner
    {
        strip = IStrip(_stripAddress);
        stripperVille = IStripperVille(_stripperVilleAddress);
    }

    modifier contractsAreSet() {
        require(address(strip) != address(0)
            && address(stripperVille) != address(0), "Contracts aren't set");

        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./ISVGame.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../external/IStrip.sol";
import "../external/IStripperVille.sol";

abstract contract SVGameState is Initializable, ISVGame, ERC721HolderUpgradeable, AdminableUpgradeable {

    IStrip public strip;
    IStripperVille public stripperVille;

    mapping(uint256 => ClubMetadata) public clubToMetadata;

    mapping(uint256 => StripperMetadata) public stripperToMetadata;

    uint256 public gameStartTime;
    uint256 public gameEndTime;

    uint8 public lastDayToStake;

    mapping(uint8 => uint8) public rankToPercentOfPool;
    mapping(uint256 => uint8) public clubIdToFinishedRank;

    uint256 public prizePool;

    uint8 public clubOwnerPercent;

    function __SVGameState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();

        lastDayToStake = 45;
        clubOwnerPercent = 10;

        rankToPercentOfPool[1] = 20;
        rankToPercentOfPool[2] = 15;
        rankToPercentOfPool[3] = 12;
        rankToPercentOfPool[4] = 11;
        rankToPercentOfPool[5] = 10;
        rankToPercentOfPool[6] = 9;
        rankToPercentOfPool[7] = 8;
        rankToPercentOfPool[8] = 6;
        rankToPercentOfPool[9] = 5;
        rankToPercentOfPool[10] = 4;
    }
}

struct ClubMetadata {
    uint64 customers;
    uint64 strippers;
    uint64 thieves;
    uint64 actionPointsEarned;
    uint64 actionPointsSpent;
    uint8 dayCalculatedUpTo;
    bool hasClaimedReward;
}

struct StripperMetadata {
    uint256 clubId;
    address owner;
    bool hasClaimedReward;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISVGame {

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStrip is IERC20Upgradeable {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IStripperVille is IERC721Upgradeable {

    function clubsCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}