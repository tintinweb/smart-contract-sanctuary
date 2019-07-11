/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
     *
     * Requirements:
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract LibMath {
    using SafeMath for uint256;

    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.mul(target).div(denominator);
    }

    function getFeeAmount(
        uint256 numerator,
        uint256 target
    )
        internal
        pure
        returns (uint256 feeAmount)
    {
        feeAmount = numerator.mul(target).div(1 ether); // todo: constants
    }
}




contract LibOrder {

    struct Order {
        uint256 makerSellAmount;
        uint256 makerBuyAmount;
        uint256 takerSellAmount;
        uint256 salt;
        uint256 expiration;
        address taker;
        address maker;
        address makerSellToken;
        address makerBuyToken;
    }

    struct OrderInfo {
        uint256 filledAmount;
        bytes32 hash;
        uint8 status;
    }

    struct OrderFill {
        uint256 makerFillAmount;
        uint256 takerFillAmount;
        uint256 takerFeePaid;
        uint256 exchangeFeeReceived;
        uint256 referralFeeReceived;
        uint256 makerFeeReceived;
    }

    enum OrderStatus {
        INVALID_SIGNER,
        INVALID_TAKER_AMOUNT,
        INVALID_MAKER_AMOUNT,
        FILLABLE,
        EXPIRED,
        FULLY_FILLED,
        CANCELLED
    }

    function getHash(Order memory order)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                order.maker,
                order.makerSellToken,
                order.makerSellAmount,
                order.makerBuyToken,
                order.makerBuyAmount,
                order.salt,
                order.expiration
            )
        );
    }

    function getPrefixedHash(Order memory order)
        public
        pure
        returns (bytes32)
    {
        bytes32 orderHash = getHash(order);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash));
    }
}




contract LibSignatureValidator   {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}




contract IKyberNetworkProxy {
    function getExpectedRate(address src, address dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) public payable returns(uint256);
}




contract LibKyberData {

    struct KyberData {
        uint256 rate;
        uint256 value;
        address givenToken;
        address receivedToken;
    }
}




/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract IExchangeUpgradability {

    uint8 public VERSION;

    event FundsMigrated(address indexed user, address indexed newExchange);
    
    function allowOrRestrictMigrations() external;

    function migrateFunds(address[] calldata tokens) external;

    function migrateEthers() private;

    function migrateTokens(address[] memory tokens) private;

    function importEthers(address user) external payable;

    function importTokens(address tokenAddress, uint256 tokenAmount, address user) external;

}




contract LibCrowdsale {

    using SafeMath for uint256;

    struct Crowdsale {
        uint256 startBlock;
        uint256 endBlock;
        uint256 hardCap;
        uint256 leftAmount;
        uint256 tokenRatio;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 weiRaised;
        address wallet;
    }

    enum ContributionStatus {
        CROWDSALE_NOT_OPEN,
        MIN_CONTRIBUTION,
        MAX_CONTRIBUTION,
        HARDCAP_REACHED,
        VALID
    }

    enum CrowdsaleStatus {
        INVALID_START_BLOCK,
        INVALID_END_BLOCK,
        INVALID_TOKEN_RATIO,
        INVALID_LEFT_AMOUNT,
        VALID
    }

    function getCrowdsaleStatus(Crowdsale memory crowdsale)
        public
        view
        returns (CrowdsaleStatus)
    {

        if(crowdsale.startBlock < block.number) {
            return CrowdsaleStatus.INVALID_START_BLOCK;
        }

        if(crowdsale.endBlock < crowdsale.startBlock) {
            return CrowdsaleStatus.INVALID_END_BLOCK;
        }

        if(crowdsale.tokenRatio == 0) {
            return CrowdsaleStatus.INVALID_TOKEN_RATIO;
        }

        uint256 tokenForSale = crowdsale.hardCap.mul(crowdsale.tokenRatio);

        if(tokenForSale != crowdsale.leftAmount) {
            return CrowdsaleStatus.INVALID_LEFT_AMOUNT;
        }

        return CrowdsaleStatus.VALID;
    }

    function isOpened(uint256 startBlock, uint256 endBlock)
        internal
        view
        returns (bool)
    {
        return (block.number >= startBlock && block.number <= endBlock);
    }


    function isFinished(uint256 endBlock)
        internal
        view
        returns (bool)
    {
        return block.number > endBlock;
    }
}




/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}




/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract&#39;s constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
}




