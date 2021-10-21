// contracts/Pegaxy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pegaxy is ERC20 {
    constructor() ERC20("Pegaxy Stone", "PGX") {
        /**
         * Mint for Pegaxy IDO
         */
        _mint(0x29153514E98081Cc172DB7b830dEA9a4d811A584, 20000000 * (10 ** decimals()));

        /**
         * Mint for Pegaxy Liquidity
         */
        _mint(0xC94fb63396aa06E90a754d92Aae67A985Ba23ab7, 100000000 * (10 ** decimals()));

        /**
         * Mint for Pegaxy Marketing and Ecosystem Reverse
         */
        _mint(0x06cD1BA9a834869E2a8476B405803D450Df41167, 300000000 * (10 ** decimals()));


        /**
         * Mint for Vesting Contract of Pegaxy Community Develop
         */        
        //Wait for contract deployed
        _mint(0x7c00Bee8552CCa98D828fFA3E7dFc58fa5CB60a6, 160000000 * (10 ** decimals()));

        /**
         * Mint for Vesting Contract of Pegaxy Team and Advisors
         */        
        //Wait for contract deployed
        _mint(0x8757E9873444aA07C610b1FC3b6717e86e6452D1, 220000000 * (10 ** decimals()));

        /**
         * Mint for Vesting Contract of Private Sale Round 1 Investors
         */
        //Wait for contracts deployed
        //0x13A07af9422Aa8b3868B1b89178a870e1c3f9424
        _mint(0xA4Ce42eA9FD102050E900Bb851525aF92b304B99, 30000000 * (10 ** decimals()));
        
        //0xcE36e34ea4C96BC3869A135Ae4F68E439029254b
        _mint(0x57362Ee4dA166a8E3ac5ce0148E7FBB3c9cCeBb3, 15000000 * (10 ** decimals()));
        
        //0x2b6EfCCe98Fe1e46967f8Ce49bd258007c796945
        _mint(0x28F3ba6ADe556e905e5D40E88ac53a68311EBdcE, 5000000 * (10 ** decimals()));
        
        //0x17dac974ec5bf41a7f6dcec1effe5bf2cebaa79a
        _mint(0x7374AbB88614092057537898E03EB624F921FA8b, 6500000 * (10 ** decimals()));
        
        //0x04616EA20406B2388583A0cb1154430A34753dF7
        _mint(0x29452e6D32B279677431AdeB83BeAEB5f2c8e5F8, 10000000 * (10 ** decimals()));
        
        //0x664Fe01207Dc37C84A97A8dCdC28bCc1Da6bEE57
        _mint(0x5e35Bb09fc63E713aAC97DeBECd4f598B0350834, 10000000 * (10 ** decimals()));

        //0x0C3bDFc1cd0FBC4a371F0F3A18Ec1F990FDd0d39
        _mint(0x80Aa48342CfD7FFB3536828a1ACd268b3b64dcFA, 2000000 * (10 ** decimals()));
        
        //0xCF280dF3da6405EabF27E1d85e2c03d3B9047309
        _mint(0x5Ec582bBF2ce59eb50e40781046f99e7daC1D607, 5000000 * (10 ** decimals()));
        
        //0x2340B5DB633b7F4BA025941b183C77E8cDEa5134
        _mint(0xA7087F684Ec5B2bE931505590cdC66D8dae4b133, 5000000 * (10 ** decimals()));
        
        //0x3E8C6676eEf25C7b18a7ac24271075F735c79A16
        _mint(0x8140faC8f6C9C6a6E7B4F110e1a0b0F2C819EAc4, 1000000 * (10 ** decimals()));
        
        //0x38B4be8a7dcf2d6fa4e6C826fAe20669BD89DF2c
        _mint(0xB4ec70f871656Fe7d76344e0d753e68048779033, 2500000 * (10 ** decimals()));
        
        //0xf480275B9F0D97Eb02DE9cEa149A8F613121C588
        _mint(0x99e1dfb42397622A26E2AD67edaEF2A6396758A6, 8000000 * (10 ** decimals()));
        
        //0xa50f89381301decb11f1918586f98c5f2077e3ca
        _mint(0x584DFD3ce3793f2f4009873601796D33f008C895, 13333333 * (10 ** decimals()));
        
        //0xb8F03E0a03673B5e9E094880EdE376Dc2caF4286
        _mint(0x49f1514496b6501F0d1914cF7f320C880ce36e4E, 16666666 * (10 ** decimals()));

        //0x05AeB176197F1800465285907844913a2bc02e75
        _mint(0x0FAd12202aD23AAbf89ac5059A42A944fc47aFf0, 10000000 * (10 ** decimals()));
        
        //0x2340B5DB633b7F4BA025941b183C77E8cDEa5134
        _mint(0xf427bFC7EFe4e92a4D3503434886F8883a58b7b6, 6666667 * (10 ** decimals()));
        
        //0xcE36e34ea4C96BC3869A135Ae4F68E439029254b
        _mint(0xE3d1a13D85c79d8E7BEda31A76702bEAD12E1602, 2666667 * (10 ** decimals()));
        
        //0x637E21Ac11F0E0Cf95D926d6bd2737b059A2858a
        _mint(0xAD6bf9C7593E38ba24F578F4d8343EA24e0Bf5d1, 3333333 * (10 ** decimals()));
        
        //0xC0855f464261832aa43f1d9d9E1cC2aCeEF7c54b
        _mint(0x37E4F25080D93941D18cb92619e71f4055BB14b1, 3333333 * (10 ** decimals()));
        
        //0x4D30922f14fD6149D06994FFc08D042Dc09bbd42
        _mint(0x94A852CD73ba4a23488e1D17e304Fe46b9D9FE93, 3333333 * (10 ** decimals()));
        
        //0x8BF99D25C3cC0Bb8ebB13395e323A3Bf78BC2d48
        _mint(0xc05ffA2c0244515B8dDC07220fDfC77c36C60073, 3333333 * (10 ** decimals()));
        
        //0x4F76e9779F4eF8Ea8361CecDEe0a2ccdbA4B06ba
        _mint(0xe2e746f79FfEe5dfF2B8c8B71D717FB4681Bcdcc, 2000000 * (10 ** decimals()));
        
        //0x175cB067535951C0e27404a5E57672ED1F477440
        _mint(0x1b18499973e7F2405E29FfeAB82A2cA9cFA1471c, 2000000 * (10 ** decimals()));

        //0x38B4be8a7dcf2d6fa4e6C826fAe20669BD89DF2c
        _mint(0x7a05FDc83f4d5D9DE102aD700E6C6a67b563eeb2, 1666667 * (10 ** decimals()));
        
        //0x380E0E7e7AF09B5f0069289356c813A1C4878fe0
        _mint(0x1CB743bd360BF665BF2e79E6b098c3f5B9f25424, 1666667 * (10 ** decimals()));
        
        //0x9e12da5Ca525Ad3EF2a35Bf8286369b3eeB0A0d2
        _mint(0xf108Ef354CD7Fd50B6b4E211971742F34a04D315, 6666667 * (10 ** decimals()));
        
        //0x338FdBd9361CA33C8F32cf373d1b2913e4Ec4540
        _mint(0xFcCF4956361C88E80aEDd1E30877910Dd9f5227A, 3333333 * (10 ** decimals()));
        
        //0x18701332a0126472ea908f54de9836ca1c5e9679
        _mint(0x3413A355F16F95147Fd584c69Ad160d0D6142911, 3333333 * (10 ** decimals()));
        
        //0x03951Cb1aE6bA341409C106000efF4D5313bD319
        _mint(0x041c85ef362B02266021b1D7bd9f4E0D1D2009D1, 1333333 * (10 ** decimals()));
        
        //0x1f5feA56Da579CD297868D5d7eAA42100cAe17f5
        _mint(0xde3427332855dC936928e1813cF8149fD7717D69, 1000000 * (10 ** decimals()));
        
        //0x3faa6715BE99A73e7eDaBdB33C294E621b79a26F
        _mint(0x37C98032327071f7ae88847Cf1f412a769534e40, 1000000 * (10 ** decimals()));
        
        //0x0C7dcFB81823F8326E53A42d5fc6F4fEc79e4547
        _mint(0xed6cdc19a6328fc9c91319d571F5117d61CB78F1, 1000000 * (10 ** decimals()));
        
        //0x6cdF11996eEd528d69Cd8B56503fDb19EC0B2977
        _mint(0x3fE8bf244f9AfDc7d386693c617b4fe7Ea1237C9, 1000000 * (10 ** decimals()));
        
        //0xf480275B9F0D97Eb02DE9cEa149A8F613121C588
        _mint(0xFB82C9ADfCb734Ac0bcF13bBf60308FBc225CB21, 1333333 * (10 ** decimals()));
        
        //0x945414c5577cfF660248715905994D51CfB23625
        _mint(0x0057D4c47Da5A0Fb86A98E011E05Fc7419E713cE, 166667 * (10 ** decimals()));
        
        //0x3E8C6676eEf25C7b18a7ac24271075F735c79A16
        _mint(0x154df82a7075735c77D0893dE8Fb32f86EC07614, 666667 * (10 ** decimals()));
        
        //0x09B64e3d589AE90ACCE69C75C346722D8EbFB65D
        _mint(0xf7d9c20b79dEA5622144Bd9A0a85C648546960B2, 666667 * (10 ** decimals()));
        
        //0x859108D264c8bd49BC90b78E6796FeE7AfdfAC63
        _mint(0x5B18c41659EABb4E499727AE478FcD5F7E94bCd4, 666667 * (10 ** decimals()));
        
        //0x603A26BaEDC8316467bC9c3BaA38606Bbc286697
        _mint(0x06F9465330C1ebedA0178a8e7CCd5adD425aDc84, 166667 * (10 ** decimals()));
        
        //0x1A923a54f042f4E43910313827Aa4C6D3429756D
        _mint(0x00Dba888701CbFAe6FF20c447528c979323CFe78, 666667 * (10 ** decimals()));
        
        //0x80B603bCE2D8Cc3acb43B6692514b463a16FB425
        _mint(0xb3852023626A280dE9F8A708C2200268BcC988D6, 666667 * (10 ** decimals()));
        
        //0x08dbbDB48CDe6d890e88328b877589cB1E0c3680
        _mint(0x32a75fBCccc4edc52f21756310D80F10D7e9F1A9, 333333 * (10 ** decimals()));
        
        //0x95c745807A5A7BE209a3F394eEc9A1Ccda4251F4
        _mint(0x0216F0dD79eAA4E4dAF3cd831F972A5Fbc78dd87, 4666667 * (10 ** decimals()));
        
        //0x739bf77ACBdd7b0D81783944D5BC07196365B26d
        _mint(0xCbF7FCdB5F2c11F8F514E31703A02D91E6FC0c0C, 1333333 * (10 ** decimals()));
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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