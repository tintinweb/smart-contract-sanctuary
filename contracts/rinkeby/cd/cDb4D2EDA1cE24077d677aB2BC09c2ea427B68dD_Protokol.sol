// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IProtokol.sol";

contract Protokol is Ownable, IProtokol {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Address for address;

    // projectId tracker using lib
    Counters.Counter private _projectIdTracker;

    // campaignId tracker using lib
    Counters.Counter private _campaignIdTracker;

    // kolId tracker using lib
    Counters.Counter private _kolIdTracker;

    IUSDT public override usdt;

    // unique Ids -> structs
    mapping(uint256 => Project) public override projects;
    mapping(uint256 => KOL) public override kols;
    mapping(uint256 => Campaign) public override campaigns;
    mapping(uint256 => CampaignKOL) public override campaignKols;

    //   projectOwner -> campaigns
    mapping(address => uint256) public override campaignCounts;

    constructor(address _usdtAddr) {
        usdt = IUSDT(_usdtAddr);
    }

    function isProjectOwner(uint256 _projectId) public view override returns (bool) {
        return projects[_projectId].projectOwner == _msgSender();
    }

    function isKOL(uint256 _kolId) public view override returns (bool) {
        return kols[_kolId].walletAddr == _msgSender();
    }

    function isCampaignActive(uint256 _campaignId) public view override returns (bool) {
        return campaigns[_campaignId].active;
    }

    function isCampaignKOL(uint256 _campaignId) public view override returns (bool) {
        return campaignKols[_campaignId].walletAddr == _msgSender();
    }

    function registerProject(Project memory _project) public override {
        require(_project.projectOwner == _msgSender(), "caller must be project owner");
        require(_project.projectAddr.isContract(), "project address not valid");
        require(_project.tokenAddr.isContract(), "token address not valid");
        require(_project.totalInvestmentRaised == 0, "totalInvestmentRaised not valid");
        require(_project.maxTokenSupply != 0, "maxTokenSupply not valid");
        require(_project.initialCirculatingSupply != 0, "initialCirculatingSupply not valid");
        require(_project.preSaleTokenPrice != 0, "preSaleTokenPrice not valid");
        require(_project.preSaleTokenAmount != 0, "preSaleTokenAmount not valid");
        require(_project.tgeDistribution != 0, "tgeDistribution not valid");

        // incrementing projectId first
        _projectIdTracker.increment();
        uint256 _projectId = _projectIdTracker.current();

        projects[_projectId] = _project;

        emit ProjectCreated(_projectId, _project);
    }

    function registerKOL(KOL memory _kol) public override {
        require(_kol.walletAddr == _msgSender(), "caller must be kol");

        // incrementing kolId first
        _kolIdTracker.increment();
        uint256 _kolId = _kolIdTracker.current();

        kols[_kolId] = _kol;

        emit KOLCreated(_kolId, _kol);
    }

    function registerCampaign(
        uint256 _projectId,
        uint256 _dateRange,
        uint256 _followersNeeded,
        uint256 _preSaleTokenPrice,
        uint256 _pricePerFollower,
        uint256 _budget
    ) public override {
        require(isProjectOwner(_projectId), "caller must be project owner");
        require(_dateRange != 0, "invalid endDate");
        require(_preSaleTokenPrice != 0, "invalid preSaleTokenPrice");
        require(_pricePerFollower != 0, "invalid pricePerFollower");
        require(_budget != 0, "invalid budget");

        // incrementing campaignId first
        _campaignIdTracker.increment();
        uint256 _campaignId = _campaignIdTracker.current();

        Campaign memory _campaign = Campaign({
            projectId: _projectId,
            endDate: _dateRange,
            followersNeeded: _followersNeeded,
            followersDone: 0,
            preSaleTokenPrice: _preSaleTokenPrice,
            pricePerFollower: _pricePerFollower,
            budget: _budget,
            active: true,
            campaignKolCount: 0
        });
        campaigns[_campaignId] = _campaign;

        // transfer the budget in smart contract
        IERC20(projects[_projectId].tokenAddr).safeTransferFrom(_msgSender(), address(this), _budget);

        emit CampaignCreated(_campaignId, _campaign);
    }

    // kol can invest in campaign
    function investInCampaign(
        uint256 _kolId,
        uint256 _campaignId,
        uint256 _followerCount,
        uint256 _amountToInvest
    ) public override {
        Campaign memory _campaign = campaigns[_campaignId];

        require(isCampaignActive(_campaignId), "campaign is not active");
        require(!isProjectOwner(_campaignId), "caller must not be project owner");
        require(isKOL(_kolId), "caller must a registered kol");
        require(!isCampaignKOL(_campaignId), "same campaign kol cannot apply twice");
        require(_amountToInvest != 0, "invalid amountToInvest");
        require(block.timestamp <= _campaign.endDate, "campaign ended");

        uint256 _followersNeeded = _campaign.followersNeeded;
        uint256 _followersDone = _campaign.followersDone;
        uint256 _followerNeedLeft = _followersNeeded - _followersDone;

        require(_followerCount <= _followerNeedLeft, "campaign follower count full");

        // token reward to be givent to kol
        uint256 _tokenReward = (_campaign.pricePerFollower * _followerCount) * _campaign.budget;

        // update campaign count
        campaigns[_campaignId].campaignKolCount = campaigns[_campaignId].campaignKolCount + 1;
        CampaignKOL memory _campaignKOL = CampaignKOL({
            walletAddr: _msgSender(),
            invested: _amountToInvest,
            followers: _followerCount,
            reward: _tokenReward
        });
        campaignKols[_campaignId] = _campaignKOL;

        // update campaign follower done status
        campaigns[_campaignId].followersDone = campaigns[_campaignId].followersDone + _followerCount;

        // update project investment status
        projects[_campaign.projectId].totalInvestmentRaised =
            projects[_campaign.projectId].totalInvestmentRaised +
            _amountToInvest;

        // transfer usdt to this contract
        usdt.transferFrom(_msgSender(), address(this), _amountToInvest);

        emit InvestedInCampaign(_campaignId, _campaignKOL);
    }

    function releaseFundsToInvestors(uint256 _campaignId, uint256[] memory _campaignKols) public override onlyOwner {
        uint256 _projectId = campaigns[_campaignId].projectId;

        require(isProjectOwner(_projectId), "caller must be project owner");
        require(isCampaignActive(_campaignId), "campaign is not active");
        require(_campaignKols.length != 0, "campaign kols not valid");

        for (uint256 i = 0; i < _campaignKols.length; i++) {
            require(campaignKols[i].walletAddr != address(0), "campaignKols are not valid");
        }

        Project memory _project = projects[_projectId];

        // set campaign to inactive
        campaigns[_campaignId].active = false;

        for (uint256 i = 0; i < _campaignKols.length; i++) {
            CampaignKOL memory _campaignkols = campaignKols[i];

            // send project tokens to kol from this smart contract
            IERC20(_project.tokenAddr).safeTransfer(_campaignkols.walletAddr, _campaignkols.reward);

            // send usdt to project owner from this smart contract
            usdt.transfer(_project.projectOwner, _campaignkols.invested);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IUSDT.sol";

interface IProtokol {
    struct Project {
        address projectOwner;
        address projectAddr;
        address tokenAddr;
        uint256 totalInvestmentRaised;
        uint256 maxTokenSupply;
        uint256 initialCirculatingSupply;
        uint256 preSaleTokenPrice;
        uint256 preSaleTokenAmount;
        uint256 tgeDistribution;
    }

    struct KOL {
        address walletAddr;
        string socialHandle;
    }

    struct Campaign {
        uint256 projectId;
        uint256 endDate;
        uint256 followersNeeded;
        uint256 followersDone;
        uint256 preSaleTokenPrice;
        uint256 pricePerFollower;
        uint256 budget;
        uint256 campaignKolCount;
        bool active;
    }

    struct CampaignKOL {
        address walletAddr;
        uint256 invested;
        uint256 followers;
        uint256 reward;
    }

    event ProjectCreated(uint256 projectId, Project);
    event KOLCreated(uint256 kolId, KOL);
    event CampaignCreated(uint256 campaignId, Campaign);
    event InvestedInCampaign(uint256 campaignId, CampaignKOL);

    function usdt() external returns (IUSDT);

    // projectId -> Project struct data
    function projects(uint256 _projectId)
        external
        returns (
            address projectOwner,
            address projectAddr,
            address tokenAddr,
            uint256 totalInvestmentRaised,
            uint256 maxTokenSupply,
            uint256 initialCirculatingSupply,
            uint256 preSaleTokenPrice,
            uint256 preSaleTokenAmount,
            uint256 tgeDistribution
        );

    // kolId -> KOL struct data
    function kols(uint256 _kolId) external returns (address walletAddr, string calldata socialHandle);

    // campaignId -> Campaign struct data
    function campaigns(uint256 _campaignId)
        external
        returns (
            uint256 projectId,
            uint256 endDate,
            uint256 followersNeeded,
            uint256 followersDone,
            uint256 preSaleTokenPrice,
            uint256 pricePerFollower,
            uint256 budget,
            uint256 campaignKolCount,
            bool active
        );

    // campaignId -> CampaignKOL struct data
    function campaignKols(uint256 _campaignKolId)
        external
        returns (
            address walletAddr,
            uint256 invested,
            uint256 followers,
            uint256 reward
        );

    // project owner -> number of campaigns
    function campaignCounts(address _projectOwner) external returns (uint256);

    function isProjectOwner(uint256 _projectId) external view returns (bool);

    function isKOL(uint256 _kolId) external view returns (bool);

    function isCampaignActive(uint256 _campaignId) external view returns (bool);

    function isCampaignKOL(uint256 _campaignId) external view returns (bool);

    function registerProject(Project calldata _project) external;

    function registerKOL(KOL calldata _kol) external;

    function registerCampaign(
        uint256 _projectId,
        uint256 _dateRange,
        uint256 _followersNeeded,
        uint256 _preSaleTokenPrice,
        uint256 _pricePerFollower,
        uint256 _budget
    ) external;

    function investInCampaign(
        uint256 _kolId,
        uint256 _campaignId,
        uint256 _followerCount,
        uint256 _amountToInvest
    ) external;

    function releaseFundsToInvestors(uint256 _campaignId, uint256[] calldata _campaignKols) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUSDT {
    function transfer(address _to, uint256 _value) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
}

