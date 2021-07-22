/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


// SPDX-License-Identifier: UNLICENSED
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

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol





/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: node_modules\@myContracts\contracts\accesser\DividendAccess.sol




abstract contract DividendAccess {
    mapping(address => bool) box;
    address dividendRoleAdmin;

    modifier onlyDividendRole() {
        require(box[msg.sender], "Only Dividend Role Permitted");
        _;
    }
    modifier onlyDividendRoleAdmin() {
        require(dividendRoleAdmin == msg.sender, "Only Dividend Role Admin Permitted");
        _;
    }

    constructor() {
        dividendRoleAdmin = msg.sender;
        grantDividendRole(msg.sender);
    }

    function isDividendRole() public view returns (bool) {
        return box[msg.sender];
    }

    function grantDividendRole(address addr_) public onlyDividendRoleAdmin {
        box[addr_] = true;
    }

    function revokeDividendRole(address addr_) public onlyDividendRoleAdmin {
        box[addr_] = false;
    }
}

// File: @myContracts\contracts\ico\ICOTiered.sol




// import "@myContracts/contracts/accesser/ICOAccess.sol";
//import "../accesser/ICOAccess.sol";


abstract contract ICOTiered is DividendAccess {
    struct IcoBox {
        uint256 price;
        uint256 lowest;
        uint256 highest;
    }
    mapping(uint256 => IcoBox) public icoConfig;
    uint256 icoLevel;
    function setIcoConfig(uint256 level, uint256 lowest, uint256 highest, uint256 price) public onlyDividendRole {
        icoConfig[level] = IcoBox(price, lowest, highest);
        if (icoLevel < level) icoLevel = level;
    }
    function _getTokenAmount(uint256 weiAmount) public virtual view returns (uint256) {
        for (uint8 i = 1; i <= icoLevel; i++) {
            if (weiAmount >= icoConfig[i].lowest && weiAmount < icoConfig[i].highest) {
                return weiAmount * icoConfig[i].price;
            }
        }
        return 0;
    }
}

// File: @myContracts\contracts\ico\ICOUtm.sol




// import "@myContracts/contracts/accesser/ICOAccess.sol";
//import "../accesser/ICOAccess.sol";


abstract contract ICOUtm is DividendAccess {
    struct UtmBox {
        uint256 defaultICOUtmRate;
        mapping(address => uint256) spreadersRate;
        address[] spreaderList;
    }
    mapping(uint256 => UtmBox) utmBox;      // 0 token, 1 eth

    function updateDefaultICOUtmRate(uint256 rate, uint256 no) public onlyDividendRole {
        utmBox[no].defaultICOUtmRate = rate;
    }

    function grantICOUtm(address addr, uint256 rate, uint256 no) public onlyDividendRole {
        if (utmBox[no].spreadersRate[addr] == 0) utmBox[no].spreaderList.push(addr);
        utmBox[no].spreadersRate[addr] = rate;
    }

    function revokeICOUtm(address addr, uint256 no) public onlyDividendRole {
        utmBox[no].spreadersRate[addr] = utmBox[no].defaultICOUtmRate;
    }

    function getICOUtmRate(address addr, uint256 no) public view onlyDividendRole returns(uint256) {
        return _getICOUtmRate(addr, no);
    }

    function _getICOUtmRate(address addr, uint256 no) internal view returns(uint256) {
        return utmBox[no].spreadersRate[addr]==0
        ?utmBox[no].defaultICOUtmRate
        :utmBox[no].spreadersRate[addr];
    }

    function getICOUtmList(uint256 no) public view onlyDividendRole returns(address[] memory) {
        return utmBox[no].spreaderList;
    }

    function getUtmPrize(address addr, uint256 amount, uint256 no) internal view returns(uint256) {
        uint256 prizeRate = _getICOUtmRate(addr, no);
        return amount * prizeRate / 100;
    }
}

// File: @openzeppelin\contracts\utils\Context.sol





/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol





// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol






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

// File: @myContracts\contracts\token\ERC20\KeyBasedERC20.sol








