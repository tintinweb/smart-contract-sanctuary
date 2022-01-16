// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/IERC20.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";
import "./interface/IPancakeRouter01.sol";

contract P2P is Ownable {

    struct Seller {
        uint ratio;
        string contactInfo;
    }

    enum Status { Pending, Accepted, Rejected, Completed, Seller_Cancelled, Buyer_Cancelled }

    struct Order {
        uint amount;
        uint timestamp;
        uint ratio;
        uint locked_amount;
        address seller;
        address buyer;
        Status status;
        bool reviewForSeller;
        bool reviewForBuyer;
        bool burnSellerLockedToken;
        bool burnBuyerLockedToken;
    }

    uint public orderCount;
    IERC20 public baseCurrency;
    IERC20 public lockedToken;

    IPancakeRouter01 public router;

    address[] public sellerList;
    Order[] public orderList;

    struct Review {
        uint128 score;
        uint128 timestamp;
        uint256 reviewHash;
    }

    struct User {
        uint balance;
        uint lockedBalance;
        Review[] reviews;        
    }

    mapping(address => User) public userInfo;
    mapping(address => Seller) public sellerInfo;


    event Deposit_Locked_Token(address sender, uint amount);
    event Create_Order(uint orderId, address indexed seller, address indexed buyer, uint amount, uint timestamp);
    event Accept_Order(uint orderId, address indexed seller, address indexed buyer);
    event Reject_Order(uint orderId, address indexed seller, address indexed buyer);
    event Complete_Order(uint orderId, address indexed seller, address indexed buyer);
    event Cancel_Order(uint orderId, address indexed seller, address indexed buyer);

    event Burn_Buyer_Locked_Token(uint orderId, address indexed seller, address indexed buyer);
    event Burn_Seller_Locked_Token(uint orderId, address indexed seller, address indexed buyer);

    event Add_Review_For_Seller(address seller, uint orderId, uint score, uint reviewHash);
    event Add_Review_For_Buyer(address buyer, uint orderId, uint score, uint reviewHash);


    constructor(address pancakeRouter) {
        router = IPancakeRouter01(pancakeRouter);
    }

    function depositLockedToken(uint amount) external {
        lockedToken.transferFrom(msg.sender, address(this), amount);
        userInfo[msg.sender].balance += amount;
        emit Deposit_Locked_Token(msg.sender, amount);
    }

    function listSeller(uint ratio, string calldata contactInfo) external {
        require(ratio > 0, "Ratio should not be zero");
        Seller storage seller = sellerInfo[msg.sender];
        if(seller.ratio == 0) {
            sellerList.push(msg.sender);
        }
        seller.ratio = ratio;
        seller.contactInfo = contactInfo;
    }

    function createOrder(address seller, uint amount) external {
        Seller memory _seller = sellerInfo[seller];
        require(_seller.ratio > 0, "Not valid seller");
        User storage seller_info = userInfo[seller];
        User storage buyer_info = userInfo[msg.sender];
        uint sellerAvailableBalance = seller_info.balance - seller_info.lockedBalance;
        uint buyerAvailableBalance = buyer_info.balance - buyer_info.lockedBalance;
        uint lock_amount = getLockedTokenAmount(amount);
        require(sellerAvailableBalance >= lock_amount, "Not enough seller locked amount");
        require(buyerAvailableBalance >= lock_amount, "Not enough buyer locked amount");
        seller_info.lockedBalance += lock_amount;
        buyer_info.lockedBalance += lock_amount;
        Order memory order;
        order.buyer = msg.sender;
        order.seller = seller;
        order.locked_amount = lock_amount;
        order.ratio = _seller.ratio;
        order.status = Status.Pending;
        orderList.push(order);
        emit Create_Order(orderCount, seller, msg.sender, amount, block.timestamp);
        orderCount += 1;
    }

    function acceptOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Pending, "Not valid status");
        baseCurrency.transferFrom(msg.sender, address(this), order.amount);
        order.status = Status.Accepted;
        emit Accept_Order(orderId, msg.sender, order.buyer);
    }

    function rejectOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Pending, "Not valid status");
        order.status = Status.Rejected;
        emit Reject_Order(orderId, msg.sender, order.buyer);
    }

    function completeOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(order.buyer, order.amount);
        order.status = Status.Completed;
        order.timestamp = block.timestamp;
        userInfo[msg.sender].lockedBalance -= order.locked_amount;
        userInfo[order.buyer].lockedBalance -= order.locked_amount;
        emit Complete_Order(orderId, msg.sender, order.buyer);
    }

    function cancelOrderSeller(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(msg.sender, order.amount);
        order.status = Status.Seller_Cancelled;
        emit Cancel_Order(orderId, msg.sender, order.buyer);
    }

    function cancelOrderBuyer(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(order.seller, order.amount);
        order.status = Status.Buyer_Cancelled;
        emit Cancel_Order(orderId, msg.sender, order.buyer);
    }
    
    function burnBuyerLockedToken(uint orderId) external {
        Order storage order = orderList[orderId];
        require(msg.sender == order.seller, "Only seller can burn buyer's locked token");
        require(order.status == Status.Completed || order.status == Status.Buyer_Cancelled, "Order is not completed");
        require(order.burnBuyerLockedToken == false, "Already burned");
        lockedToken.transfer(address(0x0), order.locked_amount);
        userInfo[order.buyer].balance -= order.locked_amount;
        order.burnBuyerLockedToken = true;
        emit Burn_Buyer_Locked_Token(orderId, msg.sender, order.buyer);
    } 

    function burnSellerLockedToken(uint orderId) external {
        Order storage order = orderList[orderId];
        require(msg.sender == order.buyer, "Only buyer can burn buyer's locked token");
        require(order.status == Status.Seller_Cancelled, "Order is not completed");       
        require(order.burnSellerLockedToken == false, "Already burned");
        lockedToken.transfer(address(0x0), order.locked_amount);
        userInfo[order.seller].balance -= order.locked_amount;
        order.burnSellerLockedToken = true;
        emit Burn_Seller_Locked_Token(orderId, msg.sender, order.buyer);
    } 

    function addReviewForSeller(uint orderId, uint128 score, uint reviewHash) external {
        Order storage order = orderList[orderId];
        require(order.buyer == msg.sender, "Not buyer");
        require(order.reviewForSeller == false, "Already exist");
        Review memory review;
        review.score = score;
        review.reviewHash = reviewHash;
        review.timestamp = uint128(block.timestamp);
        userInfo[order.seller].reviews.push(review);
        order.reviewForSeller = true;
        emit Add_Review_For_Seller(order.seller, orderId, score, reviewHash);
    }

    function addReviewForBuyer(uint orderId, uint128 score, uint reviewHash) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Not seller");
        require(order.reviewForBuyer == false, "Already exist");
        Review memory review;
        review.score = score;
        review.reviewHash = reviewHash;
        review.timestamp = uint128(block.timestamp);
        userInfo[order.buyer].reviews.push(review);
        order.reviewForBuyer = true;
        emit Add_Review_For_Buyer(order.buyer, orderId, score, reviewHash);
    }

    function getReviews(address user) external view returns(Review[] memory) {
        return userInfo[user].reviews;
    }

    function getBaseCurrencyAmount(uint locked_amount) internal view returns (uint base_amount) {
        uint price = getPrice(address(lockedToken), address(baseCurrency));
        base_amount = locked_amount * (10 ** baseCurrency.decimals()) * price / (10 ** lockedToken.decimals()) / 1e8;
    }

    function getLockedTokenAmount(uint base_amount) internal view returns (uint locked_amount) {
        uint price = getPrice(address(lockedToken), address(baseCurrency));
        locked_amount = 1e8 * base_amount * (10 ** lockedToken.decimals()) / (10 ** baseCurrency.decimals()) / price;
    }

    function getPrice(address token0, address token1) internal view returns(uint) {
        IPancakePair pair = IPancakePair(IPancakeFactory(router.factory()).getPair(token0, token1));
        (uint res0, uint res1,) = pair.getReserves();
        res0 *= 10 ** (18 - IERC20(pair.token0()).decimals());
        res1 *= 10 ** (18 - IERC20(pair.token1()).decimals());
        if(pair.token0() == token1) {
            if(res1 > 0)
                return 1e8 * res0 / res1;
        } 
        else {
            if(res0 > 0)
                return 1e8 * res1 / res0;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the BEP standard.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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