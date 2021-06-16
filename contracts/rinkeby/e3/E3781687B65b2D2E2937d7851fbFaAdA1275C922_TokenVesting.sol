/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
     * will be to transferred to `to`.
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
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// A new implementation of OpenZeppelin's TokenVesting contract with a few changes

// SPDX-License-Identifier: <SPDX-License>
// SPDX-License-Identifier: <SPDX-License>

// A new implementation of OpenZeppelin's TokenVesting contract with a few changes
// SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.4;

// A new implementation of OpenZeppelin's TokenVesting contract with a few changes

contract TokenVesting is Ownable {
    // event TokensReleased(address beneficiary, uint256 amount);
    // event BeneficiaryRevoked(address beneficiary);

    struct Beneficiary {
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 amount;
        uint256 released;
        bool revoked;
    }

    mapping(address => Beneficiary) public beneficiaries;

    IERC20 public xpnet;

    constructor(IERC20 _xpnet) {
        xpnet = _xpnet;
        createBeneficiary(
        0x8EFD00918474c909F913637Fd310cA35ed9FC4E6, 
        1623827400,
        360,
        4320,
        1666666670000000000000000
        );
              createBeneficiary(
        0xf2cdC57277CD919460E5815DE7084422B45D2DD1, 
        1623827400,
        360,
        4320,
        10000000000000000000000000
        );
              createBeneficiary(
        0xb54497979920233D5Ce27b7eBd64298C76647AEE, 
        1623827400,
        360,
        4320,
        10000000000000000000000000
        );
        createBeneficiary(
    0x3B494744Dd1Be9b050e380E68d7F37C30A9Bc8C7,
    1623827400,
    720,
    4320,
    9368000000000000000000
);
createBeneficiary(
    0xD720073bd639200cAD72eb9e7d6af2F1d867Da0f,
    1623827400,
    720,
    4320,
    5524000000000000000000
);
createBeneficiary(
    0xdE9802a161671B5a3664aA6bd55c6d2969e54ad4,
    1623827400,
    720,
    4320,
    6557000000000000000000
);
createBeneficiary(
    0x4DAd37f1A2248BF8272377865eFC001749d1d091,
    1623827400,
    720,
    4320,
    2329000000000000000000
);
createBeneficiary(
    0x075c3F8434102Ad660cF7ABa61083a2eF58dB81A,
    1623827400,
    720,
    4320,
    7480000000000000000000
);
createBeneficiary(
    0x35EA4031016eeA183980164B9F103593ce81028e,
    1623827400,
    720,
    4320,
    3603000000000000000000
);
createBeneficiary(
    0x0ec6BC89755D0dA51819d18ee5cE4013e7a80A44,
    1623827400,
    720,
    4320,
    4886000000000000000000
);
createBeneficiary(
    0x00Dd433a2BC0853B3AE9C5184ce7478E4B1bFBd4,
    1623827400,
    720,
    4320,
    9785000000000000000000
);
createBeneficiary(
    0x7Fd8341e0F2985883099f05E35F971a8F4856a6A,
    1623827400,
    720,
    4320,
    7711000000000000000000
);
createBeneficiary(
    0x0Ee3ec96fC5c17390B46888dB5C3B7AdD00b4c4a,
    1623827400,
    720,
    4320,
    2594000000000000000000
);
createBeneficiary(
    0x4dF9a1a466FAB89556621bA435A1e55f1eaD36d6,
    1623827400,
    720,
    4320,
    7432000000000000000000
);
createBeneficiary(
    0xFc64abb0Af050Ebb85E40C4BFd3117483a023D4e,
    1623827400,
    720,
    4320,
    1464000000000000000000
);
createBeneficiary(
    0x88A29635838505307B17e13e1756a648F515355c,
    1623827400,
    720,
    4320,
    6390000000000000000000
);
createBeneficiary(
    0x37725299B476e2E160Ed2fD6C9e362c44b9E4ba8,
    1623827400,
    720,
    4320,
    7765000000000000000000
);
createBeneficiary(
    0x316Cbe18f7b4fE16A6f2b55CAa997Eda1950688E,
    1623827400,
    720,
    4320,
    4605000000000000000000
);
createBeneficiary(
    0xc012161fa5378aca8d8c59B1117a1958d1ea1B8a,
    1623827400,
    720,
    4320,
    2212000000000000000000
);
createBeneficiary(
    0xAA978c7784760DD9b47Af25a60ea029835b23981,
    1623827400,
    720,
    4320,
    9197000000000000000000
);
createBeneficiary(
    0x0237f583724f30fb0ea39929CA361625a01e7e8b,
    1623827400,
    720,
    4320,
    9539000000000000000000
);
createBeneficiary(
    0x702987a0f8411a385587f754Ee727b067Efe8315,
    1623827400,
    720,
    4320,
    9525000000000000000000
);
createBeneficiary(
    0xa04F91bcd04f1602692DA3119ccb78A7715Da6C0,
    1623827400,
    720,
    4320,
    7982000000000000000000
);
createBeneficiary(
    0xb7A592059DE41638039aD25FB54C0533f48C6234,
    1623827400,
    720,
    4320,
    949000000000000000000
);
createBeneficiary(
    0x0DEFEbac43CdD01D668Bb8e1eA67a662072A50d3,
    1623827400,
    720,
    4320,
    9540000000000000000000
);
createBeneficiary(
    0x84C68cAB587FCAaA7606C3f246F3190f70D704B2,
    1623827400,
    720,
    4320,
    1384000000000000000000
);
createBeneficiary(
    0x6FEe7ff9A8d73E6CFC9665938b53b4249E619089,
    1623827400,
    720,
    4320,
    5085000000000000000000
);
createBeneficiary(
    0xE7d8eF4cB2C97b6771dD42Af179c93b63A4f762E,
    1623827400,
    720,
    4320,
    917000000000000000000
);
createBeneficiary(
    0x0Dc08e6954e151065cFacbAFD74b38a3d5fb185E,
    1623827400,
    720,
    4320,
    9717000000000000000000
);
createBeneficiary(
    0x1521eBc8DB1C35F56BFdcf0cB4c0D0bA60A15c80,
    1623827400,
    720,
    4320,
    1404000000000000000000
);
createBeneficiary(
    0xDbDfcA29dbbfD2B40354e4bed2b2ae43Fca0C5BA,
    1623827400,
    720,
    4320,
    728000000000000000000
);
createBeneficiary(
    0x847d39d5634423587B54d19C1090d2320AAfCC3B,
    1623827400,
    720,
    4320,
    5534000000000000000000
);
createBeneficiary(
    0x5148BC129c64293Bd86D051EC96afF45E2CfEf15,
    1623827400,
    720,
    4320,
    3035000000000000000000
);
createBeneficiary(
    0xCc05E773cCaB36a6e5ADc2Fcd88d7A8E2ED9F62A,
    1623827400,
    720,
    4320,
    9334000000000000000000
);
createBeneficiary(
    0x2903D459e0e7a774eB9Af133D0caa1a6B2136A3a,
    1623827400,
    720,
    4320,
    441000000000000000000
);
createBeneficiary(
    0x46e798456Fe35DFd7C3f0929923166531bFcd091,
    1623827400,
    720,
    4320,
    3589000000000000000000
);
createBeneficiary(
    0xC20Ee90E2ce67f161319EBaDff26ffdb0ee4d26D,
    1623827400,
    720,
    4320,
    8309000000000000000000
);
createBeneficiary(
    0x0b86c58Be80f00DB4B7EB52fAA175F9D76BB00bA,
    1623827400,
    720,
    4320,
    1348000000000000000000
);
createBeneficiary(
    0xF620a7127B19D82E39b386d18fF8A81beE73d2b7,
    1623827400,
    720,
    4320,
    6717000000000000000000
);
createBeneficiary(
    0x68CfFc8B215aC3A109bF9034E7a60E68EF49a4CB,
    1623827400,
    720,
    4320,
    8719000000000000000000
);
createBeneficiary(
    0xE98D80D50D526E4756E0ab8Fcd80e12060521df7,
    1623827400,
    720,
    4320,
    8153000000000000000000
);
createBeneficiary(
    0xb85220Ec720576DeF77e8f99CA689841F1c2DCf7,
    1623827400,
    720,
    4320,
    6283000000000000000000
);
createBeneficiary(
    0x5e6F476D063FfE5511957Ee31E2a310652A5ed09,
    1623827400,
    720,
    4320,
    5584000000000000000000
);
createBeneficiary(
    0x4760B9b97d8b4663dBC323d275764A22a3fC649a,
    1623827400,
    720,
    4320,
    1467000000000000000000
);
createBeneficiary(
    0xD6614eB77021351a2C6A5F588A87d47c1012908d,
    1623827400,
    720,
    4320,
    6060000000000000000000
);
createBeneficiary(
    0xE501A35020c70eCfA4D0c8365e6AB142BcECBC33,
    1623827400,
    720,
    4320,
    452000000000000000000
);
createBeneficiary(
    0x828872BdA0180c2FDe02c0Ad559D888B1d275290,
    1623827400,
    720,
    4320,
    364000000000000000000
);
createBeneficiary(
    0x2a52704E8830E6205140E1402F9F9D2A7DF3D48d,
    1623827400,
    720,
    4320,
    870000000000000000000
);
createBeneficiary(
    0x10C4a215F19b5F9400489F548EC70632f46b0941,
    1623827400,
    720,
    4320,
    6432000000000000000000
);
createBeneficiary(
    0x252be930cE6f957327F41D1298Bf44939Db3b3F6,
    1623827400,
    720,
    4320,
    9997000000000000000000
);
createBeneficiary(
    0xb2b3ebf8163c0ef415b90BC27a42d0C84F96D894,
    1623827400,
    720,
    4320,
    5756000000000000000000
);
createBeneficiary(
    0x3B827BB209fA81b9030dc8D6Cd14e35b7Adc2D80,
    1623827400,
    720,
    4320,
    8279000000000000000000
);
createBeneficiary(
    0x2e6093CeE9DB48cefC482B2173Ab8226f76d06E8,
    1623827400,
    720,
    4320,
    2255000000000000000000
);
createBeneficiary(
    0x5017aae2D5210bE07558F5fE04a41f5E3Aab9732,
    1623827400,
    720,
    4320,
    9767000000000000000000
);
createBeneficiary(
    0x99E50C9d44c65d2EF905E89Aeead68624a45E7cd,
    1623827400,
    720,
    4320,
    9378000000000000000000
);
createBeneficiary(
    0xb7DF01617aa887dce01FA560abaa141c9d631fFc,
    1623827400,
    720,
    4320,
    6843000000000000000000
);
createBeneficiary(
    0xc95aEddFe6057dc3d0b278a468c0B4C84AA6A363,
    1623827400,
    720,
    4320,
    6227000000000000000000
);
createBeneficiary(
    0xA0ceB2dEddC9aa3C092fbab3953587ac0A40C0aB,
    1623827400,
    720,
    4320,
    1348000000000000000000
);
createBeneficiary(
    0x0942AF94325e44a56c74e7ABd73984e34C2E9db2,
    1623827400,
    720,
    4320,
    4239000000000000000000
);
createBeneficiary(
    0xfE7e3E336bD99a8977c7f2C23682A8952aE8e961,
    1623827400,
    720,
    4320,
    8493000000000000000000
);
createBeneficiary(
    0x1d11efeC7d9228247902BdEBb243B2d9921F1AD6,
    1623827400,
    720,
    4320,
    2598000000000000000000
);
createBeneficiary(
    0x90883D2451987b3F466e2D022Ee199C94Ddc1417,
    1623827400,
    720,
    4320,
    9255000000000000000000
);
createBeneficiary(
    0x5D47D042C79a71BDd40A2323f7A78E3706c704bF,
    1623827400,
    720,
    4320,
    5942000000000000000000
);
    }

    // Revoke a beneficiary from his token rights
    // Once revoked cannot be reversed
    function revoke(address beneficiary) public onlyOwner {
        require(
            !beneficiaries[beneficiary].revoked,
            "TokenVesting: Beneficiary is already revoked"
        );

        beneficiaries[beneficiary].revoked = true;

        // emit BeneficiaryRevoked(beneficiary);
    }

    // Createa beneficiary to receive tokens
    // _beneficiary is the address that will receive the vested tokens
    // _start is a UNIX date of beginning of vesting
    // _duration and _cliff are time durations in seconds
    // _amount is the total tokens the beneficiary can receive
    function createBeneficiary(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _amount
    ) public onlyOwner {
        require(
            _beneficiary != address(0),
            "TokenVesting: beneficiary is the zero address"
        );
        require(
            _cliff <= _duration,
            "TokenVesting: cliff is longer than duration"
        );
        require(_duration > 0, "TokenVesting: duration is 0");
        require(_cliff > 0, "TokenVesting: cliffDuration is 0");
        require(
            _start + _duration > block.timestamp,
            "TokenVesting: final time is before current time"
        );

        beneficiaries[_beneficiary].cliff = _start + _cliff;
        beneficiaries[_beneficiary].start = _start;
        beneficiaries[_beneficiary].duration = _duration;
        beneficiaries[_beneficiary].amount = _amount;
    }

    // Transfers vested tokens to msg.sender
    function release() public {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];

        require(beneficiary.amount > 0, "TokenVesting: no amount");
        require(!beneficiary.revoked, "TokenVesting: revoked beneficiary");

        uint256 unreleased = _releasableAmount(beneficiary);
        require(unreleased > 0, "TokenVesting: no tokens are due");

        beneficiary.released = beneficiary.released + unreleased;
        xpnet.transfer(msg.sender, unreleased);
        // emit TokensReleased(msg.sender, unreleased);
    }

    // withdraw tokens from contract
    function withdraw(uint256 amount, IERC20 token) public onlyOwner {
        require(amount > 0);
        token.transfer(msg.sender, amount);
    }

    // Calculates the amount that has already vested but hasn't been released yet.
    function _releasableAmount(Beneficiary memory beneficiary)
        private
        view
        returns (uint256)
    {
        return _vestedAmount(beneficiary) - beneficiary.released;
    }

    // Calculates the amount that has already vested.
    function _vestedAmount(Beneficiary memory beneficiary)
        private
        view
        returns (uint256)
    {
        uint256 totalBalance = beneficiary.amount;

        if (block.timestamp < beneficiary.cliff) {
            return 0;
        } else if (
            block.timestamp >= (beneficiary.start + beneficiary.duration + (beneficiary.cliff - beneficiary.start))
        ) {
            return totalBalance;
        } else {
            return
                (totalBalance * (block.timestamp - beneficiary.start - (beneficiary.cliff - beneficiary.start))) /
                beneficiary.duration;
        }
    }
}