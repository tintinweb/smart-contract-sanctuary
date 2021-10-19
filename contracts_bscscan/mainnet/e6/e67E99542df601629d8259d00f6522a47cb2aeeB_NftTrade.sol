/**
 *Submitted for verification at BscScan.com on 2021-10-19
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


contract NftTrade is ERC1155Holder{
    using SafeMath for uint256;
    enum State{solding,saled,cancelled}
    struct FreeOrder{
        address holder;
        uint256 id;
        uint256 amount;
        uint256 singlePrice;
        uint256 profit;
        State   state;
    }
    FreeOrder[] public freeOrders;
    struct AuctionOrder{
        address holder;
        address token;
        uint256 id;
        uint256 amount;
        uint256 deliveryAmount;
        address heighestBidder;
        uint256 heighestBid;
        uint256 expireTime;
        uint256 profit;
    }
    mapping (uint256 => mapping(address => uint256)) public  auctionOrderPending;
    AuctionOrder[] public auctionOrders;
    struct User{
        uint256[] freeOrderIds;
        uint256[] auctionOrderIds;
        uint256[] joinAuctionOrderIds;
    }
    mapping(address=>User) userInfo;
    address manager;
    address token1155;
    address tokenMpc;
    address rewardAddress;
    uint256 totalTradeUsdAmount;
    uint256 totalTradeMpcAmount;
    uint256 boxPrice;
    uint256 fees;
    constructor(){
        manager = msg.sender;
    }

    function setTradeInfo(address reward,address token15,address mpc,uint256 box) public{
        require(manager==msg.sender,"Trade:No permit");
        rewardAddress = reward;
        token1155 = token15;
        tokenMpc = mpc;
        boxPrice = box;
    }

    function withdraw(address token,uint256 amount) public{
        require(msg.sender==manager,"Trade:No permit");
        require(amount <= fees,"Trade:Fee is not enough");
        require(IERC20(token).transfer(manager, amount),"Trade:Transfer failed");
        fees = fees.sub(amount);
    }

    function getUserNftAsset(uint256 assetId) public view returns(uint256){
        return IERC1155(token1155).balanceOf(msg.sender, assetId);
    }

    function getUserERC20Asset(address token) public view returns(uint256){
        return IERC20(token).balanceOf(msg.sender);
    }

    function getUserOrderIds() public view returns(uint256[] memory fids,uint256[] memory aids,uint256[] memory jids){
        User storage user = userInfo[msg.sender];
        fids = user.freeOrderIds;
        aids = user.auctionOrderIds;
        jids = user.joinAuctionOrderIds;
    }

    function getFreeOrderInfo(uint256 orderId) public view returns(uint256 assetId,uint256 amount,uint256 totalPrice,State sta){
        FreeOrder storage fo = freeOrders[orderId];
        assetId = fo.id;
        amount = fo.amount;
        totalPrice = fo.singlePrice.mul(amount);
        sta = fo.state;
    }

    function getAuctionOrderInfo(uint256 orderId) public view returns(uint256 assetId,address erc20,uint256 amount,
                uint256 heighest){
        AuctionOrder storage auction = auctionOrders[orderId];
        assetId = auction.id;
        erc20 = auction.token;
        amount = auction.amount;
        heighest = auction.heighestBid;
    }

    function createFreeOrder(uint256 assetId,uint256 amount,uint256 single) public returns(uint256 orderId){
        require(assetId >0 && assetId <18,"Trade:Asset id wrong");
        require(amount >0 && single >0,"Trade: Amount and price wrong");
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), assetId, amount, "");
        orderId = freeOrders.length;
        FreeOrder memory free = FreeOrder(msg.sender,assetId,amount,single,0,State.solding);
        freeOrders.push(free);
        User storage user = userInfo[msg.sender];
        user.freeOrderIds.push(orderId);
    }

    function tradingFreeOrder(uint256 orderId) public{
        FreeOrder storage fo = freeOrders[orderId];
        require(fo.state == State.solding && fo.profit == 0,"Trade:State and profit wrong");
        uint256 totalPrice = fo.amount.mul(fo.singlePrice);
        require(IERC20(tokenMpc).transferFrom(msg.sender, address(this), totalPrice),"Trade:TransferFrom failed");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, fo.id, fo.amount, "");
        totalTradeMpcAmount = totalTradeMpcAmount.add(totalPrice);
        fo.profit = totalPrice;
        fo.state = State.saled;
    }

    function withdrawFreeOrderProfit(uint256 orderId,uint256 amount) public {
        FreeOrder storage fo = freeOrders[orderId];
        require(fo.state == State.saled && fo.profit >0,"Trade:State wrong");
        require(fo.holder == msg.sender,"Trade:No permit");
        require(IERC20(tokenMpc).transfer(msg.sender, amount),"Trade:Transfer failed");
        fo.profit = fo.profit.sub(amount);
    }

    function cancelFreeOrder(uint256 orderId) public {
        FreeOrder storage fo = freeOrders[orderId];
        require(fo.state == State.solding && fo.profit ==0,"Trade:State wrong");
        require(fo.holder == msg.sender,"Trade:No permit");
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, fo.id, fo.amount, "");
        fo.state = State.cancelled;
    }

    function createAuctionOrder(address tokenAdd,uint256 assetId,uint256 amount,uint256 baseSingle) public returns(uint256 orderId){
        require(tokenAdd != address(0) && assetId >0 && amount >0 && baseSingle >0,"Trade:Amount wrong");
        IERC1155(token1155).safeTransferFrom(msg.sender,address(this),assetId,amount,"");
        orderId = auctionOrders.length;
        AuctionOrder memory auction = AuctionOrder({holder:msg.sender,token:tokenAdd,id:assetId,amount:amount,deliveryAmount:amount,
        heighestBidder:address(0),heighestBid:baseSingle.mul(amount),expireTime:block.timestamp.add(2000),profit:0});
        auctionOrders.push(auction);
        User storage user = userInfo[msg.sender];
        user.auctionOrderIds.push(orderId);
    }

    function auctionTrading(uint256 orderId,uint256 amount) public {
        AuctionOrder storage auction = auctionOrders[orderId];
        require(auction.expireTime >= block.timestamp,"Trade:State wrong");
        uint256 compare = auction.heighestBid.add(auction.heighestBid.mul(10).div(100));
        require(amount >= compare,"Trade:Price too small");
        require(IERC20(auction.token).transferFrom(msg.sender, address(this), amount),"Trade:TransferFrom failed");
        uint256 difference = (amount.sub(auction.heighestBid)).mul(20).div(100);
        auctionOrderPending[orderId][auction.heighestBidder] = auctionOrderPending[orderId][auction.heighestBidder].add(difference);
        auction.heighestBidder = msg.sender;
        auction.heighestBid = amount;
        auction.profit = amount;
        auctionOrderPending[orderId][msg.sender] = amount;
        User storage user = userInfo[msg.sender];
        user.joinAuctionOrderIds.push(orderId);
    }

    function receptNftOrERC20(uint256 orderId) public{
        AuctionOrder storage auction = auctionOrders[orderId];
        require(block.timestamp > auction.expireTime,"Trade:State wrong");
        if(msg.sender == auction.holder && auction.heighestBidder != address(0)){
            uint256 amount = 0;
            amount = auction.profit;
            require(IERC20(auction.token).transfer(msg.sender, amount),"Trade:Transfer failed");
            if(auction.token == tokenMpc){
                totalTradeMpcAmount = totalTradeMpcAmount.add(amount);
            }else{
                totalTradeUsdAmount = totalTradeUsdAmount.add(amount);
            }
            auction.profit = 0;      
        }else if(msg.sender == auction.heighestBidder){
            uint256 amount = 0;
            amount = auction.deliveryAmount;
            IERC1155(token1155).safeTransferFrom(address(this), auction.heighestBidder, auction.id, amount, ""); 
            auction.deliveryAmount = 0;
        }else{
            uint256 amount = 0;
            amount = auctionOrderPending[orderId][msg.sender];
            require(IERC20(auction.token).transfer(msg.sender, amount),"Trade:Transfer failed");
        }
    }

    function rand() internal view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        //这里对产生的id根据总发行量进行限制或重发
        return random%18;
    }

    function openNftBox(uint256 amount,uint256 price) public returns(uint256[] memory assetId){
        require(amount>0,"Trade:Amount wrong");
        require(price >= amount.mul(boxPrice),"Trade:Price wrong");
        require(IERC20(tokenMpc).transferFrom(msg.sender, address(this), price),"Trade:TransferFrom failed");
        totalTradeMpcAmount = totalTradeMpcAmount.add(price);
        for(uint i = 0; i < amount; i++){
            uint256 ran = rand();
            assetId[i] = ran;
            IERC1155(token1155).safeTransferFrom(address(0), msg.sender, ran, 1, "");
        }
    }

}