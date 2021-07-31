// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/AutomatedExternalReflector.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract DynaAutoEthDistributorV1 is AutomatedExternalReflector {

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() payable {
        _owner = msg.sender;
        currentRound = 1;
        totalEthDeposits = address(this).balance;
        currentQueueIndex = 0;
        totalRewardsSent = 0;
        totalExcludedTokenHoldings = 0;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Routers (Mainnet and Ropsten)
        uniswapV2Router = _uniswapV2Router;
        maxGas = 500000;
        minGas = 75000;
        maxReflectionsPerRound = 100;
        timeBetweenRounds = 1 minutes;
        nextRoundStart = block.timestamp + 1 minutes;

        allowLowLevelCalls = false;
        reflectionsEnabled = true;

        _excludeFromReflections(address(_uniswapV2Router), true);
        _excludeFromReflections(address(this), true);
        _excludeFromReflections(deadAddress, true);

        totalCirculatingTokens = 1 * 10 ** 12 * 10 ** 18;
    }

    function updateRouter(address newAddress, bool andPair) public onlyOwner (){

        emit UpdateRouter(newAddress, address(uniswapV2Router));

        uniswapV2Router = IUniswapV2Router02(newAddress);
        _excludeFromReflections(newAddress, true);

        if(andPair){
            address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(tokenContract), uniswapV2Router.WETH());
            _excludeFromReflections(uniswapV2Pair, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "../interfaces/ISupportingExternalReflection.sol";
import "../interfaces/IAutomatedExternalReflector.sol";
import "./Ownable.sol";
import "./LockableSwap.sol";

abstract contract  AutomatedExternalReflector is Context, LockableSwap, Ownable, IAutomatedExternalReflector {
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event TransactionRegistered(address indexed sender, address indexed recipient);
    event AirdropDelivered(uint256 numberOfPayouts, uint256 totalAmount, uint256 indexAt);
    event RoundSnapshotTaken(uint256 totalUsersUpdated);
    event UserSnapshot(address indexed userAddress, uint256 balanceRecorded);

    struct User {
        uint256 tokenBalance;
        uint256 totalPayouts;
        uint256 pendingPayouts;
        bool exists;
        uint256 lastPayoutRound;
    }

    mapping(uint256 => uint256) public poolForRound;

    uint256 public currentRound;
    uint256 public totalEthDeposits;
    uint256 public currentQueueIndex;
    uint256 public totalRewardsSent;
    uint256 public totalCirculatingTokens;
    uint256 public totalExcludedTokenHoldings = 0;

    bool public takeSnapshot = true;
    bool private snapshotPending;

    uint256 public maxGas;
    uint256 public minGas;
    uint256 public maxReflectionsPerRound;
    uint256 public timeBetweenRounds;
    uint256 public nextRoundStart;

    bool public allowLowLevelCalls = true;
    bool public reflectionsEnabled = true;

    IUniswapV2Router02 public uniswapV2Router;
    ISupportingExternalReflection public tokenContract;
    EnumerableSet.AddressSet private excludedList;

    EnumerableSet.AddressSet private privateQueue;
    address payable[] private queue;

    mapping(address => mapping(uint256 => User)) private dynaHodler;
    mapping(address => bool) public override isExcludedFromReflections;
    mapping(address => bool) public contractWhitelist;

    receive() external payable {
        totalEthDeposits = totalEthDeposits.add(msg.value);
    }

    fallback() external payable {
        totalEthDeposits = totalEthDeposits.add(msg.value);
    }

    function depositEth() public payable override returns(bool success) {
        totalEthDeposits = totalEthDeposits.add(msg.value);
        success = true;
    }

    function addNewUser(address newUserAddress, uint256 bal) private {
        dynaHodler[newUserAddress][currentRound+1] = User(bal, 0, 0, true, currentRound);
        dynaHodler[newUserAddress][currentRound] = User(bal, 0, 0, true, currentRound);
    }

    function logTransactionEvent(address from, address to) external override returns (bool) {
//        require(_msgSender() == _owner || _msgSender() == address(tokenContract), "Only Owner or Token Contract may call this function");
        if(from != address(0)) {
            logUserTransaction(from, IERC20(address(tokenContract)).balanceOf(from), true);
        }
        if(to != address(0)) {
            logUserTransaction(to, IERC20(address(tokenContract)).balanceOf(to), false);
        }

        emit TransactionRegistered(from, to);
        return true;
    }

    function logUserTransaction(address user, uint256 value, bool isSender) private {
        if(!privateQueue.contains(user)){
            privateQueue.add(user);
            queue.push(payable(user));
        }

        uint256 prevUserBal = dynaHodler[user][currentRound].tokenBalance;

        dynaHodler[user][currentRound+1] = User({
            tokenBalance: value,
            totalPayouts: dynaHodler[user][currentRound].totalPayouts,
            pendingPayouts: dynaHodler[user][currentRound].pendingPayouts,
            exists: true,
            lastPayoutRound: dynaHodler[user][currentRound].lastPayoutRound
        });

        if(isExcludedFromReflections[user]){
            if(isSender){
                totalExcludedTokenHoldings = totalExcludedTokenHoldings.sub(prevUserBal.sub(value));
            } else {
                totalExcludedTokenHoldings = totalExcludedTokenHoldings.add(value.sub(prevUserBal));
            }
        }
    }

    function reflectRewards() external override returns (bool) {
        require(gasleft() > minGas, "More gas is required for this function");
        if(!inSwapAndLiquify)
            return _reflectRewards();
        return false;
    }

    // TODO - Test viability for gas consumption on larger queues
    function snapshot() private returns (uint256){
        IERC20 controllingToken = IERC20(address(tokenContract));
        uint256 queueLength = queue.length;
        uint256 excludedTokensSnapshotted = 0;
        for(uint256 i = 0; i < queueLength; i++){
            address payable user = queue[i];
            (bool success, bytes memory data) = address(controllingToken).call(abi.encodeWithSignature("balanceOf(address)",user));
            if(success){
                uint256 bal = abi.decode(data, (uint256));
                dynaHodler[user][currentRound] = User({
                    tokenBalance: bal,
                    totalPayouts: dynaHodler[user][currentRound-1].totalPayouts,
                    pendingPayouts: dynaHodler[user][currentRound-1].pendingPayouts,
                    exists: true,
                    lastPayoutRound: dynaHodler[user][currentRound-1].lastPayoutRound
                });
                if(isExcludedFromReflections[queue[i]]){
                    excludedTokensSnapshotted = excludedTokensSnapshotted.add(bal);
                }
                emit UserSnapshot(user, bal);
            }
        }
        try controllingToken.totalSupply() returns(uint256 sup) {
            updateTotalSupply(sup);
        } catch {}
        return excludedTokensSnapshotted;
    }

    function _reflectRewards() private lockTheSwap returns(bool allComplete) {
        allComplete = false;
        if(takeSnapshot && snapshotPending){
            snapshotPending = false;
            uint256 newExcludedTally = snapshot();
            if(newExcludedTally != 0 && newExcludedTally != totalExcludedTokenHoldings)
                totalExcludedTokenHoldings = newExcludedTally;
            emit RoundSnapshotTaken(queue.length);
            return allComplete;
        }

        if(block.timestamp < nextRoundStart || address(this).balance == 0){
            return allComplete;
        }

        uint256 stopProcessingAt = currentQueueIndex.add(maxReflectionsPerRound);
        uint256 queueLength = queue.length;
        uint256 payeeCount = 0;
        uint256 payeeAmount = 0;
        uint256 startingGas = gasleft();
        uint256 endGas = 0;
        uint256 gasLeft = startingGas;
        if(startingGas > maxGas){
            endGas = startingGas.sub(maxGas);
        } else {
            endGas = minGas;
        }

        while(gasLeft > minGas && gasLeft > endGas && currentQueueIndex < stopProcessingAt && currentQueueIndex < queueLength){
            address payable hodler = payable(queue[currentQueueIndex]);
            payeeAmount = payeeAmount.add(_sendEthTo(hodler));
            dynaHodler[hodler][currentRound].lastPayoutRound = currentRound;
            dynaHodler[hodler][currentRound+1].lastPayoutRound = currentRound;
            payeeCount++;
            currentQueueIndex++;
            gasLeft = gasleft();
        }

        if(currentQueueIndex >= queueLength || poolForRound[currentRound] == 0){
            currentQueueIndex = 0;
            allComplete = true;
            nextRoundStart = block.timestamp.add(timeBetweenRounds);
            currentRound++;
            poolForRound[currentRound] = address(this).balance;
            if(takeSnapshot){
                snapshotPending = true;
            }
        }
        totalRewardsSent = totalRewardsSent.add(payeeAmount);
        emit AirdropDelivered(payeeCount, payeeAmount, currentQueueIndex);
    }

    function enableSnapshotting(bool enable) external onlyOwner {
        takeSnapshot = enable;
    }

    function _sendEthTo(address payable hodler) private returns(uint256) {
        if(!dynaHodler[hodler][currentRound].exists || dynaHodler[hodler][currentRound].tokenBalance == 0) { return 0; }
        if(dynaHodler[hodler][currentRound].lastPayoutRound == currentRound || isExcludedFromReflections[hodler]){ return 0; }
        uint256 reward = dynaHodler[hodler][currentRound].pendingPayouts;

        reward = reward.add(simplePayoutCalc(hodler));
        dynaHodler[hodler][currentRound].totalPayouts = dynaHodler[hodler][currentRound].totalPayouts.add(reward);
        dynaHodler[hodler][currentRound+1].totalPayouts = dynaHodler[hodler][currentRound].totalPayouts;
        hodler.call{value: reward}("");
        return reward;
    }

    function simplePayoutCalc(address hodler) private returns (uint256) {
        return poolForRound[currentRound].mul(dynaHodler[hodler][currentRound].tokenBalance).div(totalCirculatingTokens.sub(totalExcludedTokenHoldings));
    }

    function _calculateEthReflection (uint256 tokenQty, uint256 rewardsSoFar) private returns (uint256) {
        return poolForRound[currentRound].mul(tokenQty).div(totalCirculatingTokens);
    }

    function getRemainingPayeeCount() external view override returns(uint256 count) {
        count = queue.length.sub(currentQueueIndex);
    }

    function enableReflections(bool enable) public override onlyOwner {
        require(enable != reflectionsEnabled, "Reflections already set to this value");
        reflectionsEnabled = enable;
    }

    function _excludeFromReflections(address target, bool exclude) internal {
        isExcludedFromReflections[target] = exclude;
        if(privateQueue.add(target)){
            queue.push(payable(target));
        }
        if(exclude){
            excludedList.add(target);
        } else {
            excludedList.remove(target);
        }
    }

    function excludeFromReflections(address target, bool exclude) public override onlyOwner {
        _excludeFromReflections(target, exclude);
    }

    function updateTokenAddress(address token, bool andPair) public onlyOwner {
        tokenContract = ISupportingExternalReflection(token);
        excludeFromReflections(token, true);
        if(andPair){
            address pair = address(IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH()));
            excludeFromReflections(pair, true);
        }
        totalCirculatingTokens = IERC20(token).totalSupply();
    }

    function updateTotalSupply(uint256 newTotal) public override {
        require(_msgSender() == _owner || _msgSender() == address(tokenContract), "Only Owner or Token Contract may call this function");
        totalCirculatingTokens = newTotal;
    }

    function allowUnsafeTransactions(bool allow) public onlyOwner {
        allowLowLevelCalls = allow;
    }

    function updateGasRange(uint256 _minGas, uint256 _maxGas) public onlyOwner {
        minGas = _minGas;
        maxGas = _maxGas;
    }

    function updateMaxPayoutsPerTransaction(uint256 roundLimit) external onlyOwner {
        require(roundLimit > 0, "Payout cap must be greater than one");
        maxReflectionsPerRound = roundLimit;
    }

    function updateDelayBetweenRounds(uint256 delayInMinutes) external onlyOwner {
        timeBetweenRounds = delayInMinutes * 1 minutes;
    }

    function enrollAddress(address hodlerAddress) external {
        if(privateQueue.add(hodlerAddress)){
            queue.push(payable(hodlerAddress));
        }
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISupportingExternalReflection {
    function setReflectorAddress(address payable _reflectorAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutomatedExternalReflector {
    function depositEth() external payable returns(bool);

    function logTransactionEvent(address from, address to) external returns(bool);
    function getRemainingPayeeCount() external view returns(uint256 count);
    function reflectRewards() external returns (bool allComplete);

    function enableReflections(bool enable) external;

    function isExcludedFromReflections(address ad) external view returns(bool excluded);
    function excludeFromReflections(address target, bool excluded) external;

    function updateTotalSupply(uint256 newTotalSupply) external;

}

// SPDX-License-Identifier: MIT

//import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/utils/Context.sol';

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
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = _msgSender();

    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        require(_owner != address(0), "Zero address is not a valid caller");
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
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LockableSwap {
    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 50
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