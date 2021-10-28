/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

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

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
     //查询用户某个id的资产拥有的总量
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
     //多个地址多个id资产返回多个用户多个资产的数值
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    //from发出地址 to接收地址 id资产类别 amount要转出的数量 data可以默认为空
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
     //批量转账 from发出地址 to接收地址 ids资产类别数组 amounts不同类别资产转出的不同数量 data转账时附带的数据
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function mintNftForTrading(address receiver,uint256 assetId,uint256 amount) external;
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract NftTrading is ERC1155Holder{
    using SafeMath for uint256;
    enum State{solding,saled,cancelled}
    struct FreeOrder{
        address holder;
        uint256 id;
        uint256 amount;
        uint256 totalPrice;
        uint256 profit;
        address token;
        State   state;
    }
    FreeOrder[] public freeOrders;
    uint256[] freeOrderIds;
    struct AuctionOrder{
        address holder;
        uint256 id;
        uint256 amount;
        address heighestBidder;
        uint256 heighestBid;
        uint256 expireTime;
        uint256 profit;
        //交付
        uint256 deliveryAmount;
        address token;
    }
    mapping (uint256 => mapping(address => uint256)) private  auctionOrderPending;
    AuctionOrder[] public auctionOrders;
    uint256[] auctionOrderIds;
    struct User{
        uint256[] freeOrderIds;
        uint256[] auctionOrderIds;
        uint256[] joinAuctionOrderIds;
    }
    mapping(address=>User) userInfo;
    address manager;
    address token1155;
    address tokenUsd;
    address tokenMpc;
    address swapPair;

    uint256 totalTradingUsdAmount;
    uint256 totalTradingMpcAmount;
    uint256 public mpcFees;
    uint256 public usdFees;

    // uint256 public bossBoxPrice;
    // uint256 public landBoxPrice;
    // uint256 public workerBoxPrice;
    mapping(uint256=>uint256) boxPrice;
    mapping(uint256=>uint256) toolsPrice;

    uint256 public middleTime;

    constructor(){
        manager = msg.sender;
    }
    //设置当前合约需要的合约地址
    function setTradingAddress(address token15,address usd,address mpc) public{
        require(manager == msg.sender,"Trading:No permit");
        token1155 = token15;
        tokenUsd = usd;
        tokenMpc = mpc;
    }
    
    function setSwapAddress(address swap) public {
        require(manager == msg.sender,"Trading:No permit");
        swapPair = swap;
    }
    
    //设置价格与时间
    function setTradingPriceAndTime(uint256 bosp,uint256 lanp,uint256 worp,uint256 tim) public{
        require(manager == msg.sender,"Trading:No permit");
        // bossBoxPrice = bosp;
        // landBoxPrice = lanp;
        // workerBoxPrice = worp;
        boxPrice[1] = bosp;
        boxPrice[2] = lanp;
        boxPrice[3] = worp;
        middleTime = tim;
    }
    
    function setToolsPrice(uint256 mil,uint256 han,uint256 boo,uint256 pic) public{
        require(manager == msg.sender,"Trading:No permit");
        toolsPrice[15] = mil;
        toolsPrice[16] = han;
        toolsPrice[17] = boo;
        toolsPrice[18] = pic;
    }

    function getUserERC20Asset(address token) public view returns(uint256){
        return IERC20(token).balanceOf(msg.sender);
    }

    function getUserNftAsset(uint256 assetId) public view returns(uint256){
        return IERC1155(token1155).balanceOf(msg.sender, assetId);
    }
    
    function getAllOrderIds() public view returns(uint256[] memory free,uint256[] memory auction){
        free = freeOrderIds;
        auction = auctionOrderIds;
    }

    //获取自由交易订单的订单详情
    function getFreeOrderInfo(uint256 orderId) public view returns(uint256 assetId,uint256 amo,uint256 price,uint256 prof,State sta){
        FreeOrder storage free = freeOrders[orderId];
        assetId = free.id;
        amo = free.amount;
        price = free.totalPrice;
        prof = free.profit;
        sta = free.state;
    }
    //获取拍卖订单的订单详情
    function getAuctionOrderInfo(uint256 orderId) public view returns(uint256 assetId,uint256 amount,uint256 heigh,uint256 surTim){
        AuctionOrder storage auction = auctionOrders[orderId];
        assetId = auction.id;
        amount = auction.amount;
        heigh = auction.heighestBid;
        if(auction.expireTime>=block.timestamp){
            surTim = auction.expireTime.sub(block.timestamp);
        }else{
            surTim = 0;
        }
    }

    function getMpcTokenPrice() internal view returns(uint256){
        if (swapPair != address(0)) {
            address token0 = IPancakePair(swapPair).token0();
            (uint256 tokenA,uint256 tokenB,) = IPancakePair(swapPair).getReserves();
            //100 apple 1000cny  1apple = 1000/100  500 = 500/10 = 50apple
            if (token0 == tokenMpc) {
                return tokenB.div(tokenA);
            } else {
                return tokenA.div(tokenB);
            }
        } else {
            return 1;
        }
        
    }
    //获取自由交易订单的总价格
    function getFreeOrderPrice(uint256 orderId,address token) public view returns(uint256){
        FreeOrder storage free = freeOrders[orderId];
        uint256 mpcPrice = getMpcTokenPrice();
        if(token == tokenUsd){
            return free.totalPrice;
        }else if(token == tokenMpc){
            return free.totalPrice.div(mpcPrice);
        }else{
            return 0;
        }
    }
    //获取当前用户参与该派卖单最低应该出价多少
    function getLowestBid(uint256 orderId) public view returns(uint256) {
        AuctionOrder storage auction = auctionOrders[orderId];
        uint256 total = auction.heighestBid.add(auction.heighestBid.mul(10).div(100));
        return total.sub(auctionOrderPending[orderId][msg.sender]);
    }
    //获取道具价格
    function getToolsPrice(uint256 assetId,uint256 amount,address token) public view returns(uint256){
        //牛奶 汉堡 书籍 十字镐
        uint256 total = toolsPrice[assetId].mul(amount);
        uint256 mpcPrice = getMpcTokenPrice();
        if(token == tokenUsd){
            return total;
        }else{
            return total.div(mpcPrice);
        }
    }
    //1-boss 2-land 3-worker
    function  getBoxPrice(uint256 boxId,address token) public view returns(uint256){
        require(boxId >0 && boxId < 4,"Trading:Box id wrong");
        uint256 mpcPrice = getMpcTokenPrice();
        if (token == tokenUsd) {
            return boxPrice[boxId];
        } else {
            return boxPrice[boxId].div(mpcPrice);
        }
    }
    //创建自由交易订单
    function createFreeOrder(uint256 assetId,uint256 amount,uint256 single) public returns(uint256 orderId){
        require(assetId>0 && amount >0 && single >0,"Trading:Data wrong");
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), assetId, amount, "");
        orderId = freeOrders.length;
        FreeOrder memory free = FreeOrder(msg.sender,assetId,amount,amount.mul(single),0,address(0),State.solding);
        freeOrders.push(free);
        freeOrderIds.push(orderId);
        User storage user = userInfo[msg.sender];
        user.freeOrderIds.push(orderId);
    }
    //创建拍卖订单
    function createAuctionOrder(uint256 assetId,uint256 amount,uint256 single,address token) public returns(uint256 orderId){
        require(assetId > 0 && amount >0 && single >0,"Trading:Data wrong");
        orderId = auctionOrders.length;
        AuctionOrder memory auction = AuctionOrder(msg.sender,assetId,amount,address(0),single.mul(amount),block.timestamp.add(middleTime),0,amount,token);
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), assetId, amount, "");
        auctionOrders.push(auction);
        auctionOrderIds.push(orderId);
        User storage user = userInfo[msg.sender];
        user.auctionOrderIds.push(orderId);
    }
    //交易自由订单
    function tradingFreeOrder(uint256 orderId,address token,uint256 price) public{
        FreeOrder storage free = freeOrders[orderId];
        uint256 totalPrice = getFreeOrderPrice(orderId, token);
        require(totalPrice > 0,"Trading:Price wrong");
        require(price >= totalPrice,"Trading:Price wrong");
        require(free.state == State.solding,"Trading:State wrong");
        require(IERC20(token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, free.id, free.amount, "");
        free.token = token;
        free.profit = price.mul(97).div(100);
        free.amount = 0;
        free.state = State.saled;
        //利润计算的时候做手续费收取操作，fee做累加，profit做削减
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
            usdFees = usdFees.add(price.mul(3).div(100));
        }else{
            totalTradingMpcAmount = totalTradingMpcAmount.add(price);
            mpcFees = mpcFees.add(price.mul(3).div(100));
        }
    }
    //对拍卖订单进行出价
    function offerOfAuctionOrder(uint256 orderId,uint256 price) public{
        AuctionOrder storage auction = auctionOrders[orderId];
        uint256 payPrice = getLowestBid(orderId);
        require(payPrice >0 && price >= payPrice,"Trading:Price wrong");
        require(block.timestamp < auction.expireTime,"Trading:Auction ended");
        require(IERC20(auction.token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        auctionOrderPending[orderId][msg.sender] = auctionOrderPending[orderId][msg.sender].add(price);
        auction.heighestBidder = msg.sender;
        auction.heighestBid = price;
        auction.profit = price;
        User storage user = userInfo[msg.sender];
        user.joinAuctionOrderIds.push(orderId);
    }
    //取消自由交易订单
    function cancleFreeOrder(uint256 orderId) public{
        FreeOrder storage free = freeOrders[orderId];
        require(free.holder == msg.sender,"Trading:No permit");
        require(free.state == State.solding,"Trading:State wrong");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, free.id, free.amount, "");
        free.amount = 0;
        free.totalPrice = 0;
        free.state = State.cancelled;
    }
    //取回自由交易订单利润
    function receiveProfits(uint256 orderId,uint256 amount) public{
        FreeOrder storage free = freeOrders[orderId];
        require(free.holder == msg.sender,"Trading:No permit");
        require(free.state == State.saled,"Trading:State wrong");
        require(amount <= free.profit,"Trading:Amount wrong");
        require(IERC20(free.token).transfer(msg.sender, amount),"Trading:Transfer Failed");
        free.profit = free.profit.sub(amount);
    }
    //取回拍卖订单的出价或NFT
    function receiveNFTOrERC20(uint256 orderId) public{
        AuctionOrder storage auction = auctionOrders[orderId];
        require(block.timestamp > auction.expireTime,"Trade:State wrong");
        if(msg.sender == auction.holder && auction.heighestBidder != address(0)){
            uint256 amount = 0;
            amount = auction.profit.mul(97).div(100);
            require(IERC20(auction.token).transfer(msg.sender, amount),"Trade:Transfer failed");
            auction.profit = 0;
            if(auction.token == tokenUsd){
                usdFees = usdFees.add(auction.profit.mul(3).div(100));
            }else{
                mpcFees = mpcFees.add(auction.profit.mul(3).div(100));
            }      
        }else if(msg.sender == auction.heighestBidder){
            uint256 amount = 0;
            amount = auction.deliveryAmount;
            IERC1155(token1155).safeTransferFrom(address(this), auction.heighestBidder, auction.id, amount, ""); 
            auction.deliveryAmount = 0;
        }else{
            uint256 amount = 0;
            amount = auctionOrderPending[orderId][msg.sender];
            require(IERC20(auction.token).transfer(msg.sender, amount),"Trade:Transfer failed");
            auctionOrderPending[orderId][msg.sender] = 0;
        }
    }
    //boss盲盒取随机数
    function randBoss() internal view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%6;
    }
    //开boss盲盒
    function openNftBoxForBoss(uint256 price,address token) public returns(uint256 assetId){
        require(price >0 && token !=address(0),"Trading:Data wrong");
        uint256 boxp = getBoxPrice(1, token);
        require(boxp >0 && price >= boxp,"Trading:Price wrong");
        require(IERC20(token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        assetId = randBoss();
        IERC1155(token1155).mintNftForTrading(msg.sender, assetId, 1);
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
        }else{
            totalTradingMpcAmount = totalTradingMpcAmount.add(price);
        }
    }
    //land盲盒取随机数
    function randLand() internal view returns(uint256 ran){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint256 r = random%11;
        while(r<6){
            r = random%11;
        }
        ran = r;
    }
    //开land盲盒
    function openNftBoxForLand(uint256 price,address token) public returns(uint256 assetId){
        require(price >0 && token !=address(0),"Trading:Data wrong");
        uint256 boxp = getBoxPrice(2, token);
        require(boxp >0 && price >= boxp,"Trading:Price wrong");
        require(IERC20(token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        assetId = randLand();
        IERC1155(token1155).mintNftForTrading(msg.sender, assetId, 1);
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
        }else{
            totalTradingMpcAmount = totalTradingMpcAmount.add(price);
        }
    }
    //worker盲盒取随机数
    function randWorker() internal view returns(uint256 ran){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint256 r = random%15;
        while(r<10){
            r = random%15;
        }
        ran = r;
    }
    //开worker盲盒
    function openNftBoxForWorker(uint256 price,address token) public returns(uint256 assetId){
        require(price >0 && token !=address(0),"Trading:Data wrong");
        uint256 boxp = getBoxPrice(2, token);
        require(boxp >0 && price >= boxp,"Trading:Price wrong");
        require(IERC20(token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        assetId = randWorker();
        IERC1155(token1155).mintNftForTrading(msg.sender, assetId, 1);
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
        }else{
            totalTradingMpcAmount = totalTradingMpcAmount.add(price);
        }
    }
    //购买道具 牛奶/汉堡/书籍/十字镐
    function buyTools(uint256 assetId,uint256 amount,address token,uint256 price) public {
        require(assetId >0 && amount >0,"Trading:Data wrong");
        uint256 total = getToolsPrice(assetId, amount, token);
        require(total >0 && price >= total,"Trading:Price wrong");
        require(IERC20(token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        IERC1155(token1155).mintNftForTrading(msg.sender, assetId, amount);
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
        }else{
            totalTradingMpcAmount = totalTradingMpcAmount.add(price);
        }
    }

}