contract ExchangeStorage is Ownable {

    /**
      * @dev The minimum fee rate that the maker will receive
      * Note: 20% = 20 * 10^16
      */
    uint256 constant internal minMakerFeeRate = 200000000000000000;

    /**
      * @dev The maximum fee rate that the maker will receive
      * Note: 90% = 90 * 10^16
      */
    uint256 constant internal maxMakerFeeRate = 900000000000000000;

    /**
      * @dev The minimum fee rate that the taker will pay
      * Note: 0.1% = 0.1 * 10^16
      */
    uint256 constant internal minTakerFeeRate = 1000000000000000;

    /**
      * @dev The maximum fee rate that the taker will pay
      * Note: 1% = 1 * 10^16
      */
    uint256 constant internal maxTakerFeeRate = 10000000000000000;

    /**
      * @dev The referrer will receive 10% from each taker fee.
      * Note: 10% = 10 * 10^16
      */
    uint256 constant internal referralFeeRate = 100000000000000000;

    /**
      * @dev The amount of percentage the maker will receive from each taker fee.
      * Note: Initially: 50% = 50 * 10^16
      */
    uint256 public makerFeeRate;

    /**
      * @dev The amount of percentage the will pay for taking an order.
      * Note: Initially: 0.2% = 0.2 * 10^16
      */
    uint256 public takerFeeRate;

    /**
      * @dev 2-level map: tokenAddress -> userAddress -> balance
      */
    mapping(address => mapping(address => uint256)) internal balances;

    /**
      * @dev map: orderHash -> filled amount
      */
    mapping(bytes32 => uint256) internal filled;

    /**
      * @dev map: orderHash -> isCancelled
      */
    mapping(bytes32 => bool) internal cancelled;

    /**
      * @dev map: user -> userReferrer
      */
    mapping(address => address) internal referrals;

    /**
      * @dev The address where all exchange fees (0,08%) are kept.
      * Node: multisig wallet
      */
    address public feeAccount;

    /**
      * @return return the balance of `token` for certain `user`
      */
    function getBalance(
        address user,
        address token
    )
        public
        view
        returns (uint256)
    {
        return balances[token][user];
    }

    /**
      * @return return the balance of multiple tokens for certain `user`
      */
    function getBalances(
        address user,
        address[] memory token
    )
        public
        view
        returns(uint256[] memory balanceArray)
    {
        balanceArray = new uint256[](token.length);

        for(uint256 index = 0; index < token.length; index++) {
            balanceArray[index] = balances[token[index]][user];
        }
    }

    /**
      * @return return the filled amount of order specified by `orderHash`
      */
    function getFill(
        bytes32 orderHash
    )
        public
        view
        returns (uint256)
    {
        return filled[orderHash];
    }

    /**
      * @return return the filled amount of multple orders specified by `orderHash` array
      */
    function getFills(
        bytes32[] memory orderHash
    )
        public
        view
        returns (uint256[] memory filledArray)
    {
        filledArray = new uint256[](orderHash.length);

        for(uint256 index = 0; index < orderHash.length; index++) {
            filledArray[index] = filled[orderHash[index]];
        }
    }

    /**
      * @return return true(false) if order specified by `orderHash` is(not) cancelled
      */
    function getCancel(
        bytes32 orderHash
    )
        public
        view
        returns (bool)
    {
        return cancelled[orderHash];
    }

    /**
      * @return return array of true(false) if orders specified by `orderHash` array are(not) cancelled
      */
    function getCancels(
        bytes32[] memory orderHash
    )
        public
        view
        returns (bool[]memory cancelledArray)
    {
        cancelledArray = new bool[](orderHash.length);

        for(uint256 index = 0; index < orderHash.length; index++) {
            cancelledArray[index] = cancelled[orderHash[index]];
        }
    }

    /**
      * @return return the referrer address of `user`
      */
    function getReferral(
        address user
    )
        public
        view
        returns (address)
    {
        return referrals[user];
    }

    /**
      * @return set new rate for the maker fee received
      */
    function setMakerFeeRate(
        uint256 newMakerFeeRate
    )
        external
        onlyOwner
    {
        require(
            newMakerFeeRate >= minMakerFeeRate &&
            newMakerFeeRate <= maxMakerFeeRate,
            "INVALID_MAKER_FEE_RATE"
        );
        makerFeeRate = newMakerFeeRate;
    }

    /**
      * @return set new rate for the taker fee paid
      */
    function setTakerFeeRate(
        uint256 newTakerFeeRate
    )
        external
        onlyOwner
    {
        require(
            newTakerFeeRate >= minTakerFeeRate &&
            newTakerFeeRate <= maxTakerFeeRate,
            "INVALID_TAKER_FEE_RATE"
        );

        takerFeeRate = newTakerFeeRate;
    }

    /**
      * @return set new fee account
      */
    function setFeeAccount(
        address newFeeAccount
    )
        external
        onlyOwner
    {
        feeAccount = newFeeAccount;
    }
}




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity&#39;s return data size checking mechanism, since
        // we&#39;re implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




