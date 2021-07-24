/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Arkum is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public devTaxWallet = payable(0xEA640b5b5eD84B0439ee7c7D3a1F4bdacb6B74f3);
    address payable public marketingTaxWallet = payable(0xf4C20Ed84C922125a0716ACbB0694B292daC6306);
    address payable public buybackWallet = payable(0x2913e2BeEAf1Fbb69C20d30b4477c8B1e9E8EC93);
    address payable public bitcoinPoolWallet = payable(0x7434e44dE4f8da63dc135B1cE404df8bc2911F01);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private _totSupply = 1000000000 * 10**6 * 10**9;

    string private _name = "Arkum";
    string private _symbol = "ARKUM";
    uint8 private _decimals = 9;

    uint256 public _devFee = 1;
    uint256 private _previousDevFee = _devFee;
    uint256 public _marketingTaxFee = 2;
    uint256 private _previousMarketingTaxFee = _marketingTaxFee;
    uint256 public _buybackFee = 3;
    uint256 private _previousBuybackFee = _buybackFee;
    uint256 public _bitcoinPoolFee = 5;
    uint256 private _previousBitcoinPoolFee = _bitcoinPoolFee;
    uint256 public totalFees;

    uint256 public _maxTxAmount = 2000000 * 10**6 * 10**9; // 0.2%
    uint256 public _maxWalletBalance = _totSupply.mul(2).div(100); // 2%
    uint256 private minimumTokensBeforeSwap = 20000 * 10**6 * 10**9; // 0.002%

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwap;
    bool public swapEnabled = false;


    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _balances[_msgSender()] = _totSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromFee[devTaxWallet] = true;
        _isExcludedFromFee[marketingTaxWallet] = true;
        _isExcludedFromFee[buybackWallet] = true;
        _isExcludedFromFee[bitcoinPoolWallet] = true;

        updateTotalFee();

        emit Transfer(address(0), _msgSender(), _totSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && to != uniswapV2Pair) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require((_balances[to]+amount) <= _maxWalletBalance, 'Balance exceeding limit');
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        if (!inSwap && swapEnabled && overMinimumTokenBalance && to != uniswapV2Pair) {
            // We need to swap the current tokens to BNB
            swapTokensForEth(contractTokenBalance);

            uint256 contractBNBBalance = address(this).balance;
            if(contractBNBBalance > 0) {
                sendBNBToFee(address(this).balance);
            }
        }

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function sendBNBToFee(uint256 amount) private {
        transferTaxBNB(devTaxWallet, amount.div(totalFees).mul(_devFee));
        transferTaxBNB(marketingTaxWallet, amount.div(totalFees).mul(_marketingTaxFee));
        transferTaxBNB(buybackWallet, amount.div(totalFees).mul(_buybackFee));
        transferTaxBNB(bitcoinPoolWallet, address(this).balance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee){
            removeAllFee();
        }
        uint256 feeAmt = amount.mul(totalFees).div(100);
        uint256 transferAmount = amount.sub(feeAmt);

        _transferStandard(sender, recipient, transferAmount);
        _takeLiquidity(feeAmt);

        if(!takeFee){
            restoreAllFee();
        }
    }

    function _takeLiquidity(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)].add(amount);
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function removeAllFee() private {
        if(_devFee == 0 && _marketingTaxFee == 0 && _buybackFee == 0 && _bitcoinPoolFee == 0) return;

        _previousDevFee = _devFee;
        _previousMarketingTaxFee = _marketingTaxFee;
        _previousBuybackFee = _buybackFee;
        _previousBitcoinPoolFee = _bitcoinPoolFee;

        _devFee = 0;
        _marketingTaxFee = 0;
        _buybackFee = 0;
        _bitcoinPoolFee = 0;
        updateTotalFee();
    }

    function restoreAllFee() private {
        _devFee = _previousDevFee;
        _marketingTaxFee = _previousMarketingTaxFee;
        _buybackFee = _previousBuybackFee;
        _bitcoinPoolFee = _previousBitcoinPoolFee;
        updateTotalFee();
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function updateTotalFee() internal {
        totalFees = _devFee + _marketingTaxFee + _buybackFee + _bitcoinPoolFee;
    }

    function setDevFee(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
        updateTotalFee();
    }

    function setMarketingTaxFee(uint256 marketingTaxFee) external onlyOwner() {
        _marketingTaxFee = marketingTaxFee;
        updateTotalFee();
    }

    function setBuybackFee(uint256 buybackFee) external onlyOwner() {
        _buybackFee = buybackFee;
        updateTotalFee();
    }

    function setBitcoinPoolFee(uint256 bitcoinPoolFee) external onlyOwner() {
        _bitcoinPoolFee = bitcoinPoolFee;
        updateTotalFee();
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setDevTaxWallet(address _devTaxWallet) external onlyOwner() {
        devTaxWallet = payable(_devTaxWallet);
    }

    function setMarketingTaxWallet(address _marketingTaxWallet) external onlyOwner() {
        marketingTaxWallet = payable(_marketingTaxWallet);
    }

     function setBuybackWallet(address _buybackWallet) external onlyOwner() {
        buybackWallet = payable(_buybackWallet);
    }

     function setBitcoinPoolWallet(address _bitcoinPoolWallet) external onlyOwner() {
        bitcoinPoolWallet = payable(_bitcoinPoolWallet);
    }

    function setMaxWalletBalance(uint256 amount) external onlyOwner() {
        _maxWalletBalance = amount;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner() {
        swapEnabled = _enabled;
    }

    function transferTaxBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}