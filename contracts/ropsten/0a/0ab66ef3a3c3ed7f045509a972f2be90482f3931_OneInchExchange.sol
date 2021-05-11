/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-28
*/

pragma solidity ^0.5.0;



library ExternalCall {
    // Source: https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function externalCall(address destination, uint value, bytes memory data, uint dataOffset, uint dataLength, uint gasLimit) internal returns(bool result) {
        // solium-disable-next-line security/no-inline-assembly
        if (gasLimit == 0) {
            gasLimit = gasleft() - 40000;
        }
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gasLimit,
                destination,
                value,
                add(d, dataOffset),
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
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
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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


pragma experimental ABIEncoderV2;

contract IZrxExchange {

    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Amount of ZRX paid to feeRecipient by maker when order is filled. If set to 0, no transfer of ZRX from maker to feeRecipient will be attempted.
        uint256 takerFee;               // Amount of ZRX paid to feeRecipient by taker when order is filled. If set to 0, no transfer of ZRX from taker to feeRecipient will be attempted.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The last byte references the id of this proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The last byte references the id of this proxy.
    }

    struct OrderInfo {
        uint8 orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 hash of the order (see IZrxExchange.getOrderHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;  // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount;  // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid;            // Total amount of ZRX paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid;            // Total amount of ZRX paid by taker to feeRecipients(s).
    }

    function getOrderInfo(Order memory order)
        public
        view
        returns (OrderInfo memory orderInfo);

    function getOrdersInfo(Order[] memory orders)
        public
        view
        returns (OrderInfo[] memory ordersInfo);

    function fillOrder(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (FillResults memory fillResults);

    function fillOrderNoThrow(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (FillResults memory fillResults);
}


contract IGST2 is IERC20 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
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



contract IWETH is IERC20 {

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}



contract Shutdownable is Ownable {

    bool public isShutdown;

    event Shutdown();

    modifier notShutdown {
        require(!isShutdown, "Smart contract is shut down.");
        _;
    }

    function shutdown() public onlyOwner {
        isShutdown = true;
        emit Shutdown();
    }
}

contract IERC20NonView {
    // Methods are not view to avoid throw on proxy tokens with delegatecall inside
    function balanceOf(address user) public returns(uint256);
    function allowance(address from, address to) public returns(uint256);
}

contract ZrxMarketOrder {

    using SafeMath for uint256;

    function marketSellOrdersProportion(
        IERC20 tokenSell,
        address tokenBuy,
        address zrxExchange,
        address zrxTokenProxy,
        IZrxExchange.Order[] calldata orders,
        bytes[] calldata signatures,
        uint256 mul,
        uint256 div
    )
        external
    {
        uint256 amount = tokenSell.balanceOf(msg.sender).mul(mul).div(div);
        this.marketSellOrders(tokenBuy, zrxExchange, zrxTokenProxy, amount, orders, signatures);
    }

    function marketSellOrders(
        address makerAsset,
        address zrxExchange,
        address zrxTokenProxy,
        uint256 takerAssetFillAmount,
        IZrxExchange.Order[] calldata orders,
        bytes[] calldata signatures
    )
        external
        returns (IZrxExchange.FillResults memory totalFillResults)
    {
        for (uint i = 0; i < orders.length; i++) {

            // Stop execution if the entire amount of takerAsset has been sold
            if (totalFillResults.takerAssetFilledAmount >= takerAssetFillAmount) {
                break;
            }

            // Calculate the remaining amount of takerAsset to sell
            uint256 remainingTakerAmount = takerAssetFillAmount.sub(totalFillResults.takerAssetFilledAmount);

            IZrxExchange.OrderInfo memory orderInfo = IZrxExchange(zrxExchange).getOrderInfo(orders[i]);
            uint256 orderRemainingTakerAmount = orders[i].takerAssetAmount.sub(orderInfo.orderTakerAssetFilledAmount);

            // Check available balance and allowance and update orderRemainingTakerAmount
            {
                uint256 balance = IERC20NonView(makerAsset).balanceOf(orders[i].makerAddress);
                uint256 allowance = IERC20NonView(makerAsset).allowance(orders[i].makerAddress, zrxTokenProxy);
                uint256 availableMakerAmount = (allowance < balance) ? allowance : balance;
                uint256 availableTakerAmount = availableMakerAmount.mul(orders[i].takerAssetAmount).div(orders[i].makerAssetAmount);

                if (availableTakerAmount < orderRemainingTakerAmount) {
                    orderRemainingTakerAmount = availableTakerAmount;
                }
            }

            uint256 takerAmount = (orderRemainingTakerAmount < remainingTakerAmount) ? orderRemainingTakerAmount : remainingTakerAmount;

            IZrxExchange.FillResults memory fillResults = IZrxExchange(zrxExchange).fillOrderNoThrow(
                orders[i],
                takerAmount,
                signatures[i]
            );

            _addFillResults(totalFillResults, fillResults);
        }

        return totalFillResults;
    }

    function _addFillResults(
        IZrxExchange.FillResults memory totalFillResults,
        IZrxExchange.FillResults memory singleFillResults
    )
        internal
        pure
    {
        totalFillResults.makerAssetFilledAmount = totalFillResults.makerAssetFilledAmount.add(singleFillResults.makerAssetFilledAmount);
        totalFillResults.takerAssetFilledAmount = totalFillResults.takerAssetFilledAmount.add(singleFillResults.takerAssetFilledAmount);
        totalFillResults.makerFeePaid = totalFillResults.makerFeePaid.add(singleFillResults.makerFeePaid);
        totalFillResults.takerFeePaid = totalFillResults.takerFeePaid.add(singleFillResults.takerFeePaid);
    }

    function getOrdersInfoRespectingBalancesAndAllowances(
        IERC20 token,
        IZrxExchange zrx,
        address zrxTokenProxy,
        IZrxExchange.Order[] memory orders
    )
        public
        view
        returns (IZrxExchange.OrderInfo[] memory ordersInfo)
    {
        ordersInfo = zrx.getOrdersInfo(orders);

        for (uint i = 0; i < ordersInfo.length; i++) {

            uint256 balance = token.balanceOf(orders[i].makerAddress);
            uint256 allowance = token.allowance(orders[i].makerAddress, zrxTokenProxy);
            uint256 availableMakerAmount = (allowance < balance) ? allowance : balance;
            uint256 availableTakerAmount = availableMakerAmount.mul(orders[i].takerAssetAmount).div(orders[i].makerAssetAmount);

            for (uint j = 0; j < i; j++) {

                if (orders[j].makerAddress == orders[i].makerAddress) {

                    uint256 orderTakerAssetRemainigAmount = orders[j].takerAssetAmount.sub(
                        ordersInfo[j].orderTakerAssetFilledAmount
                    );

                    if (availableTakerAmount > orderTakerAssetRemainigAmount) {

                        availableTakerAmount = availableTakerAmount.sub(orderTakerAssetRemainigAmount);
                    } else {

                        availableTakerAmount = 0;
                        break;
                    }
                }
            }

            uint256 remainingTakerAmount = orders[i].takerAssetAmount.sub(
                ordersInfo[i].orderTakerAssetFilledAmount
            );

            if (availableTakerAmount < remainingTakerAmount) {

                ordersInfo[i].orderTakerAssetFilledAmount = orders[i].takerAssetAmount.sub(availableTakerAmount);
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
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

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





library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IERC20 token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}



contract TokenSpender {

    using SafeERC20 for IERC20;

    address public owner;
    IGST2 public gasToken;
    address public gasTokenOwner;

    constructor(IGST2 _gasToken, address _gasTokenOwner) public {
        owner = msg.sender;
        gasToken = _gasToken;
        gasTokenOwner = _gasTokenOwner;
    }

    function claimTokens(IERC20 token, address who, address dest, uint256 amount) external {
        require(msg.sender == owner, "Access restricted");
        token.safeTransferFrom(who, dest, amount);
    }

    function burnGasToken(uint gasSpent) external {
        require(msg.sender == owner, "Access restricted");
        uint256 tokens = (gasSpent + 14154) / 41130;
        gasToken.freeUpTo(tokens);
    }

    function() external {
        if (msg.sender == gasTokenOwner) {
            gasToken.transfer(msg.sender, gasToken.balanceOf(address(this)));
        }
    }
}

contract OneInchExchange is Shutdownable, ZrxMarketOrder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using ExternalCall for address;

    IERC20 constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    TokenSpender public spender;
    uint fee; // 10000 => 100%, 1 => 0.01%

    event History(
        address indexed sender,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    event Swapped(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        address indexed referrer,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 referrerFee,
        uint256 fee
    );

    constructor(address _owner, IGST2 _gasToken, uint _fee) public {
        spender = new TokenSpender(
            _gasToken,
            _owner
        );

        _transferOwnership(_owner);
        fee = _fee;
    }

    function() external payable notShutdown {
        require(msg.sender != tx.origin);
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] memory callAddresses,
        bytes memory callDataConcat,
        uint256[] memory starts,
        uint256[] memory gasLimitsAndValues
    )
    public
    payable
    notShutdown
    returns (uint256 returnAmount)
    {
        uint256 gasProvided = gasleft();

        require(minReturnAmount > 0, "Min return should be bigger then 0.");
        require(callAddresses.length > 0, "Call data should exists.");

        if (fromToken != ETH_ADDRESS) {
            spender.claimTokens(fromToken, msg.sender, address(this), fromTokenAmount);
        }

        for (uint i = 0; i < callAddresses.length; i++) {
            require(callAddresses[i] != address(spender), "Access denied");
            require(callAddresses[i].externalCall(
                gasLimitsAndValues[i] & ((1 << 128) - 1),
                callDataConcat,
                starts[i],
                starts[i + 1] - starts[i],
                gasLimitsAndValues[i] >> 128
            ));
        }

        // Return back all unswapped
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));

        returnAmount = toToken.universalBalanceOf(address(this));
        (uint256 toTokenAmount, uint256 referrerFee) = _handleFees(toToken, referrer, returnAmount, guaranteedAmount);

        require(toTokenAmount >= minReturnAmount, "Return amount is not enough");
        toToken.universalTransfer(msg.sender, toTokenAmount);

        emit History(
            msg.sender,
            fromToken,
            toToken,
            fromTokenAmount,
            toTokenAmount
        );

        emit Swapped(
            fromToken,
            toToken,
            referrer,
            fromTokenAmount,
            toTokenAmount,
            referrerFee,
            returnAmount.sub(toTokenAmount)
        );

        spender.burnGasToken(gasProvided.sub(gasleft()));
    }

    function _handleFees(
        IERC20 toToken,
        address referrer,
        uint256 returnAmount,
        uint256 guaranteedAmount
    )
    internal
    returns (
        uint256 toTokenAmount,
        uint256 referrerFee
    )
    {
        if (returnAmount <= guaranteedAmount) {
            return (returnAmount, 0);
        }

        uint256 feeAmount = returnAmount.sub(guaranteedAmount).mul(fee).div(10000);

        if (referrer != address(0) && referrer != msg.sender && referrer != tx.origin) {
            referrerFee = feeAmount.div(10);
            if (toToken.universalTransfer(referrer, referrerFee, true)) {
                returnAmount = returnAmount.sub(referrerFee);
                feeAmount = feeAmount.sub(referrerFee);
            } else {
                referrerFee = 0;
            }
        }

        if (toToken.universalTransfer(owner(), feeAmount, true)) {
            returnAmount = returnAmount.sub(feeAmount);
        }

        return (returnAmount, referrerFee);
    }

    function infiniteApproveIfNeeded(IERC20 token, address to) external notShutdown {
        if (token != ETH_ADDRESS) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }

    function withdrawAllToken(IWETH token) external notShutdown {
        uint256 amount = token.balanceOf(address(this));
        token.withdraw(amount);
    }
}