contract Exchange is LibMath, LibOrder, LibSignatureValidator, ExchangeStorage {

    using SafeMath for uint256;

    /**
      * @dev emitted when a trade is executed
      */
    event Trade(
        address indexed makerAddress,        // Address that created the order
        address indexed takerAddress,        // Address that filled the order
        bytes32 indexed orderHash,           // Hash of the order
        address makerFilledAsset,            // Address of assets filled for maker
        address takerFilledAsset,            // Address of assets filled for taker
        uint256 makerFilledAmount,           // Amount of assets filled for maker
        uint256 takerFilledAmount,           // Amount of assets filled for taker
        uint256 takerFeePaid,                // Amount of fee paid by the taker
        uint256 makerFeeReceived,            // Amount of fee received by the maker
        uint256 referralFeeReceived          // Amount of fee received by the referrer
    );

    /**
      * @dev emitted when a cancel order is executed
      */
    event Cancel(
        address indexed makerBuyToken,        // Address of asset being bought.
        address makerSellToken,               // Address of asset being sold.
        address indexed maker,                // Address that created the order
        bytes32 indexed orderHash             // Hash of the order
    );

    /**
      * @dev Compute the status of an order.
      * Should be called before a contract execution is performet in order to not waste gas.
      * @return OrderStatus.FILLABLE if the order is valid for taking.
      * Note: See LibOrder.sol to see all statuses
      */
    function getOrderInfo(
        uint256 partialAmount,
        Order memory order
    )
        public
        view
        returns (OrderInfo memory orderInfo)
    {
        // Compute the order hash
        orderInfo.hash = getPrefixedHash(order);

        // Fetch filled amount
        orderInfo.filledAmount = filled[orderInfo.hash];

        // Check taker balance
        if(balances[order.makerBuyToken][order.taker] < order.takerSellAmount) {
            orderInfo.status = uint8(OrderStatus.INVALID_TAKER_AMOUNT);
            return orderInfo;
        }

        // Check maker balance
        if(balances[order.makerSellToken][order.maker] < partialAmount) {
            orderInfo.status = uint8(OrderStatus.INVALID_MAKER_AMOUNT);
            return orderInfo;
        }

        // Check if order is filled
        if (orderInfo.filledAmount.add(order.takerSellAmount) > order.makerBuyAmount) {
            orderInfo.status = uint8(OrderStatus.FULLY_FILLED);
            return orderInfo;
        }

        // Check for expiration
        if (block.number >= order.expiration) {
            orderInfo.status = uint8(OrderStatus.EXPIRED);
            return orderInfo;
        }

        // Check if order has been cancelled
        if (cancelled[orderInfo.hash]) {
            orderInfo.status = uint8(OrderStatus.CANCELLED);
            return orderInfo;
        }

        orderInfo.status = uint8(OrderStatus.FILLABLE);
        return orderInfo;
    }

    /**
      * @dev Execute a trade based on the input order and signature.
      * Reverts if order is not valid
      */
    function trade(
        Order memory order,
        bytes memory signature
    )
        public
    {
        bool result = _trade(order, signature);
        require(result, "INVALID_TRADE");
    }

    /**
      * @dev Execute a trade based on the input order and signature.
      * If the order is valid returns true.
      */
    function _trade(
        Order memory order,
        bytes memory signature
    )
        internal
        returns(bool)
    {
        order.taker = msg.sender;

        uint256 takerReceivedAmount = getPartialAmount(
            order.makerSellAmount,
            order.makerBuyAmount,
            order.takerSellAmount
        );

        OrderInfo memory orderInfo = getOrderInfo(takerReceivedAmount, order);

        uint8 status = assertTakeOrder(orderInfo.hash, orderInfo.status, order.maker, signature);

        if(status != uint8(OrderStatus.FILLABLE)) {
            return false;
        }

        OrderFill memory orderFill = getOrderFillResult(takerReceivedAmount, order);

        executeTrade(order, orderFill);

        filled[orderInfo.hash] = filled[orderInfo.hash].add(order.takerSellAmount);

        emit Trade(
            order.maker,
            order.taker,
            orderInfo.hash,
            order.makerBuyToken,
            order.makerSellToken,
            orderFill.makerFillAmount,
            orderFill.takerFillAmount,
            orderFill.takerFeePaid,
            orderFill.makerFeeReceived,
            orderFill.referralFeeReceived
        );

        return true;
    }

    /**
      * @dev Cancel an order if msg.sender is the order signer.
      */
    function cancelSingleOrder(
        Order memory order,
        bytes memory signature
    )
        public
    {
        bytes32 orderHash = getPrefixedHash(order);

        require(
            recover(orderHash, signature) == msg.sender,
            "INVALID_SIGNER"
        );

        require(
            cancelled[orderHash] == false,
            "ALREADY_CANCELLED"
        );

        cancelled[orderHash] = true;

        emit Cancel(
            order.makerBuyToken,
            order.makerSellToken,
            msg.sender,
            orderHash
        );
    }

    /**
      * @dev Computation of the following properties based on the order input:
      * takerFillAmount -> amount of assets received by the taker
      * makerFillAmount -> amount of assets received by the maker
      * takerFeePaid -> amount of fee paid by the taker (0.2% of takerFillAmount)
      * makerFeeReceived -> amount of fee received by the maker (50% of takerFeePaid)
      * referralFeeReceived -> amount of fee received by the taker referrer (10% of takerFeePaid)
      * exchangeFeeReceived -> amount of fee received by the exchange (40% of takerFeePaid)
      */
    function getOrderFillResult(
        uint256 takerReceivedAmount,
        Order memory order
    )
        internal
        view
        returns (OrderFill memory orderFill)
    {
        orderFill.takerFillAmount = takerReceivedAmount;

        orderFill.makerFillAmount = order.takerSellAmount;

        // 0.2% == 0.2*10^16
        orderFill.takerFeePaid = getFeeAmount(
            takerReceivedAmount,
            takerFeeRate
        );

        // 50% of taker fee == 50*10^16
        orderFill.makerFeeReceived = getFeeAmount(
            orderFill.takerFeePaid,
            makerFeeRate
        );

        // 10% of taker fee == 10*10^16
        orderFill.referralFeeReceived = getFeeAmount(
            orderFill.takerFeePaid,
            referralFeeRate
        );

        // exchangeFee = (takerFeePaid - makerFeeReceived - referralFeeReceived)
        orderFill.exchangeFeeReceived = orderFill.takerFeePaid.sub(
            orderFill.makerFeeReceived).sub(
                orderFill.referralFeeReceived);

    }

    /**
      * @dev Throws when the order status is invalid or the signer is not valid.
      */
    function assertTakeOrder(
        bytes32 orderHash,
        uint8 status,
        address signer,
        bytes memory signature
    )
        internal
        pure
        returns(uint8)
    {
        uint8 result = uint8(OrderStatus.FILLABLE);

        if(recover(orderHash, signature) != signer) {
            result = uint8(OrderStatus.INVALID_SIGNER);
        }

        if(status != uint8(OrderStatus.FILLABLE)) {
            result = status;
        }

        return status;
    }

    /**
      * @dev Updates the contract state i.e. user balances
      */
    function executeTrade(
        Order memory order,
        OrderFill memory orderFill
    )
        private
    {
        uint256 makerGiveAmount = orderFill.takerFillAmount.sub(orderFill.makerFeeReceived);
        uint256 takerFillAmount = orderFill.takerFillAmount.sub(orderFill.takerFeePaid);

        address referrer = referrals[order.taker];
        address feeAddress = feeAccount;

        balances[order.makerSellToken][referrer] = balances[order.makerSellToken][referrer].add(orderFill.referralFeeReceived);
        balances[order.makerSellToken][feeAddress] = balances[order.makerSellToken][feeAddress].add(orderFill.exchangeFeeReceived);

        balances[order.makerBuyToken][order.taker] = balances[order.makerBuyToken][order.taker].sub(orderFill.makerFillAmount);
        balances[order.makerBuyToken][order.maker] = balances[order.makerBuyToken][order.maker].add(orderFill.makerFillAmount);

        balances[order.makerSellToken][order.taker] = balances[order.makerSellToken][order.taker].add(takerFillAmount);
        balances[order.makerSellToken][order.maker] = balances[order.makerSellToken][order.maker].sub(makerGiveAmount);
    }
}




