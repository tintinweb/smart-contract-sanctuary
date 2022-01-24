// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/IDeal.sol";
import "../interfaces/IGMPD.sol";
import "../external/interfaces/IUniswapV2Pair.sol";
import "../staking/interfaces/IStakingPool.sol";

import "../utils/AdminableUpgradeable.sol";

contract TierCalculator is AdminableUpgradeable {

    using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_POOLS = 15;
    uint256 public constant MAX_LOCKERS = 15;

    address[] public lockers;
    address[] public pools;

    address public token;

    mapping(address => uint256) public userLockingStarts;

    mapping(address => bool) public lockingUpdaters; // Lockers and StakeMaster
    mapping(address => bool) public dealCreators; // Deal and Wallet Creators

    event AddPool(uint256 index, address pool);
    event UpdatePool(uint256 index, address prevPool, address newPool);
    event RemovePool(uint256 index, address prevPool);

    event AddLocker(uint256 index, address locker);
    event UpdateLocker(uint256 index, address prevLocker, address newLocker);
    event RemoveLocker(uint256 index, address prevLocker);

    event SetLockingStarts(address user, uint256 lockingStart);

    event SetLockingUpdater(address lockingUpdater, bool permission);
    event SetDealCreator(address dealCreator, bool permission);

    modifier onlyTokenOrTokenLpPool(address _pool) {
        address stakingToken = IStakingPool(_pool).stakingToken();
        address rewardToken = IStakingPool(_pool).rewardToken();
        address targetToken = token; // gas optimization

        // stakingToken or rewardToken is GMPD or GMPD UNI-V2 LP
        require(
            stakingToken == targetToken ||
            rewardToken == targetToken ||
            isTokenUniLp(IUniswapV2Pair(stakingToken)) ||
            isTokenUniLp(IUniswapV2Pair(rewardToken)),
            "Only pool with GMPD or GMPD UNI-V2 LP"
        );
        _;
    }

    modifier onlyLocker(address _locker) {
        require(isLocker(ILocker(_locker)), "Only Locker is required");
        _;
    }

    modifier onlyUpdaters {
        require(lockingUpdaters[msg.sender], "Only lockingUpdaters can call");
        _;
    }

    modifier onlyCreators {
        require(dealCreators[msg.sender], "Only dealCreators can call");
        _;
    }

    function __TierCalculator_init(address _token) public initializer {
        __Adminable_init();
        token = _token;
    }

    function getTierIndex(address _user, address _deal) external view returns (bool success, uint256 tierIndex) {
        uint256 gmpdBalance = getLockedTokens(_user);

        // calculate user's tierIndex
        uint256 tiersLength = IDeal(_deal).getTiersLength();
        (bool successCheck, uint256 maxNftTier) = getMaxNftTier(_user);
        for (uint256 i = 0; i < tiersLength; i++) {
            (uint256 gmpdAmount, , ,) = IDeal(_deal).allTiers(i);
            (uint256 curGmpdAmount, , ,) = IDeal(_deal).allTiers(tierIndex);
            if (
                gmpdBalance >= gmpdAmount &&
                // check that next level is higher than current
                gmpdAmount >= curGmpdAmount
            ) {
                tierIndex = i;
                success = true;
            }
        }
        if (success) {
            tierIndex = maxNftTier <= tierIndex ? maxNftTier : 0;
            if (tierIndex != maxNftTier || !successCheck) {
                success = false;
            }
        }
    }

    function getLockedTokens(address _user) public view returns (uint256 amount) {
        address targetToken = token; // gas optimization

        // calculate user's GMPD on staking pools (max MAX_POOLS length)
        uint256 poolsLength = pools.length;
        for (uint256 i = 0; i < poolsLength; i++) {
            IStakingPool stakingPool = IStakingPool(pools[i]);

            // calculate user's staked GMPD
            (uint256 amountPool, ,) = stakingPool.userInfo(_user);
            if (amountPool > 0) {
                address stakingToken = stakingPool.stakingToken();
                amount = amount.add(_calculateTokens(targetToken, stakingToken, amountPool));
            }

            // calculate user's pending GMPD reward
            uint256 pendingReward = stakingPool.pendingReward(_user);
            if (pendingReward > 0) {
                address rewardToken = stakingPool.rewardToken();
                amount = amount.add(_calculateTokens(targetToken, rewardToken, pendingReward));
            }
        }

        // add user's locked GMPD on locker to staked GMPD (max MAX_POOLS length)
        uint256 lockersLength = lockers.length;
        for (uint256 i = 0; i < lockersLength; i++) {
            amount = amount.add(ILocker(lockers[i]).getLockedGMPD(_user));
        }
    }

    function getMaxNftTier(address _user) public view returns (bool success, uint256 nftTier) {
        nftTier = 0;
        for (uint256 i = 0; i < lockers.length; i++) {
            uint256 tokenId = ILocker(lockers[i]).userNFT(_user);
            uint256 tier = IGMPD(ILocker(lockers[i]).collection()).nftTypes(tokenId);
            if (tokenId != 0) {
                success = true;
            }
            if (tier > nftTier) {
                nftTier = tier;
            }
        }
    }

    function isTokenUniLp(IUniswapV2Pair _lp) public view returns (bool) {
        // try UNI-V2 LP token0
        address token0;
        try _lp.token0() returns (address result) {
            token0 = result;
        } catch {
            return false;
        }

        // try UNI-V2 LP token1
        address token1;
        try _lp.token1() returns (address result) {
            token1 = result;
        } catch {
            return false;
        }

        address targetToken = token; // gas optimization
        return token0 == targetToken || token1 == targetToken;
    }

    function isLocker(ILocker _locker) public view returns (bool) {
        try _locker.getLockedGMPD(msg.sender) {
            return true;
        } catch {
            return false;
        }
    }

    function resetStartOnce(address _user) external onlyUpdaters {
        if (userLockingStarts[_user] == 0) {
            userLockingStarts[_user] = now;
        }
    }

    function resetStart(address _user) external onlyCreators {
        userLockingStarts[_user] = now;
    }

    // ** OWNER OR ADMIN logic **

    // Set lockingStart by owner or admin
    function setLockingStart(address _user, uint256 _lockingStart) external onlyOwnerOrAdmin {
        require(_lockingStart <= block.timestamp, "setLockingStart: invalid locking start value");

        userLockingStarts[_user] = _lockingStart;

        emit SetLockingStarts(_user, _lockingStart);
    }

    // ** POOL PART **

    function addPool(address _pool) external onlyOwnerOrAdmin onlyTokenOrTokenLpPool(_pool) {
        require(pools.length < MAX_POOLS, "addPool: pools size exceed");

        pools.push(_pool);

        emit AddPool(pools.length - 1, _pool); // safe sub
    }

    function updatePool(uint256 _index, address _pool) external onlyOwnerOrAdmin onlyTokenOrTokenLpPool(_pool) {
        require(_index < pools.length, "updatePool: index exceeds pools");

        address prevPool = pools[_index];
        pools[_index] = _pool;

        emit UpdatePool(_index, prevPool, _pool);
    }

    function removePool(uint256 _index) external onlyOwnerOrAdmin {
        require(_index < pools.length, "removePool: index exceeds pools");

        address prevPool = pools[_index];

        // update current index and remove last element
        pools[_index] = pools[pools.length - 1]; // safe sub
        pools.pop();

        emit RemovePool(_index, prevPool);
    }

    // ** LOCKER PART **

    function addLocker(address _locker) external onlyOwnerOrAdmin onlyLocker(_locker) {
        require(lockers.length < MAX_LOCKERS, "addLocker: lockers size exceed");

        lockers.push(_locker);

        emit AddLocker(lockers.length - 1, _locker); // safe sub
    }

    function updateLocker(uint256 _index, address _locker) external onlyOwnerOrAdmin onlyLocker(_locker) {
        require(_index < lockers.length, "updateLocker: index exceeds lockers");

        address prevLocker = lockers[_index];
        lockers[_index] = _locker;

        emit UpdateLocker(_index, prevLocker, _locker);
    }

    function removeLocker(uint256 _index) external onlyOwnerOrAdmin {
        require(_index < lockers.length, "removeLocker: index exceeds lockers");

        address prevLocker = lockers[_index];

        // update current index and remove last element
        lockers[_index] = lockers[lockers.length - 1]; // safe sub
        lockers.pop();

        emit RemoveLocker(_index, prevLocker);
    }

    // ** LOCKING UPDATER PART **

    function setLockingUpdater(address _lockingUpdater, bool _permission) external onlyOwnerOrAdmin {
        lockingUpdaters[_lockingUpdater] = _permission;

        emit SetLockingUpdater(_lockingUpdater, _permission);
    }

    // ** DEAL CREATOR PART **

    function setDealCreator(address _dealCreator, bool _permission) external onlyOwnerOrAdmin {
        dealCreators[_dealCreator] = _permission;

        emit SetDealCreator(_dealCreator, _permission);
    }

    // ** INTERNAL functions **

    // calculate GMPD amount
    function _calculateTokens(
        address targetToken,
        address curToken,
        uint256 amount
    ) internal view returns (uint256) {
        // curToken is GMPD
        if (curToken == targetToken) {
            return amount;
        }
        // curToken is GMPD UNI-V2 LP
        else if (isTokenUniLp(IUniswapV2Pair(curToken))) {
            // calculate GMPD amount on UNI-V2 LP
            uint256 lpTotalSupply = IERC20Upgradeable(curToken).totalSupply();
            return (lpTotalSupply > 0)
                ? IERC20Upgradeable(targetToken).balanceOf(curToken)
                    .mul(amount)
                    .div(lpTotalSupply)
                : 0;
        }

        return 0;
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract AdminableUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public isAdmin;

    event SetAdminPermission(address indexed admin, bool permission);

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Only admin can call");
        _;
    }

    modifier onlyOwnerOrAdmin {
        require((owner() == msg.sender) || isAdmin[msg.sender], "Only owner or admin can call");
        _;
    }

    function __Adminable_init() internal initializer {
        __Ownable_init();
    }

    function setAdminPermission(address _user, bool _permission) external onlyOwner {
        isAdmin[_user] = _permission;

        emit SetAdminPermission(_user, _permission);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStakingPool {

    // ** VIEW **

    function getUserInfo(address user) external view returns (uint256, uint256);

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256);

    function hasWhitelisting() external view returns (bool);

    // only for active whitelist
    function isWhitelisted(address _address) external view returns (bool);

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function userInfo(address _user) external view returns (uint256, uint256, bool);

    // ** USER logic **

    function stakeTokens(uint256 _amountToStake) external;

    // Leave the pool. Claim back your tokens.
    // Unlocks the staked + gained tokens and burns pool shares
    function withdrawStake(uint256 _amount) external;

    function reinvestTokens() external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external;

    // ** OWNER logic **

    function withdrawPoolRemainder() external;

    function extendDuration(uint256 _addTokenAmount) external;

    function setHasWhitelisting(bool value) external;

    // add to whitelist
    function add(address[] memory _addresses) external;

    // remove from whitelist
    function remove(address[] memory _addresses) external;

    function setFeeTo(address _feeTo) external;

    function setAdminPermission(address _user, bool _permission) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IGMPD.sol";

interface ILocker {    
     
     function updatePenalty(uint256 _index, uint256 _duration, uint256 _penaltyBP) external;

     function getLockedGMPD(address _user) external view returns (uint256);

     function collection() external view returns (IGMPD);

     function userNFT(address _user) external view returns (uint256);

     /// @dev create the deposit.
     /// @param _amount Amount of deposit.
     function deposit(uint256 _amount) external;

     /// @dev Withdraw deposits
     /// @param _amount unlock amount
     function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

pragma solidity 0.6.12;

interface IGMPD is IERC721Upgradeable {
    function nftTypes(uint256 _tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDeal {

    function getTiersLength() external view returns (uint256);

    function allTiers(uint256 _index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function setAdminPermission(address _user, bool _permission) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}