contract KeyBasedERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return calcYFromX(_balances[account]);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        (,,,uint256 amountLeft_) = _beforeRealMoveFilter(sender, recipient, amount, amount);

        _realMove(sender, recipient, amountLeft_);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    function _afterRealMove() internal virtual {}

    function _beforeRealMoveFilter(address from, address to, uint256 amount, uint256 amountLeft) internal virtual returns(address from_, address to_, uint256, uint256 amountLeft_){
        return (from,to,amount,amountLeft);
    }
    function _realMove(address from, address to, uint256 amount) internal {
        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
//        require(fromBalance >= amount, Strings.toString(fromBalance));
//        require(fromBalance >= amount, Strings.toString(amount));

        _balances[from] = calcYFromX(fromBalance - amount);
        _balances[to] += calcYFromX(amount);

        emit Transfer(from, to, amount);
    }

    event UpdateK(uint256 oldK, uint256 newK);

    uint256 kBase = 10**decimals(); // Avoid decimal calculations
    uint256 public k = 1 * kBase; // initial as it self with 1
    function updateK(uint256 newK) internal {require(newK > k); emit UpdateK(k, newK); k = newK;}
    function calcYFromX(uint256 x) private view returns (uint256) {return x * k / kBase;}
    function calcXFromY(uint256 y) private view returns (uint256) {return y * kBase / k;}
}

// File: @myContracts\contracts\token\ERC20\FeeHandler.sol








contract FeeHandler is DividendAccess, KeyBasedERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    )
    KeyBasedERC20(name_, symbol_) {}
    struct Fee {
        bool exists;
        string feeName;     // burn/dividend/fund
        uint256 percent;    // */100
        address feeTo;
        uint256 remainMinTotalSupply;   // eg: burn. if not keep ,will burn all to zero
    }

    address public blackHole = address(0x000000000000000000000000000000000000dEaD);
    mapping(uint256 => Fee) public feeConfig;
    uint256[] feeNames;

    function addFeeConfig(string memory feeName, uint256 percent, address feeTo, uint256 remainMinTotalSupply) public onlyDividendRole {
        uint256 feeNameBytes = uint256(keccak256(abi.encodePacked(feeName)));
        if (!feeConfig[feeNameBytes].exists) {
            feeNames.push(feeNameBytes);
        }
        feeConfig[feeNameBytes] = Fee(true, feeName, percent, feeTo, remainMinTotalSupply);
    }

//    function _beforeRealMoveFilter(address from, address to, uint256 amount, uint256 amountLeft)
//        internal virtual override returns (address from_, address to_, uint256, uint256 amountLeft_){
//
//        uint256 fees = _handAllFees(amount);
//
//        return super._beforeRealMoveFilter(from, to, amount, amountLeft - fees);
//    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        _handAllFees(from, amount);
        return super._beforeTokenTransfer(from, to, amount);
    }

    function _handAllFees(address from, uint256 amount) private {
        if (!isDividendRole()) {
            _feeCheck(from, amount);
            for (uint i=0;i<feeNames.length;i++) {
                uint256 fee = amount * feeConfig[feeNames[i]].percent / 100;
                if (fee > 0 && totalSupply() - super.balanceOf(blackHole) > feeConfig[feeNames[i]].remainMinTotalSupply) {
                    super._realMove(from, feeConfig[feeNames[i]].feeTo, fee);
                }
            }
        }
    }

    function _feeCheck(address from, uint256 amount) private view {
        uint256 feeTotal;

        for (uint i=0;i<feeNames.length;i++) {
            uint256 fee = amount * feeConfig[feeNames[i]].percent / 100;
            if (fee > 0 && totalSupply() - super.balanceOf(blackHole) > feeConfig[feeNames[i]].remainMinTotalSupply) {
                feeTotal += fee;
            }
        }

        if (feeTotal>0) require(super.balanceOf(from) > feeTotal+amount, "balance+fee not enough.");
    }
}

// File: @myContracts\contracts\token\ERC20\Dividend.sol







contract Dividend is DividendAccess,FeeHandler {

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 dividendPercent)
        FeeHandler(name_, symbol_)
    {
        addFeeConfig("dividend", dividendPercent, address(this), 0);
    }

    // keep coin for dividend core
    address GOLD_BLESS_YOU = address(1);    // black hole 1

    uint256 public dividendThreshold = 999999 * 10 ** decimals(); // use for auto dividend
    bool public autoDividend = false;
    bool public realtimeDividend = false;

    event DividendEvent(uint256 total);
    event ChangeDividendThreshold(uint256 oldKDividendThreshold, uint256 newKDividendThreshold);

    bool kUnLock;
    modifier onlyKUnLock() {
        require(kUnLock, "wait for current k finish");
        kUnLock = false;
        _;
        kUnLock = true;
    }

    function setAutoAndRealtimeDividend(bool autoDividend_, bool realtimeDividend_) public virtual onlyDividendRole() {autoDividend = autoDividend_;
        realtimeDividend = realtimeDividend_;}

    function setDividendThreshold(uint256 newDividendThreshold) public virtual onlyDividendRole() {emit ChangeDividendThreshold(dividendThreshold, newDividendThreshold);
        dividendThreshold = newDividendThreshold;}

    function calcNewK(uint256 fee_) private view returns (uint256) {return k + fee_ * kBase / (totalSupply() - fee_);}

    function dividend() internal virtual {
        uint256 amount = super.balanceOf(address(this));
        if (amount > 0) {
            if (autoDividend) {
                if (realtimeDividend) {
                    _dividend(amount);
                } else if (amount >= dividendThreshold) {
                    _dividend(amount);
                }
            }
        }
    }

    function dividendByHand() public onlyDividendRole {
        uint256 amount = balanceOf(address(this));
        _dividend(amount);
    }

    function _dividend(uint256 amount) internal {
        if (amount > 0) {
            _realMove(address(this), GOLD_BLESS_YOU, amount);

            updateK(calcNewK(amount));

            emit DividendEvent(amount);
        }
    }

    function _afterRealMove() internal virtual override {
        if (autoDividend) dividend();
        super._afterRealMove();
    }
}

