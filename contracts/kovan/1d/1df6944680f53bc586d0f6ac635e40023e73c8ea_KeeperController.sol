/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange{
    /* ================= Functions ================= */
    function buyComponents(address _component, uint256 _value, uint256 _wethQuantity) external;
    function change() external;
    function wthto() external;
}
interface IWethPool{
    /*============ Functions ================ */
    function withdraw(address payable _userAddress, uint256 _withdrawAmount) external returns (bool);
    function ffp(uint256 _amount) external returns (bool);
}

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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


interface IWeth is IERC20{
    /* ================= Functions ================= */
    function deposit()
        external
        payable;
    function withdraw(
        uint256 wad
    )
        external;
}

interface IKeepRegistry {
    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function getMinBalanceForUpkeep(uint256 id)
        external
        view
        returns (uint96 minBalance);

    function addFunds(uint256 id, uint96 amount) external;
}

interface IPrice{
    /*=============== Functions ========================*/
    function getxPrice() external returns (uint256);

    function getyPrice(uint256 _bbb) external returns (uint256,uint256,uint256);
    
    function getzPrice() external returns (uint256);
     
    function getwPrice(address _aaa) external returns(uint256);

    function getLinkPrice() external returns(uint256);
}

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}


contract KeeperController is KeeperCompatibleInterface{

    using SafeMath for uint256;
    /* ================ Events ================== */
    
    event KeeperIDsSetted(uint256 _aKeeperId, uint256 _bKeeperId, uint256 _cKeeperId, uint256 _dKeeperId, uint256 _eKeeperId, uint256 _fKeeperId);
    event PriceSetted(address _priceAddress);
    event KeeperRegistrySetted(address _keeperRegistryAddress);

    /* ================ State Variables ================== */

    address public linkToken;
    address private owner;
    address public wethPoolAddress;
    address public exchangeAddress;
    address public keeperRegistryAddress;
    uint256 public constant MAX_INT = 2**256 - 1;
    // chainlink keeper id of a contract
    uint256 public aKeeperId;
    // chainlink keeper id of b contract
    uint256 public bKeeperId;
    // chainlink keeper id of c  contract
    uint256 public cKeeperId;
    // chainlink keeper id of d contract
    uint256 public dKeeperId;
    // chainlink keeper id of e contract
    uint256 public eKeeperId;
    // chainlink keeper id of this contract
    uint256 public selfKeeperId;
    // for self keeper
    uint96 public selfKeeperRequirementPercentage;
    // for other keeper
    uint96 public keeperRequirementPercentage;
    // struct map of keepers
    mapping(uint256 => KeeperBalances) public keeperBalancesMap;
    // importing chainlink keeper methods
    IKeepRegistry public keeper;
    IExchange private exchange;
    IWethPool private wethPool;
    IWeth private weth;
    IPrice private price;
    // info of Keepers
    struct KeeperBalances{
        uint96 minBalance;
        uint96 currentBalance;
        uint96 requirement;
    }

    /* ================= Modifiers ================= */
    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }


    /* ================ Constructor ================== */
    constructor(
        address _weth,
        address _linkToken,
        address _exchangeAddress,
        address _wethPoolAddress,
        address _priceAddress,
        address _keeperRegistryAddress,
        uint96 _selfKeeperRequirementPercentage,
        uint96 _keeperRequirementPercentage
    ) {
        owner = msg.sender;
        keeper = IKeepRegistry(_keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
        weth = IWeth(_weth);
        linkToken = _linkToken;
        exchangeAddress = _exchangeAddress;
        exchange = IExchange(_exchangeAddress);
        wethPoolAddress = _wethPoolAddress;
        wethPool = IWethPool(wethPoolAddress);
        price = IPrice(_priceAddress);
        require(_selfKeeperRequirementPercentage != 0, "not zero");
        selfKeeperRequirementPercentage = _selfKeeperRequirementPercentage;
        require(_keeperRequirementPercentage != 0, "not zero");
        keeperRequirementPercentage = _keeperRequirementPercentage;
    }
    
    /* ================ Functions ================== */
    /* ================ Public Functions ================== */

    function setKeeperIDs(
        uint256 _aKeeperId,
        uint256 _bKeeperId,
        uint256 _cKeeperId,
        uint256 _dKeeperId,
        uint256 _eKeeperId,
        uint256 _selfKeeperId
    ) public returns(uint256,uint256,uint256,uint256,uint256,uint256){
        require(_aKeeperId != 0);
        aKeeperId = _aKeeperId;
        require(_bKeeperId != 0);
        bKeeperId = _bKeeperId;
        require(_cKeeperId != 0);
        cKeeperId = _cKeeperId;
        require(_dKeeperId != 0);
        dKeeperId = _dKeeperId;
        require(_eKeeperId != 0);
        eKeeperId = _eKeeperId;
        require(_selfKeeperId != 0);
        selfKeeperId = _selfKeeperId;
        emit KeeperIDsSetted(_aKeeperId, _bKeeperId, _cKeeperId, _dKeeperId, _eKeeperId, _selfKeeperId);
        return (aKeeperId, bKeeperId, cKeeperId, dKeeperId, eKeeperId, selfKeeperId);
    }


    /*
     * Notice: Setting keeper registry contract address
     * Params:
     * '_keeperRegistryAddress' The keeper registry contract address
     */
    function setKeeperRegistry(
        address _keeperRegistryAddress
    ) public returns(address){
        keeper = IKeepRegistry(_keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
        emit KeeperRegistrySetted(keeperRegistryAddress);
        return keeperRegistryAddress;
    }

    /*
     * Notice: Setting keeper keeper percentage
     * Params:
     * '_fKeeperRequirementPercentage' The f keeper percentage
     * '_keeperRequirementPercentage' The other keeper percentage
     */
    function setKeeperPercentage(
        uint96 _selfKeeperRequirementPercentage,
        uint96 _keeperRequirementPercentage
    ) public returns(uint96,uint96){
        require(_selfKeeperRequirementPercentage != 0, "not zero");
        selfKeeperRequirementPercentage = _selfKeeperRequirementPercentage;
        require(_keeperRequirementPercentage != 0, "not zero");
        keeperRequirementPercentage = _keeperRequirementPercentage;
        return (selfKeeperRequirementPercentage, keeperRequirementPercentage);
    }
    
    /*
     * Notice: KeeperRegistryAddress approve to link token
     */
    function approveLink() public onlyOwner {
        ERC20 _link = ERC20(linkToken);
        bool _success = _link.approve(keeperRegistryAddress, MAX_INT);
        require(_success, "Approve failed");
    }


    /* ================ External Functions ================== */

    receive() external payable{}

    
    /*
     * Notice: chainlink keeper method. It controls boolean value for execute perfomUpkeep
     */
    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        getVariables();
        upkeepNeeded =
            keeperBalancesMap[aKeeperId].currentBalance < keeperBalancesMap[aKeeperId].requirement ||
            keeperBalancesMap[bKeeperId].currentBalance < keeperBalancesMap[bKeeperId].requirement ||
            keeperBalancesMap[cKeeperId].currentBalance < keeperBalancesMap[cKeeperId].requirement||
            keeperBalancesMap[dKeeperId].currentBalance < keeperBalancesMap[dKeeperId].requirement ||
            keeperBalancesMap[eKeeperId].currentBalance < keeperBalancesMap[eKeeperId].requirement ||
            keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement;
        performData = checkData;
    }

    /*
     * Notice: chainlink keeper method. It executes controller method
     */
    function performUpkeep(bytes calldata performData) external override {
        require((keeperBalancesMap[aKeeperId].currentBalance < keeperBalancesMap[aKeeperId].requirement ||
            keeperBalancesMap[bKeeperId].currentBalance < keeperBalancesMap[bKeeperId].requirement ||
            keeperBalancesMap[cKeeperId].currentBalance < keeperBalancesMap[cKeeperId].requirement||
            keeperBalancesMap[dKeeperId].currentBalance < keeperBalancesMap[dKeeperId].requirement ||
            keeperBalancesMap[eKeeperId].currentBalance < keeperBalancesMap[eKeeperId].requirement ||
            keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement), "not epoch");
            uint96 _value;
            if(keeperBalancesMap[aKeeperId].currentBalance < keeperBalancesMap[aKeeperId].requirement){
                _value = keeperBalancesMap[aKeeperId].requirement - keeperBalancesMap[aKeeperId].currentBalance;
            }
            if(keeperBalancesMap[bKeeperId].currentBalance < keeperBalancesMap[bKeeperId].requirement){
                _value = _value + (keeperBalancesMap[bKeeperId].requirement - keeperBalancesMap[bKeeperId].currentBalance);
            }
            if(keeperBalancesMap[cKeeperId].currentBalance < keeperBalancesMap[cKeeperId].requirement){
                _value = _value + (keeperBalancesMap[cKeeperId].requirement - keeperBalancesMap[cKeeperId].currentBalance);
            }
            if(keeperBalancesMap[dKeeperId].currentBalance < keeperBalancesMap[dKeeperId].requirement){
                _value = _value + (keeperBalancesMap[dKeeperId].requirement - keeperBalancesMap[dKeeperId].currentBalance);
            }
            if(keeperBalancesMap[eKeeperId].currentBalance < keeperBalancesMap[eKeeperId].requirement){
                _value = _value + (keeperBalancesMap[eKeeperId].requirement - keeperBalancesMap[eKeeperId].currentBalance);
            }
            if(keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement){
                _value = _value + (keeperBalancesMap[selfKeeperId].requirement - keeperBalancesMap[selfKeeperId].currentBalance);
            }
        controller(_value);
        performData;
    }
    
    /* ================ Internal Functions ================== */

    /*
     * Notice: brings ether from weth pool
     * Param:
     * '_wethQuantity' Quantity of ether to bring
     */
    function bringEth(uint256 _wethQuantity) public {
        address payable _payableThis = payable(address(this));
        wethPool.withdraw(_payableThis, _wethQuantity);
        weth.deposit{value: _wethQuantity}();
        weth.transfer(exchangeAddress, _wethQuantity);
    }
     /*
     * Notice: this method buys link token
     * Param:
     * '_linkQuantity' Quantity of link token to swap
     * '_wethQuantity' Quantity of wrapped ether to swap with link token 
     */
    function buyLink(uint256 _linkQuantity, uint256 _wethQuantity) public {
        bringEth(_wethQuantity);
        exchange.buyComponents(linkToken, _linkQuantity, _wethQuantity);
        exchange.wthto();
    }

    /*
     * Notice: this method reads minBalance and balance variables 
               from chainlink keepRegistry contract
               Calculating and comparing requirements
    * Returns: minBalances, balances and requirements for all keepers
    */
    function getVariables() public
    {

        KeeperBalances memory _taumKeeper;
        _taumKeeper.minBalance = keeper.getMinBalanceForUpkeep(aKeeperId);
        (, , , _taumKeeper.currentBalance, , , ) = keeper.getUpkeep(aKeeperId);
        _taumKeeper.requirement = _taumKeeper.minBalance*keeperRequirementPercentage;
        keeperBalancesMap[aKeeperId] = _taumKeeper;

        KeeperBalances memory _bKeeper;
        _bKeeper.minBalance = keeper.getMinBalanceForUpkeep(bKeeperId);
        (, , , _bKeeper.currentBalance, , , ) = keeper.getUpkeep(bKeeperId);
        _bKeeper.requirement = _bKeeper.minBalance*keeperRequirementPercentage;
        keeperBalancesMap[bKeeperId] = _bKeeper;

        KeeperBalances memory _cKeeper;
        _cKeeper.minBalance = keeper.getMinBalanceForUpkeep(cKeeperId);
        (, , , _cKeeper.currentBalance, , , ) = keeper.getUpkeep(cKeeperId);
        _cKeeper.requirement = _cKeeper.minBalance*keeperRequirementPercentage;
        keeperBalancesMap[cKeeperId] = _cKeeper;

        KeeperBalances memory _dKeeper;
        _dKeeper.minBalance = keeper.getMinBalanceForUpkeep(dKeeperId);
        (, , , _dKeeper.currentBalance, , , ) = keeper.getUpkeep(dKeeperId);
        _dKeeper.requirement = _dKeeper.minBalance*keeperRequirementPercentage;
        keeperBalancesMap[dKeeperId] = _dKeeper;

        KeeperBalances memory _eKeeper;
        _eKeeper.minBalance = keeper.getMinBalanceForUpkeep(eKeeperId);
        (, , , _eKeeper.currentBalance, , , ) = keeper.getUpkeep(eKeeperId);
        _eKeeper.requirement = _eKeeper.minBalance*keeperRequirementPercentage;
        keeperBalancesMap[eKeeperId] = _eKeeper;

        KeeperBalances memory _selfKeeper;
        _selfKeeper.minBalance = keeper.getMinBalanceForUpkeep(selfKeeperId);
        (, , , _selfKeeper.currentBalance, , , ) = keeper.getUpkeep(selfKeeperId);
        _selfKeeper.requirement = _selfKeeper.minBalance*selfKeeperRequirementPercentage;
        keeperBalancesMap[selfKeeperId] = _selfKeeper;

    }

    /*
     * Notice: this method buys link token as needed
                executes from chainlink keeper
     * Params: minBalances, balances and requirements of all keepers for buy link token.
     */
    function controller(uint96 value) public {
        
        uint96 _preLinkToBuy = value * 20 / 100;
        uint96 _linkToBuy = value + _preLinkToBuy;
        uint256 _wethQuantity = (uint256(_linkToBuy)).mul(price.getLinkPrice()).div(10**18);
        buyLink(uint256(value), _wethQuantity);
        KeeperBalances memory _a = keeperBalancesMap[aKeeperId];
        KeeperBalances memory _b = keeperBalancesMap[bKeeperId];
        KeeperBalances memory _c = keeperBalancesMap[cKeeperId];
        KeeperBalances memory _d = keeperBalancesMap[dKeeperId];
        KeeperBalances memory _e = keeperBalancesMap[eKeeperId];
        KeeperBalances memory _self = keeperBalancesMap[selfKeeperId];

        if (_a.currentBalance < _a.requirement) {
            uint96 _linkQuantity = _a.requirement - _a.currentBalance;
            keeper.addFunds(aKeeperId, _linkQuantity);
        }
        if (_b.currentBalance < _b.requirement) {
            uint96 _linkQuantity = _b.requirement - _b.currentBalance;
            keeper.addFunds(bKeeperId, _linkQuantity);
        }
        if (_c.currentBalance < _c.requirement) {
            uint96 _linkQuantity = _c.requirement - _c.currentBalance;
            keeper.addFunds(cKeeperId, _linkQuantity);
        }
        if (_d.currentBalance < _d.requirement) {
            uint96 _linkQuantity = _d.requirement - _d.currentBalance;
            keeper.addFunds(dKeeperId, _linkQuantity);
        }
        if (_e.currentBalance < _e.requirement) {
            uint96 _linkQuantity = _e.requirement - _e.currentBalance;
            keeper.addFunds(eKeeperId, _linkQuantity);
        }
        if (_self.currentBalance < _self.requirement) {
            uint96 _linkQuantity = _self.requirement - _self.currentBalance;
            keeper.addFunds(selfKeeperId, _linkQuantity);
        }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}