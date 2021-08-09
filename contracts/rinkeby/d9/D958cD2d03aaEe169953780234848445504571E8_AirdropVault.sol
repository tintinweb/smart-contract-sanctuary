//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./vaults/WhitelistVault.sol";

contract AirdropVault is WhitelistVault {
    constructor(address _tosAddress, uint256 _maxInputOnce)
        WhitelistVault("Airdrop", _tosAddress, _maxInputOnce)
    {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ClaimVaultLib.sol";
import "./BaseVault.sol";
import "./VaultWhitelistStorage.sol";

//import "hardhat/console.sol";

contract WhitelistVault is BaseVault, VaultWhitelistStorage {
    using SafeERC20 for IERC20;

    ///@dev constructor
    ///@param _name Vault's name
    ///@param _tos Allocated tos address
    constructor(
        string memory _name,
        address _tos,
        uint256 _inputMaxOnce
    ) {
        name = _name;
        tos = _tos;
        maxInputOnceTime = _inputMaxOnce;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _totalTgeCount   total tge count
    ///@param _startTime start time
    ///@param _periodTimesPerClaim period time per claim
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _totalTgeCount,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    ) external onlyOwner {

        initializeBase(
            _totalAllocatedAmount,
            _totalTgeCount,
            _totalTgeCount,
            _startTime,
            _periodTimesPerClaim
        );

    }

    ///@dev allocate amount for first round (TGE)
    ///@param amount total claimable amount
    function allocateAmountTGE(uint256 amount)
        external
        onlyOwner
        nonZero(amount)
        validTgeRound(1)
    {
        require(
            totalTgeAmount + amount <= totalAllocatedAmount,
            "WhitelistVault: exceed total allocated amount"
        );
        uint256 round = 1;
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.allocated, "WhitelistVault: already allocated");
        tgeinfo.allocated = true;
        tgeinfo.allocatedAmount = amount;
        totalTgeAmount += amount;
        lastClaimedRound = round;

        if(totalTgeCount > 1 )  allocatedAmountForRound =  (totalAllocatedAmount - amount) / (totalTgeCount - 1);

        emit AllocatedAmount(round, amount);
    }

    ///@dev allocate amount for each round (except TGE)
    ///@param round  it is the period unit can claim once
    function allocateAmountRound(uint256 round)
        internal
        nonZero(lastClaimedRound)
        nonZero(allocatedAmountForRound)
    {
        require(
            round > 1 && round <= totalTgeCount ,
            "WhitelistVault: no available round"
        );

        uint256 calcRound = (block.timestamp - startTime) / periodTimesPerClaim;

        /// It can be set only during each round.
        require(round == calcRound+1, "WhitelistVault: no current round period");


        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.allocated, "WhitelistVault: already allocated");

        uint256 amount = (round - lastClaimedRound) * allocatedAmountForRound;
        tgeinfo.allocated = true;
        tgeinfo.allocatedAmount = amount ;
        totalTgeAmount += amount;
        lastClaimedRound = round;

        emit AllocatedAmount(round, amount);
    }

    ///@dev start round, Calculate how much the whitelisted people in the round can claim.
    function startRound()
        external
        onlyOwner
        nonZero(totalTgeCount)
    {
        uint256 round = currentRound();
        require(round > 0 && round <= totalTgeCount, "WhitelistVault: non-valid round");

        if(round > 1) allocateAmountRound(round);

        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(
            tgeinfo.allocated && tgeinfo.allocatedAmount > 0,
            "WhitelistVault: no allocated"
        );
        require(!tgeinfo.started, "WhitelistVault: already started");
        require(tgeinfo.whitelist.length > 0, "WhitelistVault: no whitelist");

        tgeinfo.started = true;
        tgeinfo.amount = tgeinfo.allocatedAmount / tgeinfo.whitelist.length;

        emit StartedRound(round);
    }

    ///@dev next claimable start time
    function startRoundTime(uint256 round)
        external
        view
        returns (uint256 start)
    {
        if (round > 0 && round <= totalTgeCount)
            start = startTime + (periodTimesPerClaim * (round - 1));
    }

    ///@dev number of unclaimed
    function unclaimedInfos(address _user)
        public
        view
        returns (uint256 count, uint256 amount)
    {
        count = 0;
        amount = 0;
        if (block.timestamp > startTime) {
            uint256 curRound = currentRound();
            for (uint256 i = 1; i <= curRound; i++) {
                if (curRound >= i) {
                    ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                    if (tgeinfo.started &&
                        tgeinfo.claimedTime[_user].joined &&
                        tgeinfo.claimedTime[_user].claimedTime == 0)
                    {
                            count++;
                            amount += tgeinfo.amount;
                    }
                }
            }
        }
    }

    ///@dev number of unclaimed
    function unclaimedInfosDetails(address _user)
        external
        view
        returns (uint256[] memory _rounds, uint256[] memory _amounts)
    {

        (uint256 size,) = unclaimedInfos(_user);
        uint256[] memory counts = new uint256[](size);
        uint256[] memory amounts = new uint256[](size);

        if(size > 0){
            uint256 k = 0;
            if (block.timestamp > startTime) {
                uint256 curRound = currentRound();
                for (uint256 i = 1; i <= curRound; i++) {
                    if (curRound >= i) {
                        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                        if (tgeinfo.started &&
                            tgeinfo.claimedTime[_user].joined &&
                            tgeinfo.claimedTime[_user].claimedTime == 0
                        ) {
                            counts[k] = i;
                            amounts[k] = tgeinfo.amount;
                            k++;
                        }
                    }
                }
            }
        }
        return (counts, amounts);
    }


    ///@dev claim
    function claim() external {

        uint256 amount = 0;
        require(block.timestamp > startTime, "WhitelistVault: not started yet");

        uint256 curRound = currentRound();
        for (uint256 i = 1; i <= curRound; i++) {
            if (curRound >= i) {
                ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[i];
                if (tgeinfo.started &&
                    tgeinfo.claimedTime[msg.sender].joined &&
                    tgeinfo.claimedTime[msg.sender].claimedTime == 0
                ) {
                    tgeinfo.claimedTime[msg.sender].claimedTime = block.timestamp;
                    tgeinfo.claimedCount++;
                    amount += tgeinfo.amount;
                }
            }
        }

        require(amount > 0, "WhitelistVault: no claimable amount");
        totalClaimedAmount += amount;

        userClaimedAmount[msg.sender] += amount;

        require(
            IERC20(tos).transfer(msg.sender, amount),
            "WhitelistVault: transfer fail"
        );

        emit Claimed(msg.sender, amount, totalClaimedAmount);
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title Function for getting the current chain ID
library ClaimVaultLib {
    struct ClaimedInfo {
        bool joined;
        uint256 claimedTime;
    }

    struct TgeInfo {
        bool allocated;
        bool started;
        uint256 allocatedAmount;
        uint256 claimedCount;
        uint256 amount;
        address[] whitelist;
        mapping(address => ClaimedInfo) claimedTime;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/ClaimVaultLib.sol";

import "../common/AccessibleCommon.sol";
import "./BaseVaultStorage.sol";
import "./VaultEvent.sol";

contract BaseVault is BaseVaultStorage, AccessibleCommon, VaultEvent {
    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount
    ///@param _totalTgeCount   total tge count
    ///@param _startTime start time
    ///@param _periodTimesPerClaim period time per claim
    function initializeBase(
        uint256 _totalAllocatedAmount,
        uint256 _totalClaims,
        uint256 _totalTgeCount,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    )
        public
        onlyOwner
        nonZero(_totalAllocatedAmount)
        nonZero(_totalClaims)
        nonZero(_startTime)
        nonZero(_periodTimesPerClaim)
    {
        require(
            IERC20(tos).balanceOf(address(this)) >= _totalAllocatedAmount,
            "BaseVault: balanceOf is insuffient"
        );

        require(totalAllocatedAmount == 0, "BaseVault: already initialized");
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaims = _totalClaims;
        totalTgeCount = _totalTgeCount;
        startTime = _startTime;
        periodTimesPerClaim = _periodTimesPerClaim;
        endTime = _startTime + (_periodTimesPerClaim * _totalClaims);
    }

    receive() external payable {
        revert("cannot receive Ether");
    }

    ///@dev set max input at once time of whitelist
    ///@param _maxInputOnceTime  max input at once time
    function setMaxInputOnceTimeWhitelist(uint256 _maxInputOnceTime)
        external
        onlyOwner
        nonZero(_maxInputOnceTime)
        nonSame(maxInputOnceTime, _maxInputOnceTime)
    {
        maxInputOnceTime = _maxInputOnceTime;
    }

    ///@dev Register the white list for the round.
    ///@param round  it is the period unit can claim once
    ///@param users people who can claim in that round
    function addWhitelist(uint256 round, address[] calldata users)
        external
        onlyOwner
        nonZero(round)
        validTgeRound(round)
        validMaxInputOnceTime(users.length)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        require(!tgeinfo.started, "BaseVault: already started");

        for (uint256 i = 0; i < users.length; i++) {
            if (
                users[i] != address(0) && !tgeinfo.claimedTime[users[i]].joined
            ) {
                tgeinfo.claimedTime[users[i]].joined = true;
                tgeinfo.whitelist.push(users[i]);
            }
        }

        emit AddedWhitelist(round, users);
    }

    function currentRound() public view returns (uint256 round) {
        if (block.timestamp < startTime) {
            round = 0;
        } else {
            round = (block.timestamp - startTime) / periodTimesPerClaim;
            round++;
        }
    }

    ///@dev Amount that can be withdrawn by the owner
    function availableWithdrawAmount() public view returns (uint256 amount) {
        uint256 balance = IERC20(tos).balanceOf(address(this));
        uint256 remainSendAmount = totalAllocatedAmount - totalClaimedAmount;
        require(balance >= remainSendAmount, "BaseVault: insufficent");
        amount = balance - remainSendAmount;
    }

    ///@dev withdraw to whom
    ///@param to to address to send
    function withdraw(address to) external onlyOwner nonZeroAddress(to) {
        uint256 amount = availableWithdrawAmount();
        require(amount > 0, "BaseVault: no withdrawable amount");
        require(
            IERC20(tos).transfer(to, amount),
            "BaseVault: transfer fail"
        );

        emit Withdrawal(msg.sender, amount);
    }

    ///@dev get Tge infos
    ///@param round  it is the period unit can claim once
    ///@return allocated whether allocated
    ///@return started whether started
    ///@return allocatedAmount allocated amount
    ///@return claimedCount claimed  count
    ///@return amount the claimeable amount by person in TGE period
    ///@return whitelist who can claim in TGE period
    function getTgeInfos(uint256 round)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (
            bool allocated,
            bool started,
            uint256 allocatedAmount,
            uint256 claimedCount,
            uint256 amount,
            address[] memory whitelist
        )
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];

        return (
            tgeinfo.allocated,
            tgeinfo.started,
            tgeinfo.allocatedAmount,
            tgeinfo.claimedCount,
            tgeinfo.amount,
            tgeinfo.whitelist
        );
    }

    ///@dev get the claim info of whitelist's person
    ///@param round  it is the period unit can claim once
    ///@param user person in whitelist
    ///@return joined whether joined
    ///@return claimedTime the claimed time
    function getWhitelistInfo(uint256 round, address user)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (bool joined, uint256 claimedTime)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        if (tgeinfo.claimedTime[user].joined)
            return (
                tgeinfo.claimedTime[user].joined,
                tgeinfo.claimedTime[user].claimedTime
            );
    }

    ///@dev get the total count of whitelist in round
    ///@param round  it is the period unit can claim once
    ///@return total the total count of whitelist in round
    function totalWhitelist(uint256 round)
        external
        view
        nonZero(round)
        validTgeRound(round)
        returns (uint256 total)
    {
        ClaimVaultLib.TgeInfo storage tgeinfo = tgeInfos[round];
        total = tgeinfo.whitelist.length;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VaultWhitelistStorage {

    uint256 public allocatedAmountForRound;
    uint256 public lastClaimedRound;
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../libraries/ClaimVaultLib.sol";

contract BaseVaultStorage {
    uint256 public maxInputOnceTime;
    ///
    string public name;
    ///
    address public tos;

    uint256 public totalAllocatedAmount;
    uint256 public totalClaimedAmount;
    // uint256 public totalClaims;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public periodTimesPerClaim;

    uint256 public totalClaims;
    uint256 public totalTgeCount;
    uint256 public totalTgeAmount;

    /// round => TgeInfo
    mapping(uint256 => ClaimVaultLib.TgeInfo) public tgeInfos;

    mapping(address => uint256) public userClaimedAmount;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "BaseVaultStorage: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "BaseVaultStorage: zero value");
        _;
    }

    modifier nonSame(uint256 _value1, uint256 _value2) {
        require(_value1 != _value2, "BaseVault: same value");
        _;
    }

    modifier nonSameAddress(address _value1, address _value2) {
        require(_value1 != _value2, "BaseVault: same address");
        _;
    }

    modifier validTgeRound(uint256 _round) {
        require(_round <= totalTgeCount, "BaseVault: exceed available round");
        _;
    }

    modifier validMaxInputOnceTime(uint256 _length) {
        require(
            _length > 0 && _length <= maxInputOnceTime,
            "BaseVault: check input count at once time"
        );
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VaultEvent {
    /// @dev event on set claimer
    /// @param newClaimer new claimer address
    event SetNewClaimer(address newClaimer);

    /// @dev event on allocate amount
    ///@param round  it is the period unit can claim once
    ///@param amount total claimable amount
    event AllocatedAmount(uint256 round, uint256 amount);

    /// @dev event on add whitelist
    ///@param round  it is the period unit can claim once
    ///@param users people who can claim in that round
    event AddedWhitelist(uint256 round, address[] users);

    /// @dev event on start round
    ///@param round  it is the period unit can claim once
    event StartedRound(uint256 round);

    /// @dev event on start
    event Started();

    /// @dev event on claim
    ///@param caller  claimer
    ///@param amount  the claimed amount of caller
    ///@param totalClaimedAmount  total claimed amount
    event Claimed(
        address indexed caller,
        uint256 amount,
        uint256 totalClaimedAmount
    );

    /// @dev event on withdraw
    ///@param caller  owner
    ///@param amount  the withdrawable amount of owner
    event Withdrawal(address indexed caller, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165 {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}