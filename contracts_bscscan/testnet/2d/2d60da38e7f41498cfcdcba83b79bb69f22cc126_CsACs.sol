/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
pragma solidity >=0.6.2;
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol
pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol
pragma solidity >=0.5.0;
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol
pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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

// File: Contract.sol
pragma solidity ^0.8.0;
contract DividendDistributor is Ownable {
    struct Share {
        uint256 amount;
        mapping(address => uint256) totalReleased;
    }

    address router02 = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IUniswapV2Router02 private _UniswapV2Router02;

    // TOKENS
    IERC20 tokenToDiv = IERC20(0x8a9424745056Eb399FD19a0EC26A14316684e274);

    // adresses and indexes for distribution
    address[] private _payees;
    uint256 private _totalShares;
    mapping (address => Share) private _shares;
    mapping (address => uint256) private _payeesClaims;
    mapping (address => uint256) private _payeesIndexes;
    mapping(address => uint256) private _ierc20TotalReleased;

    // current index for distribution
    uint256 private _currentIndex;

    // distribution period
    uint256 private _minPeriod = 0;
    uint256 private _minDistribution = 0;
    bool private _distributeEnabled = false;
    bool private _depositEnabled = false;

    address private _masterContract;
    modifier onlyMasterContract() {
        require(_msgSender() == _masterContract); _;
    }

    constructor () {
        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _ierc20TotalReleased[address(tokenToDiv)] = 0;
        _masterContract = _msgSender();
    }

    function updateShare(address account, uint256 amount) external onlyMasterContract {
        //if(_shares[account].amount > 0){
        //    release(account);
        //}

        if(amount > 0 && _shares[account].amount == 0){
            _addPayee(account);
        } else if(amount == 0 && _shares[account].amount > 0){
            _removePayee(account);
        }

        _totalShares = _totalShares - _shares[account].amount + amount;
        _shares[account].amount = amount;
    }

    function distribute(uint256 gas) external onlyMasterContract {
        if (!_distributeEnabled) { return; }
        uint256 shareholderCount = _payees.length;
        if(shareholderCount < 3) { return; }

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(_currentIndex >= shareholderCount){
                _currentIndex = 0;
            }

            if(_shouldDistribute(_payees[_currentIndex])){
                release(_payees[_currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
    }

    function release(address account) internal {
        if(_shares[account].amount == 0){ return; }

        uint256 amount = pendingPayment(account);
        if(amount > 0){
            _ierc20TotalReleased[address(tokenToDiv)] =_ierc20TotalReleased[address(tokenToDiv)] + amount;
            tokenToDiv.transfer(account, amount);
            _payeesClaims[account] = block.timestamp;
            _shares[account].totalReleased[address(tokenToDiv)] = _shares[account].totalReleased[address(tokenToDiv)] + amount;
        }
    }

    function deposit() public payable onlyMasterContract {
        if (!_depositEnabled) { return; }
        address[] memory path = new address[](2);
        path[0] = _UniswapV2Router02.WETH();
        path[1] = address(tokenToDiv);

        uint256 toSwap = address(this).balance;

        _UniswapV2Router02.swapExactETHForTokensSupportingFeeOnTransferTokens{value: toSwap}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function pendingPayment(address account) public view returns (uint256) {
        require(_shares[account].amount > 0, "Share holder not found");
        uint256 totalReceived = tokenToDiv.balanceOf(address(this)) + _ierc20TotalReleased[address(tokenToDiv)];
        return (totalReceived * _shares[account].amount) / _totalShares - _shares[account].totalReleased[address(tokenToDiv)];
    }

    function _addPayee(address account) internal {
        _payeesIndexes[account] = _payees.length;
        _payees.push(account);
    }

    function _removePayee(address account) internal {
        _payees[_payeesIndexes[account]] = _payees[_payees.length-1];
        _payeesIndexes[_payees[_payees.length-1]] = _payeesIndexes[account];
        _payees.pop();
    }

    function _shouldDistribute(address account) internal view returns (bool) {
        return _payeesClaims[account] + _minPeriod < block.timestamp
            && pendingPayment(account) > _minDistribution;
    }

    // getters
    function getTotalRealeasedByToken(address token) external view onlyOwner returns(uint256) {
        return _ierc20TotalReleased[token];
    }

    function getMasterContract() external view onlyOwner returns(address) {
        return _masterContract;
    }

    // setters
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external onlyOwner {
        _minPeriod = minPeriod;
        _minDistribution = minDistribution;
    }

    function setNewTokenToDiv(address token) external onlyOwner  {
        tokenToDiv = IERC20(token);
        _ierc20TotalReleased[address(tokenToDiv)] = 0;
    }

    function setRouter(address _router02) external onlyOwner {
        router02 = _router02;
        _UniswapV2Router02 = IUniswapV2Router02(router02);
    }

    function setDistributeEnabled(bool enabled) external onlyOwner  {
        _distributeEnabled = enabled;
    }

    function setDepositEnabled(bool enabled) external onlyOwner  {
        _depositEnabled = enabled;
    }

    // send and receive token  
    function withdrawBNB(uint256 amount) external onlyOwner{
        payable(_msgSender()).transfer(amount);
    }

    function withdrawToken(address tokenAddress, address to, uint256 value) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= value, "HFT: Insufficient token balance");

        try IERC20(tokenAddress).transfer(to, value) {} catch {
            revert("HFT: Transfer failed");
        }
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }
}

pragma solidity ^0.8.0;
contract CsACs is IERC20, IERC20Metadata, Context, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Name, symbol and decimals
    string private _name = "CsACsv8";
    string private _symbol = "CsACsv8";
    uint8 private _decimals = 18;

    // Total supply
    uint256 private _totalSupply = 10000000 * (10 ** _decimals); // 10m

    // Fee variables
    uint256 private _buyDevFee = 5; // 5%
    uint256 private _buyDividendFee = 5; // 5%
    uint256 private _buyTotalFee = 10; // 10%
    uint256 private _sellDevFee = 2; // 5%
    uint256 private _sellDividendFee = 2; // 5%
    uint256 private _sellTotalFee = 4; // 10%
    uint256 private _feeDenominator = 100;

    // Fee receivers
    address _devFeeReceiver = 0xca770C8a4fFa9e20c00B52B622a62C962B0d1046;

    // Fee exempt
    mapping (address => bool) private _isFeeExempt;
    mapping (address => bool) private _isDividendExempt;

    DividendDistributor distributor;
    uint256 private _distributorGas = 3000000;

    // Sell amount of tokens when a sell takes place
    uint256 private _swapThreshold = _totalSupply * 10 / 10000; // 0.1% of supply
    bool private _swapEnabled = false;
    bool private _inSwap;
    modifier swapping() { _inSwap = true; _; _inSwap = false; }


    // mainnet
    // 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address router02 = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IUniswapV2Router02 private _UniswapV2Router02;
    IUniswapV2Factory private _UniswapV2Factory;
    IUniswapV2Pair private _UniswapV2Pair;

    constructor () {
        distributor = new DividendDistributor();

        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));

        _isFeeExempt[_msgSender()] = true;
        _isFeeExempt[_devFeeReceiver] = true;
        _isFeeExempt[address(this)] = true;

        _isDividendExempt[_msgSender()] = true;
        _isDividendExempt[_devFeeReceiver] = true;
        _isDividendExempt[address(this)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // Main transfer method
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
        bool isSell = recipient == address(_UniswapV2Pair);

        uint256 recipientAmount = _shouldTakeFee(sender) ? _takeFee(sender, amount, isSell) : amount;
        if(_inSwap){ return _basicTransfer(sender, recipient, amount, recipientAmount); }

        _basicTransfer(sender, recipient, amount, recipientAmount);

        // Dividend tracker
        if(!_isDividendExempt[sender]) {
            distributor.updateShare(sender, balanceOf(sender));
        }

        if(!_isDividendExempt[recipient]) {
            distributor.updateShare(recipient, balanceOf(recipient));
        }

        // Check if we should do the swapback
        if(_shouldSwapBack()){ _swapBack(); }

        try distributor.distribute(_distributorGas) {} catch {}
    }

    // Do a normal transfer
    function _basicTransfer(address sender, address recipient, uint256 senderAmount, uint256 recipientAmount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= senderAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - senderAmount;
        }
        _balances[recipient] += recipientAmount;
        emit Transfer(sender, recipient, recipientAmount);
    }

    // Check if sender is not feeExempt
    function _shouldTakeFee(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }

    function _takeFee (address sender, uint256 amount, bool isSell) internal returns (uint256){
        uint256 feeAmount;
        uint256 devFeeAmount;
        uint256 dividendFeeAmount;
        if(isSell) {
            feeAmount = (amount * _sellTotalFee * 10**18) / (_feeDenominator * 10**18);
            devFeeAmount = (amount * _sellDevFee * 10**18) / (_feeDenominator * 10**18);
            dividendFeeAmount = (amount * _sellDividendFee * 10**18) / (_feeDenominator * 10**18);
        } else {
            feeAmount = (amount * _buyTotalFee * 10**18) / (_feeDenominator * 10**18);
            devFeeAmount = (amount * _buyDevFee * 10**18) / (_feeDenominator * 10**18);
            dividendFeeAmount = (amount * _buyDividendFee * 10**18) / (_feeDenominator * 10**18);
        }

        _balances[_devFeeReceiver] += devFeeAmount;
        distributor.updateShare(_devFeeReceiver, balanceOf(_devFeeReceiver));
        emit Transfer(sender, _devFeeReceiver, devFeeAmount);

        _balances[address(this)] += dividendFeeAmount;
        emit Transfer(sender, address(this), dividendFeeAmount);

        return amount - feeAmount;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _shouldSwapBack() internal view returns (bool) {
        return !_inSwap
        && _msgSender() != address(_UniswapV2Pair)
        && _swapEnabled
        && _balances[address(this)] >= _swapThreshold;
    }

    function _swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapV2Router02.WETH();

        uint256 toSwap = _balances[address(this)];
        _approve(address(this), address(_UniswapV2Router02), toSwap);
        
        _UniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwap,
            0,
            path,
            address(distributor),
            block.timestamp
        );

        try distributor.deposit() {} catch {}
    }

    // getters
    function getDistributorAddress(bool see) external view onlyOwner returns(address) {
        if(see) {
            return address(distributor);
        } else {
            return address(distributor);
        }
    }

    function getTotalRealeasedByToken(address token) external view onlyOwner returns(uint256) {
        return distributor.getTotalRealeasedByToken(token);
    }

    function getSwapThreshold() external view onlyOwner returns(uint256) {
        uint256 threshold = _swapThreshold;
        return threshold;
    }

    function getMasterContract() external view onlyOwner returns(address) {
        return distributor.getMasterContract();
    }

    // setters
    function setIsDividendExempt(address account, bool exempt) external onlyOwner {
        // require(account != address(this) && account != pair);
        _isDividendExempt[account] = exempt;
        if(exempt){
            distributor.updateShare(account, 0);
        }else{
            distributor.updateShare(account, _balances[account]);
        }
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        _swapEnabled = enabled;
    }

    function setSwapThreshold(uint256 dividend, uint256 divider) external onlyOwner {
        require(divider > 0, "Divider must be not zero" );
        require(dividend < divider, "Cannot set more than 100%" );
        _swapThreshold = _totalSupply * dividend / divider;
    }

    function setBuyFees(uint256 devFee, uint256 dividendFee, uint256 totalFee) external onlyOwner {
        _buyDevFee = devFee;
        _buyDividendFee = dividendFee;
        _buyTotalFee = totalFee;
    }

    function seSellFees(uint256 devFee, uint256 dividendFee, uint256 totalFee) external onlyOwner {
        _sellDevFee = devFee;
        _sellDividendFee = dividendFee;
        _sellTotalFee = totalFee;
    }

    function setDevFeeReceiver(address devFeeReceiver) external onlyOwner {
        _devFeeReceiver = devFeeReceiver;
    }

    function setRouter(address _router02) external onlyOwner {
        router02 = _router02;
        
        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));

        distributor.setRouter(_router02);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setNewTokenToDiv(address token) external onlyOwner {
        distributor.setNewTokenToDiv(token);
    }

    function setDistributeEnabled(bool enabled) external onlyOwner  {
        distributor.setDistributeEnabled(enabled);
    }

    function setDepositEnabled(bool enabled) external onlyOwner  {
        distributor.setDepositEnabled(enabled);
    }

    // manual triggers
    function triggeringManualSwapBack() external onlyOwner {
        _swapBack();
    }

    function triggeringManualDistribute() external onlyOwner {
        distributor.distribute(_distributorGas);
    }
    
    function triggeringManualDeposit() external onlyOwner {
        distributor.deposit();
    }

    // send and receive token  
    function withdrawBNB(uint256 amount) external onlyOwner{
        payable(_msgSender()).transfer(amount);
    }

    function withdrawToken(address tokenAddress, address to, uint256 value) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= value, "HFT: Insufficient token balance");

        try IERC20(tokenAddress).transfer(to, value) {} catch {
            revert("HFT: Transfer failed");
        }
    }
  
    function withdrawBNBFromDistributor(uint256 amount) external onlyOwner{
        distributor.withdrawBNB(amount);
    }

    function withdrawTokenFromDistributor(address tokenAddress, address to, uint256 value) external onlyOwner {
        distributor.withdrawToken(tokenAddress, to, value);
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    // temporary
    function getPendingPayment(address account) external view onlyOwner returns(uint256) {
        return distributor.pendingPayment(account);
    }
}