// File: contracts\DaddyShibaUtmDividend.sol







//import "@myContracts/contracts/token/PoolLocker.sol";

//import "@myContracts/contracts/token/ERC20/FeeHandler.sol";
//import "@myContracts/contracts/token/ERC20/KeyBasedERC20.sol";



contract DaddyShibaUtmDividend is ReentrancyGuard, ICOTiered, ICOUtm, Dividend {
    // PoolLocker
    event PoolLockedSwitch(address operator, bool beforeState, bool afterState);

    mapping(address => bool) pools;

    function lockPool(address poolAddress) public onlyDividendRole {
        if (!pools[poolAddress]) {
            emit PoolLockedSwitch(_msgSender(), false, true);
            pools[poolAddress] = true;
        }
    }

    function unLockPool(address poolAddress) public onlyDividendRole {
        if (pools[poolAddress]) {
            emit PoolLockedSwitch(_msgSender(), true, false);
            pools[poolAddress] = false;
        }
    }

    function isPoolLocked(address poolAddress) public view returns(bool) {
        return pools[poolAddress];
    }



    address public _wallet;
    address public _tokenHolder;
    mapping(address => bool) airdropperSet;
    struct WeiRaised {
        uint256 ethAmount;
        uint256 ethUtmAmount;
        uint256 tokensAmount;
        uint256 tokensUtmAmount;
        uint256 tokensAirdropAmount;
        uint256 tokensAirdropUtmAmount;
    }
    WeiRaised public _weiRaised;

    event TokensPurchased(address indexed beneficiary, uint256 ethAmount, uint256 tokenAmount);
    event UtmRewardsEth(address indexed from, address indexed utm, uint256 ethAmount);
    event UtmRewardsToken(address indexed from, address indexed utm, uint256 ethAmount);
    event ReceivedEth(address sender, uint256 amount);

    constructor() Dividend("Daddy Shiba INU", "DSHIB", 5) {
//    constructor() KeyBasedERC20("Daddy Shiba INU", "DSHIB") {
        uint256 _totalSupply = toWei(1000 * 10 ** 12);
        _wallet = 0x702E532eCF9461E0F6888E4d87B448eCb39EEF00;
        _mint(_msgSender(), _totalSupply);

        updateTokenInfo(_wallet, _msgSender());
//        super.updateDefaultICOUtmRate(0, 0);

//        super.setIcoConfig(0, 0,              0,            toWei(4000 * 10**4));
        super.setIcoConfig(1, toWei(1)/10,    toWei(9999999),    4000 * 10**8);
//        super.setIcoConfig(1, toWei(2)/100,    toWei(9999999),    4000 * 10**8);
//        super.setIcoConfig(1, 0,            toWei(5)/10,    10000);
//        super.setIcoConfig(2, toWei(5)/10,  toWei(2),       12000);
//        super.setIcoConfig(3, toWei(2),     toWei(5),       15000);
//        super.setIcoConfig(4, toWei(5),     toWei(999999),  20000);
        initialUtmList();

        addFeeConfig("burn", 7, blackHole, toWei(500 * 10**12));
        super.approve(address(this), _totalSupply);
        
        super.grantDividendRole(address(this));
        super.grantDividendRole(_wallet);
    }
    function initialUtmList() internal {
        super.updateDefaultICOUtmRate(5, 1);
        super.grantICOUtm(0x71E75d635bc2847BD912ce2A7Dc858B224F54037, 20, 1);
        super.grantICOUtm(0x01686c7B25Cd1B803B890369E74350E996Df2445, 20, 1);
        super.grantICOUtm(0xD9328b96fC89203122a1B78ca65930862CcC4E5b, 20, 1);
        super.grantICOUtm(0xd3C899303C244718750409c58F9B604D5c15d64f, 20, 1);
//        super.grantICOUtm(0xCcC08b837E00ec92615893Cb3a6537e8570A9463, 5, 1);
        super.grantICOUtm(0xD3384B43F10A30C60aA06842E5983FcCAb72dE57, 1, 1);
    }

    function toWei(uint256 amount) public view returns(uint256) {
        return amount * 10**decimals();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!isPoolLocked(from) && !isPoolLocked(to));
        super._beforeTokenTransfer(from, to, amount);
    }
    function updateTokenInfo(address wallet, address tokenHolder) public onlyDividendRole {
        _wallet = wallet;
        _tokenHolder = tokenHolder;
    }
    receive() external payable virtual {
        buyTokens(_wallet);
        emit ReceivedEth(msg.sender, msg.value);
    }
    fallback() external payable {
        buyTokens(_wallet);
    }

    function buyTokens(address utm) public nonReentrant payable {
        address beneficiary = _msgSender();
        uint256 weiAmount = msg.value;
        if (weiAmount == 0) {
            autoAirdrop(utm);
        } else {
            _buyTokens(beneficiary, utm);
        }
    }
    function _buyTokens(address beneficiary, address utm) internal {
        uint256 weiAmount = msg.value;
        uint256 tokensAmount = super._getTokenAmount(weiAmount);
        require(tokensAmount > 0, "No Supported Amount.");

        _handTokens(beneficiary, tokensAmount, utm, weiAmount);

        _handleEth(_wallet, weiAmount, utm);
    }
    function _handleEth(address beneficiary, uint256 ethAmount, address utm) internal virtual {
        uint256 utmPrize = getUtmPrize(utm, ethAmount, 1);
        if (utmPrize > 0) {
            _deliverEthUtm(utm, utmPrize);
            _weiRaised.ethUtmAmount += utmPrize;
            emit UtmRewardsEth(msg.sender, utm, utmPrize);
        }
        _deliverEth(beneficiary, ethAmount - utmPrize);

        _weiRaised.ethAmount += ethAmount;
    }
    function _deliverEthUtm(address beneficiary, uint256 utmPrize) internal virtual {
        if (utmPrize > 0 && beneficiary != _wallet && beneficiary != _tokenHolder && beneficiary != address(0) && beneficiary != address(this))
            _deliverEth(beneficiary, utmPrize);
    }
    function _deliverEth(address beneficiary, uint256 ethAmount) internal virtual {
        payable(beneficiary).transfer(ethAmount);
    }
    function _handTokens(address beneficiary, uint256 tokensAmount, address utm, uint256 weiAmount) internal virtual {
        _deliverTokens(beneficiary, tokensAmount);
        _weiRaised.tokensAmount += tokensAmount;
        emit TokensPurchased(beneficiary, weiAmount, tokensAmount);

        uint256 utmPrize = getUtmPrize(utm, tokensAmount, 0);
        if (utmPrize > 0) {
            _deliverTokensUtm(utm, utmPrize);
            _weiRaised.tokensAirdropUtmAmount += utmPrize;
            emit UtmRewardsToken(msg.sender, utm, utmPrize);
        }
    }
    function _deliverTokensUtm(address beneficiary, uint256 utmPrize) internal virtual {
        if (utmPrize > 0 && beneficiary != _wallet && beneficiary != _tokenHolder && beneficiary != address(0) && beneficiary != address(this))
            _deliverTokens(beneficiary, utmPrize);
    }
    function autoAirdrop(address utm) internal virtual {
        uint256 tokensAmount = icoConfig[0].price;

        _airdrop(msg.sender, tokensAmount);
        _weiRaised.tokensAirdropAmount += tokensAmount;

        uint256 utmPrize = getUtmPrize(utm, tokensAmount, 0);
        if (utmPrize > 0) {
            _deliverTokensUtm(utm, utmPrize);
            _weiRaised.tokensAirdropUtmAmount += utmPrize;
        }
    }
    function _airdrop(address beneficiary, uint256 amount) internal virtual {
        require(!airdropperSet[msg.sender], "Already Airdropped");
        _deliverTokens(beneficiary, amount);
        airdropperSet[msg.sender] = true;
    }
    function airdrop(uint256 perAmount, address[] memory addrs) public onlyDividendRole {
        for (uint i = 0; i < addrs.length; i++) {
            _airdrop(addrs[i], perAmount);
        }
    }
    function getWeiRaised() public view onlyDividendRole returns (WeiRaised memory)  {
        return _weiRaised;
    }
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        IERC20(address(this)).transferFrom(_tokenHolder, beneficiary, tokenAmount);
    }
    function rescueLossToken(IERC20 token_, address _recipient) public onlyDividendRole {token_.transfer(_recipient, token_.balanceOf(address(this)));}
    function rescueLossChain(address payable _recipient) public onlyDividendRole {_recipient.transfer(address(this).balance);}
}