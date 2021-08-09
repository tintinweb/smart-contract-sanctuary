/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract CREEMM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Creemm testt";
    string private constant _symbol = "CREEMM";

    uint256 private _totalSupply;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping (address => BalanceOwner) private _balances;
    address[] private _balanceOwners;
    struct BalanceOwner {
        uint256 amount;
        bool exists;
        uint256 sellCooldown;
    }

    address private peechAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; 
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _devAddress = 0xBE47870737d075Fa019eB8813172a87D84270003;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    
    bool public tradeAllowed = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool public swapEnabled = false;
    
    uint256 private _maxTxAmount;     
    uint256 private _devFee = 6;
    uint256 private _peechBurn = 4;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _mint(msg.sender, 1000000000*10**18);
        _maxTxAmount = _totalSupply;
        _balanceOwners.push(address(this));
        _balances[address(this)].exists = true;
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
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
    function decimals() public pure returns (uint8) {
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
        return _balances[account].amount;
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
        _balances[account].amount += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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


    // This function enables or disables the 1% transfer lock
    function lockOnePercent(bool shouldLock) external onlyOwner() {
        if (shouldLock){
            _maxTxAmount = _totalSupply.mul(100).div(10000);
        }else {
            _maxTxAmount = _totalSupply;
        }
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    // This function adds liquidity for the token
    function addLiquidity() external onlyOwner() {
        // Define interface for router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Router = _uniswapV2Router;

        // Approve the router to manage the total supply
        _approve(address(this), address(uniswapV2Router), _totalSupply);

        // Create DON - WETH Pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // Add liquidity to the pool by transferring the total amount of ETH in the contract and the total amount of tokens owned by the contract address to the LP
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);

        // Enable trading
        swapEnabled = true;
        liquidityAdded = true;        
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        tradeAllowed = true;
    }

    // This function converts the current token balance of the contract address to ETH
    function manualswap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    // This function sends the current ETH balance in the contract to the dev wallet
    function manualsend() external onlyOwner() {
        (payable(_devAddress)).transfer(address(this).balance);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Get balance of sender
        uint256 senderBalance = _balances[from].amount;

        // Make sure the sender can afford the transfer
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        // If it is not the owner who is transferring
        if (from != owner() && to != owner()) {
            
            // If it is the LP that is transferring
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                // Make sure trading is enabled
                require(tradeAllowed);

                // Make sure the ratios are within the limits                
                require(amount <= _maxTxAmount);
                
            }

            // if not currently swapping tokens for ETH and the LP is not the sender
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
                // Make sure the amount is less than a third of the pair balance
                require(amount <= balanceOf(uniswapV2Pair).mul(33).div(1000));
                // Make sure the seller is not on cool down
                require(_balances[from].sellCooldown < block.timestamp);
                burnContractTokens();
                // Set new cool down of the from address
                _balances[from].sellCooldown = block.timestamp + (45 seconds);
            }
        }

        // Define fee flag
        bool takeFee = true;

        // If from or to address is excluded from fees
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            // Set flag to false
            takeFee = false;
        }

        // Run before token transfer
        _beforeTokenTransfer(from, to, amount);

        // Remove the tokens from the servers balance
        unchecked {
            _balances[from].amount = senderBalance - amount;
        }

        if (!_balances[to].exists){
            _balanceOwners.push(to);
            _balances[to].exists = true;
        }       

        uint256 toContract = 0;        

        uint256 toReceive = amount;

        // If fees should be payed
        if (takeFee){

            // Calculate one percent
            uint256 onePercent = amount.mul(100).div(10000);
            
            // Calculate fees
            toContract = onePercent * (_devFee + _peechBurn);            
            
            // Adjust tokens to send to recepient
            toReceive = (amount - toContract);
            _balances[address(this)].amount += toContract;
           
            // Emit events
            emit Transfer(from, address(this), toContract);   
        }

        // Add the tokens to recieve to the recepient
        _balances[to].amount += toReceive;
        emit Transfer(from, to, toReceive);
        _afterTokenTransfer(from, to, amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function swapETHForPeechAndBurn(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(peechAddress);

        _approve(address(this), address(uniswapV2Router), ethAmount);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(burnAddress),block.timestamp);
    }

    function setDevPercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "Dev fee percentage must be less than or equal to 100%");
        _devFee = percentage;
    }


    function burnContractTokens() private{
        uint256 contractBalance = _balances[address(this)].amount;
        if (contractBalance > 0){

            // Get current eth balance
            uint256 currentEthBalance = address(this).balance;

            swapTokensForEth(contractBalance);
            // Get new eth balance
            uint256 newEthBalance = address(this).balance;

            // Calculate delta
            uint256 ethRecievedFromSwap = newEthBalance - currentEthBalance;

            uint256 peechBurn = ethRecievedFromSwap.mul(_peechBurn * 100).div(10000);
            (payable(_devAddress)).transfer(ethRecievedFromSwap - peechBurn);

            // Burn the delta
            swapETHForPeechAndBurn(peechBurn);
        }
    }

    function setPeechBurnPercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "Dev fee percentage must be less than or equal to 100%");
        _peechBurn = percentage;
    }

    receive() external payable {}
}