/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require((value == 0) || (token.allowance(address(this), spender) == 0));
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
     * on the return value: the return value is optional (but if data is returned, it must equal true).
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

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title AssetsValue
 * @dev The contract which hold all tokens and ETH as a assets
 * Also should be responsible for the balance increasing/decreasing and validation
 */
contract AssetsValue {
    // using safe math calculation
    using SafeMath for uint256;

    // for being secure during transactions between users and contract gonna use SafeERC20 lib
    using SafeERC20 for IERC20;

    // The id for ETH asset is 0x0 address
    // the rest assets should have their token contract address
    address internal _ethAssetIdentificator = address(0);

    // Order details which is available by JAVA long number
    struct OrderDetails {
        // does the order has been deposited
        bool created;
        // the 0x0 for Ethereum and ERC contract address for tokens
        address asset;
        // tokens/eth amount
        uint256 amount;
    }

    // Each user has his own state and details
    struct User {
        // user exist validation bool
        bool exist;
        // contract order index
        uint256 index;
        // contract index (0, 1, 2 ...) => exchange order number (JAVA long number)
        mapping(uint256 => uint256) orderIdByIndex;
        // JAVA long number => order details
        mapping(uint256 => OrderDetails) orders;
    }

    // ETH wallet => Assets => value
    mapping(address => User) private _users;

    modifier orderIdNotExist(
        uint256 orderId,
        address user
    ) {
        require(_users[user].orders[orderId].created == false, "orderIdIsNotDeposited: user already deposit this orderId");
        _;
    }

    // Events
    event AssetDeposited(uint256 orderId, address indexed user, address indexed asset, uint256 amount);
    event AssetWithdrawal(uint256 orderId, address indexed user, address indexed asset, uint256 amount);

    // -----------------------------------------
    // EXTERNAL
    // -----------------------------------------

    function deposit(
        uint256 orderId
    ) public orderIdNotExist(orderId, msg.sender) payable {
        require(msg.value != 0, "deposit: user needs to transfer ETH for calling this method");

        _deposit(orderId, msg.sender, _ethAssetIdentificator, msg.value);
    }

    function deposit(
        uint256 orderId,
        uint256 amount,
        address token
    ) public orderIdNotExist(orderId, msg.sender) {
        require(token != address(0), "deposit: invalid token address");
        require(amount != 0, "deposit: user needs to fill transferable tokens amount for calling this method");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(orderId, msg.sender, token, amount);
    }

    function withdraw(
        uint256 orderId
    ) external {
        // validation of the user existion
        require(_doesUserExist(msg.sender) == true, "withdraw: the user is not active");

        // storing the order information (asset and amount)
        OrderDetails memory order = _getDepositedOrderDetails(orderId, msg.sender);
        address asset = order.asset;
        uint256 amount = order.amount;

        // order amount validation, it should not be zero
        require(amount != 0, "withdraw: this order Id has been finished or waiting for the redeem");

        _withdrawOrderBalance(orderId, msg.sender);

        if (asset == _ethAssetIdentificator) {
            msg.sender.transfer(amount);
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }

        emit AssetWithdrawal(orderId, msg.sender, asset, amount);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    function _deposit(
        uint256 orderId,
        address sender,
        address asset,
        uint256 amount
    ) internal {
        _activateIfUserIsNew(sender);
        _depositOrderBalance(orderId, sender, asset, amount);

        emit AssetDeposited(orderId, sender, asset, amount);
    }

    function _doesUserExist(
        address user
    ) internal view returns (bool) {
        return _users[user].exist;
    }

    function _activateIfUserIsNew(
        address user
    ) internal returns (bool) {
        if (_doesUserExist(user) == false) {
            _users[user].exist = true;
        }
        return true;
    }

    function _getDepositedOrderDetails(
        uint256 orderId,
        address user
    ) internal view returns (OrderDetails memory order) {
        return _users[user].orders[orderId];
    }

    function _depositOrderBalance(
        uint256 orderId,
        address user,
        address asset,
        uint256 amount
    ) internal returns (bool) {
        User storage u = _users[user];
        u.orderIdByIndex[u.index] = orderId;
        u.orders[orderId] = OrderDetails(true, asset, amount);
        u.index += 1;
        return true;
    }

    function _withdrawOrderBalance(
        uint256 orderId,
        address user
    ) internal returns (bool) {
        _users[user].orders[orderId].amount = 0;
        return true;
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    function doesUserExist(
        address user
    ) external view returns (bool) {
        return _doesUserExist(user);
    }

    function getUserDepositsAmount(
        address user
    ) external view returns (
        uint256
    ) {
        return _users[user].index;
    }

    function getDepositedOrderDetails(
        uint256 orderId,
        address user
    ) external view returns (
        bool created,
        address asset,
        uint256 amount
    ) {
        OrderDetails memory order = _getDepositedOrderDetails(orderId, user);
        return (
            order.created,
            order.asset,
            order.amount
        );
    }
}

/**
 * @title CrossBlockchainSwap
 * @dev Fully autonomous cross-blockchain swapping smart contract
 */
contract CrossBlockchainSwap is AssetsValue, Ownable {
    // swaps&#39; state
    enum State { Empty, Filled, Redeemed, Refunded }

    // users can swap ETH and ERC tokens
    enum SwapType { ETH, Token }

    // the body of each swap
    struct Swap {
        uint256 initTimestamp;
        uint256 refundTimestamp;
        bytes32 secretHash;
        bytes32 secret;
        address initiator;
        address recipient;
        address asset;
        uint256 amount;
        State state;
    }

    // mapping of swaps based on secret hash and swap info
    mapping(bytes32 => Swap) private _swaps;

    // min/max life limits for swap order
    // can be changed only by the contract owner
    struct SwapTimeLimits {
        uint256 min;
        uint256 max;
    }

    // By default, the contract has limits for swap orders lifetime
    // The swap order can be active from 10 minutes until 6 months
    SwapTimeLimits private _swapTimeLimits = SwapTimeLimits(10 minutes, 180 days);

    // -----------------------------------------
    // EVENTS
    // -----------------------------------------

    event Initiated(
        uint256 orderId,
        bytes32 secretHash,
        address indexed initiator,
        address indexed recipient,
        uint256 initTimestamp,
        uint256 refundTimestamp,
        address indexed asset,
        uint256 amount
    );

    event Redeemed(
        bytes32 secretHash,
        uint256 redeemTimestamp,
        bytes32 secret,
        address indexed redeemer
    );

    event Refunded(
        uint256 orderId,
        bytes32 secretHash,
        uint256 refundTime,
        address indexed refunder
    );

    // -----------------------------------------
    // MODIFIERS
    // -----------------------------------------

    modifier isNotInitiated(bytes32 secretHash) {
        require(_swaps[secretHash].state == State.Empty, "isNotInitiated: this secret hash was already used, please use another one");
        _;
    }

    modifier isRedeemable(bytes32 secret) {
        bytes32 secretHash = _hashTheSecret(secret);
        require(_swaps[secretHash].state == State.Filled, "isRedeemable: the swap with this secretHash does not exist or has been finished");
        uint256 refundTimestamp = _swaps[secretHash].refundTimestamp;
        require(refundTimestamp > block.timestamp, "isRedeemable: the redeem is closed for this swap");
        _;
    }

    modifier isRefundable(bytes32 secretHash, address refunder) {
        require(_swaps[secretHash].state == State.Filled, "isRefundable: the swap with this secretHash does not exist or has been finished");
        require(_swaps[secretHash].initiator == refunder, "isRefundable: only the initiator of the swap can call this method");
        uint256 refundTimestamp = _swaps[secretHash].refundTimestamp;
        require(block.timestamp >= refundTimestamp, "isRefundable: the refund is not available now");
        _;
    }

    // -----------------------------------------
    // FALLBACK
    // -----------------------------------------

    function () external payable {
        // reverts all fallback & payable transactions
        revert();
    }

    // -----------------------------------------
    // EXTERNAL
    // -----------------------------------------

    /**
     *  @dev If user wants to swap ERC token, before initiating the swap between that
     *  initiator need to call approve method from his tokens&#39; smart contract,
     *  approving to it to spend the value1 amount of tokens
     *  @param secretHash the encoded secret which they discussed at offline (SHA256)
     *  @param refundTimestamp the period when the swap should be active
     *  it should be written in MINUTES
     */
    function initiate(
        uint256 orderId,
        bytes32 secretHash,
        address recipient,
        uint256 refundTimestamp
    ) public isNotInitiated(secretHash) {
        // validation that refund Timestamp more than exchange min limit and less then max limit
        _validateRefundTimestamp(refundTimestamp * 1 minutes);

        OrderDetails memory order = _getDepositedOrderDetails(orderId, msg.sender);

        // validation of the deposited order existing and non-zero amount 
        require(order.created == true, "initiate: this order Id has not been created and deposited yet");
        require(order.amount != 0, "initiate: this order Id has been finished or waiting for the redeem");

        // withdrawing the balance of this orderId from sender deposites
        _withdrawOrderBalance(orderId, msg.sender);

        // swap asset details
        _swaps[secretHash].asset = order.asset;
        _swaps[secretHash].amount = order.amount;

        // swap status
        _swaps[secretHash].state = State.Filled;

        // swap clients
        _swaps[secretHash].initiator = msg.sender;
        _swaps[secretHash].recipient = recipient;
        _swaps[secretHash].secretHash = secretHash;

        // swap timestapms
        _swaps[secretHash].initTimestamp = block.timestamp;
        _swaps[secretHash].refundTimestamp = block.timestamp + (refundTimestamp * 1 minutes);

        emit Initiated(
            orderId,
            secretHash,
            msg.sender,
            recipient,
            block.timestamp,
            refundTimestamp,
            order.asset,
            order.amount
        );
    }

    /**
     *  @dev Deposit and initiate swap for ETH
     *  It includes deposit and initiate methods
     */
    function depositAndInitiate(
        uint256 orderId,
        bytes32 secretHash,
        address recipient,
        uint256 refundTimestamp
    ) external payable {
        deposit(orderId);
        initiate(orderId, secretHash, recipient, refundTimestamp);
    }

    /**
     *  @dev Deposit and initiate swap for ERC20 tokens
     *  It includes deposit and initiate methods
     */
    function depositAndInitiate(
        uint256 orderId,
        uint256 amount,
        address token,
        bytes32 secretHash,
        address recipient,
        uint256 refundTimestamp
    ) external {
        deposit(orderId, amount, token);
        initiate(orderId, secretHash, recipient, refundTimestamp);
    }

    /**
     *  @dev The participant of swap, who has the secret word and the secret hash can call this method
     *  and receive assets from contract.
     *  @param secret which both sides discussed before initialization
     */
    function redeem(
        bytes32 secret
    ) external isRedeemable(secret) {
        // storing the secret hash generated from secret
        bytes32 secretHash = _hashTheSecret(secret);

        // closing the state of this swap order
        _swaps[secretHash].state = State.Redeemed;

        // storing the recipient address
        address recipient = _swaps[secretHash].recipient;

        if (_getSwapType(secretHash) == SwapType.ETH) {
            // converting recipient address to payable address
            address payable payableReceiver = address(uint160(recipient));
            // transfer ETH to recipient wallet
            payableReceiver.transfer(_swaps[secretHash].amount);
        } else {
            // transfer tokens to recipient address
            IERC20(_swaps[secretHash].asset).safeTransfer(recipient, _swaps[secretHash].amount);
        }

        // saving the secret
        _swaps[secretHash].secret = secret;

        emit Redeemed (
            secretHash,
            block.timestamp,
            secret,
            recipient
        );
    }

    /**
     *  @dev The initiator can get back his tokens until refundTimestamp comes,
     *  after that both sides cannot do anything with this swap
     *  @param secretHash the encoded secret which they discussed at offline (SHA256)
     */
    function refund(
        uint256 orderId,
        bytes32 secretHash
    ) public isRefundable(secretHash, msg.sender) {
        _swaps[secretHash].state = State.Refunded;
        _depositOrderBalance(orderId, msg.sender, _swaps[secretHash].asset, _swaps[secretHash].amount);

        emit Refunded(
            orderId,
            secretHash,
            block.timestamp,
            msg.sender
        );
    }

    /**
     *  @dev The owner can change time limits for swap lifetime
     *  Amounts should be written in MINUTES
     */
    function changeSwapLifetimeLimits(
        uint256 newMin,
        uint256 newMax
    ) external onlyOwner {
        require(newMin != 0, "changeSwapLifetimeLimits: newMin and newMax should be bigger then 0");
        require(newMax >= newMin, "changeSwapLifetimeLimits: the newMax should be bigger then newMax");

        _swapTimeLimits = SwapTimeLimits(newMin * 1 minutes, newMax * 1 minutes);
    }

    // -----------------------------------------
    // INTERNAL
    // -----------------------------------------

    /**
     *  @dev Validating the period time of swap
     * It should be equal/bigger than 10 minutes and equal/less than 180 days
     */
    function _validateRefundTimestamp(
        uint256 refundTimestamp
    ) private view {
        require(refundTimestamp >= _swapTimeLimits.min, "_validateRefundTimestamp: the timestamp should be bigger than min swap lifetime");
        require(_swapTimeLimits.max >= refundTimestamp, "_validateRefundTimestamp: the timestamp should be smaller than max swap lifetime");
    }

    function _hashTheSecret(
        bytes32 secret
    ) private pure returns (bytes32) {
        return sha256(abi.encodePacked(secret));
    }

    function _getSwapType(
        bytes32 secretHash
    ) private view returns (SwapType tp) {
        if (_swaps[secretHash].asset == _ethAssetIdentificator) {
            return SwapType.ETH;
        } else {
            return SwapType.Token;
        }
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    /**
     *  @dev Get limits of a lifetime for swap in minutes
     *  @return min lifetime
     *  @return max lifetime
     */
    function getSwapLifetimeLimits() public view returns (uint256, uint256) {
        return (
            _swapTimeLimits.min,
            _swapTimeLimits.max
        );
    }

    /**
     *  @dev Identification of the swap type with assets and value fields
     *  @param secretHash the encoded secret which they discussed at offline (SHA256)
     *  @return tp (type) of swap
     */
    function getSwapType(
        bytes32 secretHash
    ) public view returns (SwapType tp) {
        return _getSwapType(secretHash);
    }

    /**
     *  @dev Check the secret hash for existence, it can be used in UI for form validation
     *  @param secretHash the encoded secret which they discussed at offline (SHA256)
     *  @return state of this swap
     */
    function getSwapData(
        bytes32 secretHash
    ) external view returns (
        uint256,
        uint256,
        bytes32,
        bytes32,
        address,
        address,
        uint256,
        State state
    ) {
        Swap memory swap = _swaps[secretHash];
        return (
            swap.initTimestamp,
            swap.refundTimestamp,
            swap.secretHash,
            swap.secret,
            swap.initiator,
            swap.asset,
            swap.amount,
            swap.state
        );
    }

    /**
     *  @dev To avoid issues between solidity hashing algorithm and the algorithm which will be used in the platform
     *  we gonna use the same hashing algorithm which uses the smart contract
     *  this is only the getter method without interaction from the blockchain, so it is safe
     *  @return secret hash of bytes32 secret
     */
    function getHashOfSecret(
        bytes32 secret
    ) external pure returns (bytes32) {
        return _hashTheSecret(secret);
    }
}