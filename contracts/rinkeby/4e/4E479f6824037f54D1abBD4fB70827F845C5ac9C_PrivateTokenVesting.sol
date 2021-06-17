/**
 *Submitted for verification at Etherscan.io on 2021-06-17
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

// A new implementation of OpenZeppelin's TokenVesting contract with a few changes

contract PrivateTokenVesting is Ownable {
    // event TokensReleased(address beneficiary, uint256 amount);
    // event BeneficiaryRevoked(address beneficiary);

    struct Beneficiary {
        uint256 amount;
        uint256 released;
        bool revoked;
    }

    uint256 public start;
    uint256 public cliff;
    uint256 public duration;
    mapping(address => Beneficiary) public beneficiaries;

    IERC20 public xpnet;
    
    // _start is a UNIX date of beginning of vesting
    // _cliff is a UNIX date of end date of cliff
    // _duration is a time durations in seconds

    constructor(IERC20 _xpnet, uint256 _start, uint256 _cliff, uint256 _duration) {
        xpnet = _xpnet;
        start = _start;
        cliff = _cliff;
        duration = _duration;
        createBeneficiary(0x8EFD00918474c909F913637Fd310cA35ed9FC4E6, 1111111110000000000000000);
        createBeneficiary(0xf2cdC57277CD919460E5815DE7084422B45D2DD1, 6666666670000000000000000);
                createBeneficiary(0x4E31dc0267bFdF78112068D72098B12AAEB970e6, 2000000000000000000000000);
                        createBeneficiary(0xb54497979920233D5Ce27b7eBd64298C76647AEE, 4000000000000000000000000);
                        createBeneficiary(0xF3aCca8D5caFbbAF6Ff9E6B77174CBF3Ab273F54, 4000000000000000000000000);
        
        createBeneficiary(
    0x3B494744Dd1Be9b050e380E68d7F37C30A9Bc8C7,
    4581000000000000000000
);
createBeneficiary(
    0xD720073bd639200cAD72eb9e7d6af2F1d867Da0f,
    5009000000000000000000
);
createBeneficiary(
    0xdE9802a161671B5a3664aA6bd55c6d2969e54ad4,
    7681000000000000000000
);
createBeneficiary(
    0x4DAd37f1A2248BF8272377865eFC001749d1d091,
    1037000000000000000000
);
createBeneficiary(
    0x075c3F8434102Ad660cF7ABa61083a2eF58dB81A,
    4309000000000000000000
);
createBeneficiary(
    0x35EA4031016eeA183980164B9F103593ce81028e,
    373000000000000000000
);
createBeneficiary(
    0x0ec6BC89755D0dA51819d18ee5cE4013e7a80A44,
    1709000000000000000000
);
createBeneficiary(
    0x00Dd433a2BC0853B3AE9C5184ce7478E4B1bFBd4,
    5542000000000000000000
);
createBeneficiary(
    0x7Fd8341e0F2985883099f05E35F971a8F4856a6A,
    1253000000000000000000
);
createBeneficiary(
    0x0Ee3ec96fC5c17390B46888dB5C3B7AdD00b4c4a,
    8095000000000000000000
);
createBeneficiary(
    0x4dF9a1a466FAB89556621bA435A1e55f1eaD36d6,
    8974000000000000000000
);
createBeneficiary(
    0xFc64abb0Af050Ebb85E40C4BFd3117483a023D4e,
    7089000000000000000000
);
createBeneficiary(
    0x88A29635838505307B17e13e1756a648F515355c,
    3025000000000000000000
);
createBeneficiary(
    0x37725299B476e2E160Ed2fD6C9e362c44b9E4ba8,
    2743000000000000000000
);
createBeneficiary(
    0x316Cbe18f7b4fE16A6f2b55CAa997Eda1950688E,
    7019000000000000000000
);
createBeneficiary(
    0xc012161fa5378aca8d8c59B1117a1958d1ea1B8a,
    1879000000000000000000
);
createBeneficiary(
    0xAA978c7784760DD9b47Af25a60ea029835b23981,
    3023000000000000000000
);
createBeneficiary(
    0x0237f583724f30fb0ea39929CA361625a01e7e8b,
    2649000000000000000000
);
createBeneficiary(
    0x702987a0f8411a385587f754Ee727b067Efe8315,
    5936000000000000000000
);
createBeneficiary(
    0xa04F91bcd04f1602692DA3119ccb78A7715Da6C0,
    9712000000000000000000
);
createBeneficiary(
    0xb7A592059DE41638039aD25FB54C0533f48C6234,
    9484000000000000000000
);
createBeneficiary(
    0x0DEFEbac43CdD01D668Bb8e1eA67a662072A50d3,
    2861000000000000000000
);
createBeneficiary(
    0x84C68cAB587FCAaA7606C3f246F3190f70D704B2,
    2671000000000000000000
);
createBeneficiary(
    0x6FEe7ff9A8d73E6CFC9665938b53b4249E619089,
    9762000000000000000000
);
createBeneficiary(
    0xE7d8eF4cB2C97b6771dD42Af179c93b63A4f762E,
    9852000000000000000000
);
createBeneficiary(
    0x0Dc08e6954e151065cFacbAFD74b38a3d5fb185E,
    6677000000000000000000
);
createBeneficiary(
    0x1521eBc8DB1C35F56BFdcf0cB4c0D0bA60A15c80,
    9055000000000000000000
);
createBeneficiary(
    0xDbDfcA29dbbfD2B40354e4bed2b2ae43Fca0C5BA,
    2136000000000000000000
);
createBeneficiary(
    0x847d39d5634423587B54d19C1090d2320AAfCC3B,
    6796000000000000000000
);
createBeneficiary(
    0x5148BC129c64293Bd86D051EC96afF45E2CfEf15,
    8910000000000000000000
);
createBeneficiary(
    0xCc05E773cCaB36a6e5ADc2Fcd88d7A8E2ED9F62A,
    5949000000000000000000
);
createBeneficiary(
    0x2903D459e0e7a774eB9Af133D0caa1a6B2136A3a,
    8466000000000000000000
);
createBeneficiary(
    0x46e798456Fe35DFd7C3f0929923166531bFcd091,
    5114000000000000000000
);
createBeneficiary(
    0xC20Ee90E2ce67f161319EBaDff26ffdb0ee4d26D,
    10168000000000000000000
);
createBeneficiary(
    0x0b86c58Be80f00DB4B7EB52fAA175F9D76BB00bA,
    8064000000000000000000
);
createBeneficiary(
    0xF620a7127B19D82E39b386d18fF8A81beE73d2b7,
    6939000000000000000000
);
createBeneficiary(
    0x68CfFc8B215aC3A109bF9034E7a60E68EF49a4CB,
    2531000000000000000000
);
createBeneficiary(
    0xE98D80D50D526E4756E0ab8Fcd80e12060521df7,
    2833000000000000000000
);
createBeneficiary(
    0xb85220Ec720576DeF77e8f99CA689841F1c2DCf7,
    3221000000000000000000
);
createBeneficiary(
    0x5e6F476D063FfE5511957Ee31E2a310652A5ed09,
    2730000000000000000000
);
createBeneficiary(
    0x4760B9b97d8b4663dBC323d275764A22a3fC649a,
    9681000000000000000000
);
createBeneficiary(
    0xD6614eB77021351a2C6A5F588A87d47c1012908d,
    3724000000000000000000
);
createBeneficiary(
    0xE501A35020c70eCfA4D0c8365e6AB142BcECBC33,
    1735000000000000000000
);
createBeneficiary(
    0x828872BdA0180c2FDe02c0Ad559D888B1d275290,
    4743000000000000000000
);
createBeneficiary(
    0x2a52704E8830E6205140E1402F9F9D2A7DF3D48d,
    8621000000000000000000
);
createBeneficiary(
    0x10C4a215F19b5F9400489F548EC70632f46b0941,
    4241000000000000000000
);
createBeneficiary(
    0x252be930cE6f957327F41D1298Bf44939Db3b3F6,
    4167000000000000000000
);
createBeneficiary(
    0xb2b3ebf8163c0ef415b90BC27a42d0C84F96D894,
    3929000000000000000000
);
createBeneficiary(
    0x3B827BB209fA81b9030dc8D6Cd14e35b7Adc2D80,
    6252000000000000000000
);
createBeneficiary(
    0x2e6093CeE9DB48cefC482B2173Ab8226f76d06E8,
    9542000000000000000000
);
createBeneficiary(
    0x5017aae2D5210bE07558F5fE04a41f5E3Aab9732,
    2521000000000000000000
);
createBeneficiary(
    0x99E50C9d44c65d2EF905E89Aeead68624a45E7cd,
    10055000000000000000000
);
createBeneficiary(
    0xb7DF01617aa887dce01FA560abaa141c9d631fFc,
    9951000000000000000000
);
createBeneficiary(
    0xc95aEddFe6057dc3d0b278a468c0B4C84AA6A363,
    7772000000000000000000
);
createBeneficiary(
    0xA0ceB2dEddC9aa3C092fbab3953587ac0A40C0aB,
    995000000000000000000
);
createBeneficiary(
    0x0942AF94325e44a56c74e7ABd73984e34C2E9db2,
    2491000000000000000000
);
createBeneficiary(
    0xfE7e3E336bD99a8977c7f2C23682A8952aE8e961,
    2747000000000000000000
);
createBeneficiary(
    0x1d11efeC7d9228247902BdEBb243B2d9921F1AD6,
    8448000000000000000000
);
createBeneficiary(
    0x90883D2451987b3F466e2D022Ee199C94Ddc1417,
    9199000000000000000000
);
createBeneficiary(
    0x5D47D042C79a71BDd40A2323f7A78E3706c704bF,
    8285000000000000000000
);
createBeneficiary(
    0xE5aD514cB34050CFE4D6eA71d9DC97DE15275302,
    9690000000000000000000
);
createBeneficiary(
    0x29Eb66Cb2E4549F1c1Ba59C6C375195D4349f4F2,
    5705000000000000000000
);
createBeneficiary(
    0x410B3e78d69f6b2F09D709DF818962BfA77AeE01,
    1861000000000000000000
);
createBeneficiary(
    0x6470A681164c285dDa7e60a4978F7f4DA4B6BD45,
    7507000000000000000000
);
createBeneficiary(
    0xeeE62eeA474d65728EeFCf1f2AcaE3413A3f2376,
    871000000000000000000
);
createBeneficiary(
    0x31B2628864e08B01ae3170Bc5157cAe80f4e86Ab,
    1450000000000000000000
);
createBeneficiary(
    0xdeca91c84aD549aa068a941405E63D8DD4b0Da22,
    7564000000000000000000
);
createBeneficiary(
    0x010Cf2Dcb54950d55658D3B852e4B2e476d72202,
    5020000000000000000000
);
createBeneficiary(
    0x3f83c1493005AC585F6c74e3599AE8019C7fdDB4,
    9844000000000000000000
);
createBeneficiary(
    0x2580A71A387eaf95e5552E4C8d56BEBD05D7E719,
    1925000000000000000000
);
createBeneficiary(
    0xFe828ceE8AAC042328bfa9773D73f38f2d115A1c,
    6315000000000000000000
);
createBeneficiary(
    0xD43FA16033C5fD1aE3B69C7B4A7Dc2cfc39F8Aa3,
    8126000000000000000000
);
createBeneficiary(
    0xBb1725844C51940d4ebeA3af04397d67d906DaE3,
    7236000000000000000000
);
createBeneficiary(
    0xD63123BeB5F177FD66CAf057e7fBe9E01e9bD109,
    4344000000000000000000
);
createBeneficiary(
    0xD5336E6E916209eEA86be0a287732Edd7c70dB1D,
    6613000000000000000000
);
createBeneficiary(
    0x67296Ab5a01149b36A6571518fCB85d915E07Ffb,
    3889000000000000000000
);
createBeneficiary(
    0x367e8D94F3Cc960F8C7f123aE8d4a9124f46c7D7,
    6721000000000000000000
);
createBeneficiary(
    0xa6cb533FbB31A7B2e79C5DC20a357b2106801599,
    6705000000000000000000
);
createBeneficiary(
    0x9Df692057Cee5867c2CEfa14e4e97AE2007c0d54,
    5536000000000000000000
);
createBeneficiary(
    0x6530D8C29E0BC9f31066b56962AFf377126016BC,
    7423000000000000000000
);
createBeneficiary(
    0x2cA32cC74DD1a447C0eCb31ee522EFD0622Dbf75,
    5350000000000000000000
);
createBeneficiary(
    0xD47D68C0Cc64e4fa9651174bF6F7ba78dE940D7a,
    10133000000000000000000
);
createBeneficiary(
    0x29B7E0C7B65449DC16d24Da7a7dB7b8195999c44,
    4747000000000000000000
);
createBeneficiary(
    0x5F848be47ab4496A959D56f566D69ae3e7cd8724,
    3237000000000000000000
);
createBeneficiary(
    0x5490CA0635Eb6B0f69a406EeBef6DEb659BE533b,
    3418000000000000000000
);
createBeneficiary(
    0xC1FbFDE6C7a995c0cBcd3aD877a99051b7A96Ae2,
    8585000000000000000000
);
createBeneficiary(
    0x18213B3F13A4f9E2cb5be87617e3cA53bf46CB7d,
    9022000000000000000000
);
createBeneficiary(
    0xd667821BfaAC011cF354E3b8f13De7cbfb16C61b,
    6496000000000000000000
);
createBeneficiary(
    0x9925593791E84b2212Fd539DC90F4149B97E69F6,
    1097000000000000000000
);
createBeneficiary(
    0x399665EAC3a221A6920199EbaE5D99061Af12Fd7,
    8348000000000000000000
);
createBeneficiary(
    0x44c7747a2362a07e5b7AD3De0D70453Bf65B1B10,
    1803000000000000000000
);
createBeneficiary(
    0x1839dC240c880DF4bFC26Ab0f34234285839da2e,
    4204000000000000000000
);
createBeneficiary(
    0xd0f50fb61966aE2CD676252C0bFc8Ca7B871e5d3,
    6863000000000000000000
);
createBeneficiary(
    0x364c00bfB32c45b43313DcE18CeC4dfDA4c7dF4d,
    9631000000000000000000
);
createBeneficiary(
    0xAC81F4c18cF22C0c7Fdf4566219653051b353724,
    7959000000000000000000
);
createBeneficiary(
    0x41e43b6A97a963c149c3d83A6D2752a81941A8A9,
    3782000000000000000000
);
createBeneficiary(
    0x7abFdf30794d1A920432C1eAD3E1334cd1176cEe,
    2581000000000000000000
);
createBeneficiary(
    0x6d2643Bf618Fb2B04131f3170918DBFAC985d0F0,
    9315000000000000000000
);
createBeneficiary(
    0x94A18a75118b05c4202Db9F683762152B58c3E80,
    898000000000000000000
);
createBeneficiary(
    0x73740F3023Ef1e0887691Ef4877d8Ed7C8668524,
    2102000000000000000000
);
createBeneficiary(
    0x6556E1960AB54485E5fCAc45e200e3D672ce14a9,
    7242000000000000000000
);
createBeneficiary(
    0x935AD08cE4525874392C0213B829c643949719eB,
    962000000000000000000
);
createBeneficiary(
    0xEb0904Bd0c6DC133aF6aa8e1BA0aA21960fB2226,
    4345000000000000000000
);
createBeneficiary(
    0x5592ef0cefCA748c50600eF10Fc5d277817c7506,
    341000000000000000000
);
createBeneficiary(
    0x33D54C02d5C4Bd379480deeC0a13f8E796Ca05F6,
    933000000000000000000
);
createBeneficiary(
    0x5eDA71395ecCC9b752E2f2d98c7F77724358a5Fc,
    2571000000000000000000
);
createBeneficiary(
    0x816F242EFC4Ccbafa76fb467007d36076f55b6B7,
    1992000000000000000000
);
createBeneficiary(
    0x601d355082A74709fAa933229C9c6BE056487030,
    9473000000000000000000
);
createBeneficiary(
    0xbdF53EDbA01e570736cc9294f928BA0b364aDe7b,
    1621000000000000000000
);
createBeneficiary(
    0xfb945b3b402c1B48576A82F70c26bEbdD4B06073,
    6919000000000000000000
);
createBeneficiary(
    0x5E413086b876C85DA4847b5bEf5872881feCA28c,
    2122000000000000000000
);
createBeneficiary(
    0x4784cc311E72d1A5312a55e6e89Ce0912488A39F,
    3704000000000000000000
);
createBeneficiary(
    0x40193d5DFF86B5533aebe799EcA9f9403A2eF483,
    7329000000000000000000
);
createBeneficiary(
    0x5746549e4AFAE353f3413a55A97a6B9D96fB1287,
    6194000000000000000000
);
createBeneficiary(
    0x59f194Fa229081A57767D05AeACD812752607093,
    2348000000000000000000
);
createBeneficiary(
    0xE310FbFAa1c645c39Bb30C585c939516F57B60AE,
    5019000000000000000000
);
createBeneficiary(
    0xbDCe36ca2aBc84f782A24677eeA78AD47705EBaA,
    4616000000000000000000
);
createBeneficiary(
    0x7bE5A4a45a9A1b65a362059c7b40386AFB173d33,
    5299000000000000000000
);
createBeneficiary(
    0xD3815A18132183018ddEE505f4C6ada7d75E98FC,
    3461000000000000000000
);
createBeneficiary(
    0xdCCe6e1eC1F1a643D8d55157E4D74fd2d673465F,
    2119000000000000000000
);
createBeneficiary(
    0x0Fd3b74DE50F5411E9d2082b6BFBdD813685ecbd,
    7671000000000000000000
);
createBeneficiary(
    0xe1D558a4DB979DA05E685Ed84298932853169d5B,
    3362000000000000000000
);
createBeneficiary(
    0x1476B70dE1816B7317064D058109d408D7BaDfFA,
    6097000000000000000000
);
createBeneficiary(
    0xb0d8a01B67DfDbA815ca7bD9a5B405eF6BaDA789,
    7036000000000000000000
);
createBeneficiary(
    0xcEeE7C3C3bB3669eA5b99615F2D59BA7E720B766,
    9425000000000000000000
);
createBeneficiary(
    0x3531115C98F0BF64B75b46d9c6BBd0c2a83a26c5,
    3295000000000000000000
);
createBeneficiary(
    0xdCb31690223a01E79aA3c749258619260aff58d5,
    9314000000000000000000
);
createBeneficiary(
    0xD51aCE37D52CEde35252f4a7c25784A7B39AA45b,
    10231000000000000000000
);
createBeneficiary(
    0x20253F3559A4eFD7b64A4bC3da819E646aF81bBF,
    2932000000000000000000
);
createBeneficiary(
    0x5FE6fFF598F305520E1ff4CEACe853bDD7e9a3Be,
    3131000000000000000000
);
createBeneficiary(
    0x067593083685Bc7B78517C5F98f18d24cCeF887b,
    5301000000000000000000
);
createBeneficiary(
    0xb8ec1aA8DA9CeFD779081dF439DC7aFCb1705eAf,
    3659000000000000000000
);
createBeneficiary(
    0xf598DE21bfAc85a3219Ae90F81691c5e69e17850,
    10067000000000000000000
);
createBeneficiary(
    0x53d56e9bF8b6c1a6b272DE9E7C8ecCbf23336208,
    3003000000000000000000
);
createBeneficiary(
    0xf180ad01b285886eeaDa86F71D26135f46a11a12,
    9683000000000000000000
);
createBeneficiary(
    0x83E4e87672C809fcBc29CC4eB79C2A5aEA59Dcfc,
    6082000000000000000000
);
createBeneficiary(
    0xf1076165977B07Cf8011A2493EDCeb3547C6b009,
    1111000000000000000000
);
createBeneficiary(
    0x01A835d7E3c208A5CE5Bd1C58E07b4d60558749b,
    1580000000000000000000
);
createBeneficiary(
    0xFc87CBD42C31BF0b82D8D34D36ddCC4180E027e2,
    8924000000000000000000
);
createBeneficiary(
    0xf663E8E2756F2efEc67EB5725c9bAF5B5e7A47ae,
    6115000000000000000000
);
createBeneficiary(
    0xb71dFbc299499088008e0e8E24A4ac4D7a445872,
    8871000000000000000000
);
createBeneficiary(
    0x5e8A3a93dd57Bcb0c340bd3bfE20C1B2c66244C2,
    9448000000000000000000
);
createBeneficiary(
    0xa97187517C4446c9fF0e0dA5AC07FebB7BcB6cf6,
    8023000000000000000000
);
createBeneficiary(
    0x280C4E9bd22829817FD12258b1Ba78Ec8FC83cC7,
    10161000000000000000000
);
createBeneficiary(
    0xe4FcA562ABAeF12345F891A31f0F39c1E565Ae4b,
    4150000000000000000000
);
createBeneficiary(
    0x2681d0Bd4aBFc5F87704461457BB32b8C4e15Fa8,
    361000000000000000000
);
createBeneficiary(
    0x244C822Ba7857895C7f070AAd977116C0b14a000,
    5110000000000000000000
);
createBeneficiary(
    0xd4551e302ffcF1cfFCa95D20fd5772bA97f84e2d,
    5899000000000000000000
);
createBeneficiary(
    0x7a7F10d8f5b60cc8F3cB860e372589deb15b85fc,
    8721000000000000000000
);
createBeneficiary(
    0xE10F100D3FA141820Fd98862C01B18721693E196,
    7496000000000000000000
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

    // _amount is the total tokens the beneficiary can receive
    function createBeneficiary(
        address _beneficiary,
        uint256 _amount
    ) public onlyOwner {
        require(
            _beneficiary != address(0),
            "PrivateTokenVesting: beneficiary is the zero address"
        );
        require(_amount > 0, "PrivateTokenVesting: cannot vest 0 tokens");
        beneficiaries[_beneficiary].amount = _amount;
    }

    // Transfers vested tokens to msg.sender
    function release() public {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];

        require(beneficiary.amount > 0, "PrivateTokenVesting: no amount");
        require(!beneficiary.revoked, "PrivateTokenVesting: revoked beneficiary");

        uint256 unreleased = _releasableAmount(beneficiary);
        require(unreleased > 0, "PrivateTokenVesting: no tokens are due");

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

        if (block.timestamp < cliff) {
            return 0;
        } else if (
            block.timestamp >= (start + duration + (cliff - start))
        ) {
            return totalBalance;
        } else {
            return
                (totalBalance * (block.timestamp - start - (cliff - start))) /
                duration;
        }
    }
}