contract ExchangeKyberProxy is Exchange, LibKyberData {
    using SafeERC20 for IERC20;

    /**
      * @dev The precision used for calculating the amounts - 10*18
      */
    uint256 constant internal PRECISION = 1000000000000000000;

    /**
      * @dev Max decimals allowed when calculating amounts.
      */
    uint256 constant internal MAX_DECIMALS = 18;

    /**
      * @dev Decimals of Ether.
      */
    uint256 constant internal ETH_DECIMALS = 18;

    /**
      * @dev The address that represents ETH in Kyber Network Contracts.
      */
    address constant internal KYBER_ETH_TOKEN_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    uint256 constant internal MAX_DEST_AMOUNT = 2**256 - 1;

    /**
      * @dev KyberNetworkProxy contract address
      */
    IKyberNetworkProxy constant internal kyberNetworkContract =
        IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    /**
      * @dev Swaps ETH/TOKEN, TOKEN/ETH or TOKEN/TOKEN using KyberNetwork reserves.
      */
    function kyberSwap(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        bytes32 hash
    )
        public
        payable
    {
        address taker = msg.sender;

        KyberData memory kyberData = getSwapInfo(
            givenAmount,
            givenToken,
            receivedToken,
            taker
        );

        uint256 convertedAmount = kyberNetworkContract.trade.value(kyberData.value)(
            kyberData.givenToken,
            givenAmount,
            kyberData.receivedToken,
            taker,
            MAX_DEST_AMOUNT,
            kyberData.rate,
            feeAccount
        );

        emit Trade(
            address(kyberNetworkContract),
            taker,
            hash,
            givenToken,
            receivedToken,
            givenAmount,
            convertedAmount,
            0,
            0,
            0
        );
    }

    /**
      * @dev Exchange ETH/TOKEN, TOKEN/ETH or TOKEN/TOKEN using the internal
      * balance mapping that keeps track of user&#39;s balances. It requires user to first invoke deposit function.
      * The function relies on KyberNetworkProxy contract.
      */
    function kyberTrade(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        bytes32 hash
    )
        public
    {
        address taker = msg.sender;

        KyberData memory kyberData = getTradeInfo(
            givenAmount,
            givenToken,
            receivedToken
        );

        balances[givenToken][taker] = balances[givenToken][taker].sub(givenAmount);

        uint256 convertedAmount = kyberNetworkContract.trade.value(kyberData.value)(
            kyberData.givenToken,
            givenAmount,
            kyberData.receivedToken,
            address(this),
            MAX_DEST_AMOUNT,
            kyberData.rate,
            feeAccount
        );

        balances[receivedToken][taker] = balances[receivedToken][taker].add(convertedAmount);

        emit Trade(
            address(kyberNetworkContract),
            taker,
            hash,
            givenToken,
            receivedToken,
            givenAmount,
            convertedAmount,
            0,
            0,
            0
        );
    }

    /**
      * @dev Helper function to determine what is being swapped.
      */
    function getSwapInfo(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        address taker
    )
        private
        returns(KyberData memory)
    {
        KyberData memory kyberData;
        uint256 givenTokenDecimals;
        uint256 receivedTokenDecimals;

        if(givenToken == address(0x0)) {
            require(msg.value == givenAmount, "INVALID_ETH_VALUE");

            kyberData.givenToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.receivedToken = receivedToken;
            kyberData.value = givenAmount;

            givenTokenDecimals = ETH_DECIMALS;
            receivedTokenDecimals = IERC20(receivedToken).decimals();
        } else if(receivedToken == address(0x0)) {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = ETH_DECIMALS;

            IERC20(givenToken).safeTransferFrom(taker, address(this), givenAmount);
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        } else {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = receivedToken;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = IERC20(receivedToken).decimals();

            IERC20(givenToken).safeTransferFrom(taker, address(this), givenAmount);
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        }

        (kyberData.rate, ) = kyberNetworkContract.getExpectedRate(
            kyberData.givenToken,
            kyberData.receivedToken,
            givenAmount
        );

        return kyberData;
    }

    /**
      * @dev Helper function to determines what is being
        swapped using the internal balance mapping.
      */
    function getTradeInfo(
        uint256 givenAmount,
        address givenToken,
        address receivedToken
    )
        private
        returns(KyberData memory)
    {
        KyberData memory kyberData;
        uint256 givenTokenDecimals;
        uint256 receivedTokenDecimals;

        if(givenToken == address(0x0)) {
            kyberData.givenToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.receivedToken = receivedToken;
            kyberData.value = givenAmount;

            givenTokenDecimals = ETH_DECIMALS;
            receivedTokenDecimals = IERC20(receivedToken).decimals();
        } else if(receivedToken == address(0x0)) {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = ETH_DECIMALS;
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        } else {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = receivedToken;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = IERC20(receivedToken).decimals();
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        }

        (kyberData.rate, ) = kyberNetworkContract.getExpectedRate(
            kyberData.givenToken,
            kyberData.receivedToken,
            givenAmount
        );

        return kyberData;
    }

    function getExpectedRateBatch(
        address[] memory givenTokens,
        address[] memory receivedTokens,
        uint256[] memory givenAmounts
    )
        public
        view
        returns(uint256[] memory, uint256[] memory)
    {
        uint256 size = givenTokens.length;
        uint256[] memory expectedRates = new uint256[](size);
        uint256[] memory slippageRates = new uint256[](size);

        for(uint256 index = 0; index < size; index++) {
            (expectedRates[index], slippageRates[index]) = kyberNetworkContract.getExpectedRate(
                givenTokens[index],
                receivedTokens[index],
                givenAmounts[index]
            );
        }

       return (expectedRates, slippageRates);
    }
}




