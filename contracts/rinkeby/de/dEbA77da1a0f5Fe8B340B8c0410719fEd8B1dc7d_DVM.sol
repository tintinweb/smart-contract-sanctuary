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

import "./ERC20.sol";
import "./Struct.sol";

/**
 * 要頒發ERC20 TOKEN給用戶的話
 * 必須先將有Token的Address(部署合約Address)執行approve
 * approve function 必須輸入可以領取該Token的Address和領取數量
 * 之後就可以用transferFrom function將Token給該用戶
 * allowance function 可查看owner授予用戶多少token
 * 當用戶有一定的token時就可以執行transfer把token轉給其他人
 */

contract DVM is ERC20 {
    constructor() ERC20("DVM", "V-Token") {
        owner = msg.sender;
        _mint(owner, 1000000 * (10**decimals()));
    }

    //變數宣告
    address owner;
    //
    VehicleSale[] VehicleSaleArr;
    //廠商查看自己最後一次的合約上傳紀錄 是否已通過平台審核
    mapping(address => VendorCoopData) public ContractApprove;
    mapping(address => Order[]) public Orders;
    mapping(address => bool) public Whitelist;
    mapping(address => bool) public Cooperation;
    mapping(string => VehicleMaintain) public VehicleMaintainData;
    mapping(string => Vehicle) public Vehicles;
    mapping(string => VehicleSale) public VehiclesSale;
    //廠商當前的審核階段
    mapping(address => ContractProgress) public VendorCoopStage;

    //事件宣告

    /**
     *  Event
     *
     * 廠商登記汽車時觸發該event，該event會在後台有歷史紀錄 讓廠商和顧客看到資料被登記
     */

    event VehicleRecord(
        string indexed _VIN,
        address indexed _owner,
        address indexed _sender,
        string _vMake,
        string _vModel,
        uint256 _createAt
    );

    /**
     *  Event
     *
     * 用戶上傳二手車時觸發該event。
     */

    event VehicleSaleRecord(
        string indexed _VIN,
        string indexed _vMake,
        address indexed _seller,
        string _vVIN,
        uint32 _vPrice,
        uint256 _createAt
    );

    /**
     *  Event
     *
     * 廠商幫用戶維修時觸發該event，該event會在後台有歷史紀錄 讓廠商和顧客看到資料被登記
     */
    event VehicleMaintenRecord(
        string indexed _VIN,
        address indexed _vendorAddress,
        address indexed _customerAddress,
        int8 _vMaintainType,
        string _vDescription,
        string _vVIN,
        string _vImageHash,
        uint24 _vMile,
        uint32 _vPrice,
        uint256 _createAt
    );

    /**
     *  Event
     *
     * 廠商幫用戶登記意外事件時觸發event
     */
    event VehicleAccidentRecord(
        string indexed _VIN,
        address indexed _vendorAddress,
        address indexed _customerAddress,
        int8 _vAccidentType,
        string _vDescription,
        string _vVIN,
        string _vImageHash,
        uint24 _vMile,
        uint256 _createAt
    );

    /**
     *  Event
     *
     * 紀錄合作廠商address，indexed之後可利用平台查詢該筆紀錄。
     */
    event Coop(address indexed _vendorAddress, uint256 _time);
    /**
     *  Event
     *
     * 廠商上傳合約後觸發該event，廠商自己可利用該event查看自己上傳的歷史紀錄。
     */
    event VendorUploadContract(
        address indexed _vendorAddress,
        string _passwordHash,
        string _contractHash,
        uint256 _createAt
    );

    /**
     *  Event
     *
     * 買家下訂商品時觸發該event，可以在商品頁面帶入下訂商品的歷史紀錄，買家也可以在後台查看自己曾經下訂過哪些商品。
     */
    event buyerBuyOrBidItem(
        uint256 indexed _identifyCode,
        address indexed _buyerAddress,
        int256 _itemPrice,
        string _itemName
    );
    //修飾符宣告

    modifier onlyOwner() {
        //檢查發送者是不是owner 不是的話就回傳Not Owner
        require(msg.sender == owner, "Not Owner!!!");
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
        require(Whitelist[_address] == true);
        _;
    }

    /**
     * Modifier function
     *
     * 檢查廠商是否已在合作名單內
     */
    modifier checkCooperation(address _address) {
        require(Cooperation[_address] == true);
        _;
    }

    modifier startContract(address _address) {
        require(VendorCoopStage[_address] == ContractProgress.START);
        _;
    }

    modifier payContract(address _address) {
        require(VendorCoopStage[_address] == ContractProgress.PAY);
        _;
    }

    modifier pendingContract(address _address) {
        require(VendorCoopStage[_address] == ContractProgress.PENDING);
        _;
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

    function uploadVehicleData(
        uint24 _vMile,
        address _customerAddress,
        string memory _vMake,
        string memory _vModel,
        string memory _vListed,
        string memory _vTransmission,
        string memory _vColor,
        string memory _vEnergy,
        string memory _vExhaust,
        string memory _VIN
    ) public {
        Vehicles[_VIN] = Vehicle({
            owner: _customerAddress,
            vMake: _vMake,
            vModel: _vModel,
            vListed: _vListed,
            vTransmission: _vTransmission,
            vColor: _vColor,
            vEnergy: _vEnergy,
            vMile: _vMile,
            vExhaust: _vExhaust,
            vPreviousOwner: 0,
            vAccident: 0,
            vMaintain: 0
        });

        emit VehicleRecord(
            _VIN,
            _customerAddress,
            msg.sender,
            _vMake,
            _vModel,
            block.timestamp
        );
    }

    function saleVehicle(
        string memory _VIN,
        uint32 _vPrice,
        uint24 _vMile,
        string memory _vLocal,
        string memory _vMake,
        string memory _vDescription,
        string memory _vBigImageHash,
        string memory _vSmallImageHash,
        string memory _vListed,
        bool _smoke
    ) public {
        VehiclesSale[_VIN] = VehicleSale({
            VIN: _VIN,
            vPrice: _vPrice,
            vLocal: _vLocal,
            vDescription: _vDescription,
            vBigImageHash: _vBigImageHash,
            vSmallImageHash: _vSmallImageHash,
            vListed: _vListed,
            vMile: _vMile,
            smoke: _smoke
        });

        VehicleSaleArr.push(
            VehicleSale(
                _VIN,
                _vPrice,
                _vLocal,
                _vDescription,
                _vBigImageHash,
                _vSmallImageHash,
                _vListed,
                _vMile,
                _smoke
            )
        );

        emit VehicleSaleRecord(
            _VIN,
            _vMake,
            msg.sender,
            _VIN,
            _vPrice,
            block.timestamp
        );
    }

    /**
     * Public function
     *
     * 廠商維修用戶商品
     */
    function maintainVehicle(
        string memory _VIN,
        address _vendorAddress,
        address _customerAddress,
        uint32 _vPrice,
        uint24 _vMile,
        int8 _vMaintainType,
        string memory _vDescription,
        string memory _vImageHash
    ) public checkCooperation(_vendorAddress) {
        //搜尋VIN會帶出之前維修過的資訊
        VehicleMaintainData[_VIN] = VehicleMaintain({
            vendorAddress: _vendorAddress,
            customerAddress: _customerAddress,
            vMaintainType: _vMaintainType,
            vDescription: _vDescription,
            vImageHash: _vImageHash,
            vMile: _vMile,
            vPrice: _vPrice,
            createAt: block.timestamp
        });

        Vehicles[_VIN].vMaintain += 1;

        emit VehicleMaintenRecord(
            _VIN,
            _vendorAddress,
            _customerAddress,
            _vMaintainType,
            _vDescription,
            _VIN,
            _vImageHash,
            _vMile,
            _vPrice,
            block.timestamp
        );
    }

    function accidentVehicle(
        string memory _VIN,
        address _vendorAddress,
        address _customerAddress,
        int8 _vAccidentType,
        string memory _vDescription,
        string memory _vImageHash,
        uint24 _vMile
    ) public checkCooperation(_vendorAddress) {
        Vehicles[_VIN].vAccident += 1;
        emit VehicleAccidentRecord(
            _VIN,
            _vendorAddress,
            _customerAddress,
            _vAccidentType,
            _vDescription,
            _VIN,
            _vImageHash,
            _vMile,
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
        emit buyerBuyOrBidItem(_index, _buyerAddress, _itemPrice, _itemName);
    }

    /**
     * Public function
     * 待:下訂單後雙方必須再同意一次
     * 更改用戶訂單狀態，將雙方訂單更改為已完成，即賣家同意買家提出之價格或是以原價購買。
     */
    function updateOrderState(
        address _sellerAddress,
        address _buyerAddress,
        uint256 _sellerIndex,
        uint256 _buyerIndex
    ) public {
        Orders[_sellerAddress][_sellerIndex].state = true;
        Orders[_buyerAddress][_buyerIndex].state = true;
    }

    /* -------------------------------------電子合約-----------------------------------------------  */
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
        payContract(_address)
        costs(1 ether)
    {
        Cooperation[_address] = true;
        ContractApprove[_address].stage = 3;
        VendorCoopStage[_address] = ContractProgress.SUCCESS;
        emit Coop(_address, block.timestamp);
    }

    /**
     * Public function
     *
     * 廠商上傳電子合約Hash，該過程完成後廠商的合作流程更改為PENDING。
     */
    function vendorUploadContractHash(
        address _address,
        string memory _passwordHash,
        string memory _contractHash
    ) public checkWhitelist(_address) startContract(_address) {
        VendorCoopStage[_address] = ContractProgress.PENDING;
        ContractApprove[_address] = VendorCoopData({
            vendorAddrss: _address,
            contractHash: _contractHash,
            passwordHash: _passwordHash,
            stage: 1,
            coop: false
        });
        emit VendorUploadContract(
            _address,
            _passwordHash,
            _contractHash,
            block.timestamp
        );
    }

    /**
     * Public function
     *
     * 平台同意廠商電子合約內容，並將廠商的合作狀態改為付款。
     */
    function approveVendorContract(address _address)
        public
        onlyOwner
        pendingContract(_address)
    {
        VendorCoopStage[_address] = ContractProgress.PAY;
        ContractApprove[_address].stage = 2;
        ContractApprove[_address].coop = true;
    }

    /**
     * Public function
     *
     * 平台拒絕廠商電子合約內容，並將廠商的合作狀態改為初始。
     */
    function rejectVendorContract(address _address)
        public
        onlyOwner
        pendingContract(_address)
    {
        ContractApprove[_address].stage = 0;
        VendorCoopStage[_address] = ContractProgress.START;
    }

    /* -------------------------------------電子合約-----------------------------------------------  */

    /**
     * Public function
     *
     * 根據用戶Address回傳訂單資訊
     */
    function getOrder(address _address) public view returns (Order[] memory) {
        return Orders[_address];
    }

    function getVehicles() public view returns (VehicleSale[] memory) {
        return VehicleSaleArr;
    }

    /**
     * Public function
     *
     * 查看智能合約擁有的Ether
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOrderLength(address _address) public view returns (uint256) {
        return Orders[_address].length;
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
enum ContractProgress {
    START,
    PENDING,
    PAY,
    SUCCESS,
    DECRYPT
}

struct Vehicle {
    address owner;
    string vMake;
    string vModel;
    string vListed;
    string vTransmission;
    string vColor;
    string vEnergy;
    string vExhaust;
    uint8 vPreviousOwner;
    uint16 vAccident;
    uint16 vMaintain;
    uint24 vMile;
}

struct VehicleSale {
    string VIN;
    uint32 vPrice;
    string vLocal;
    string vDescription;
    string vBigImageHash;
    string vSmallImageHash;
    string vListed;
    uint24 vMile;
    bool smoke;
}

struct VehicleMaintain {
    address vendorAddress;
    address customerAddress;
    int8 vMaintainType;
    string vDescription;
    string vImageHash;
    uint24 vMile;
    uint32 vPrice;
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

struct VendorCoopData {
    address vendorAddrss;
    string contractHash;
    string passwordHash;
    int256 stage;
    bool coop;
}

