/**
 *Submitted for verification at snowtrace.io on 2022-01-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

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

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IAllocationController {
    function penguinTiers(address penguinAddress) external view returns(uint8);
    function allocations(address penguinAddress) external view returns(uint256);
    function totalAllocations() external view returns(uint256);
}

contract PenguinBoosterRocket is Ownable {
    using SafeERC20 for IERC20;
    //token for event
    IERC20 public tokenForDistribution;
    //token to be used for payment
    IERC20 public tokenToPay;
    //contract that can controls allocations
    address public allocationController;
    //amount of tokenToPay that buys an entire tokenForDistribution
    uint256 public exchangeRateWholeToken;
    //divisor for exchange rate. set in constructor equal to 10**decimals of tokenForDistribution
    uint256 public immutable exchangeRateDivisor;
    //amount of tokenToBuy that a penguin can purchase per allocation, ***SCALLED UP by 1e18***. set in constructor
    uint256 public immutable allocationRate;
    //UTC timestamp of event start
    uint256 public eventStart;
    //UTC timestamp of event end
    uint256 public eventEnd;
    //set in BIPS. can be adjusted up to allow all addresses to purchase more tokens
    uint256 public allocationMultiplierBIPS;
    //tracks sum of all tokens sold
    uint256 public totalTokensSold;
    //tracks sum of proceeds collated in tokenToPay from all token sales
    uint256 public totalProceeds;
    //determines if exchange rate is adjustable or fixed
    bool public adjustableExchangeRate;
    //determines if start/end times can be adjusted, or if they are fixed
    bool public adjustableTiming;
    //determines if allocationMultiplierBIPS is adjustable or fixed at 1
    bool public adjustableAllocationMultiplierBIPS;
    //amount of tokens purchased by each address
    mapping(address => uint256) public tokensPurchased;
    //discount amounts for tiers in BIPS
    uint256[4] public discountBIPS;

    //Keeps track of wether a user has agreed to the terms and conditions or not.
    mapping(address => bool) public hasAgreedToTermsAndConditions;

    //special testing mapping
    mapping(address => bool) public testingWhitelist;

    event TokensPurchased(address indexed buyer, uint256 amountPurchased);
    event ExchangeRateSet(uint256 newExchangeRate);
    event AllocationMultiplierBIPSIncreased(uint256 newMultiplier);
    event AgreedToTermsAndConditions(address userThatAgreed, bool hasAgreed, uint256 block_timestamp);

    //checks to see if purchase is allowed
    modifier checkPurchase(address buyer, uint256 amountToBuy) {
        require(eventOngoing() || testingWhitelist[buyer],"event not ongoing");
        require(canPurchase(buyer) >= amountToBuy, "you cannot buy this many tokens");
        require(amountToBuy <= tokensLeftToDistribute(), "amountToBuy exceeds contract balance");
        _;
    }

    constructor(
            IERC20 tokenForDistribution_,
            IERC20 tokenToPay_,
            uint256 eventStart_,
            uint256 eventEnd_,
            uint256 exchangeRateWholeToken_,
            uint256 allocationRate_,
            address allocationController_,
            bool adjustableExchangeRate_,
            bool adjustableTiming_,
            bool adjustableAllocationMultiplierBIPS_) {
        require(eventStart_ > block.timestamp, "event must start in future");
        require(eventStart_ < eventEnd_, "event must start before it ends");
        tokenForDistribution = tokenForDistribution_;
        tokenToPay = tokenToPay_;
        eventStart = eventStart_;
        eventEnd = eventEnd_;
        exchangeRateWholeToken = exchangeRateWholeToken_;
        emit ExchangeRateSet(exchangeRateWholeToken_);
        exchangeRateDivisor = 10**(tokenForDistribution.decimals());
        allocationRate = allocationRate_; //REMINDER: this is scaled up by 1e18
        allocationController = allocationController_;
        adjustableExchangeRate = adjustableExchangeRate_;
        adjustableTiming = adjustableTiming_;
        adjustableAllocationMultiplierBIPS = adjustableAllocationMultiplierBIPS_;
        allocationMultiplierBIPS = 10000; //starts as multiplier of 1
        emit AllocationMultiplierBIPSIncreased(10000);
        discountBIPS = [0, 0, 0, 0];
    }

    //PUBLIC (VIEW) FUNCTIONS
    function eventStarted() public view returns(bool) {
        return(block.timestamp >= eventStart);
    }

    function eventEnded() public view returns(bool) {
        return(block.timestamp > eventEnd);
    }

    function eventOngoing() public view returns(bool) {
        return(eventStarted() && !eventEnded());
    }

    //get amount of tokens buyer can purchase
    function canPurchase(address penguinAddress) public view returns(uint256) {
        uint256 allocation = IAllocationController(allocationController).allocations(penguinAddress);
        return(((allocation * allocationRate * allocationMultiplierBIPS) / 10000) / 1e18 - tokensPurchased[penguinAddress]);
    }

    //find amount of tokenToPay needed to buy amountToBuy of tokenForDistribution
    function findAmountToPay(uint256 amountToBuy, address penguinAddress) public view returns(uint256) {
        uint8 userTier = IAllocationController(allocationController).penguinTiers(penguinAddress);
        if(userTier > 0) {
            userTier -= 1;
        }
        uint256 discount = discountBIPS[userTier];
        uint256 amountToPay = ((amountToBuy * exchangeRateWholeToken * (10000 - discount)) / 10000) / exchangeRateDivisor;
        return amountToPay;
    }

    function tokensLeftToDistribute() public view returns(uint256) {
        return tokenForDistribution.balanceOf(address(this));
    }

    function hasTheUserAgreed(address _user) public view returns(bool) {
        return hasAgreedToTermsAndConditions[_user];
    }

    //PUBLIC FUNCTIONS
    function agreeToTermsAndConditions() public {
        if (hasAgreedToTermsAndConditions[msg.sender]){
          return;
        }
        else {
          hasAgreedToTermsAndConditions[msg.sender] = true;
          emit AgreedToTermsAndConditions(msg.sender, hasAgreedToTermsAndConditions[msg.sender], block.timestamp);
        }
    }

    //EXTERNAL FUNCTIONS
    function purchaseTokens(uint256 amountToBuy) external checkPurchase(msg.sender, amountToBuy) {
        agreeToTermsAndConditions();
        require(amountToBuy > 0);
        _processPurchase(msg.sender, amountToBuy);
    }

    //OWNER-ONLY FUNCTIONS
    function adjustStart(uint256 newStartTime) external onlyOwner {
        require(adjustableTiming, "timing is not adjustable");
        require(!eventOngoing(), "cannot adjust start while event ongoing");
        require(newStartTime < eventEnd, "event must start before it ends");
        require(newStartTime > block.timestamp, "event must start in future");
        eventStart = newStartTime;
    }

    function adjustEnd(uint256 newEndTime) external onlyOwner {
        require(adjustableTiming, "timing is not adjustable");
        require(eventStart < newEndTime, "event must start before it ends");
        eventEnd = newEndTime;
    }

    function adjustExchangeRate(uint256 newExchangeRate) external onlyOwner {
        require(adjustableExchangeRate, "exchange rate is not adjustable");
        exchangeRateWholeToken = newExchangeRate;
        emit ExchangeRateSet(newExchangeRate);
    }

    function increaseAllocationMultiplierBIPS(uint256 newAllocationMultiplierBIPS) external onlyOwner {
        require(adjustableAllocationMultiplierBIPS, "allocationMultiplierBIPS is not adjustable");
        require(newAllocationMultiplierBIPS > allocationMultiplierBIPS, "can only increase multiplier");
        allocationMultiplierBIPS = newAllocationMultiplierBIPS;
        emit AllocationMultiplierBIPSIncreased(newAllocationMultiplierBIPS);
    }

    function withdrawDistributionProceeds(address dest) external onlyOwner {
        uint256 toSend = tokenToPay.balanceOf(address(this));
        tokenToPay.safeTransfer(dest, toSend);
    }

    function withdrawUnsoldTokens(address dest) external onlyOwner {
        uint256 toSend = tokenForDistribution.balanceOf(address(this));
        tokenForDistribution.safeTransfer(dest, toSend);
    }

    function addToTestingWhitelist(address tester) external onlyOwner {
        testingWhitelist[tester] = true;
    }

    //INTERNAL FUNCTIONS
    function _processPurchase(address penguinAddress, uint256 amountToBuy) internal {
        uint256 amountToPay = findAmountToPay(amountToBuy, penguinAddress);
        totalProceeds += amountToPay;
        tokenForDistribution.safeTransfer(penguinAddress, amountToBuy);
        totalTokensSold += amountToBuy;
        tokensPurchased[penguinAddress] += amountToBuy;
        emit TokensPurchased(penguinAddress, amountToBuy);
        tokenToPay.safeTransferFrom(penguinAddress, address(this), amountToPay);
    }
}