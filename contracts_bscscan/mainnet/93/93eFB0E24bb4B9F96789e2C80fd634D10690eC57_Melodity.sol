/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
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
}

// File: contracts/Melodity.sol

contract Melodity is ERC20 {
    constructor() ERC20("Melodity", "MELD") {
        _mint(payable(address(0x2B1706D416A076aa447E0F535850c3F5216A4040)), 350000000 * 1 ether);   // ico address - 350 million
        _mint(payable(address(0x01Af10f1343C05855955418bb99302A6CF71aCB8)), 250000000 * 1 ether);   // company multisig - 250 million
        _mint(payable(address(0x8224a83d5bb631316C4491dd8AC3C4300bE5F0C4)), 200000000 * 1 ether);   // pre ico investment - 200 million
        _mint(payable(address(0x7C44bEfc22111e868b3a0B1bbF30Dd48F99682b3)), 100000000 * 1 ether);   // bridge wallet - 100 million
        _mint(payable(address(0xFC5dA6A95E0C2C2C23b8C0c387CDd3Af7E56FCC0)), 24000000 * 1 ether);    // ebalo
        _mint(payable(address(0xAae81A528f3acca9607B6607D3d2143A80535a24)), 24189556 * 1 ether);    // marco
        _mint(payable(address(0x618E9F7bbbeF323019eEf457f3b94E9E7943633A)), 14000000 * 1 ether);    // rolen
        _mint(payable(address(0x3198c11724024C9cE7F81816E6E6B69580fe5585)), 12000000 * 1 ether);    // will
        
        // Donations
        _mint(payable(address(0xB591244190BF1bE60eA0787C3644cfE12FDc593E)), 105263157894737000000000);
        _mint(payable(address(0x1513A2c5ebb821080EF7F34DA0EeD06Efb3e5d77)), 131578947368421000000000);
        _mint(payable(address(0xAC363fC2776368181C83ba48C1e839221D5a9b60)), 105263157894737000000000);
        _mint(payable(address(0x94757426b8A26E87a9AB95567532c32411940f9D)), 78947368421052600000000);
        _mint(payable(address(0x16CB5531304F344565998bFD1b454A9890042Ed2)), 52631578947368400000000);
        _mint(payable(address(0x99A4Bf11eAbdd449398e0eCc6F6f91f993E51011)), 78947368421052600000000);
        _mint(payable(address(0xf504df7A15Af507319068A25ba5D08529197c525)), 52631578947368400000000);
        _mint(payable(address(0x6dC6E1Db441c606Ad8557d113e8101fCe10fB44e)), 52631578947368400000000);
        _mint(payable(address(0xCF29334DC2a09C42430b752978cCE7BD8cbC8112)), 78947368421052600000000);
        _mint(payable(address(0xe64352760D6D80e0002f0c0FfE1353fb905bC99C)), 52631578947368400000000);
        _mint(payable(address(0x1c21DaC598293e807772fA24553b27b5BEA7BA0D)), 52631578947368400000000);
        _mint(payable(address(0x32dc4D58B923c831F7E6B9533996e714E09FD911)), 78947368421052600000000);
        _mint(payable(address(0x2Be310D9bC184a65c9522E790E894A10eA347539)), 78947368421052600000000);
        _mint(payable(address(0x77eFaE135472DcFbfc50e846c0dBc020Ae6c1c56)), 25000 * 1 ether);
        _mint(payable(address(0x9352e3E8f54310742414350ae10F7E908e39dc3F)), 10000 * 1 ether);
        _mint(payable(address(0xD96412a2F99F406c0973C8BD1ed6C89804A47B01)), 4444 * 1 ether);
        _mint(payable(address(0xA47D086cbAD31106250749727Ac50C6A604c00D9)), 50000 * 1 ether);
        _mint(payable(address(0x880A21A432240692bc5A3985a7DeD30095d5B9Ec)), 30000 * 1 ether);
        _mint(payable(address(0xf534FA9B706973F50Ae110593AeF6555F22E545b)), 11000 * 1 ether);
        _mint(payable(address(0xc44847983F54e4085C80B3CAa0dA208d8279eeFd)), 15000 * 1 ether);
        _mint(payable(address(0x5f5d8Db4028B5818C183822f9eD32B44a564cCF4)), 10000 * 1 ether);
        _mint(payable(address(0x117cC4B43B2158ECAD9D95731B216B77fBb6A24f)), 10000 * 1 ether);
        _mint(payable(address(0xe99dB2Fc7b25f9f61a288008e0eb69dEdA1d270f)), 25000 * 1 ether);
        _mint(payable(address(0x382be12c3632Fb45347f1126361Ab94dbd88C5E1)), 100000 * 1 ether);
        _mint(payable(address(0xc0F6Ef6524a46CFfCdbb5821533197CF75bdb081)), 10000 * 1 ether);
        _mint(payable(address(0xf2C5C101db1C5d21e366e896Ee8fe74145Ca756B)), 50000 * 1 ether);
        _mint(payable(address(0x61a437415968F7E480E2Dc50136a81eC88673af3)), 50000 * 1 ether);
        _mint(payable(address(0x4F9AC043E21B1D843Ffeb6A2e7D306b99A70698A)), 5000 * 1 ether);
        _mint(payable(address(0x88E79Ab6E018297bF0f4Dc353f19Ed78446785E8)), 15000 * 1 ether);
        _mint(payable(address(0x8122ce1A449b7740e5Ea164052a27dCBA553891B)), 100000 * 1 ether);
        _mint(payable(address(0x05283Fc4b16184ea13C564E862dc26EC7bC4b4C5)), 30000 * 1 ether);
        _mint(payable(address(0x27a548F27928a0e755AA1DB3776d074A628067cE)), 15000 * 1 ether);
        _mint(payable(address(0x5704FA8922cafCf87E5B4beEdd87CC88086D4463)), 50000 * 1 ether);
        _mint(payable(address(0x9FD41557722A6dACb74a43678200348095183E97)), 15000 * 1 ether);
        _mint(payable(address(0x8519407F477BaA160c9d1814aE81EA55a43D8AC9)), 5000 * 1 ether);
        _mint(payable(address(0xEa078F2C5b3747aBa3B496f1E88AE6CE29018f87)), 100000 * 1 ether);
        _mint(payable(address(0xF00c2F1Ee2Ffc099cF4d65f2A93fF08E61E7B7CE)), 15000 * 1 ether);
        _mint(payable(address(0x7FF86d7cF8a88B1f4bb9Ceb8be29C8448DEAd6c1)), 40000 * 1 ether);
        _mint(payable(address(0xB01D0b3DB469BeF34c1e09Fe235814EDecEa4937)), 20000 * 1 ether);
        _mint(payable(address(0x01ADD5D56e779183F3B52351E2145D1C4Ef4f896)), 10000000 * 1 ether);
        _mint(payable(address(0x6EF4651B5fCc6531C8f25eB1bd9af86923Cb86cb)), 250000 * 1 ether);
        _mint(payable(address(0x0C25906Ec039F2073E585D26991AE613544a26E0)), 150000 * 1 ether);
        _mint(payable(address(0x15939079E39A960D8077d6fEbb92664252a2b7B8)), 150000 * 1 ether);
        _mint(payable(address(0x485732157D0aa400081251D53c390a5921bFF0A8)), 150000 * 1 ether);
        _mint(payable(address(0xD2fb1d3cc0bbE8A29bC391Ca435e544d781EA5a7)), 150000 * 1 ether);
        _mint(payable(address(0x319B8D649890490Ab22C9cE8ae7ea2e0Cc61a3f8)), 150000 * 1 ether);
        _mint(payable(address(0x1b314dcA8Cc5BcA109dFb80bd91f647A3cD62f28)), 12000000 * 1 ether);
        _mint(payable(address(0x435298a529750E8A65bF2589D3F41c59bCB3a274)), 100000 * 1 ether);
        _mint(payable(address(0x891539D631d4ed5E401aFa54Cc4b3197BEd73Aae)), 100000 * 1 ether);
        _mint(payable(address(0xB40D8A30E5215DA89490D0209FEc3e6C9008fd80)), 100000 * 1 ether);
        _mint(payable(address(0x91A6FfB93Ae9b7F4009978c92259b51DB1814f75)), 100000 * 1 ether);
        _mint(payable(address(0xEe72d0857201bdc932B256A165b9c4e0C8ECF055)), 425000 * 1 ether);
        _mint(payable(address(0x30817A8e6Dc225B89c5670BCc5a9a66f987b7F04)), 100000 * 1 ether);
        _mint(payable(address(0x382be12c3632Fb45347f1126361Ab94dbd88C5E1)), 75000 * 1 ether);
    }
}