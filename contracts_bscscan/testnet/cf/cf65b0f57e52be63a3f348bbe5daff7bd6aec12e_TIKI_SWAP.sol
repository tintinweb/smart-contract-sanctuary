/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**
 *
 *  SWAP:
 *  EverTiki -> dexIRA
 *
 */

// SPDX-License-Identifier: MIT

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!
pragma solidity 0.6.12;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

interface IERC20 {
     event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract ERC20 is  IERC20 {
    using SafeMathInt for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual  returns (string memory) {
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
        return _decimals;
        // return 18; // @note Update to 18 decimals (disabled)
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
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - (subtractedValue));
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

        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);
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

        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + (amount);
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

        _balances[account] = _balances[account]- (amount);
        _totalSupply = _totalSupply - (amount);
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
    ) public virtual {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
    external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token,uint256 amountTokenDesired,uint256 amountTokenMin,uint256 amountETHMin,address to,uint256 deadline)
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline)
    external returns (uint amountA, uint amountB);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
    external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s)
    external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
    external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract TIKI_SWAP {

    bool public saleActive;
    // IERC20 _fTikToken;
    ERC20 erc20;
    IUniswapV2Router01 rout;

    address public _fTikToken;
    address public _newTikToken;

    address public owner;
    mapping(address => bool) whitelist;
    mapping(address => bool) adminAddress;

    uint256 public exchangedTokens;
    uint256 public price;

    event details(address token, address to, uint256 amountRecieved);
    event Whitelist(address indexed userAddress, bool Status);
    event bnbExchange(address userAddress, address, uint256);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"TIKI TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }

    constructor( address _V1, address _V2, uint256 _priceToSwap) public {
        owner =  _msgSender();
        saleActive = true;
        _fTikToken = _V1;
        _newTikToken = _V2;
        price = _priceToSwap;
        // rout = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E); // LIVE PC v2
        // rout = IUniswapV2Router01(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // TESTNET 0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44
        rout = IUniswapV2Router01(0x00749e00Af4359Df5e8C156aF6dfbDf30dD53F44); // rigelProtocol
        adminAddress[msg.sender] = true;
        whitelist[msg.sender] = true;
        saleActive = true;
        emit Whitelist(msg.sender, true);
    }

    // Change the token price
    // Note: Set the price respectively considering the decimals of busd
    // Example: If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).

    modifier onlyAdmin() {
        require(adminAddress[msg.sender]);
        _;
    }
    
    receive() external payable {

    }

    function updateWhitelist(address _account) onlyAdmin external {
        whitelist[_account] = true;
    }

    function exchangeTik(uint256 _tokenAmount) public {
        // uint256 getV1Cost = _tokenAmount * (IERC20(_fTikToken).decimals());
        uint256 getV2Cost = _tokenAmount / 10e18 * 10e9;

        if (whitelist[msg.sender] = true) {
            require(saleActive == true, "TIKI: SALE HAS ENDED.");
            require(_tokenAmount >= 0, "TIKI: BUY ATLEAST 1 TOKEN.");
            
            require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");
            require(IERC20(_newTikToken).transfer(_msgSender(), getV2Cost), "TIKI: CONTRACT DOES NOT HAVE ENOUGH TOKENS.");

            exchangedTokens += _tokenAmount;
        } else {
            require(saleActive == true, "TIKI: SALE HAS ENDED.");
            require(_tokenAmount >= 0, "TIKI: BUY ATLEAST 1 TOKEN.");

            uint256 cost = getV2Cost * price;

            require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");
            require(IERC20(_newTikToken).transfer(_msgSender(), cost), "TIKI: CONTRACT DOES NOT HAVE ENOUGH TOKENS.");
        }

        emit details(_newTikToken, _msgSender(), _tokenAmount);
    }

    function exchangeV1ToBNB( uint256 _tokenAmount) public onlyOwner {
        require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");

        payable(_msgSender()).transfer(_tokenAmount);
        address(this).balance - _tokenAmount;
        emit bnbExchange(_msgSender(), address(this), _tokenAmount);
    }

    // function ret() public payable {
    // }

    function ball() public view returns(uint256) {
        return (address(this).balance);
    }

    function balTik() public view returns(uint256 _TikToken) {
        _TikToken = IERC20(_fTikToken).balanceOf(address(this));
        return _TikToken;
    }
    
    function getAmountOutpust(uint256 _amount) public view returns(uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = _fTikToken;
        path[1] = rout.WETH();
        return rout.getAmountsOut(_amount, path);
    }
    
    function swapTokensForEth(uint256 tokenAmount) public onlyOwner {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _fTikToken;
        path[1] = rout.WETH();

        ERC20(_fTikToken)._approve( address(this), address(rout), tokenAmount);

        // Make the swap
        rout.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 20 minutes
        );
    }

    function addLiquidity()  onlyOwner public returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        uint256 contractBalanceFtoken = IERC20(_fTikToken).balanceOf(address(this));
        uint256 contractBalanceNtoken = IERC20(_newTikToken).balanceOf(address(this));

        IERC20(_fTikToken).approve(address(rout), contractBalanceFtoken);
        IERC20(_newTikToken).approve(address(rout), contractBalanceNtoken);

        require(contractBalanceNtoken >= contractBalanceFtoken, "you are trying to reduce the current market price");

        // function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
        rout.addLiquidity(_newTikToken,_fTikToken,contractBalanceNtoken,contractBalanceFtoken,0,0, _newTikToken,block.timestamp + 10 minutes);

        return (amountToken,amountETH,liquidity);
    }

    function addLiquidityETH(uint256 _amount)  onlyOwner public returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        uint256 contractBalanceFtoken = IERC20(_fTikToken).balanceOf(address(this));
        uint256 contractBalanceNtoken = IERC20(_newTikToken).balanceOf(address(this));

        IERC20(_fTikToken).approve(address(rout), contractBalanceFtoken);
        IERC20(_newTikToken).approve(address(rout), contractBalanceNtoken);

        require(contractBalanceNtoken >= contractBalanceFtoken, "you are trying to reduce the current market price");

        // function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
        // {value:totalContributions.div(2)}(address(token),TOKENS_FOR_LP,1,1,address(this),block.timestamp + 10 minutes);
        rout.addLiquidityETH{value:_amount}(address(_newTikToken),contractBalanceNtoken,1,1,address(this),block.timestamp + 10 minutes);

        return (amountToken,amountETH,liquidity);
    }

    function changeRouterContract(address _newRout) onlyOwner public {
        rout = IUniswapV2Router01(_newRout);
    }

    // End the sale, don't allow any purchases anymore and send remaining rgp to the owner
    function disableSale() external onlyOwner{

        // End the sale
        saleActive = false;

        // Send unsold tokens and remaining busd to the owner. Only ends the sale when both calls are successful
        IERC20(_newTikToken).transfer(owner, IERC20(_newTikToken).balanceOf(address(this)));
    }

    function setPriceForUnWhitelistedAddress(uint256 _priceToSwap) public onlyOwner{
        price = _priceToSwap;
    }

    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress[_adminAddress]=true;
    }

    function removeAdmin(address _adminAddress) public onlyOwner {
        delete(adminAddress[_adminAddress]);
    }

    // Start the sale again - can be called anytime again
    // To enable the sale, send RGP tokens to this contract
    function enableSale() external onlyOwner{

        // Enable the sale
        saleActive = true;

        // Check if the contract has any tokens to sell or cancel the enable
        require(IERC20(_newTikToken).balanceOf(address(this)) >= 1, "TIKI: CONTRACT DOES NOT HAVE TOKENS TO SELL.");
    }

    // Withdraw (accidentally) to the contract sent eth
    function withdrawBNB() external payable onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Withdraw (accidentally) to the contract sent ERC20 tokens
    function withdrawNewTiki(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));

        IERC20(_token).transfer(owner, _tokenBalance);
    }
}