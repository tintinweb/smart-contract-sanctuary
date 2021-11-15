// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * 要頒發ERC20 TOKEN給用戶的話
 * 必須先將有Token的Address(部署合約Address)執行approve
 * approve function 必須輸入可以領取該Token的Address和領取數量
 * 之後就可以用transferFrom function將Token給該用戶
 * allowance function 可查看owner授予用戶多少token
 *
 */

contract Shop is ERC20 {
    //變數宣告
    address owner;
    Item[] public Items;
    mapping(address => string[]) public UserInvntory;
    mapping(address => Order[]) public Orders;
    mapping(address => bool) public Whitelist;
    mapping(address => bool) public Cooperation;
    mapping(address => int256) public UserBonus;
    mapping(uint256 => RepairItem) public RepairItems;
    mapping(uint256 => Item) public ItemDetails;
    mapping(uint256 => RepairDetail[]) public RepairDetails;
    mapping(uint256 => string) public CommentHash;

    //結構宣告
    struct Item {
        address sender;
        string itemName;
        int256 itemPrice;
        int256 itemRepairPrice;
        int256 itemQuantity;
        int256 itemCategoryId;
        uint256 id;
        string itemDescription;
        string originalImageHash;
        string thumbnailImageHash;
        uint256 createAt;
    }

    struct RepairItem {
        address vendorAddress;
        address customerAddress;
        address sender;
        string itemName;
        uint256 createAt;
    }

    struct RepairDetail {
        string itemProblem;
        string itemDescription;
        string imageHash;
        int256 itemPrice;
        uint256 createAt;
    }

    struct Order {
        address sellerAddress;
        address buyerAddress;
        string itemName;
        int256 orderPrice;
        int256 sellerOrderId;
        int256 buyerOrderId;
        uint256 index;
        bool state;
        uint256 createAt;
    }

    struct UserInventory {
        string imagesHash;
    }

    //事件宣告

    /**
     *  Event
     *
     * 用戶創建物品時觸發該event，將用戶address用indexed紀錄，之後平台可利用該indexed查詢該筆紀錄。
     */
    event Create(
        address indexed _from,
        int256 indexed _itemCategoryId,
        string _itemName,
        uint256 _index,
        uint256 _time
    );

    /**
     *  Event
     *
     * 廠商幫用戶維修物品時觸發該event，將廠商address和用戶address用indexed紀錄，之後平台可利用該indexed查詢該筆紀錄。
     */
    event Repair(
        address indexed _from,
        address indexed _to,
        string indexed _itemProblem,
        uint256 _index,
        uint256 _time
    );

    /**
     *  Event
     *
     * 紀錄合作廠商address，indexed之後可利用平台查詢該筆紀錄。
     */
    event Coop(address indexed _vendorAddress, uint256 _time);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() ERC20("DShop", "Dtoken") {
        owner = msg.sender;
        _mint(owner, 1000000 * (10**decimals()));
    }

    modifier onlyOwner() {
        //檢查發送者是不是owner 不是的話就回傳Not Owner
        require(msg.sender == owner, "Not Owner!!!");
        _;
    }

    modifier checkEnoughBonus(address _address, int256 price) {
        require(UserBonus[_address] >= price, "User not have enough bonus");
        _;
    }

    /**
     * Modifier function
     *
     * 檢查廠商是否有足夠的Ether完成合作流程
     */
    modifier costs(uint256 _amount) {
        require(msg.value >= _amount, "Not enough Ether provided.");
        _;
        if (msg.value > _amount)
            payable(msg.sender).transfer(msg.value - _amount);
    }

    /**
     * Modifier function
     *
     * 檢查廠商是否已在白名單內
     */
    modifier checkWhitelist(address _address) {
        require(
            Whitelist[_address] == true,
            "The address does not exist in the Whiltelist"
        );
        _;
    }

    /**
     * Modifier function
     *
     * 檢查廠商是否已在合作名單內
     */
    modifier checkCooperation(address _address) {
        require(
            Cooperation[_address] == true,
            "The address does not exist in the Cooperation list"
        );
        _;
    }

    /**
     * Public function
     *
     * 將廠商的address加入白名單內，只有owner能執行這個function。
     */
    function addToWhitelist(address _address) public onlyOwner {
        Whitelist[_address] = true;
    }

    /**
     * Public Payble function
     *
     * 廠商透過該function完成合作流程，廠商必須先是白名單內的成員，之後支付x個ether後即可加入至合作名單。
     */
    function payToCooperationWithDshop(address _address)
        public
        payable
        checkWhitelist(_address)
        costs(1 ether)
    {
        Cooperation[_address] = true;
        emit Coop(_address, block.timestamp);
    }

    /**
     * Public function
     *
     * 查看智能合約擁有的Ether
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Public function
     *
     * 將智能合約內的Ether領出來，只有owner能執行。
     */
    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    /**
     * Public function
     * 待:將index改將index改為智能合約隨機生成的碼。
     * 新增商品，Item是放所有商品的陣列，ItemDetails是存放單個商品的資料，_index是商品的辨識碼。
     */
    function createItem(
        string memory _itemName,
        int256 _itemPrice,
        int256 _itemRepairPrice,
        int256 _itemQuantity,
        int256 _itemCategoryId,
        string memory _itemDescription,
        string memory _originalImageHash,
        string memory _thumbnailImageHash,
        uint256 _index
    ) public {
        Item memory newItem = Item({
            id: _index,
            itemName: _itemName,
            itemPrice: _itemPrice,
            itemRepairPrice: _itemRepairPrice,
            itemQuantity: _itemQuantity,
            itemCategoryId: _itemCategoryId,
            itemDescription: _itemDescription,
            sender: msg.sender,
            originalImageHash: _originalImageHash,
            thumbnailImageHash: _thumbnailImageHash,
            createAt: block.timestamp
        });
        Items.push(newItem);
        ItemDetails[_index] = Item({
            id: _index,
            itemName: _itemName,
            itemPrice: _itemPrice,
            itemRepairPrice: _itemRepairPrice,
            itemQuantity: _itemQuantity,
            itemCategoryId: _itemCategoryId,
            itemDescription: _itemDescription,
            sender: msg.sender,
            originalImageHash: _originalImageHash,
            thumbnailImageHash: _thumbnailImageHash,
            createAt: block.timestamp
        });
        emit Create(
            msg.sender,
            _itemCategoryId,
            _itemName,
            _index,
            block.timestamp
        );
    }

    /**
     * Public function
     * 待:將購買商品的流程想完整一點。
     * 購買商品
     */
    function buy(
        address _address,
        int256 _bonus,
        string memory _imagesHash
    ) public returns (bool) {
        UserBonus[_address] += _bonus;
        UserInvntory[_address].push(_imagesHash);
        transfer(_address, 1000);
        return true;
    }

    /**
     * Public function
     *
     * 廠商維修用戶商品
     */
    function repair(
        address _vendorAddress,
        address _customerAddress,
        string memory _itemName,
        string memory _itemDescription,
        string memory _itemProblem,
        string memory _imageHash,
        int256 _itemRepairPrice,
        uint256 _index
    ) public checkCooperation(_vendorAddress) {
        RepairItems[_index] = RepairItem({
            vendorAddress: _vendorAddress,
            customerAddress: _customerAddress,
            sender: msg.sender,
            itemName: _itemName,
            createAt: block.timestamp
        });
        RepairDetails[_index].push(
            RepairDetail(
                _itemProblem,
                _itemDescription,
                _imageHash,
                _itemRepairPrice,
                block.timestamp
            )
        );
        emit Repair(
            _vendorAddress,
            _customerAddress,
            _itemProblem,
            _index,
            block.timestamp
        );
    }

    /**
     * Public function
     *
     * 用戶下訂單，在買方和賣方的訂單紀錄裏面都會各紀錄一筆，初始狀態都是false代表訂單未完成。
     */
    function order(
        address _sellerAddress,
        address _buyerAddress,
        string memory _itemName,
        int256 _itemPrice,
        uint256 _index,
        int256 _sellerOrderNo,
        int256 _buyerOrderNo
    ) public {
        Orders[_sellerAddress].push(
            Order(
                _sellerAddress,
                _buyerAddress,
                _itemName,
                _itemPrice,
                _sellerOrderNo,
                _buyerOrderNo,
                _index,
                false,
                block.timestamp
            )
        );
        Orders[_buyerAddress].push(
            Order(
                _sellerAddress,
                _buyerAddress,
                _itemName,
                _itemPrice,
                _sellerOrderNo,
                _buyerOrderNo,
                _index,
                false,
                block.timestamp
            )
        );
    }

    /**
     * Public function
     * 待:下訂單後雙方必須再同意一次
     * 更改用戶訂單狀態，將雙方訂單更改為已完成，即賣家同意買家提出之價格或是以原價購買。
     */
    function checkOrderState(
        address _sellerAddress,
        address _buyerAddress,
        uint256 _sellerIndex,
        uint256 _buyerIndex
    ) public {
        Orders[_sellerAddress][_sellerIndex].state = true;
        Orders[_buyerAddress][_buyerIndex].state = true;
    }

    /**
     * Public function
     * 待:下訂單後雙方必須再同意一次
     * 將某商品的商品留言記錄下來並上傳到IPFS，該留言陣列只紀錄IPFS Hash。
     */
    function setCommentHash(uint256 _index, string memory _commentHash) public {
        CommentHash[_index] = _commentHash;
    }

    /**
     * Public function
     * 待:消耗ERC20來兌換物品，並想好一套與贈品廠商合作的流程，或是折價機制。
     * 兌換獎品
     */
    function exchangeGift(address _address, int256 price)
        public
        checkEnoughBonus(_address, price)
        returns (bool)
    {
        UserBonus[_address] -= price;
        return true;
    }

    /**
     * Public function
     *
     * 回傳所有商品資訊
     */
    function getAllItemsData() public view returns (Item[] memory) {
        return Items;
    }

    /**
     * Public function
     *
     * 根據用戶Address回傳訂單資訊
     */
    function getOrder(address _address) public view returns (Order[] memory) {
        return Orders[_address];
    }

    /**
     * Public function
     *
     * 透過輸入商品辨識碼，回傳維修商品資訊。
     */
    function getRepairDetail(uint256 _index)
        public
        view
        returns (RepairDetail[] memory)
    {
        return RepairDetails[_index];
    }

    function getUserInventory(address _address)
        public
        view
        returns (string[] memory)
    {
        return UserInvntory[_address];
    }

    function getOrderLength(address _address) public view returns (uint256) {
        return Orders[_address].length;
    }
}

