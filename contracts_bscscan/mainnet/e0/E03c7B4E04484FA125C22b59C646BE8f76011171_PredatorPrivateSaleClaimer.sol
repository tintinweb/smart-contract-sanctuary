/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/PredatorPrivateSaleClaimer.sol



pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * Contracnt for Private Sale Winers to claim their PED
 * Address of THIS CONTRACT has to be excluded from fees & Rewards
 * Contract needs 5.4 million PED token holding
 */
contract PredatorPrivateSaleClaimer is Ownable{

    // List of all private sale winner addresses
    address[] private whitelistAccounts;

    // Mapping for determening if address can claim
    mapping(address => bool) private claimable;

    // Event for successfully claimed tokens
    event Claim(address indexed account, uint256 amount);

    // Claim time: 13/12/21 20:00:00 UTC
    uint256 public claimTime = 1639425600;

    // PED address
    address public tokenAddress;

    // Amount of tokens to claim per winner (54,000 PED / 0.5 BNB)
    uint256 public tokenAmount = 54000 * 10**18;


    constructor() {
        // List of addresses of all winners
        address[] memory wl = new address[](97);
        wl[0] = 0x169bbaf74F0F5B1D4f2E1faE70A1e14d90e39308;
        wl[1] = 0x41248b9a1bCbDd752ECD5fcD9A907aA1D101394E;
        wl[2] = 0xE3a9eFc10AfAFBE6a25D32F6053bFEC28b538949;
        wl[3] = 0xAf395eBa18A65BBC0f0dcBE8285ebDDb13F9CD6b;
        wl[4] = 0x3b7936A81e427BE998dF435130c0d094Fff1F7F0;
        wl[5] = 0x822a435193F6a5f8F6c62158fBFdc97656e73193;
        wl[6] = 0xF4eac245BA62c9e157F78ac81250E901c92C98B0;
        wl[7] = 0xDce7863A638CaA71FeE398a7C638124200430126;
        wl[8] = 0xd35D11726014988c74c402678E3A823469afC425;
        wl[9] = 0x4636De0F65e3a8fE2D40b6389baadC62109074Aa;
        wl[10] = 0x12C0A7e0268f92ADfBd3C63dC8a02B01c66b3E64;
        wl[11] = 0xF8b2D227A456C8a14480FA70cB0fBc01F28f1DcE;
        wl[12] = 0x200c75f122Ab6D4563075d8deCa5AE84f9392B30;
        wl[13] = 0xd605b50723A73e8B6f5b25eEa2A29462D14C84E4;
        wl[14] = 0xa48421393e16346052f5f3Eaaa12926282b6694B;
        wl[15] = 0x3288c7D2Cc59c1c5072BA6b200ad6c73AC4Bb8B9;
        wl[16] = 0xc87c18b667Ab417A8a422D41511Af0468796F301;
        wl[17] = 0x72E3C91223E31C7F569F85D683B1DF09a85a2681;
        wl[18] = 0x28CD183E595f46f2938079eaFFd7b3B7CF6BC288;
        wl[19] = 0x1E059C116801b433F02934dC4E329dE229bdfB8E;
        wl[20] = 0x51C3F2d273c78a7AEb41C0103c47f69FEc7Be280;
        wl[21] = 0x1416Bf62F4Dd65378dFC36A87C06D6EfAf86979F;
        wl[22] = 0xaFD72dDa5C318e4C43827198bABa2e6BD8ecDa84;
        wl[23] = 0x4C6C449f33D147aa067029B8e2827812A5b4b2D1;
        wl[24] = 0xfDd8c42BD9bc5C43E4e1A24De5a1718E07a7Ed37;
        wl[25] = 0x6Ec284E1b18958F73E31dDB1aE1563D16556e546;
        wl[26] = 0xbD1419BD6E78F81c906373C140942A8E645536Ab;
        wl[27] = 0x47C3c9224036E84859B8C74D2EAED55C862aA6AA;
        wl[28] = 0xB4be843103893f26717d274e08555BDce27271A6;
        wl[29] = 0x6e2E78Aa619681D1f6fE2E2790845670348d40A7;
        wl[30] = 0xf1e42d9b9a37a7C68827c7E09CA22447fEF867e8;
        wl[31] = 0x52E5cAB0eDe7303C3DE191eD04E2D22766Df31d0;
        wl[32] = 0x23A04fdAca14e1E28794A93132eee5242250254d;
        wl[33] = 0xCb9C8502A2e185e8BE597552BF9d809119754f8A;
        wl[34] = 0x80e49181dd74c2b4655ebeE79B7B4b6c42D78C18;
        wl[35] = 0xF8a6B592469679D6B4ec85578575B62ce975d5d2;
        wl[36] = 0x82F130D97fFDf0D7852Ea99c9BdCF0e3789B2195;
        wl[37] = 0x05933214714791D7486DC5a71e4A655F4003b019;
        wl[38] = 0x9C5c388cf9BBD016a0f8d84aB0f21020C5de42bF;
        wl[39] = 0x891bf47C42Af28Be9bcaB4a1d5D222349D8065bF;
        wl[40] = 0x5B198099A5E59Ce0b1e10c0a7a8AfCa80ACa8BCC;
        wl[41] = 0xFBD5fcAFF3E413D1A7A61769aE61e3e5Cd57c316;
        wl[42] = 0xA2755ceFB44d9e65Fa2e7B7D3137AFB1D29d9463;
        wl[43] = 0x91aD0BaDDc41e72b2ffb17F76964C243041a0bf7;
        wl[44] = 0xcC0c478154f1fc2a0b683671b23A9Ae0fe997C4D;
        wl[45] = 0x73187fDfFC76559cbEbe05d6258AF35D64B67743;
        wl[46] = 0x4aD22C464DB408D08E9D7BC8D17Bbe7De23cb447;
        wl[47] = 0xFC43b22214dDC1f55b9dB11EcEa9b9fa5CBe7C41;
        wl[48] = 0x6efe5F5805Ab60e2D75225C8b3aa492bA5407017;
        wl[49] = 0x9FefD55674EbC732075EE6E361B696e891633724;
        wl[50] = 0x512e76E4A2e5ED31e9F4f4eEF05cd210832A53e4;
        wl[51] = 0x314b5A81cC029Adc884db7B191e15e6c73E65A56;
        wl[52] = 0x61F9DCdD0637b28D8E289d47dafc54aDA5Bc00b8;
        wl[53] = 0x7422ec1DaCbd1F7893f35F7B0158559FC5aEf8B0;
        wl[54] = 0x03516e93173e53111704c80cE522fb03857662c3;
        wl[55] = 0x03b47515E5E7a7c3a8FF6eaCF0Beef08B331e3AB;
        wl[56] = 0x69af50e9AaA9Fc9bfCc70bB074FB9590690D9b43;
        wl[57] = 0x03Ed7383AA2739584e4bb8dBFA4A0E9cC78C535C;
        wl[58] = 0xC1B5f576E540Da276c9F4f990b4a1e62d3f1d2a2;
        wl[59] = 0x4E067955cbFe74C1a28700d4a89925A767632532;
        wl[60] = 0x49FAECfE85d34385b0DD77177B71bb181123eA70;
        wl[61] = 0x51b97228Aa3468B21648A2F1DAF81945Bb67CC8C;
        wl[62] = 0x4D15402B96e5E5965aDaCBe54C05B815049F4f14;
        wl[63] = 0x2E5A378f25DDDD62fbb439Dd78f736a28557feeB;
        wl[64] = 0x74C55e48A7A3fbaA288F534CdCFEECD2dDC37213;
        wl[65] = 0x32772b2DA3f7135CfcAF20f1c20Ee4C231e8454C;
        wl[66] = 0x61d6e4ab0371d6934DC1955c1B05e5d392376C71;
        wl[67] = 0x8C47bfeD6A99dB3eEc412Bcb973eCa763242C08a;
        wl[68] = 0xd7Aa178bB566c614d75b3aa0E64ab90C2feFF80d;
        wl[69] = 0x24141a358980B41084a487bb39c5E0a95B6E6559;
        wl[70] = 0x1043df894050Beea4B5377C7Ed0C5B832D33b8c5;
        wl[71] = 0xfdd838e71620E7C184960B0cf516f6deC9A00C90;
        wl[72] = 0x8aba01eb0180D4e905210f8b6075dDA68E1E8672;
        wl[73] = 0x7Ae6BB66DD9C3Da5F406BC259Cb18d4B7A2AC838;
        wl[74] = 0x351037870F1b55582F7E29a92b6717CB7Ed36AdB;
        wl[75] = 0x2b254207ddaa4D0F797687d0bf5bb2E384DE27d7;
        wl[76] = 0x70bbB01E587eE2c7f2372632ed35e98286C9e9a9;
        wl[77] = 0xEfFc052aA67326341275666Dd7ac090162187BdD;
        wl[78] = 0xc1CF58740d55f47A9853d8f8d9988e111A0cC5bB;
        wl[79] = 0xb94Fbbdf4b4e0a3f026C838254B490cBc850F005;
        wl[80] = 0xc7F87E393D496F9c335A4132B0bD4e5598E89174;
        wl[81] = 0x4E925A1779C1C30B89830e2B7d8Ab84949105A41;
        wl[82] = 0x244E332D8ae1Fa493E2de6ACca304F9D9c7307A6;
        wl[83] = 0x8701AFa967CbbD940DF79b4cd3529DE50Deb6400;
        wl[84] = 0x98711fb7341c2E17dfBC8A6e699310b4AE8700e9;
        wl[85] = 0x341b3Ba68165B3Ec687FB072F1B56e9ad3eB4b3e;
        wl[86] = 0xef315FA2881EB48081806D848fCEd05e1750Ca48;
        wl[87] = 0x75b8de3a317C94fe0DDD6Ea767C662F23A647eEE;
        wl[88] = 0xe28d972515B8016D4a52904a90408DddF9C84704;
        wl[89] = 0x965ba02135Dc66C08ED05Ae440fC51B53bCFBbbD;
        wl[90] = 0xdcDF70C2D944CC120DA73AA2A4505453c11D3e33;
        wl[91] = 0x52dbF0f72FD63f4BcC44CdeB69aEd27c14B97f39;
        wl[92] = 0x92e46afb0Cc31ff9b52414c3E3C842384fc61c33;
        wl[93] = 0xaED06cf42F5e11e9E37cf5B56f3e2A7fF41a1c4e;
        wl[94] = 0xC572a408bba126bC6C7c22303a0c1a8adB5Dd2cd;
        wl[95] = 0x40E0f6D5187B67ccDC3D319b48D728Bc96FeBF33;
        wl[96] = 0x41e1baEa422523c8416B4f5278EE3e69Eb2ac917;

        // Add list to WL winner list
        addWhiteList(wl);

        // Initiate with PED address
        tokenAddress = 0x2E7dC370a5F713d32543c6eA33B012d5cBB20Ef1; 
    }


    // @dev: Set PED address
    function setTokenAddress(address _addr) external onlyOwner {
        tokenAddress =_addr;
    }


    // @dev: Set new time for claim
    function setClaimTime(uint256 _time) external onlyOwner {
        claimTime = _time;
    }


    // @dev: Check if address is allowed  to claim
    function checkClaimable(address _addr) public view returns(bool) {
        return claimable[_addr];
    }


    // @dev: Add address to WL address list
    // Requires: Unique address
    function addWhitelistAccount(address _addr) public onlyOwner {
        require(_addr != owner(), "Owner can not add himself!");
        require(!claimable[_addr], "Address already inserted");

        whitelistAccounts.push(_addr);
        claimable[_addr] = true;
    }


    // @dev: Add list of addresses for WL address list
    function addWhiteList(address[] memory _addrList) public onlyOwner {
        for(uint256 i = 0; i < _addrList.length; i++) {
            addWhitelistAccount(_addrList[i]);
        }
    }


    // @dev: Return address to specified index
    function getAddressByIndex(uint256 i) public view returns(address) {
        require(i < whitelistAccounts.length, "Index too big");
        return whitelistAccounts[i];
    }


    // @dev: Return length of WL address list
    function getWhiteListLength() public view returns(uint256) {
        return whitelistAccounts.length;
    }


    // @dev: Claim available PED tokens
    // Requires: Current time >= claimTime && msg.sender is allowed to claim
    function claim() external {
        require(block.timestamp >= claimTime, "Too early for claiming PED"); // GET UNIX TIME: https://www.unixtimestamp.com/
        require(claimable[_msgSender()], "Claim not available for this address");

        // Send PED to msg.sender
        bool claimed = IERC20(tokenAddress).transfer(_msgSender(), tokenAmount);

        // If successful: emit Claim && disallow for address for another claim
        if (claimed) {
            emit Claim(_msgSender(), tokenAmount);
            claimable[_msgSender()] = false;
        }
    }

    // @dev: Claim rest of PED tokens that weren't claimed by Private Sale Winners after a week
    // Requires: Only Owner & time >= privSale Opening time + 1 week
    function withdrawPED() external onlyOwner {
        require(block.timestamp >= 1640030400, "One Week after Private Sale Opening is not finished"); // Set due date when owner can withdraw rest PED
        IERC20 ped = IERC20(tokenAddress);
        ped.transfer(owner(), ped.balanceOf(address(this)));
    }

}