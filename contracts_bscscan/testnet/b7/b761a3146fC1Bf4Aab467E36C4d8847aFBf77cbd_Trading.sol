/**
 *Submitted for verification at BscScan.com on 2021-11-18
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    function burnNftForTrading(address from,uint256 assetId) external;
    function mintNftForBoxAndTools(address receiver,uint256 assetId,uint256 amount) external;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface ITrading{
    enum State{solding,saled,cancelled}
    struct FreeOrder{
        address holder;
        uint256 id;
        uint256 amount;
        uint256 totalPrice;
        uint256 profit;
        address token;
        uint256 time;
        State   state;
    }

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
        uint256 time;
        //mapping(address=>uint256) auctionOrderPending;
    }

    struct OfferPrice{
        address ofCustomer;
        uint256 price;
        uint256 time;
    }

    struct User{
        uint256[] freeOrderIds;
        uint256[] auctionOrderIds;
        uint256[] joinAuctionOrderIds;
    }

    // function getMpcTokenPrice() external view returns(uint256);
    // function tokenUsd() external view returns(address);

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Trading is ITrading,ERC1155Holder{
    using SafeMath for uint256;
    FreeOrder[] public freeOrders;
    uint256[] freeOrderIds;

    AuctionOrder[] public auctionOrders;
    uint256[] auctionOrderIds;
    
    OfferPrice[] public offerPrices;
    //mapping(address=>mapping(uint256=>uint256)) auctionOrderPending;
    mapping(uint256=>uint256[]) public joinAuctionIds;
    mapping(address=>User) userInfo;

    address manager;
    address public token1155;
    address public tokenUsd;
    address public tokenMpc;
    address public swapPair;
    //address public boxAndTools;

    uint256 public totalTradingUsdAmount;
    //uint256 public totalTradingMpcAmount;
    uint256 public mpcFees;
    uint256 public usdFees;
    uint256 public rewardMpcAmount;
    uint256 public destorMpcyAmount;
    mapping(uint256=>uint256) public tradingSupply;

    constructor(){
        manager = msg.sender;
        FreeOrder memory free = FreeOrder(msg.sender,0,0,0,0,address(0),0,State.cancelled);
        freeOrders.push(free);
        AuctionOrder memory auction = AuctionOrder({
            holder : msg.sender,
            id     : 0,
            amount : 0,
            heighestBidder :address(0),
            heighestBid :0,
            expireTime : block.timestamp,
            profit : 0,
            deliveryAmount :0,
            token : address(0),
            time:0
        });
        auctionOrders.push(auction);
        OfferPrice memory offer = OfferPrice(msg.sender,0,block.timestamp);
        offerPrices.push(offer);
    }

    function setTradingAddress(address token15,address usd,address mpc) public{
        require(manager == msg.sender,"Trading:No permit");
        token1155 = token15;
        tokenUsd = usd;
        tokenMpc = mpc;
    }

    function isApproveNft() public view returns(bool){
        return IERC1155(token1155).isApprovedForAll(msg.sender,address(this));
    }

    function isApproveErc20(address token) public view returns(bool){
        uint256 appAmount = IERC20(token).allowance(msg.sender,address(this));
        if(appAmount>=100000e18){
            return true;
        }else{
            return false;
        }
    }

    function getUserAllOrderIds() public view returns(uint256[] memory fids,uint256[] memory aids,uint256[] memory jids){
        User storage user = userInfo[msg.sender];
        fids = user.freeOrderIds;
        aids = user.auctionOrderIds;
        jids = user.joinAuctionOrderIds;
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
    
    function getAllFressOrderIds() public view returns(uint256[] memory){
        return freeOrderIds;
    }
    
    function getAllAuctionOrderIds() public view returns(uint256[] memory){
        return auctionOrderIds;
    }

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

    function getFreeOrderPrice(uint256 orderId) public view returns(uint256 price,address token){
        FreeOrder storage free = freeOrders[orderId];
        price = free.totalPrice;
        token = free.token;
    }

    function getLowestBid(uint256 orderId) public view returns(uint256 price,address token) {
        AuctionOrder storage auction = auctionOrders[orderId];
        price = auction.heighestBid.add(auction.heighestBid.mul(5).div(100));
        token = auction.token;
    }

    function createFreeOrder(uint256 assetId,uint256 amount,uint256 single,address token) public returns(uint256 orderId){
        require(assetId>0 && amount >0 && single >0,"Trading:Data wrong");
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), assetId, amount, "");
        orderId = freeOrders.length;
        FreeOrder memory free = FreeOrder(msg.sender,assetId,amount,amount.mul(single),0,token,block.timestamp,State.solding);
        freeOrders.push(free);
        freeOrderIds.push(orderId);
        User storage user = userInfo[msg.sender];
        user.freeOrderIds.push(orderId);
        tradingSupply[assetId] = tradingSupply[assetId].add(amount);
    }

    function createAuctionOrder(uint256 assetId,uint256 amount,uint256 single,uint256 time,address token) public returns(uint256 orderId){
        require(assetId > 0 && amount >0 && single >0,"Trading:Data wrong");
        orderId = auctionOrders.length;
        AuctionOrder memory auction = AuctionOrder(msg.sender,assetId,amount,
                                                address(0),single.mul(amount),
                                                block.timestamp.add(time.mul(24).mul(3600)),
                                                0,amount,token,block.timestamp);
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), assetId, amount, "");
        auctionOrders.push(auction);
        auctionOrderIds.push(orderId);
        User storage user = userInfo[msg.sender];
        user.auctionOrderIds.push(orderId);
        tradingSupply[assetId] = tradingSupply[assetId].add(amount);
    }

    function updateFees(address token,uint256 price) internal{
        if(token == tokenUsd){
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
            usdFees = usdFees.add(price.mul(3).div(100));
        }else{
            totalTradingUsdAmount = totalTradingUsdAmount.add(price);
            mpcFees = mpcFees.add(price.mul(3).div(100));
            rewardMpcAmount = rewardMpcAmount.add(price.mul(3).div(100).mul(30).div(100));
            destorMpcyAmount = destorMpcyAmount.add(price.mul(3).div(100).mul(70).div(100));
        }
    }

    function tradingFreeOrder(uint256 orderId,uint256 price) public{
        FreeOrder storage free = freeOrders[orderId];
        (uint256 totalPrice,) = getFreeOrderPrice(orderId);
        require(totalPrice > 0,"Trading:Price wrong");
        require(price >= totalPrice,"Trading:Price wrong");
        require(free.state == State.solding,"Trading:State wrong");
        require(IERC20(free.token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, free.id, free.amount, "");
        free.profit = price.mul(97).div(100);
        free.amount = 0;
        free.state = State.saled; 
    }

    function offerOfAuctionOrder(uint256 orderId,uint256 price) public {
        AuctionOrder storage auction = auctionOrders[orderId];
        require(auction.holder != msg.sender,"Staking:You do not have permit");
        (uint256 payPrice,) = getLowestBid(orderId);
        require(payPrice >0 && price >= payPrice,"Trading:Price wrong");
        require(block.timestamp <= auction.expireTime,"Trading:Auction ended");
        require(IERC20(auction.token).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        if(auction.heighestBidder != address(0)){
            uint256 amount = 0;
            amount = auction.heighestBid;
            require(IERC20(auction.token).transfer(auction.heighestBidder, amount),"Trading:Transfer failed");
            auction.heighestBid = 0;
            auction.profit = 0;
        }
        auction.heighestBidder = msg.sender;
        auction.heighestBid = price;
        auction.profit = price;
        User storage user = userInfo[msg.sender];
        user.joinAuctionOrderIds.push(orderId);  
        OfferPrice memory offer = OfferPrice(msg.sender,price,block.timestamp);
        uint256 offerId = offerPrices.length;
        offerPrices.push(offer);
        joinAuctionIds[orderId].push(offerId);
    }

    function getAuctionIsEnd(uint256 orderId) public view returns(bool end){
        AuctionOrder storage auction = auctionOrders[orderId];
        if (block.timestamp > auction.expireTime) {
            end = true;
        } else {
            end = false;
        }
    }

    function getJoinAuctionIds(uint256 auctionId) public view returns(uint256[] memory){
        return joinAuctionIds[auctionId];
    }

    function cancleFreeOrder(uint256 orderId) public{
        FreeOrder storage free = freeOrders[orderId];
        require(free.holder == msg.sender,"Trading:No permit");
        require(free.state == State.solding,"Trading:State wrong");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, free.id, free.amount, "");
        free.amount = 0;
        free.totalPrice = 0;
        free.state = State.cancelled;
    }

    function receiveProfits(uint256 orderId,uint256 amount) public{
        FreeOrder storage free = freeOrders[orderId];
        require(free.holder == msg.sender,"Trading:No permit");
        require(free.state == State.saled,"Trading:State wrong");
        require(amount <= free.profit,"Trading:Amount wrong");
        require(IERC20(free.token).transfer(msg.sender, amount),"Trading:Transfer Failed");
        free.profit = free.profit.sub(amount);
    }

    function getAuctionResult(uint256 orderId) public view returns(uint256 assetId,uint256 amount,address token){
        AuctionOrder storage auction = auctionOrders[orderId];
        if(block.timestamp > auction.expireTime){
            if(msg.sender==auction.holder && auction.heighestBidder !=address(0)){
                assetId = 0;
                amount = auction.profit.mul(97).div(100);
                token = auction.token;
            }
            if(msg.sender==auction.holder && auction.heighestBidder ==address(0)){
                assetId = auction.id;
                amount = auction.deliveryAmount;
                token = address(0);
            }
            if(msg.sender==auction.heighestBidder){
                assetId = auction.id;
                amount = auction.deliveryAmount;
                token = auction.token;
            }
        }   
    }

    function receiveNFTOrERC20(uint256 orderId) public{
        AuctionOrder storage auction = auctionOrders[orderId];
        require(block.timestamp > auction.expireTime,"Trade:State wrong");
        if (msg.sender == auction.holder && auction.heighestBidder != address(0)) {
            uint256 amount = 0;
            amount = auction.profit.mul(97).div(100);
            require(IERC20(auction.token).transfer(msg.sender, amount),"Trade:Transfer failed");
            if(auction.token == tokenUsd){
                usdFees = usdFees.add(auction.profit.mul(3).div(100));
                auction.profit = 0;
            }else{
                mpcFees = mpcFees.add(auction.profit.mul(3).div(100));
                rewardMpcAmount = rewardMpcAmount.add(auction.profit.mul(3).div(100).mul(30).div(100));
                destorMpcyAmount = destorMpcyAmount.add(auction.profit.mul(3).div(100).mul(70).div(100));
                auction.profit = 0;
            }
        }
        if(msg.sender == auction.heighestBidder){
            uint256 amount = 0;
            amount = auction.deliveryAmount;
            IERC1155(token1155).safeTransferFrom(address(this), auction.heighestBidder, auction.id, amount, ""); 
            auction.deliveryAmount = 0;
        }
        if(msg.sender == auction.holder && auction.heighestBidder == address(0)){
            uint256 amount = 0;
            amount = auction.deliveryAmount;
            IERC1155(token1155).safeTransferFrom(address(this), msg.sender, auction.id, amount, ""); 
            auction.deliveryAmount = 0;
        }
    }


}


contract BoxAndTool{
    using SafeMath for uint256;
    uint256 public boxOfBossPrice;
    uint256 public boxOfLandPrice;
    uint256 public boxOfWorkerPrice;
    uint256 bossEndTime;
    uint256 landEndTime;
    uint256 workerEndTime;
    mapping(uint256=>address) supportToken;
    mapping(uint256=>uint256) surplusSupply;
    mapping(uint256=>uint256) toolPrices;
    mapping(address=>bool) isBuy;
    address usdtErc20;
    address mpcErc20;
    address token1155;
    address manager;
    uint256 public totalTrading;

    constructor(){
        manager = msg.sender;
    }

    modifier onlyManager(){
        require(manager == msg.sender, "BoxAndTool:No permit");
        _;
    }
    
    function getApproveResult(address token) public view returns(bool){
        uint256 approve = IERC20(token).allowance(msg.sender,address(this));
        if(approve >= 100000e18){
            return true;
        }
        return false;
    }

    function changeOwner(address manage) public onlyManager{
        manager = manage;
    }
    
    function setSurplusSupply(uint256[] memory ids,uint256[] memory amounts) public onlyManager{
        for(uint i=0; i<ids.length; i++){
            surplusSupply[ids[i]] = amounts[i];
        }
    }

    function setSupportAddress(uint256 id,address token) public onlyManager{
        supportToken[id] = token;
    }

    function setTokenAddress(address uErc20,address mErc20,address erc1155) public onlyManager{
        usdtErc20 = uErc20;
        mpcErc20 = mErc20;
        token1155 = erc1155;
    }

    function setBoxPrice(uint256 bos,uint256 lan,uint256 wor) public onlyManager{
        boxOfBossPrice = bos;
        boxOfLandPrice = lan;
        boxOfWorkerPrice = wor;
    }

    function setEndTime(uint256 bos,uint256 lan,uint256 wor) public {
        require(manager == msg.sender,"Trading:No permit");
        bossEndTime = block.timestamp.add(bos);
        landEndTime = block.timestamp.add(lan);
        workerEndTime = block.timestamp.add(wor);
    }

    function getBossSurplusTime() public view returns(uint256 bos){
        if(bossEndTime >= block.timestamp){
            bos = bossEndTime.sub(block.timestamp);
        }else{
            bos = 0;
        }
    }

    function getLandSurplusTime() public view returns(uint256 lan){
        if (landEndTime >= block.timestamp) {
            lan = landEndTime.sub(block.timestamp);
        } else {
            lan = 0;
        }
    }

    function getWorkerSurplusTime() public view returns(uint256 wor){
        if (workerEndTime >= block.timestamp) {
            wor = workerEndTime.sub(block.timestamp);
        } else {
            wor = 0;
        }
    }

    function randBoss() public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint256 ran = random%6;
        if(ran==0){
            return ran+1;
        }
        return ran;
    }
    //[1,2,3,4,5],[10,20,30,40,50]
    //"800000000000000000000","300000000000000000000","250000000000000000000"
    //"86400","86400","86400"
    //"1","0xcd8AfcbFa9921964ff41FF1BF2469c1B37AC66DD"
    function randLand() public view returns(uint256 ran){
        uint256 random = randBoss().add(5);
        if(random == 10){
            ran = random.sub(1);
        }
        ran = random;
    }
    //"0xe89A5ce0Cd813Da5172b7394349feF04d4395131","0xcd8AfcbFa9921964ff41FF1BF2469c1B37AC66DD","0xa10A6D360e84D8689719dE52160C249de8eb8454"
    //[1,"2",3,"4",5,"6",7,"8",9,"10",11,"12",13,14],[100,"200",300,"400",500,"600",700,"800",900,"1000",1100,"1200",1300,1400]
    //"864000","864000","864000"
    //"800000000000000000000","300000000000000000000","250000000000000000000"
    function openNftBoxForBoss(uint256 price) public returns(uint256 assetId){
        require(isBuy[msg.sender]==false,"BoxAndTool:Only once");
        require(price >= boxOfBossPrice, "BoxAndTool:Wrong price");
        require(block.timestamp < bossEndTime, "BoxAndTool:Time wrong");
        assetId = randBoss();
        require(IERC20(supportToken[1]).transferFrom(msg.sender,address(this),price),"BoxAndTool:Wrong price");
        IERC1155(token1155).mintNftForBoxAndTools(msg.sender, assetId, 1);
        surplusSupply[assetId] = surplusSupply[assetId].sub(1);
        isBuy[msg.sender] = true;
        updateTotalTrading(supportToken[1],price);
    }
    
    function openNftBoxForLand(uint256 price) public  returns(uint256 assetId){
        require(price >= boxOfLandPrice, "BoxAndTool:Wrong price");
        require(block.timestamp < landEndTime, "BoxAndTool:Time wrong");
        assetId = randLand();
        require(IERC20(supportToken[2]).transferFrom(msg.sender,address(this),price),"BoxAndTool:Wrong price");
        IERC1155(token1155).mintNftForBoxAndTools(msg.sender, assetId, 1);
        surplusSupply[assetId] = surplusSupply[assetId].sub(1);
        updateTotalTrading(supportToken[2],price);
    }
    
    function openNftBoxForWorker(uint256 price) public  returns(uint256 assetId){
        require(price >= boxOfWorkerPrice, "BoxAndTool:Wrong price");
        require(block.timestamp < workerEndTime, "BoxAndTool:Time wrong");
        assetId = randLand().add(9);
        require(IERC20(supportToken[3]).transferFrom(msg.sender,address(this),price),"BoxAndTool:Wrong price");
        IERC1155(token1155).mintNftForBoxAndTools(msg.sender, assetId, 1);
        surplusSupply[assetId] = surplusSupply[assetId].sub(1);
        updateTotalTrading(supportToken[3],price);
    }
    
    function buyTools(uint256 assetId,uint256 amount,uint256 price) public {
        require(assetId == 15 || assetId == 16 || assetId == 17 || assetId == 18,"BoxAndTool:Wrong asset");
        require(price >= toolPrices[assetId].mul(amount),"BoxAndTool:Wrong price");
        require(IERC20(supportToken[4]).transferFrom(msg.sender, address(this), price),"Trading:TransferFrom failed");
        IERC1155(token1155).mintNftForBoxAndTools(msg.sender, assetId, amount);
        updateTotalTrading(supportToken[4],price);
    }
    
    function updateTotalTrading(address token,uint256 amount) internal{
        if(token == mpcErc20){
            totalTrading = totalTrading.add(amount.mul(2));
        }else{
            totalTrading = totalTrading.add(amount);
        }
    }

}