/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


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
    constructor () {
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
}


interface IPancakeRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

     function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}
interface IERC20Mintable{
    function mintFor(address account, uint amount) external;
    function mintPurchased(address account, uint amount, uint lockTime) external;
    function mint(uint amount) external;
    function isMinter(address _addr) external view returns(bool);
}
interface IsYSL{
    function mintPurchased(address account, uint amount, uint lockTime) external;
}
interface IReferral{
    function hasReferral(address _account) external view returns(bool);
    function referrals(address _account) external view returns(address);
    function proccessReferral(address _sender, address _segCreator, bytes memory _sig) external;
    
}
interface IAirdrop{
    function isAirdropped(address _account) external view returns(bool);
}

/// @title sYSL Token Price Discovery contract
/// @author Simranpal Dhillon, Hardev Dhillon
/// @author Blaize team: Anna Korunska, Artem Martiukhin & Pavlo Horbonos
/// @notice PriceDiscovery powers first stage of the sYSL token sale called price discovery.
/// Aim of this stage is to raise funds and determine price of the sYSL token.
contract PriceDiscovery is Ownable {
    using SafeERC20 for IERC20;

    enum Stage{
        PrivateSale, Pub1, Pub2, Pub3, Pub4, Pub5, Pub6, Pub7, Referral, Closed
    }
    enum Token{
        BUSD, WBNB
    }
    /// @notice Event emitted on each successful user deposit.
    /// @param depositorAddress Address of the user who performed a deposit.
    /// @param stage Current stage 0-for private sale, 1-7 for each day of public sale, 8 - referral programm
    /// @param token 0 - for BUSD, 1 - for WBNB
    /// @param tokenAmount Amount deposited in tokens
    /// @param usdAmount Amount deposited in USD
    /// @param amountOfBonuses Amount of bonuses received after deposit
    event DepositSuccessful(
        address indexed depositorAddress, uint stage, uint token, uint tokenAmount, uint usdAmount, uint amountOfBonuses);

    /*****
     * CONSTANTS AND PRE-SET VALUES
     *****/

    /// @notice Price discovery process duration.
    uint constant public PRICE_DISCOVERY_DURATION = 7 days;
    ///@notice Private sale process duration
    uint constant public PRIVATE_SALE_DURATION = 23 days;
    /// @dev Bonus coefficients are stored multiplied by COEFFICIENT_DECIMALS value.
    uint constant public COEFFICIENT_DECIMALS = 1000;

    mapping(address=>bool) whitelist;
    uint constant whitelistCoefficient = 4000;
    /// @notice When depositing funds during discovery, 
    /// users receive additional bonuses depending on a discovery day.
    /* x3, x2, x1.8, x1.6, x1.5, x1.3, x1.2, x1, x0.1 */
    uint[] public bonusCoefficient = [3000, 2000, 1800, 1600, 1500, 1300, 1200, 1000, 100];
    uint[] public minimumDeposit
        = [5000 ether, 2500 ether, 2000 ether, 1500 ether, 1000 ether, 500 ether, 250 ether, 0, 0];
    uint[] public lockTime
        = [750 days, 750 days, 600 days, 450 days, 375 days, 225 days, 150 days, 0, 750 days];

    /*****
     * SALE STORAGE
     *****/
    
    /// @notice Planned initial total supply of the sYSL token.
    uint public initialTotalSupply;
    /// @notice Timestamp of price discovery process initiation.
    uint public priceDiscoveryStartTime;
    /// @notice Timestamp of private sale  proccess initiation.
    uint public privateSaleStartTime;
    /// @notice Amount of BUSD (ownerless liquidity) collected by the contract
    uint public totalBUSDcollected;
    /// @notice Amount of dollar equivalent sYSL (deposit + bonus + referral)
    uint public totalBUSDwithBonusesCollected;

    /// @notice Shows, that the BUSD was successfully transferred to liquidity pool
    bool public liquidityWithdrawn;


    //// @notice BUSD and WBNB token contracts.
    address[2] public tokens;
    /// @notice Pancake swap router contract.
    IPancakeRouter02 public swapRouterContract;
    IReferral public referralContract;
    IAirdrop public airdropContract;

    uint public deadline;

    /*****
     * USER STORAGE
     *****/
    
    /// @notice Real USD amount deposited by the user during each stage
    mapping(address => mapping(uint8 => uint)) public amountDepositedByUserAndStage;
    /// @notice Total amount with bonuses received by the user durin each stage
    mapping(address => mapping(uint8 => uint)) public amountWithBonusesByUserAndStage;


    /// @notice The check if the user has already withdrawn his sYSL
    mapping(address => bool) public withdrawn;

    /// @notice sYSL token address
    address public sYSL;

    /*****
     * MODIFIERS
     *****/
    modifier notStarted() {
        require(block.timestamp < privateSaleStartTime, "Already started");
        _;
    }

    modifier discoveryFinished() {
        require(
            block.timestamp >= priceDiscoveryStartTime + PRICE_DISCOVERY_DURATION,
            "Discovery is not finished yet"
        );
        _;
    }

    modifier discoveryCurrent() {
        require(
            block.timestamp >= privateSaleStartTime && block.timestamp < priceDiscoveryStartTime + PRICE_DISCOVERY_DURATION,
            "Discovery finished yet or not started"
        );
        _;
    }

    modifier supportedToken(Token token) {
        require(
            token == Token.BUSD || token==Token.WBNB,
                "Token not supported for sYSL price discovery"
        );
        _;
    }

    /*****
     * CONSTRUCTOR AND ADMIN FUNCTIONS
     *****/

    /// @notice Performs contract initial setup.
    /// @param _sYSL sYSL token address.
    /// @param _busdContractAddress BUSD token contract address.
    /// @param _wbnbContractAddress WBNB token contract address.
    /// @param _swapRouterContractAddress Uniswap router contract address.
    /// @param _privateStartTime Timestamp of private sale start time.
    constructor(
        address _sYSL,
        address _busdContractAddress,
        address _wbnbContractAddress,
        address _swapRouterContractAddress,
        address _referralContractAddress,
        uint _privateStartTime)
    {
        sYSL = _sYSL;
        tokens[uint(Token.BUSD)] = _busdContractAddress;
        tokens[uint(Token.WBNB)] = _wbnbContractAddress;
        swapRouterContract = IPancakeRouter02(_swapRouterContractAddress);
        referralContract = IReferral(_referralContractAddress);
        initialTotalSupply = 100000 * 10**18;
        privateSaleStartTime = _privateStartTime;
        priceDiscoveryStartTime = privateSaleStartTime + PRIVATE_SALE_DURATION;
        deadline=20 minutes;
    }

    /// @notice Call change discovery start time.
    /// Owner can change discovery start time if it's not started yet.
    /// @param newStartTime New timestamp of price dicovery start time..
    function updateStartTime(uint newStartTime) external onlyOwner notStarted {
        require(newStartTime > block.timestamp, "New discovery start time must be in future");
        privateSaleStartTime = newStartTime;
        priceDiscoveryStartTime = privateSaleStartTime + PRIVATE_SALE_DURATION;
    }

    /// @notice Call change initial supply of sYSL token.
    /// Owner can change initial supply if sYSL price was not finalized yet.
    /// @param newInitialTotalSupply New sYSL token initial supply.
    function updateInitialTotalSupply(uint newInitialTotalSupply) external onlyOwner {
        require(priceDiscoveryStartTime + PRICE_DISCOVERY_DURATION >block.timestamp, "Sale is closed");
        initialTotalSupply = newInitialTotalSupply;
    } 

    function setDeadline(uint _deadline) external onlyOwner {
        deadline=_deadline*1 minutes;
    }

    function setAirdrop(address _airdrop) external onlyOwner {
        airdropContract = IAirdrop(_airdrop);
    }

    /// @notice Function to recover tokens stacked after the direct transfer
    /// @param _token Token address.
    /// @param _amount Amount to recover
    function recoverToken(address _token, uint256 _amount) external onlyOwner discoveryFinished {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        // In case if BUSD should be recovered - only extra amount (over total purchased)
        if (_token == tokens[uint8(Token.BUSD)] && liquidityWithdrawn) {
            require(tokenBalance - totalBUSDcollected >= _amount, "Not enough tokens");
        }
        require(tokenBalance >= _amount, "Not enough tokens");
        IERC20(_token).safeTransfer(_msgSender(), _amount);
    }

    function withdrawTeamBUSD(address _teamAddress) external onlyOwner discoveryFinished {
        require(_teamAddress != address(0), "Zero address");
        require(liquidityWithdrawn, "Ownerless liquidity should be transferred");

        uint256 liqToTransfer = totalBUSDcollected / 2;
        totalBUSDcollected = 0;
        IERC20(tokens[uint8(Token.BUSD)]).safeTransfer(_teamAddress, liqToTransfer);
    }

    function withdrawLiquidityBUSD(address _liquidityProvider) external onlyOwner discoveryFinished {
        require(_liquidityProvider != address(0), "Zero address");
        require(!liquidityWithdrawn, "Ownerless liquidity should NOT be transferred yet");

        liquidityWithdrawn = true;
        uint256 liqToTransfer = totalBUSDcollected / 2;
        IERC20(tokens[uint8(Token.BUSD)]).safeTransfer(_liquidityProvider, liqToTransfer);
    }


    /*****
     * DEPOSIT / WITHDRAW
     *****/
    
    /// @notice Call to perform deposit by user.
    /// @param amount Amount of token deposited.
    /// @param token Contract address of token deposited.
    /// @param signature Signature for the referral code.
    function deposit(uint amount, Token token, bytes memory signature, address creator) external discoveryCurrent supportedToken(token) {
        require(amount > 0, "Incorrect amount");
        uint256 usdDepositedWithBonuses = _deposit(amount, token);

        if ( creator != address(0) ) {
            IReferral(referralContract).proccessReferral(_msgSender(), creator, signature);
        }

        bool hasRef = IReferral(referralContract).hasReferral(_msgSender());
        if ( hasRef ) {
            address referrer = IReferral(referralContract).referrals(_msgSender());
            require(creator == address(0) || referrer == creator, "Incorrect referrer");

            uint256 referredAmount = usdDepositedWithBonuses * bonusCoefficient[uint8(Stage.Referral)] / COEFFICIENT_DECIMALS;

            amountWithBonusesByUserAndStage[referrer][uint8(Stage.Referral)] += referredAmount;
            totalBUSDwithBonusesCollected += referredAmount;

            emit DepositSuccessful(referrer, uint(Stage.Referral), uint(Token.BUSD), 0, 0, referredAmount);
        }
    }

    function _deposit(uint amount, Token token) internal returns(uint256) {
        uint8 stage = uint8(getCurrentStage()); // stage is already private or public
        bool isWbnb = (token == Token.WBNB);
        
        uint usdDeposited;
        uint amountOfReceivedBonuses;

        uint amountUSDBefore = IERC20(tokens[uint(Token.BUSD)]).balanceOf(address(this)); 
        IERC20(tokens[uint(token)]).safeTransferFrom(_msgSender(), address(this), amount);
        
        if ( isWbnb ) {
            _swapToBusd(deadline, amount);
            uint amountUSDAfter = IERC20(tokens[uint(Token.BUSD)]).balanceOf(address(this)); 
            usdDeposited = amountUSDAfter - amountUSDBefore;
        }
        else {
            usdDeposited = amount;
        }
        // No deposits on current stage
        if (amountDepositedByUserAndStage[_msgSender()][stage] == 0 && 
                (address(airdropContract) == address(0) || !airdropContract.isAirdropped(_msgSender())))
        {
            require(usdDeposited >= minimumDeposit[stage], "Not enough to deposit on current sale day");
        }
        
        if (stage == uint8(Stage.PrivateSale) && whitelist[_msgSender()]) {
            amountOfReceivedBonuses = usdDeposited*whitelistCoefficient/COEFFICIENT_DECIMALS;
        }
        else {
            amountOfReceivedBonuses = usdDeposited*bonusCoefficient[uint8(stage)]/COEFFICIENT_DECIMALS;
        }

        amountWithBonusesByUserAndStage[_msgSender()][uint8(stage)] += amountOfReceivedBonuses;
        totalBUSDwithBonusesCollected += amountOfReceivedBonuses;
        
        amountDepositedByUserAndStage[_msgSender()][uint8(stage)] += usdDeposited;
        totalBUSDcollected += usdDeposited;
        
        emit DepositSuccessful(_msgSender(), uint(stage), isWbnb ? uint(Token.WBNB) : uint(Token.BUSD),
                 amount, usdDeposited, amountOfReceivedBonuses);

        return amountOfReceivedBonuses;
    }


    /// @notice Claims unlocked sYSL. Performes nothing if discovery is not finished.
    /// @dev the contract should have Minter role for the sYSL contract
    function sYSLwithdraw() external discoveryFinished {
        require(!withdrawn[_msgSender()], "User has already withdrawn sYSL");
        uint256 amountDeposited = getTotalDepositedWithBonusesByUser(_msgSender());

        if (amountDeposited > 0) {
            uint256 _lockTime = getLockTimeByUser(_msgSender());
            uint256 sYSLamount = amountDeposited * 10**18 / getDiscoveredPrice();
            
            IsYSL(sYSL).mintPurchased(_msgSender(), sYSLamount, _lockTime);

            withdrawn[_msgSender()] = true;
        }
    }

    function addToWhitelist(address[] memory addrs) external onlyOwner{
        for(uint i=0; i<addrs.length; i++){
            if(addrs[i]!=address(0)){
                whitelist[addrs[i]]=true;
            }
        }
    }

    function removeFromWhitelist(address[] memory addrs) external onlyOwner{
        for(uint i=0; i<addrs.length; i++){
           if(whitelist[addrs[i]]){
               whitelist[addrs[i]]=false;
           }
        }
    }

    /*****
     * VIEW INTERFACE
     *****/
    
    /// @notice Call to calculate sYSL token price.
    /// @return recalculated sYSL initial price in USD (with decimals)
     function getDiscoveredPrice() public view returns(uint256){
        return totalBUSDcollected * 10**18 / initialTotalSupply;
    }

    /// @notice Call to calculate sYSL supply.
    /// @return Recalculated initial sYSL supply (with decimals)
     function getDiscoveredSupply() public view returns(uint256){
        return totalBUSDwithBonusesCollected * 10**18 / getDiscoveredPrice();
    }

    /// @notice Call to calculate users BUSD deposit with bonuses.
    /// @param _user Users account
    /// @return Recalculated value of deposit with bonuses
    function getTotalDepositedWithBonusesByUser(address _user) public view returns(uint256) {
        uint256 total;

        for (uint8 i = 0; i < uint8(Stage.Closed); i++) {
            total += amountWithBonusesByUserAndStage[_user][i];
        }
        return total;
    }

    /// @notice Call to get users BUSD deposit.
    /// @param _user Users account
    /// @return Recalculated value of deposit
    function getTotalDepositedByUser(address _user) public view returns(uint256) {
        uint256 total;

        for (uint8 i = 0; i < uint8(Stage.Closed); i++) {
            total += amountDepositedByUserAndStage[_user][i];
        }
        return total;
    }

    /// @notice Call to get users lock time.
    /// @param _user Users account
    /// @return Recalculated lock time - average by all received bonuses
    function getLockTimeByUser(address _user) public view returns(uint256) {
        uint256 total = getTotalDepositedWithBonusesByUser(_user);
        uint256 totalLock;

        if (total == 0) return 0;

        for (uint8 i = 0; i < uint8(Stage.Closed); i++) {
            uint256 curStageLock = lockTime[i] * amountWithBonusesByUserAndStage[_user][i];
            totalLock += curStageLock;  
        }
        return totalLock / total;
    }

    /// @notice Call to get min deposit.
    /// @return Min deposit for the current stage
    function getCurrentMinDeposit() external view returns (uint256) {
        Stage _stage = getCurrentStage();
        if (_stage == Stage.Closed) return 0;

        return minimumDeposit[uint8(_stage)];
    }
    

    /// @notice Returns min deposit for the user at the chosen stage.
    /// May be 0 for if the user has already performed min deposit.
    /// there will be no minimum requirement for any subsequent deposits made on the same day
    /// from the same wallet address
    /// @return Min deposit for the current stage for the user
    function getMinDepositByUserAndStage(address _user, Stage _stage) external view returns (uint256) {
        if (amountDepositedByUserAndStage[_user][uint8(_stage)] > 0) {
            return 0;
        }

        return minimumDeposit[uint8(_stage)];
    }


    function getMinWBNBDepositByStage(Stage _stage) external view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = tokens[uint(Token.BUSD)];
        path[1] = tokens[uint(Token.WBNB)];
        uint amounts = swapRouterContract.getAmountsOut(minimumDeposit[uint(_stage)], path)[1];
        return amounts;
    }

    /// @notice Call to get the current stage.
    /// @return _stage Current stage
    function getCurrentStage() public view returns(Stage _stage) {
        if (block.timestamp < privateSaleStartTime ||
                        block.timestamp > priceDiscoveryStartTime + PRICE_DISCOVERY_DURATION) {
            _stage =  Stage.Closed;
        }
        else if (block.timestamp < priceDiscoveryStartTime){
            _stage = Stage.PrivateSale;
        }
        else {
            _stage = Stage((block.timestamp-priceDiscoveryStartTime)/(1 days) + 1);
        }
    }

    /*****
     * INTERNAL HELPERS
     *****/

    /// @notice Internal function used to swap all WBNB collected during discovery to BUSD tokens.
    /// @dev This solution relies on the pancake swap, 
    // which requires minimal amount in and deadline parameters for security reasons.
    /// Those values are expected from the contract manager that's going to perform discovery finalization.
    function _swapToBusd(uint _deadline, uint _wbnbAmountToSwap) 
        internal{
        address[] memory path = new address[](2);
        path[0] = tokens[uint(Token.WBNB)];
        path[1] = tokens[uint(Token.BUSD)];
        IERC20(tokens[uint(Token.WBNB)]).approve(address(swapRouterContract), _wbnbAmountToSwap);
        swapRouterContract.swapExactTokensForTokens(
            _wbnbAmountToSwap,
            1,
            path,
            address(this),
            _deadline
        );
    }
}