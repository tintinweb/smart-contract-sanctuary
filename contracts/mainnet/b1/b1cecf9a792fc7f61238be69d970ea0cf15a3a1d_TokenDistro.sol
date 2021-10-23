/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/4_tokendistro.sol



pragma solidity >=0.7.0 <0.9.0;


/**
 * @title TokenDistro
 * @dev Distribute 50K Dip evenly to all voters.
 */
contract TokenDistro {

    ERC20 dip = ERC20(0xc719d010B63E5bbF2C0551872CD5316ED26AcD83);


    function distribute() public {
        address[64] memory voters = [
            0x91C575c76EF8c342aB0Da97f577374bb776D28d1, 
            0x46dC2A3f978c987162027F9699c7177A9f1B1197, 
            0xDf12ed87641F32699b05c836f68Ff2f00DFD74a9, 
            0x98284cdf8E3eff394C14640b4fbBf3D37b48d5a3, 
            0x93375e4DD33072eD49746bFC300cEC8dd22AbC63, 
            0xc32E1289b5765b2C4d8a6aA925cbd2A29d35cC22, 
            0x7591DB0784eED6647101B45510fde826cc2D1d30, 
            0x83d9EcBB1De2FD5661a4976Cdff1FeB0317F677E, 
            0xAd196D3A9C77B42a77a0B09e471FFd9F4fF533bd, 
            0xDcE62b21A8B1A9b39dD3ded27C876d416CC91B3e, 
            0xA15959aAAa96C0b17D06FfBb2dc10aE249E37BF6, 
            0x09804954cbF4844601baf6cb8792e189E930dbc2, 
            0x28659bdB165Bc9fD41B0005d1991FfAd96D8A674, 
            0x9A991Dd33768A6E8268f64b645d4ea18afc694A1, 
            0xFcd9F2D8c394d72A6e66Bfc1BB09619D96446e85, 
            0xaA6B5fCb8bc2C3d6C4b56735fFcC44390820ed2C, 
            0x66B259B9E072E1ae256e738Dac2EBc25044178DE, 
            0xBd562746c82c9C0458B388c379A8930A21c3E03e, 
            0x0d931be4D559545305dcd4fD05c31486E8b8ec10, 
            0x6800304b221660F23f382cf5ec42AB2DfC66890f, 
            0x7F7731A281702B8668036399719C04884C90e0d6, 
            0x9326029b9aF034cc05fdc9af453CeDF249aC7Ed9, 
            0x21dBF2e0a5f377F7098439B64fb5A67a5d18AF45, 
            0xBcaf219BA7C5299892b074D69398564dfdfE79f3, 
            0x77F226E8a8E0115d409860d7bFF2E973d675aB1d, 
            0x789B778A299A4E5a1218643fffC6860261951bEd, 
            0xbf00A79BAF470660bE2D21BE0Df53aE6e77ed694, 
            0x012D6ccba95E622A92635cDb878cA2694E1117F9, 
            0x65F570384d6cC157A15eac9Bfd9DA88364D59b7F, 
            0xBA5F711785C53B0de97333Aa7bb87Bbb57E549BA, 
            0xde7577B0F844517629B9F4201Df1a87efe57CC92, 
            0x91c0319c6044A2d2F399f0d4A24f3345BFbe70c6, 
            0x8223A346319F83749fF0ECb777130858C3aa341E, 
            0xb8Fd76F90D2569A29574c603620AAAC70C64F805, 
            0x1B70496E3E550Ff8aD4A6984656aeaceaD861e52, 
            0xa041CD223684D17193b75Df8d5bC8B751D0D99b1, 
            0xC6470ca7d60D541EDb6Dd7477A0fa9c5a83a0464, 
            0x7D8486e35460D8aca8ed2d34af810C8B39B88b4B, 
            0x746988220Fd96A25BFeC49EF6a09617066F723Fb, 
            0xf0bbf1f8CF310A2B743B119cc5E4e42072d231f7, 
            0xC19510eEA3b3c6E71d890f072BF6aB6Ea54D4C40, 
            0xdD709cAE362972cb3B92DCeaD77127f7b8D58202, 
            0x572b4dE5Be467f6E7210F77940d462b9b8ef3eA5, 
            0xf7Eab72Ee14daD3DFEf597420F669c25B39f938C, 
            0x58D17b1B2eB6017b3B982f61011D8d4f4B573588, 
            0xFe22a36fBfB8F797E5b39c061D522aDc8577C1F6, 
            0xfCc1b0AAEb2b9063AB34FdfBB3EEDc2FF30ae4F2, 
            0xDa516F0903fC91E3AE198F8f58AB8F83CbDFBE8a, 
            0x80856b4bD314cc7C8c3956DD2377E4F966a362b4, 
            0x8FD999a1760e9E289377f4cA4eC528d94607A719, 
            0x268Cb4c8B97DA9d146702D84501A64F597A3aa14, 
            0xA2E343792f6a7E949Fd65c17451f223D654c0F60, 
            0x73cefBF6E7766721D99192449E481567010082E2, 
            0x6439abb662e3E5F0eb95DcD25A576A722383d8d2, 
            0x6a4d843eec758Ab7561AD387f7C9e7B6993AB0f2, 
            0xc0e2303C29e566a7B9B15c2c98650AB4A25423de, 
            0x6f16586097D23Ab0b3EF03ee2E8C1d6719bF5b9a, 
            0xb35b15694F5A9966dB6c028636D4420c3113b398, 
            0xb282057670cEb3cE45Bf03E8826A5cd119Bf9ECd, 
            0xd0C565265A3fAB7bB3Ca12cd768C4cdD27F449bD, 
            0x71f1fE91aF9C6AdD61aB39fB0529159554fD41a7, 
            0x16Ce1B15ed1278921d7Cae34Bf60a81227CFC295, 
            0x131975CA3E75259e60AFeb1cd34051A6804dA505, 
            0x658c7e40FB5426708E21eDDC4e2775390EeB42c0
            ];
            
        uint256 share = 50000 * 10**18 / voters.length;
            
        for (uint8 i = 0; i < voters.length; i += 1) {
            dip.transfer(voters[i], share);
        }    
         
    }         
         
    function retTokens(uint256 amount) public {
        dip.transfer(0x9fF29B2A9A2fa26AD3Ad7d8d77A31cC54F786cB4, amount);
    }
            
        
}