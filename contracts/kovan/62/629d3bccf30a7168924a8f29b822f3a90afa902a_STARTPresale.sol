/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-09
*/

pragma solidity 0.6.12;


// File: @openzeppelin/contracts/math/SafeMath.sol
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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract STARTPresale {
    using SafeMath for uint256;

    address payable public bscsDevAddress; // address of contract dev

    IERC20 public token; // token that will be sold
    address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to

    mapping(address => uint256) public investments; // total wei invested per address
    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => uint256) public claimed; // if claimed=1, first period is claimed, claimed=2, second period is claimed, claimed=0, nothing claimed.

    uint256 public totalInvestorsCount; // total investors count
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public cakeLiquidityAddingTime; // time when adding of liquidity in PancakeSwap starts, investors can claim their tokens afterwards

    uint256 public claimCycle = 30 days;

    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens
    bool public refundAllowed = false; // if true, investor can get refund his investment.
    bool public claimAllowed = false; // if true, investory can claim tokens.

    bool public isAudited = false; // if true, it's passed, false, it's not failed.
    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkGithub;
    bytes32 public linkWebsite;
    bytes32 public linkLogo;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audit
    struct AuditorInfo {
        bytes32 auditor; // auditor name
        bool isVerified; // if true -> passed, false -> failed
        bool isWarning; // if true -> warning, false -> no warning
        string verifiedHash; // stores content of audit summary (actual text)
        string warningHash; // stores content of warnings
    }

    AuditorInfo public auditInformation;

    constructor(address _bscsDevAddress) public {
        require(_bscsDevAddress != address(0));

        bscsDevAddress = payable(_bscsDevAddress);
    }

    modifier onlyBscsDev() {
        require(bscsDevAddress == msg.sender);
        _;
    }

    modifier whitelistedAddressOnly() {
        require(
            whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!presaleCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier isValidClaimPeriod() {
        uint256 currentPeriod = 0;
        if (
            now >= cakeLiquidityAddingTime &&
            now < cakeLiquidityAddingTime + claimCycle
        ) {
            currentPeriod = 1;
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle &&
            now < cakeLiquidityAddingTime + claimCycle * 2
        ) {
            currentPeriod = 2;
        }
        if (
            now >= cakeLiquidityAddingTime + claimCycle * 2 &&
            now < cakeLiquidityAddingTime + claimCycle * 3
        ) {
            currentPeriod = 3;
        }
        if (now >= cakeLiquidityAddingTime + claimCycle * 3) {
            currentPeriod = 4;
        }
        require(currentPeriod > 0, "Listing not started");

        require(
            claimed[msg.sender] < currentPeriod,
            "Already claimed or refunded"
        );
        _;
    }

    modifier onlyRefundAllowed() {
        require(refundAllowed, "Refund is disallowed");
        _;
    }

    modifier onlyClaimAllowed() {
        require(claimAllowed, "Claim is disallowed");
        _;
    }

    modifier whitelistedAuditorOnly() {
        require(
            auditorWhitelistedAddresses[msg.sender],
            "Auditor Address not whitelisted"
        );
        _;
    }

    function setAddressInfo(
        address _tokenAddress,
        address _unsoldTokensDumpAddress
    ) external onlyBscsDev {
        require(_tokenAddress != address(0));
        require(_unsoldTokensDumpAddress != address(0));

        token = IERC20(_tokenAddress);
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlyBscsDev {
        require(_totalTokens > 0);
        require(_tokenPriceInWei > 0);
        require(_openTime > 0);
        require(_closeTime > 0);
        require(_hardCapInWei > 0);

        // Hard cap > (token amount * token price)
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei));
        // Soft cap > to hard cap
        require(_softCapInWei <= _hardCapInWei);
        //  Min. wei investment > max. wei investment
        require(_minInvestInWei <= _maxInvestInWei);
        // Open time >= close time
        require(_openTime < _closeTime);

        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        bytes32 _linkLogo
    ) external onlyBscsDev {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkGithub = _linkGithub;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
        linkLogo = _linkLogo;
    }

    function setAuditorInfo(
        bytes32 _auditor,
        bool _isVerified,
        bool _isWarning,
        string calldata _verifiedHash,
        string calldata _warningHash
    ) external whitelistedAuditorOnly {
        auditInformation.auditor = _auditor;
        auditInformation.isVerified = _isVerified;
        auditInformation.isWarning = _isWarning;
        auditInformation.verifiedHash = _verifiedHash;
        auditInformation.warningHash = _warningHash;
    }

    function addWhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyBscsDev
    {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyBscsDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function setRefundAllowed(bool _refundAllowed)
        external
        onlyBscsDev
    {
        refundAllowed = _refundAllowed;
    }

    function allowClaim(uint256 _cakeLiquidityAddingTime) external onlyBscsDev {
        require(_cakeLiquidityAddingTime > 0);
        require(closeTime > 0);
        require(_cakeLiquidityAddingTime >= closeTime);

        claimAllowed = true;
        cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
    }

    function setClaimCycle(uint256 _claimCycle)
        external
        onlyBscsDev
    {
        claimCycle = _claimCycle;
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.mul(1e18).div(tokenPriceInWei);
    }

    function invest()
        public
        payable
        whitelistedAddressOnly
        presaleIsNotCancelled
    {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value <= tokensLeft.mul(tokenPriceInWei));
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(
            totalInvestmentInWei >= minInvestInWei ||
                totalCollectedWei >= hardCapInWei.sub(1 ether),
            "Min investment not reached"
        );
        require(
            maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
            "Max investment reached"
        );

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }

    receive() external payable {
        invest();
    }

    function transferUnsoldTokens()
        external
        onlyBscsDev
        presaleIsNotCancelled
    {
        uint256 unsoldTokensAmount =
            token.balanceOf(address(this)).sub(
                getTokenAmount(totalCollectedWei)
            );
        if (unsoldTokensAmount > 0) {
            token.transfer(unsoldTokensDumpAddress, unsoldTokensAmount);
        }
    }

    function claimTokens()
        external
        whitelistedAddressOnly
        presaleIsNotCancelled
        investorOnly
        isValidClaimPeriod
        onlyClaimAllowed
    {
        claimed[msg.sender] = claimed[msg.sender].add(1); // make sure this goes first before transfer to prevent reentrancy
        token.transfer(
            msg.sender,
            getTokenAmount(investments[msg.sender].div(4))
        );
    }

    function getRefund()
        external
        whitelistedAddressOnly
        investorOnly
        onlyRefundAllowed
    {
        if (!presaleCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
            require(claimed[msg.sender] == 0, "Already claimed");
        }

        claimed[msg.sender] = 4; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance = address(this).balance;
        require(presaleBalance > 0);

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
    }

    function cancelAndTransferTokensToDev() external onlyBscsDev {
        if (bscsDevAddress != msg.sender) {
            revert();
        }

        require(!presaleCancelled);
        presaleCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(bscsDevAddress, balance);
        }
    }

    function collectFundsRaised() external onlyBscsDev {
        require(!presaleCancelled);

        if (address(this).balance > 0) {
            bscsDevAddress.transfer(address(this).balance);
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol
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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol
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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

// File: @openzeppelin/contracts/GSN/Context.sol
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract STARToken is ERC20 {

    constructor() public ERC20("BSCstarter", "START") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

contract BSCstarterInfo is Ownable {
    using SafeMath for uint256;

    uint256 private devFeePercentage = 2; // fees going to dev AND BSCS hodlers (2% each)
    uint256 private minDevFeeInWei = 5 ether; // min fee amount going to dev AND BSCS hodlers
    uint256 private maxRewardQualifyBal = 20000 * 1e18; // max amount to HODL to qualify for BNB fee rewards
    uint256 private minRewardQualifyBal = 1250 * 1e18; // min amount to HODL to qualify for BNB fee rewards
    uint256 private minRewardQualifyPercentage = 10; // percentage of discount on tokens for qualifying holders
    uint256 private presaleGrantAmount = 100 * 1e18; // grant given to 'good' projects 30 days after raise
    address private incubatorMsigAddress; // community address used to release presale incubator grants

    address[] private presaleAddresses; // track all presales created
    address[] private presaleGrantAddresses; // track all presale grants assigned

    uint256 private minInvestorBSCSBalance = 100 * 1e18; // min amount to investors HODL BSCS balance
    uint256 private minStakeTime = 24 hours;
    uint256 private minUnstakeTime = 24 hours;
    uint256 private minClaimTime = 7 days;

    address payable[] private bscsTokenPresales;

    address private pancakeSwapRouter =
        address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address private pancakeSwapFactory =
        address(0xBCfCcbde45cE874adCB698cC183deBcF17952812);
    address private wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address private bscsFactoryAddress;

    constructor(address payable[] memory _bscsTokenPresales) public {
        bscsTokenPresales = _bscsTokenPresales;
    }

    modifier onlyFactory() {
        require(bscsFactoryAddress == msg.sender);
        _;
    }

    function getBscsFactoryAddress() external view returns (address) {
        return bscsFactoryAddress;
    }

    function setBscsFactoryAddress(address _newFactoryAddress)
        external
        onlyOwner
    {
        bscsFactoryAddress = _newFactoryAddress;
    }

    function addPresaleAddress(address _presale)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(_presale);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 bscsId) external view returns (address) {
        return presaleAddresses[bscsId];
    }

    function addPresaleGrantAddress(address _presaleGrant)
        external
        onlyFactory
        returns (uint256)
    {
        presaleGrantAddresses.push(_presaleGrant);
        return presaleGrantAddresses.length - 1;
    }

    function getPresaleGrantsCount() external view returns (uint256) {
        return presaleGrantAddresses.length;
    }

    function getPresaleGrantAddress(uint256 _id)
        external
        view
        returns (address)
    {
        return presaleGrantAddresses[_id];
    }

    function getDevFeePercentage() external view returns (uint256) {
        return devFeePercentage;
    }

    function setDevFeePercentage(uint256 _devFeePercentage) external onlyOwner {
        devFeePercentage = _devFeePercentage;
    }

    function getMinDevFeeInWei() external view returns (uint256) {
        return minDevFeeInWei;
    }

    function setMinDevFeeInWei(uint256 _minDevFeeInWei) external onlyOwner {
        minDevFeeInWei = _minDevFeeInWei;
    }

    function getPresaleGrantAmount() external view returns (uint256) {
        return presaleGrantAmount;
    }

    function setPresaleGrantAmount(uint256 _presaleGrantAmount)
        external
        onlyOwner
    {
        require(
            _presaleGrantAmount <= 5000 * 1e18,
            "Invalid presale grant amount"
        );
        presaleGrantAmount = _presaleGrantAmount;
    }

    function getIncubatorMsigAddress() external view returns (address) {
        return incubatorMsigAddress;
    }

    function setIncubatorMsigAddress(address _incubatorMsigAddress)
        external
        onlyOwner
    {
        incubatorMsigAddress = _incubatorMsigAddress;
    }

    function getMinRewardQualifyPercentage() external view returns (uint256) {
        return minRewardQualifyPercentage;
    }

    function setMinRewardQualifyPercentage(uint256 _minRewardQualifyPercentage)
        external
        onlyOwner
    {
        minRewardQualifyPercentage = _minRewardQualifyPercentage;
    }

    function getMinRewardQualifyBal() external view returns (uint256) {
        return minRewardQualifyBal;
    }

    function setMinRewardQualifyBal(uint256 _minRewardQualifyBal)
        external
        onlyOwner
    {
        minRewardQualifyBal = _minRewardQualifyBal;
    }

    function getMaxRewardQualifyBal() external view returns (uint256) {
        return maxRewardQualifyBal;
    }

    function setMaxRewardQualifyBal(uint256 _maxRewardQualifyBal)
        external
        onlyOwner
    {
        maxRewardQualifyBal = _maxRewardQualifyBal;
    }

    function getMinInvestorBSCSBalance() external view returns (uint256) {
        return minInvestorBSCSBalance;
    }

    function setMinInvestorBSCSBalance(uint256 _minInvestorBSCSBalance)
        external
        onlyOwner
    {
        minInvestorBSCSBalance = _minInvestorBSCSBalance;
    }

    function getMinStakeTime() external view returns (uint256) {
        return minStakeTime;
    }

    function setMinStakeTime(uint256 _minStakeTime) external onlyOwner {
        minStakeTime = _minStakeTime;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function setMinUnstakeTime(uint256 _minUnstakeTime) external onlyOwner {
        minUnstakeTime = _minUnstakeTime;
    }

    function getMinClaimTime() external view returns (uint256) {
        return minClaimTime;
    }

    function setMinClaimTime(uint256 _minClaimTime) external onlyOwner {
        minClaimTime = _minClaimTime;
    }

    function getBscsTokenPresales()
        external
        view
        returns (address payable[] memory)
    {
        return bscsTokenPresales;
    }

    function setBscsTokenPresales(address payable[] memory _bscsTokenPresales)
        external
        onlyOwner
    {
        bscsTokenPresales = _bscsTokenPresales;
    }

    function getLockedBalance(address payable sender)
        external
        view
        returns (uint256 totalLockedBalance)
    {
        totalLockedBalance = 0;
        for (uint256 i = 0; i < bscsTokenPresales.length; i++) {
            STARTPresale tokenPresale = STARTPresale(bscsTokenPresales[i]);

            uint256 senderInvestment = tokenPresale.investments(sender);
            uint256 senderClaimed = tokenPresale.claimed(sender);
            if (senderInvestment > 0 && senderClaimed < 4) {
                uint256 poolTokenPriceInWei = tokenPresale.tokenPriceInWei();
                uint256 poolLockedBalance =
                    senderInvestment
                        .div(4)
                        .mul(4 - senderClaimed)
                        .mul(1e18)
                        .div(poolTokenPriceInWei);
                totalLockedBalance = totalLockedBalance.add(poolLockedBalance);
            }
        }
    }

    function getPancakeSwapRouter() external view returns (address) {
        return pancakeSwapRouter;
    }

    function setPancakeSwapRouter(address _pancakeSwapRouter)
        external
        onlyOwner
    {
        pancakeSwapRouter = _pancakeSwapRouter;
    }

    function getPancakeSwapFactory() external view returns (address) {
        return pancakeSwapFactory;
    }

    function setPancakeSwapFactory(address _pancakeSwapFactory)
        external
        onlyOwner
    {
        pancakeSwapFactory = _pancakeSwapFactory;
    }

    function getWBNB() external view returns (address) {
        return wbnb;
    }

    function setWBNB(address _wbnb) external onlyOwner {
        wbnb = _wbnb;
    }
}

contract BSCstarterStaking is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    STARToken public bscsToken;
    BSCstarterInfo public bscStarterInfo;

    event Staked(address indexed from, uint256 amount);
    event Unstaked(address indexed from, uint256 amount);

    struct AccountInfo {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
    }
    mapping(address => AccountInfo) public accountInfos;

    constructor(address _bscsToken, address _bscStarterInfo) public {
        bscsToken = STARToken(_bscsToken);
        bscStarterInfo = BSCstarterInfo(_bscStarterInfo);
    }

    function stake(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Invalid amount");
        require(bscsToken.balanceOf(msg.sender) >= _amount, "Invalid balance");

        AccountInfo storage account = accountInfos[msg.sender];
        bscsToken.transferFrom(msg.sender, address(this), _amount);
        account.balance = account.balance.add(_amount);
        account.lastStakedTimestamp = block.timestamp;
        if (account.lastUnstakedTimestamp == 0) {
            account.lastUnstakedTimestamp = block.timestamp;
        }
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount, uint256 _burnFeePercent)
        external
        nonReentrant
    {
        AccountInfo storage account = accountInfos[msg.sender];
        uint256 minUnstakeTime = bscStarterInfo.getMinUnstakeTime();
        require(
            account.lastUnstakedTimestamp + minUnstakeTime <= block.timestamp,
            "Invalid unstake time"
        );
        require(account.balance > 0, "Nothing to unstake");
        require(_amount > 0, "Invalid amount");
        if (account.balance < _amount) {
            _amount = account.balance;
        }
        account.balance = account.balance.sub(_amount);
        account.lastUnstakedTimestamp = block.timestamp;

        uint256 burnAmount = _amount.mul(_burnFeePercent);
        if (burnAmount > 0) {
            _amount = _amount.sub(burnAmount);
            bscsToken.transfer(
                address(0x000000000000000000000000000000000000dEaD),
                burnAmount
            );
        }

        bscsToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }
}

interface IPancakeSwapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract BSCstarterPresale {
    using SafeMath for uint256;

    address payable internal bscsFactoryAddress; // address that creates the presale contracts
    address payable public bscsDevAddress; // address where dev fees will be transferred to
    address public bscsLiqLockAddress; // address where LP tokens will be locked
    BSCstarterStaking public bscsStakingPool;
    BSCstarterInfo public bscStarterInfo;

    IERC20 public token; // token that will be sold
    IERC20 public bscsToken; // system token
    address payable public presaleCreatorAddress; // address where percentage of invested wei will be transferred to
    address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to

    mapping(address => uint256) public investments; // total wei invested per address
    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => bool) public claimed; // if true, it means investor already claimed the tokens or got a refund

    uint256 private bscsDevFeePercentage; // dev fee to support the development of BSCstarter
    uint256 private bscsMinDevFeeInWei; // minimum fixed dev fee to support the development of BSCstarter
    uint256 public bscsId; // used for fetching presale without referencing its address
    uint256 public presaleGrantId; // tracks any incubator grants given

    uint256 public totalInvestorsCount; // total investors count
    uint256 public presaleCreatorClaimWei; // wei to transfer to presale creator per investor claim
    uint256 public presaleCreatorClaimTime; // time when presale creator can collect funds raise
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public cakeListingPriceInWei; // token price when listed in PancakeSwap
    uint256 public cakeLiquidityAddingTime; // time when adding of liquidity in PancakeSwap starts, investors can claim their tokens afterwards
    uint256 public cakeLPTokensLockDurationInDays; // how many days after the liquity is added the presale creator can unlock the LP tokens
    uint256 public cakeLiquidityPercentageAllocation; // how many percentage of the total invested wei that will be added as liquidity

    mapping(address => uint256) public voters; // addresses voting on sale
    uint256 public noVotes; // total number of no votes
    uint256 public yesVotes; // total number of yes votes
    uint256 public minYesVotesThreshold = 100000 * 1e18; // minimum number of yes votes needed to pass
    uint256 public minVoterBSCSBalance = 1000 * 1e18; // minimum number of BSCS tokens to hold to vote
    uint256 public minInvestorBSCSBalance; // minimum number of BSCS tokens to hold to invest
    uint256 public minRewardQualifyBal; // min amount to HODL to qualify for token discounts
    uint256 public minRewardQualifyPercentage; // percentage of discount on tokens for qualifying holders

    bool public cakeLiquidityAdded = false; // if true, liquidity is added in PancakeSwap and lp tokens are locked
    bool public onlyWhitelistedAddressesAllowed = false; // if true, only whitelisted addresses can invest
    bool public bscsDevFeesExempted = false; // if true, presale will be exempted from dev fees
    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens

    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkGithub;
    bytes32 public linkWebsite;
    bytes32 public linkLogo;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audit
    struct AuditorInfo {
        bytes32 auditor; // auditor name
        bool isVerified; // if true -> passed, false -> failed
        bool isWarning; // if true -> warning, false -> no warning
        string verifiedHash; // stores content of audit summary (actual text)
        string warningHash; // stores content of warnings
    }
    AuditorInfo public auditInformation;

    constructor(
        address _bscsFactoryAddress,
        address _bscStarterInfo,
        address _bscsDevAddress,
        uint256 _minRewardQualifyBal,
        uint256 _minRewardQualifyPercentage
    ) public {
        require(_bscsFactoryAddress != address(0));
        require(_bscsDevAddress != address(0));

        bscsFactoryAddress = payable(_bscsFactoryAddress);
        bscsDevAddress = payable(_bscsDevAddress);
        minRewardQualifyBal = _minRewardQualifyBal;
        minRewardQualifyPercentage = _minRewardQualifyPercentage;
        bscStarterInfo = BSCstarterInfo(_bscStarterInfo);
    }

    modifier onlyBscsDev() {
        require(
            bscsFactoryAddress == msg.sender || bscsDevAddress == msg.sender
        );
        _;
    }

    modifier onlyPresaleCreatorOrBscsFactory() {
        require(
            presaleCreatorAddress == msg.sender ||
                bscsFactoryAddress == msg.sender,
            "Not presale creator or factory"
        );
        _;
    }

    modifier onlyPresaleCreatorOrBscsDev() {
        require(
            presaleCreatorAddress == msg.sender || bscsDevAddress == msg.sender,
            "Not presale creator or dev"
        );
        _;
    }

    modifier onlyPresaleCreator() {
        require(presaleCreatorAddress == msg.sender, "Not presale creator");
        _;
    }

    modifier whitelistedAddressOnly() {
        require(
            !onlyWhitelistedAddressesAllowed ||
                whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!presaleCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier notYetClaimedOrRefunded() {
        require(!claimed[msg.sender], "Already claimed or refunded");
        _;
    }

    modifier votesPassed() {
        require(
            yesVotes > noVotes && yesVotes >= minYesVotesThreshold,
            "Votes not passed"
        );
        _;
    }

    modifier whitelistedAuditorOnly() {
        require(
            auditorWhitelistedAddresses[msg.sender],
            "Auditor Address not whitelisted"
        );
        _;
    }

    function setAddressInfo(
        address _presaleCreator,
        address _tokenAddress,
        address _bscsTokenAddress,
        address _unsoldTokensDumpAddress
    ) external onlyPresaleCreatorOrBscsFactory {
        require(_presaleCreator != address(0));
        require(_tokenAddress != address(0));
        require(_unsoldTokensDumpAddress != address(0));

        presaleCreatorAddress = payable(_presaleCreator);
        token = IERC20(_tokenAddress);
        bscsToken = IERC20(_bscsTokenAddress);
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlyPresaleCreatorOrBscsFactory {
        require(_totalTokens > 0);
        require(_tokenPriceInWei > 0);
        require(_openTime > 0);
        require(_closeTime > 0);
        require(_hardCapInWei > 0);

        // Hard cap > (token amount * token price)
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei));
        // Soft cap > to hard cap
        require(_softCapInWei <= _hardCapInWei);
        //  Min. wei investment > max. wei investment
        require(_minInvestInWei <= _maxInvestInWei);
        // Open time >= close time
        require(_openTime < _closeTime);

        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function setPancakeSwapInfo(
        uint256 _cakeListingPriceInWei,
        uint256 _cakeLiquidityAddingTime,
        uint256 _cakeLPTokensLockDurationInDays,
        uint256 _cakeLiquidityPercentageAllocation
    ) external onlyPresaleCreatorOrBscsFactory {
        require(_cakeListingPriceInWei > 0);
        require(_cakeLiquidityAddingTime > 0);
        require(_cakeLPTokensLockDurationInDays > 0);
        require(_cakeLiquidityPercentageAllocation > 0);

        require(closeTime > 0);
        // Listing time < close time
        require(_cakeLiquidityAddingTime >= closeTime);

        cakeListingPriceInWei = _cakeListingPriceInWei;
        cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
        cakeLPTokensLockDurationInDays = _cakeLPTokensLockDurationInDays;
        cakeLiquidityPercentageAllocation = _cakeLiquidityPercentageAllocation;
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        bytes32 _linkLogo
    ) external onlyPresaleCreatorOrBscsFactory {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkGithub = _linkGithub;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
        linkLogo = _linkLogo;
    }

    function setAuditorInfo(
        bytes32 _auditor,
        bool _isVerified,
        bool _isWarning,
        string calldata _verifiedHash,
        string calldata _warningHash
    ) external whitelistedAuditorOnly {
        auditInformation.auditor = _auditor;
        auditInformation.isVerified = _isVerified;
        auditInformation.isWarning = _isWarning;
        auditInformation.verifiedHash = _verifiedHash;
        auditInformation.warningHash = _warningHash;
    }

    function setBscsInfo(
        address _bscsLiqLockAddress,
        uint256 _bscsDevFeePercentage,
        uint256 _bscsMinDevFeeInWei,
        uint256 _bscsId,
        uint256 _presaleGrantId,
        address _bscsStakingPool
    ) external onlyBscsDev {
        bscsLiqLockAddress = _bscsLiqLockAddress;
        bscsDevFeePercentage = _bscsDevFeePercentage;
        bscsMinDevFeeInWei = _bscsMinDevFeeInWei;
        bscsId = _bscsId;
        presaleGrantId = _presaleGrantId;
        bscsStakingPool = BSCstarterStaking(_bscsStakingPool);
    }

    function setBscsDevFeesExempted(bool _bscsDevFeesExempted)
        external
        onlyBscsDev
    {
        bscsDevFeesExempted = _bscsDevFeesExempted;
    }

    function setOnlyWhitelistedAddressesAllowed(
        bool _onlyWhitelistedAddressesAllowed
    ) external onlyPresaleCreatorOrBscsFactory {
        onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
    }

    function setMinVoterBSCSBalance(uint256 _minVoterBSCSBalance)
        external
        onlyBscsDev
    {
        require(_minVoterBSCSBalance >= 10 * 1e18);
        minVoterBSCSBalance = _minVoterBSCSBalance * 1e18;
    }

    function setMinYesVotesThreshold(uint256 _minYesVotesThreshold)
        external
        onlyBscsDev
    {
        require(_minYesVotesThreshold >= 10000 * 1e18); // cannot be < 1% of supply
        minYesVotesThreshold = _minYesVotesThreshold * 1e18;
    }

    function setMinInvestorBSCSBalance(uint256 _minInvestorBSCSBalance) 
        external 
        onlyBscsDev 
    {
        minInvestorBSCSBalance = _minInvestorBSCSBalance;
    }

    function addWhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyPresaleCreatorOrBscsFactory
    {
        onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyBscsDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
        (balance, lastStakedTimestamp, lastUnstakedTimestamp) = bscsStakingPool
            .accountInfos(msg.sender);
        uint256 minStakeTime = bscStarterInfo.getMinStakeTime();
        uint256 bscsBalance = bscStarterInfo.getLockedBalance(msg.sender);

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            bscsBalance = bscsBalance.add(balance);
        }
        if (bscsBalance >= minRewardQualifyBal) {
            uint256 pctQualifyingDiscount =
                tokenPriceInWei.mul(minRewardQualifyPercentage).div(100);
            return
                _weiAmount.mul(1e18).div(
                    tokenPriceInWei.sub(pctQualifyingDiscount)
                );
        } else {
            return _weiAmount.mul(1e18).div(tokenPriceInWei);
        }
    }

    function invest()
        public
        payable
        whitelistedAddressOnly
        presaleIsNotCancelled
        votesPassed
    {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value > 0);

        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
        (balance, lastStakedTimestamp, lastUnstakedTimestamp) = bscsStakingPool
            .accountInfos(msg.sender);
        uint256 minStakeTime = bscStarterInfo.getMinStakeTime();
        uint256 bscsBalance = bscStarterInfo.getLockedBalance(msg.sender);

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            bscsBalance = bscsBalance.add(balance);
        }
        if (bscsBalance >= minRewardQualifyBal) {
            // apply discount to qualifying hodlers
            uint256 pctQualifyingDiscount =
                tokenPriceInWei.mul(minRewardQualifyPercentage).div(100);
            require(
                msg.value <=
                    tokensLeft
                        .mul(tokenPriceInWei.sub(pctQualifyingDiscount))
                        .div(1e18),
                "Not enough tokens left"
            );
        } else {
            require(
                msg.value <= tokensLeft.mul(tokenPriceInWei).div(1e18),
                "Not enough tokens left"
            );
        }
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(
            totalInvestmentInWei >= minInvestInWei ||
                totalCollectedWei >= hardCapInWei.sub(1 ether),
            "Min investment not reached"
        );
        require(
            maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
            "Max investment reached"
        );

        if (minInvestorBSCSBalance > 0) {
            require(
                bscsBalance >= minInvestorBSCSBalance,
                "Not enough BSCS on account"
            );
        }

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }

    receive() external payable {
        invest();
    }

    function addLiquidityAndLockLPTokens() external presaleIsNotCancelled {
        require(totalCollectedWei > 0);
        require(!cakeLiquidityAdded, "Liquidity already added");
        require(
            !onlyWhitelistedAddressesAllowed ||
                whitelistedAddresses[msg.sender] ||
                msg.sender == presaleCreatorAddress,
            "Not whitelisted or not presale creator"
        );

        if (
            totalCollectedWei >= hardCapInWei.sub(1 ether) &&
            block.timestamp < cakeLiquidityAddingTime
        ) {
            require(msg.sender == presaleCreatorAddress, "Not presale creator");
        } else if (block.timestamp >= cakeLiquidityAddingTime) {
            require(
                msg.sender == presaleCreatorAddress ||
                    investments[msg.sender] > 0,
                "Not presale creator or investor"
            );
            require(totalCollectedWei >= softCapInWei, "Soft cap not reached");
        } else {
            revert("Liquidity cannot be added yet");
        }

        cakeLiquidityAdded = true;

        uint256 finalTotalCollectedWei = totalCollectedWei;
        uint256 bscsDevFeeInWei;
        if (!bscsDevFeesExempted) {
            uint256 pctDevFee =
                finalTotalCollectedWei.mul(bscsDevFeePercentage).div(100);
            bscsDevFeeInWei = pctDevFee > bscsMinDevFeeInWei ||
                bscsMinDevFeeInWei >= finalTotalCollectedWei
                ? pctDevFee
                : bscsMinDevFeeInWei;
        }
        if (bscsDevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(
                bscsDevFeeInWei
            );
            bscsDevAddress.transfer(bscsDevFeeInWei);
            // factory manages BSCS hodlers fund where they can claim earned BNB rewards
            finalTotalCollectedWei = finalTotalCollectedWei.sub(
                bscsDevFeeInWei
            );
            bscsFactoryAddress.transfer(bscsDevFeeInWei);
        }

        uint256 liqPoolEthAmount =
            finalTotalCollectedWei.mul(cakeLiquidityPercentageAllocation).div(
                100
            );
        uint256 liqPoolTokenAmount =
            liqPoolEthAmount.mul(1e18).div(cakeListingPriceInWei);

        IPancakeSwapV2Router02 pancakeSwapRouter =
            IPancakeSwapV2Router02(
                address(bscStarterInfo.getPancakeSwapRouter())
            );

        token.approve(address(pancakeSwapRouter), liqPoolTokenAmount);

        pancakeSwapRouter.addLiquidityETH{value: liqPoolEthAmount}(
            address(token),
            liqPoolTokenAmount,
            0,
            0,
            bscsLiqLockAddress,
            block.timestamp.add(15 minutes)
        );

        presaleCreatorClaimWei = address(this).balance.mul(1e18).div(
            totalInvestorsCount.mul(1e18)
        );
        presaleCreatorClaimTime = block.timestamp + 1 days;
    }

    function vote(bool yes) external presaleIsNotCancelled {
        uint256 balance;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
        (balance, lastStakedTimestamp, lastUnstakedTimestamp) = bscsStakingPool
            .accountInfos(msg.sender);
        uint256 minStakeTime = bscStarterInfo.getMinStakeTime();
        uint256 voterBalance = bscStarterInfo.getLockedBalance(msg.sender);

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            voterBalance = voterBalance.add(balance);
        }

        require(voterBalance >= minVoterBSCSBalance, "Not enough BSCS to vote");
        require(voters[msg.sender] == 0, "Vote already casted");

        voters[msg.sender] = voterBalance;
        if (yes) {
            yesVotes = yesVotes.add(voterBalance);
        } else {
            noVotes = noVotes.add(voterBalance);
        }
    }

    function claimTokens()
        external
        whitelistedAddressOnly
        presaleIsNotCancelled
        investorOnly
        notYetClaimedOrRefunded
    {
        require(cakeLiquidityAdded, "Liquidity not yet added");

        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        token.transfer(msg.sender, getTokenAmount(investments[msg.sender]));

        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 funds =
                presaleCreatorClaimWei > balance
                    ? balance
                    : presaleCreatorClaimWei;
            presaleCreatorAddress.transfer(funds);
        }
    }

    function getRefund()
        external
        whitelistedAddressOnly
        investorOnly
        notYetClaimedOrRefunded
    {
        if (!presaleCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
        }

        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 presaleBalance = address(this).balance;
        require(presaleBalance > 0);

        if (investment > presaleBalance) {
            investment = presaleBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
    }

    function cancelAndTransferTokensToPresaleCreator() external {
        if (
            !cakeLiquidityAdded &&
            presaleCreatorAddress != msg.sender &&
            bscsDevAddress != msg.sender
        ) {
            revert();
        }
        if (cakeLiquidityAdded && bscsDevAddress != msg.sender) {
            revert();
        }

        require(!presaleCancelled);
        presaleCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(presaleCreatorAddress, balance);
        }
    }

    function collectFundsRaised() external onlyPresaleCreator {
        require(cakeLiquidityAdded);
        require(!presaleCancelled);
        require(block.timestamp >= presaleCreatorClaimTime);

        if (address(this).balance > 0) {
            presaleCreatorAddress.transfer(address(this).balance);
        }
    }

    function burnUnsoldTokens() external onlyPresaleCreatorOrBscsDev {
        require(cakeLiquidityAdded);
        require(!presaleCancelled);
        require(block.timestamp >= presaleCreatorClaimTime + 1 days); // wait 2 days before allowing burn

        uint256 unsoldTokensAmount = token.balanceOf(address(this));
        if (unsoldTokensAmount > 0) {
            token.transfer(unsoldTokensDumpAddress, unsoldTokensAmount);
        }
    }
}