contract ExchangeBatchTrade is Exchange {

    /**
      * @dev Cancel an array of orders if msg.sender is the order signer.
      */
    function cancelMultipleOrders(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            cancelSingleOrder(
                orders[index],
                signatures[index]
            );
        }
    }

    /**
      * @dev Execute multiple trades based on the input orders and signatures.
      * Note: reverts of one or more trades fail.
      */
    function takeAllOrRevert(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            bool result = _trade(orders[index], signatures[index]);
            require(result, "INVALID_TAKEALL");
        }
    }

    /**
      * @dev Execute multiple trades based on the input orders and signatures.
      * Note: does not revert if one or more trades fail.
      */
    function takeAllPossible(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            _trade(orders[index], signatures[index]);
        }
    }
}




contract ExchangeMovements is ExchangeStorage {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
      * @dev emitted when a deposit is received
      */
    event Deposit(
        address indexed token,
        address indexed user,
        address indexed referral,
        address beneficiary,
        uint256 amount,
        uint256 balance
    );

    /**
      * @dev emitted when a withdraw is received
      */
    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

    /**
      * @dev emitted when a transfer is received
      */
    event Transfer(
        address indexed token,
        address indexed user,
        address indexed beneficiary,
        uint256 amount,
        uint256 userBalance,
        uint256 beneficiaryBalance
    );

    /**
      * @dev Updates the level 2 map `balances` based on the input
      *      Note: token address is (0x0) when the deposit is for ETH
      */
    function deposit(
        address token,
        uint256 amount,
        address beneficiary,
        address referral
    )
        public
        payable
    {
        uint256 value = amount;
        address user = msg.sender;

        if(token == address(0x0)) {
            value = msg.value;
        } else {
            IERC20(token).safeTransferFrom(user, address(this), value);
        }

        balances[token][beneficiary] = balances[token][beneficiary].add(value);

        if(referrals[user] == address(0x0)) {
            referrals[user] = referral;
        }

        emit Deposit(
            token,
            user,
            referrals[user],
            beneficiary,
            value,
            balances[token][beneficiary]
        );
    }

    /**
      * @dev Updates the level 2 map `balances` based on the input
      *      Note: token address is (0x0) when the deposit is for ETH
      */
    function withdraw(
        address token,
        uint amount
    )
        public
    {
        address payable user = msg.sender;

        require(
            balances[token][user] >= amount,
            "INVALID_WITHDRAW"
        );

        balances[token][user] = balances[token][user].sub(amount);

        if (token == address(0x0)) {
            user.transfer(amount);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }

        emit Withdraw(
            token,
            user,
            amount,
            balances[token][user]
        );
    }

    /**
      * @dev Transfer assets between two users inside the exchange. Updates the level 2 map `balances`
      */
    function transfer(
        address token,
        address to,
        uint256 amount
    )
        external
        payable
    {
        address user = msg.sender;

        require(
            balances[token][user] >= amount,
            "INVALID_TRANSFER"
        );

        balances[token][user] = balances[token][user].sub(amount);

        balances[token][to] = balances[token][to].add(amount);

        emit Transfer(
            token,
            user,
            to,
            amount,
            balances[token][user],
            balances[token][to]
        );
    }
}




