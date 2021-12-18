/**
 *Submitted for verification at polygonscan.com on 2021-12-17
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/BLAQ.sol




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

// File: contracts/OnesSource.sol

pragma solidity ^0.8.0;

contract OnesSource is Context, IERC20, IERC20Metadata {
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
     *
     * Mints total supply of 100000000000000000000000000 to the deployer
     */
    constructor() {
        _name = "Ones Source";
	    _symbol = "BLAQ";

        // All gets sent to presale address after launch. 20000000000000000000000000 goes to liquidity and 50000000000000000000000000 will be sold in presale.
        _mint(msg.sender, 70000000000000000000000000);
        _mint(0xC28e3559298DB2D54B36D62A130cB664d1B2A77e, 30000000000000000000000000); // treasuryAddress.

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

    /*
    *   Instructions to launch:
    *   Compile code and Launch OnesSource
    *   Notice the launcher address receives all the presale and liquidity tokens.
    *   Launch the presale address and pass in the contract address of the blaq token previously launched and the owner address for the blaq project
    *   Send all tokens to the presale address (70000000000000000000000000)
    *   Presale is live after "pauseRounds" is called with "false" passed in
    *   Each round will end when all tokens are sold and the presale will pause. "pauseRounds" will need to be called each round at the start to open it to presale
    *
    *
    *   Instructions to use:
    *   Make sure the presale is live
    *   Authorize presale contract to spend the funds you wish to buy with
    *   Enter the Integer amount of tokens you wish to buy into the "buyWith" function you wish to use and confirm transaction
    *   Contract will add the amount purchased to your vesting amount to be released after the presale Ends
    *
    *
    *   Important information 
    */
contract BlaqPresale is Ownable {
    
    IUniswapV2Router01 public _router = IUniswapV2Router01(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IERC20 public _blaq =        IERC20(0x57670839ddd40dF533BFCe05d93bcDC3C4C669Fe);
    IERC20 public _usdc =        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public _usdt =        IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public _wmatic =      IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address private _devWalletOne =     0x36ff4148E8C18f35B0617a1Cc8be870A8c441974;
    address private _devWalletTwo =     0x48E8a0168FC4C2A5fA2BB2785ac3Cd512Cb3CA89;
    address private _teamWallet =       0xd88C70ec3986C1e303CFb5179f9272d9CF77a3f1;
    address private _marketingWallet =  0x1D65E8eb7b8B28A4fB51A484B5Bb03E78ca2ECa4;
    address private _appDevWallet =     0x5d85858d5a434Bf32346AE091Cb557CAF91ddc51;
    uint256 public _blaqDecimals = 18;
    uint256 public _presaleEndDate;
    uint256 public _currentRound = 1;
    uint256 public _tokensSold = 0;
    uint256 public _operatorFundsWithdrawn = 0;
    uint256 public _totalPresaleTokens =    50000000;
    uint256 public _totalLiquidityTokens =  20000000;
    uint256 private _devCut = 100; // Out of 1000 for 0.1 decimal usage
    uint256 private _teamCut = 250; // Out of 1000 for 0.1 decimal usage
    uint256 private _marketingCut = 150; // Out of 1000 for 0.1 decimal usage
    uint256 private _appDevCut = 500; // Out of 1000 for 0.1 decimal usage
    
    bool public _paused = true;
    bool public _isInPresale = false;

    // Functionality to keep all the information needed for each round
    // _tokensLeft tracsk the tokens that can still be bought in the current round
    // _usdcPrice lists the price for one token for the current round
    struct _presaleRound {
        uint256 _tokensLeft;
        uint256 _usdcPrice;
    }

    // Functionality to keep all the information needed for all buyers in the presale
    // _unitsClaimed tracks how many months of tokens have been claimed so far
    // _roundX tracks the current token amount the buyer has in each round
    struct _investor {
        uint256 _unitsClaimed;
        uint256 _round1;
        uint256 _round2;
        uint256 _round3;
        uint256 _round4;    
    }

    // Mappings for the presale round information and the buyer information
    mapping(uint256 => _presaleRound) public _rounds;
    mapping(address => _investor) public _investors;

    // Takes in the blaq address and the address of the wallet that will own the contract
    // This sets up the routers and the rounds in addition to starting the timer for the hard end of the presale 
    constructor() {
        
        // Denotes presale has not started
        _presaleEndDate = 0;    

        // _totalPresaleTokens / 4 = 12,500,000
        _rounds[1]._tokensLeft = _totalPresaleTokens / 4;
        _rounds[1]._usdcPrice = 300000;
        
        _rounds[2]._tokensLeft = _totalPresaleTokens / 4;
        _rounds[2]._usdcPrice = 600000;
        
        _rounds[3]._tokensLeft = _totalPresaleTokens / 4;
        _rounds[3]._usdcPrice = 900000;
        
        _rounds[4]._tokensLeft = _totalPresaleTokens / 4;
        _rounds[4]._usdcPrice = 1200000;

        // Approves the router to spend all the coin we are dealing with
        _usdc.approve(address(_router), ~uint256(0));
        _usdt.approve(address(_router), ~uint256(0));
        _wmatic.approve(address(_router), ~uint256(0));
        _blaq.approve(address(_router), ~uint256(0));

    }

    function startPresale() external onlyOwner{
        require(_presaleEndDate == 0, "You have already begun the presale");
        // Begins the presale
        _isInPresale = true;
        _pauseRounds(false);
        // Marks the hard end of the presale when the liquidity will be added and the token will go live
        _presaleEndDate = block.timestamp + (26 * 1 weeks);
	    
    }

    function changeRouter(address newRouter) external onlyOwner{
        _router = IUniswapV2Router01(newRouter);
	
    }

    // Functionality for retreiving the price of the requested amount of tokens in USDC (6 decimal places)
    // Fails if asking for more than allowed in round
    function getPrice(uint256 amount) public view returns(uint256) {
        require(amount <= _rounds[_currentRound]._tokensLeft, "There is not that many tokens left to sell in this round.");
        return amount * _rounds[_currentRound]._usdcPrice;

    }

    // Functionality to subtract the Blaq purchased at given round and add to claimable tokens for user. Errors if more Blaq are being purchased that there is left in sale
    // increments if round finishes
    function consumeBlaq(address user, uint256 amount) internal {
        require(!_paused, "BLAQ Presale: Presale paused.");
        require(_rounds[_currentRound]._tokensLeft >= amount, "BLAQ Presale: Attempting to purchase more than presale level has left.");
        _rounds[_currentRound]._tokensLeft -= amount;
        amount = amount * (10 ** _blaqDecimals);
        if(_currentRound == 1) {
            _investors[user]._round1 += amount;
        } else if(_currentRound == 2) {
            _investors[user]._round2 += amount;
        }else if(_currentRound == 3) {
            _investors[user]._round3 += amount;
        } else {
            _investors[user]._round4 += amount;
        }

        // If all tokens have been purchased the round increments up and presale is paused for owner to start up again after marketing
        if(_rounds[_currentRound]._tokensLeft == 0) {
            _currentRound++;
            _pauseRounds(true);
        }

        // If all rounds are over and we move to round 5 OR the end of the presale passes and a transaction is attempted
        if(_currentRound == 5 || block.timestamp >= _presaleEndDate) {
            _endPresale();
        }

    }

    // Functionality for purchasing with USDC
    function buyWithUsdc(uint256 amount) public {
        // Gets price for tokens desired then takes tokens equal to price to be paid
        uint256 price = getPrice(amount);
        _usdc.transferFrom(msg.sender, address(this), price);

        // Checks that amount desired can be purchased, then adds purchased amount to buyer and to total sold.
        _tokensSold += amount;
        consumeBlaq(msg.sender, amount);

    }

    // Functionality for purchasing with USDT
    function buyWithUsdt(uint256 amount) public {
        // Gets price for tokens desired then takes tokens equal to price to be paid
        uint256 price = getPrice(amount);
        address[] memory path = new address[](2);
        path[0] = address(_usdt);
        path[1] = address(_usdc);

        uint256[] memory output = _router.getAmountsIn(price, path);
        _usdt.transferFrom(msg.sender, address(this), output[0]);

        _router.swapTokensForExactTokens(price, output[0], path, address(this), block.timestamp + 100);
        
        // Checks that amount desired can be purchased, then adds purchased amount to buyer and to total sold.
        _tokensSold += amount;
        consumeBlaq(msg.sender, amount);

    }

    // Functionality for purchasing with wrapped MATIC
    function buyWithWMatic(uint256 amount) public {
        // Gets price for tokens desired then takes tokens equal to price to be paid
        uint256 price = getPrice(amount);
        address[] memory path = new address[](2);
        path[0] = address(_wmatic);
        path[1] = address(_usdc);

        uint[] memory output = _router.getAmountsIn(price, path);
        _wmatic.transferFrom(msg.sender, address(this), output[0]);

        _router.swapTokensForExactTokens(price, output[0], path, address(this), block.timestamp + 100);

        // Checks that amount desired can be purchased, then adds purchased amount to buyer and to total sold.
        _tokensSold += amount;
        consumeBlaq(msg.sender, amount);

    }

    // Functionality for Pause/Unpause the presale rounds
    function pauseRounds(bool pause) external onlyOwner {
        _pauseRounds(pause);

    }

    // Internal function call for pauseRounds
    function _pauseRounds(bool pause) internal {
        _paused = pause;

    }

    // Allows anyone to withdraw from the 25% of presale funds to operate the project
    // ie: 100$ raised, operator withdraws 25$, another 1$ is made, operator withdraws 0.25$
    function withdrawOperatorFunds() public {
        _withdrawOperatorFunds();

    }

    // Internal function call for withdrawOperatorFunds
    function _withdrawOperatorFunds() internal {
        uint256 fundsGenerated = 0;

        // Iterates through the rounds and adds up funds generated
        for(uint256 i = 1 ; i < 5; i++) {
            fundsGenerated += ((_totalPresaleTokens / 4) - _rounds[i]._tokensLeft) * _rounds[i]._usdcPrice;
        }

        // Calculates the amount the operator can withdraw. At any time they can withdraw 25% of the tokens collected. 
        // They can not withdraw the same tokens twice
        uint256 operatorFunds = (fundsGenerated / 4) - _operatorFundsWithdrawn;
        if(operatorFunds > 0) {
            _operatorFundsWithdrawn += operatorFunds;
            _usdc.transfer(_devWalletOne, ((operatorFunds * (_devCut / 2)) / 1000) );       // 5%
            _usdc.transfer(_devWalletTwo, ((operatorFunds * (_devCut / 2)) / 1000) );       // 5%
            _usdc.transfer(_teamWallet, ((operatorFunds * _teamCut) / 1000) );              // 25%
            _usdc.transfer(_marketingWallet, ((operatorFunds * _marketingCut) / 1000) );    // 15% 
            _usdc.transfer(_appDevWallet, ((operatorFunds * _appDevCut) / 1000) );          // 50 %
        }

    }

    // Owner Override to end Presale early
    function endPresale() external onlyOwner {
        _endPresale();

    }

    // Ends Presale & Pairs Liquidity
    function _endPresale() internal {
        _isInPresale = false;
        _presaleEndDate = block.timestamp;
        _currentRound = 5;
        pairLiquidity();

    }

    // Functionality to pair the liquidity after criteria have been met (Switch is hit, all tokens are sold, or 6 months pass since presale starts)
    function pairLiquidity() internal {
        _withdrawOperatorFunds();
        uint256 usdcBalance = _usdc.balanceOf(address(this)); // This will send the remaining balance AFTER withdrawOperator funds is called.
        uint256 tokensLeftOver = _totalPresaleTokens - _tokensSold;
        uint256 liquidityAmount = _totalLiquidityTokens - (tokensLeftOver * 4000) / 10000;
        // Locks up remaining tokens not consumed in presaleand liquidity pairing to the team wallet
        _investors[owner()]._round1 += ((_totalLiquidityTokens - liquidityAmount) + tokensLeftOver) * (10 ** _blaqDecimals);

        // add the liquidity
        _router.addLiquidity(
            address(_blaq),
            address(_usdc),
            liquidityAmount * (10 ** _blaqDecimals),
            usdcBalance,
            // Bounds the extent to which the WETH/token price can go up before the transaction reverts. 
            // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
            0,
            // Bounds the extent to which the token/WETH price can go up before the transaction reverts.
            // 0 = accept any amount (slippage is inevitable)
            0,
            // this is a centralized risk if the owner's account is ever compromised (see Certik SSL-04)
            owner(),
            block.timestamp
        );

    }

    // View function for tokens still in vesting contract
    function viewVestedTokens(address user) public view returns(uint256) {

        uint256 vestedTokens = 0;
        if(_investors[user]._unitsClaimed < 4 && _investors[user]._round4 > 0) {
            vestedTokens += (4 - _investors[user]._unitsClaimed) * (_investors[user]._round4 / 4);
        }
        if(_investors[user]._unitsClaimed < 8 && _investors[user]._round3 > 0) {
            vestedTokens += (8 - _investors[user]._unitsClaimed) * (_investors[user]._round3 / 8);
        }
        if(_investors[user]._unitsClaimed < 16 && _investors[user]._round2 > 0) {
            vestedTokens += (16 - _investors[user]._unitsClaimed) * (_investors[user]._round2 / 16);
        }
        if(_investors[user]._unitsClaimed < 32 && _investors[user]._round1 > 0) {
            vestedTokens += (32 - _investors[user]._unitsClaimed) * (_investors[user]._round1 / 32);
        }
        return vestedTokens;

    }

    // View function for unlocked tokens and current claim unit
    function claimable(address user) public view returns(uint256) {
        if(block.timestamp < _presaleEndDate) {
            return 0;
        }
        uint256 ableToBeClaimed = 0;
        uint256 claimUnits = (block.timestamp - _presaleEndDate) / 4 weeks;
        uint256 unitsClaimed = _investors[user]._unitsClaimed;
        uint256 monthsToClaim;

        //  This operator works like -> (condition) ? (if true x): (else y)
        // Logic for round 4, $1.20 each, 1/4 total round purchase released each month
        if(unitsClaimed < 4){
            monthsToClaim = (claimUnits > 4) ? (4 - unitsClaimed) : (claimUnits - unitsClaimed);
            ableToBeClaimed += ((_investors[user]._round4) / 4) * monthsToClaim;
        }

        // Logic for round 3, $0.90 each, 1/8 total round purchase released each month 
        if(unitsClaimed < 8){
            monthsToClaim = (claimUnits > 8) ? (8 - unitsClaimed) : (claimUnits - unitsClaimed);
            ableToBeClaimed += ((_investors[user]._round3) / 8) * monthsToClaim;
        }

        // Logic for round 2, $0.60 each, 1/12 total round purchase released each month
        if(unitsClaimed < 16){
            monthsToClaim = (claimUnits > 16) ? (16 - unitsClaimed) : (claimUnits - unitsClaimed);
            ableToBeClaimed += ((_investors[user]._round2) / 16) * monthsToClaim;
        }

        // Logic for round 1, $0.30 each, 1/16 total round purchase released each month
        if(unitsClaimed < 32){
            monthsToClaim = (claimUnits > 32) ? (32 - unitsClaimed) : (claimUnits - unitsClaimed);
            ableToBeClaimed += ((_investors[user]._round1) / 32) * monthsToClaim;
        }       

        return ableToBeClaimed;

    }
    
    // Function to claim vested tokens purchased in presale and for Blaq treasury
    function claim() external {
        require(!_isInPresale && _currentRound == 5, "Vesting has not begun.");
        uint256 claimableTokens = claimable(msg.sender);
        require(claimableTokens > 0, "You have no tokens to claim at this point.");

        uint256 claimUnits = (block.timestamp - _presaleEndDate) / 4 weeks;
        _investors[msg.sender]._unitsClaimed = (claimUnits < 32) ? claimUnits : 32;
        
        _blaq.transfer(msg.sender, claimableTokens);
    
    }

}