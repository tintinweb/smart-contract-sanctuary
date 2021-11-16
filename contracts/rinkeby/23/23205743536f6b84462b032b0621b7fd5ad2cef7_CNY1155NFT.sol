// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./IERC1155MetadataURI.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./ERC165.sol";
import "./ERC20.sol";



/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) internal _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;
    
    string private _name;
    string private _symbol;
    uint256 internal _totalSupply;


    /**
     * @dev See {_setURI}.
     */
    constructor (string memory name_, string memory symbol_, string memory uri_) {
        _setURI(uri_);
        _name = name_;
        _symbol = symbol_;
    }
    
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }
    

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        // require(to != address(0), "ERC1155: transfer to the zero address");
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );

        // address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        // uint256 fromBalance = _balances[id][from];
        // require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        // _balances[id][from] = fromBalance - amount;
        // _balances[id][to] += amount;

        // emit TransferSingle(operator, from, to, id, amount);

        // _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        // require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        // require(to != address(0), "ERC1155: transfer to the zero address");
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: transfer caller is not owner nor approved"
        // );

        // address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // for (uint256 i = 0; i < ids.length; ++i) {
        //     uint256 id = ids[i];
        //     uint256 amount = amounts[i];

        //     uint256 fromBalance = _balances[id][from];
        //     require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        //     _balances[id][from] = fromBalance - amount;
        //     _balances[id][to] += amount;
        // }

        // emit TransferBatch(operator, from, to, ids, amounts);

        // _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;
        _totalSupply -= amount;

        

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract ERC1155Mintable is ERC1155, Ownable{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // 
    
    // 订单编号记录
    uint256 private orderNonce = 10001001000000;
    
    // 取消、已支付、已发货、完成
    enum OrderState{
        Cancel,
        Paid,
        Shipped,
        TradeFinish
    }
    
    struct TokenInfo {
        // 商品编号
        uint256 id;
        // 创建者地址
        address creator;
        // 商品详情数据
        string tokenUri;
        // 商品单价
        uint256 price;
        // 库存总数量
        uint256 totalSupply;
        // 销售总数量
        uint256 salesVolume;
    }

    struct OrderInfo {
        // 订单Id
        uint256 id;
        // 购买者
        address buyer;
        // 订单状态
        OrderState state;
        // 订单总金额
        uint256 amount;
        // 购买数量
        uint256 quantity;
        // 收货地址ID
        uint256 receipt;
        // 商品ID
        uint256 tokenId;
        // 物流订单ID
        string delivery;
        // 使用何种代币进行支付，需要记录合约地址
        address tokenAddress;
    }

    struct UserInfo {
        // 用户头像或照片
        string avatar;
        // 用户常用地址或住址
        uint256 receipt;
        // 用户信誉程度
        uint256 credit;
    }
    
    // id => TokenInfo，商品ID => 商品信息
    mapping(uint256 => TokenInfo) internal tokens;
    // id => OrderInfo, 订单ID => 订单信息
    mapping(uint256 => OrderInfo) internal orders;
    // 销毁事件，操作者、商品ID、商品信息
    event EventDestroy(address indexed operator, uint256 id, TokenInfo info);
    // 购买取消事件，操作者、购买者、订单ID
    event Aborted(address indexed operator, address indexed buyer, uint256 id);
    // 购买确认事件，操作者、卖家、订单Id、购买数量
    event ConfirmPurchase(address indexed operator, address indexed seller, uint256 id, uint256 quantities);
    // 卖家确认发货事件，操作者、订单ID、收货地址ID、物流订单ID
    event ConfirmDelivery(address indexed operator, uint256 _id, uint256 _receipt, string _delivery);
    // 确认收货事件，操作者、订单ID
    event ConfirmReceipt(address indexed operator, uint256 id);
    

    constructor (string memory name_, string memory symbol_, string memory uri_) ERC1155(name_, symbol_, uri_) {
        
    }

    

    modifier creatorOnly(uint256 _id) {
        require(tokens[_id].creator == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId) override
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getBalanceByTokenAddress(address tokenAddress) public view returns(uint256) {
        IERC20 erc20 = IERC20(tokenAddress);
        return erc20.balanceOf(address(this));
    }
    
    function approve(address tokenAddress, uint256 amount) public virtual returns (bool) {
        IERC20 erc20 = IERC20(tokenAddress);
        return erc20.approve(address(this), amount);
    }
    
    // 创建商品，商品ID、商品价格、库存数量、商品信息网址
    function create(uint256 _id, uint256 _price, uint256 _initialSupply, string calldata _uri) public returns(bool)  {
        require(tokens[_id].id == 0, 'Invalid _id.');

        TokenInfo memory token = TokenInfo(_id, msg.sender, _uri, _price, _initialSupply, 0);
        
        tokens[_id] = token;
        _totalSupply += _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);

        return true;
    }
    // 销毁商品，商品ID
    function destroy(uint256 _id) external onlyOwner {
        TokenInfo storage token = tokens[_id];
        require(token.salesVolume == 0, 'Can not be destroyed.');
        
        _totalSupply -= token.totalSupply;
        delete tokens[_id];

        emit EventDestroy(msg.sender, _id, token);
    }
    // 购买商品，订单ID、商品ID、商品数量、收货地址、代币合约地址
    function buyToken(uint256 _tokenid, uint256 _quantities, uint256 _receipt, address tokenAddress) public returns(uint256 _id) {
        TokenInfo storage token = tokens[_tokenid];
        uint256 amount = _quantities.mul(token.price);
        uint256 stock = token.totalSupply - token.salesVolume;
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 allowance = erc20.allowance(msg.sender, address(this));
        
        //require(amount == msg.value, 'Insufficient purchase amount.');
        require(_quantities <= stock, 'Insufficient inventory.');
        require(allowance >= amount, "Token allowance too small");
        
        _id = ++orderNonce;
        OrderInfo memory order = OrderInfo(_id, msg.sender, OrderState.Paid, amount, _quantities, _receipt, _tokenid, '', tokenAddress);
        orders[_id] = order;
        token.salesVolume = _quantities.add(token.salesVolume);
        _balances[_tokenid][msg.sender] = _quantities.add(_balances[_tokenid][msg.sender]);
        
        // 开始转账，先把金额转到合约（交易保障），等用户收到货后在转到卖家账号
        //payable(token.creator).transfer(amount);
        erc20.transferFrom(msg.sender, address(this), amount);
        
        emit TransferSingle(msg.sender, token.creator, msg.sender, _id, _quantities);
        emit ConfirmPurchase(msg.sender, token.creator, _id, _quantities);
        
        
        if (msg.sender.isContract()) {
            super._doSafeTransferAcceptanceCheck(msg.sender, token.creator, msg.sender, _id, _quantities, '');
        }
    }
    // 卖家取消交易，订单Id、代币合约地址
    function sellerAbort(uint256 _id) public {
        OrderInfo storage order = orders[_id];
        TokenInfo storage token = tokens[order.tokenId];
        require(msg.sender == token.creator || msg.sender == owner(), "Only seller can call this.");
        require(order.state == OrderState.Paid, "Invalid state.");
        emit Aborted(msg.sender, order.buyer, _id);
        order.state = OrderState.Cancel;
        token.salesVolume -= order.quantity;
        _balances[token.id][msg.sender] = order.quantity.sub(_balances[token.id][msg.sender]);

        // 返还用户已支付的金额
        //payable(order.buyer).transfer(address(this).balance);
        IERC20 erc20 = IERC20(order.tokenAddress);
        erc20.transfer(order.buyer, order.amount);
    }
    // 卖家确认发货，订单ID、物流ID
    function sellerConfirmDelivery(uint256 _id, string calldata _delivery) public {
        OrderInfo storage order = orders[_id];
        TokenInfo storage token = tokens[order.tokenId];
        require(msg.sender == token.creator || msg.sender == owner(), "Only seller can call this.");
        require(order.state == OrderState.Paid, "Invalid state.");
        emit ConfirmDelivery(msg.sender, _id, order.receipt, _delivery);
        order.delivery = _delivery;
        order.state = OrderState.Shipped;
    }
    // 买家确认收货，订单ID
    function buyerConfirmReceipt(uint256 _id) public {
        OrderInfo storage order = orders[_id];
        TokenInfo storage token = tokens[order.tokenId];
        require(msg.sender == order.buyer || msg.sender == owner(), "Only buyer can call this.");
        require(order.state == OrderState.Shipped, "Invalid state.");
        emit ConfirmReceipt(msg.sender, _id);
        order.state = OrderState.TradeFinish;

        // 交易成功，将收益转入到卖家账号中
        //buyer.transfer(order.amount);
        //payable(token.creator).transfer(address(this).balance);
        IERC20 erc20 = IERC20(order.tokenAddress);
        erc20.transfer(token.creator, order.amount);
    }
    
    
    
    
    

    function setURI(string calldata _uri, uint256 _id) external onlyOwner {
        TokenInfo storage token = tokens[_id];
        require(msg.sender == token.creator || msg.sender == owner());
        
        token.tokenUri = _uri;
        emit URI(_uri, _id);
    }

    function orderInfo(uint256 _id) public view returns (OrderInfo memory info){
        return orders[_id];
    }
    
    function tokenInfo(uint256 _id) public view returns (TokenInfo memory info) {
        return tokens[_id];
    }
    
    function tokenURI(uint256 _id) public view returns (string memory _uri) {
        TokenInfo storage token = tokens[_id];
        return token.tokenUri;
    }
   
    function uri(uint256 _id) public view override returns (string memory) {
        TokenInfo storage token = tokens[_id];
        return token.tokenUri;
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}


/**
    https://etherscan.io/token/0xfba1e2a5202ddd90aa721f7695c658045a75895a
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
    Complie Settings:
    version  v0.8.7+commit.e28d00a7
    Enable optimzation  200
*/
contract CNY1155NFT is ERC1155Mintable {

    constructor() ERC1155Mintable("CHAINSTORE", "CHAINSTORE", "https://chainstore.io") {
        //_mint(msg.sender, 3306000);
    }
    
    
    
}