contract ExchangeUpgradability is Ownable, ExchangeStorage {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
      * @dev version of the exchange
      */
    uint8 constant public VERSION = 1;

    /**
      * @dev the address of the upgraded exchange contract
      */
    address public newExchange;

    /**
      * @dev flag to allow migrating to an upgraded contract
      */
    bool public migrationAllowed;

    /**
      * @dev emitted when funds are migrated
      */
    event FundsMigrated(address indexed user, address indexed newExchange);

    /**
    * @dev Owner can set the address of the new version of the exchange contract.
    */
    function setNewExchangeAddress(address exchange)
        external
        onlyOwner
    {
        newExchange = exchange;
    }

    /**
    * @dev Enables/Disables the migrations. Can be called only by the owner.
    */
    function allowOrRestrictMigrations()
        external
        onlyOwner
    {
        migrationAllowed = !migrationAllowed;
    }

    /**
    * @dev Migrating assets of the caller to the new exchange contract
    */
    function migrateFunds(address[] calldata tokens) external {

        require(
            false != migrationAllowed,
            "MIGRATIONS_DISALLOWED"
        );

        require(
            IExchangeUpgradability(newExchange).VERSION() > VERSION,
            "INVALID_VERSION"
        );

        migrateEthers();

        migrateTokens(tokens);

        emit FundsMigrated(msg.sender, newExchange);
    }

    /**
    * @dev Helper function to migrate user&#39;s Ethers. Should be called in migrateFunds() function.
    */
    function migrateEthers() private {
        address user = msg.sender;
        uint256 etherAmount = balances[address(0x0)][user];
        if (etherAmount > 0) {
            balances[address(0x0)][user] = 0;
            IExchangeUpgradability(newExchange).importEthers.value(etherAmount)(user);
        }
    }

    /**
    * @dev Helper function to migrate user&#39;s tokens. Should be called in migrateFunds() function.
    */
    function migrateTokens(address[] memory tokens) private {
        address user = msg.sender;
        address exchange = newExchange;
        for (uint256 index = 0; index < tokens.length; index++) {

            address tokenAddress = tokens[index];

            uint256 tokenAmount = balances[tokenAddress][user];

            if (0 == tokenAmount) {
                continue;
            }

            IERC20(tokenAddress).safeApprove(exchange, tokenAmount);

            balances[tokenAddress][user] = 0;

            IExchangeUpgradability(exchange).importTokens(tokenAddress, tokenAmount, user);
        }
    }

    /**
    * @dev Helper function to migrate user&#39;s Ethers. Should be called only from the new exchange contract.
    */
    function importEthers(address user)
        external
        payable
    {
        require(
            false != migrationAllowed,
            "MIGRATION_DISALLOWED"
        );

        require(
            user != address(0x0),
            "INVALID_USER"
        );

        require(
            msg.value > 0,
            "INVALID_AMOUNT"
        );

        require(
            IExchangeUpgradability(msg.sender).VERSION() < VERSION,
            "INVALID_VERSION"
        );

        balances[address(0x0)][user] = balances[address(0x0)][user].add(msg.value); // todo: constants
    }
    
    /**
    * @dev Helper function to migrate user&#39;s Tokens. Should be called only from the new exchange contract.
    */
    function importTokens(
        address token,
        uint256 amount,
        address user
    )
        external
    {
        require(
            false != migrationAllowed,
            "MIGRATION_DISALLOWED"
        );

        require(
            token != address(0x0),
            "INVALID_TOKEN"
        );

        require(
            user != address(0x0),
            "INVALID_USER"
        );

        require(
            amount > 0,
            "INVALID_AMOUNT"
        );

        require(
            IExchangeUpgradability(msg.sender).VERSION() < VERSION,
            "INVALID_VERSION"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        balances[token][user] = balances[token][user].add(amount);
    }
}




contract ExchangeOffering is ExchangeStorage, LibCrowdsale {

    address constant internal BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address constant internal ETH_ADDRESS = address(0x0);

    using SafeERC20 for IERC20;

    using SafeMath for uint256;

    mapping(address => Crowdsale) public crowdsales;

    mapping(address => mapping(address => uint256)) public contributions;

    event TokenPurchase(
        address indexed token,
        address indexed user,
        uint256 tokenAmount,
        uint256 weiAmount
    );

    event TokenBurned(
        address indexed token,
        uint256 tokenAmount
    );

    function registerCrowdsale(
        Crowdsale memory crowdsale,
        address token
    )
        public
        onlyOwner
    {
        require(
            CrowdsaleStatus.VALID == getCrowdsaleStatus(crowdsale),
            "INVALID_CROWDSALE"
        );

        require(
            crowdsales[token].wallet == address(0),
            "CROWDSALE_ALREADY_EXISTS"
        );

        uint256 tokenForSale = crowdsale.hardCap.mul(crowdsale.tokenRatio);

        IERC20(token).safeTransferFrom(crowdsale.wallet, address(this), tokenForSale);

        crowdsales[token] = crowdsale;
    }

    function buyTokens(address token)
       public
       payable
    {
        require(msg.value != 0, "INVALID_MSG_VALUE");

        uint256 weiAmount = msg.value;

        address user = msg.sender;

        Crowdsale memory crowdsale = crowdsales[token];

        require(
            ContributionStatus.VALID == validContribution(weiAmount, crowdsale, user, token),
            "INVALID_CONTRIBUTION"
        );

        uint256 purchasedTokens = weiAmount.mul(crowdsale.tokenRatio);

        crowdsale.leftAmount = crowdsale.leftAmount.sub(purchasedTokens);

        crowdsale.weiRaised = crowdsale.weiRaised.add(weiAmount);

        balances[ETH_ADDRESS][crowdsale.wallet] = balances[ETH_ADDRESS][crowdsale.wallet].add(weiAmount);

        balances[token][user] = balances[token][user].add(purchasedTokens);

        contributions[token][user] = contributions[token][user].add(weiAmount);

        crowdsales[token] = crowdsale;

        emit TokenPurchase(token, user, purchasedTokens, weiAmount);
    }

    function burnTokensWhenFinished(address token) public
    {
        require(
            isFinished(crowdsales[token].endBlock),
            "CROWDSALE_NOT_FINISHED_YET"
        );

        uint256 leftAmount = crowdsales[token].leftAmount;

        crowdsales[token].leftAmount = 0;

        IERC20(token).safeTransfer(BURN_ADDRESS, leftAmount);

        emit TokenBurned(token, leftAmount);
    }

    function validContribution(
        uint256 weiAmount,
        Crowdsale memory crowdsale,
        address user,
        address token
    )
        public
        view
        returns(ContributionStatus)
    {
        if (!isOpened(crowdsale.startBlock, crowdsale.endBlock)) {
            return ContributionStatus.CROWDSALE_NOT_OPEN;
        }

        if(weiAmount < crowdsale.minContribution) {
            return ContributionStatus.MIN_CONTRIBUTION;
        }

        if (contributions[token][user].add(weiAmount) > crowdsale.maxContribution) {
            return ContributionStatus.MAX_CONTRIBUTION;
        }

        if (crowdsale.hardCap < crowdsale.weiRaised.add(weiAmount)) {
            return ContributionStatus.HARDCAP_REACHED;
        }

        return ContributionStatus.VALID;
    }
}




contract ExchangeSwap is Exchange, ExchangeMovements  {

    /**
      * @dev Swaps ETH/TOKEN, TOKEN/ETH or TOKEN/TOKEN using off-chain signed messages.
      * The flow of the function is Deposit -> Trade -> Withdraw to allow users to directly
      * take liquidity without the need of deposit and withdraw.
      */
    function swapFill(
        Order[] memory orders,
        bytes[] memory signatures,
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        address referral
    )
        public
        payable
    {
        address taker = msg.sender;

        uint256 balanceGivenBefore = balances[givenToken][taker];
        uint256 balanceReceivedBefore = balances[receivedToken][taker];

        deposit(givenToken, givenAmount, taker, referral);

        for (uint256 index = 0; index < orders.length; index++) {
            require(orders[index].makerBuyToken == givenToken, "GIVEN_TOKEN");
            require(orders[index].makerSellToken == receivedToken, "RECEIVED_TOKEN");

            _trade(orders[index], signatures[index]);
        }

        uint256 balanceGivenAfter = balances[givenToken][taker];
        uint256 balanceReceivedAfter = balances[receivedToken][taker];

        uint256 balanceGivenDelta = balanceGivenAfter.sub(balanceGivenBefore);
        uint256 balanceReceivedDelta = balanceReceivedAfter.sub(balanceReceivedBefore);

        if(balanceGivenDelta > 0) {
            withdraw(givenToken, balanceGivenDelta);
        }

        if(balanceReceivedDelta > 0) {
            withdraw(receivedToken, balanceReceivedDelta);
        }
    }
}




contract WeiDex is
    Exchange,
    ExchangeKyberProxy,
    ExchangeBatchTrade,
    ExchangeMovements,
    ExchangeUpgradability,
    ExchangeOffering,
    ExchangeSwap
{
    function () external payable { }
}