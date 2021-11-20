/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

abstract contract Context {
    function senderAddress() internal view virtual returns (address) {
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

    constructor () {
        address msgSender = senderAddress();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == senderAddress(), "Ownable: caller is not the owner");
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract OURTESTV6 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private reflectionOwners;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => bool) private feeExemption;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant tokens = 10000000000000 * 10**9;
    uint256 private reflectionsTotal = (MAX - (MAX % tokens));
    uint256 public tokensFeeTotal;
    
    address payable private feeWallet1;
    
    string private constant _name = "OURTESTv6.1.6";
    string private constant _symbol = "ORTv6.1.6";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    event MaxTxAmountUpdated(uint maxTransactionAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        feeWallet1 = payable(0x38EB73ac1F91e1C966115a46b20081c53914091B);
        reflectionOwners[address(this)] = reflectionsTotal;
        feeExemption[owner()] = true;
        feeExemption[address(this)] = true;
        feeExemption[feeWallet1] = true;
        emit Transfer(address(senderAddress()), senderAddress(), tokens);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return tokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(reflectionOwners[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(senderAddress(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(senderAddress(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, senderAddress(), allowances[sender][senderAddress()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= reflectionsTotal, "Amount must be less than total reflectionOwners");
        uint256 currentRate = getSupplyRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferMoreThanOwnership(address account, uint256 amount) public view returns (bool) {
        uint256 totalTokensFromTotalReflection = tokenFromReflection(reflectionsTotal);
        uint256 totalTokensOwned = balanceOf(account);
        uint256 additionalRateAllowed = getLPRate(account);
        
        if(calculateTokenOwnership(totalTokensOwned, totalTokensFromTotalReflection, amount) <= 100 + additionalRateAllowed){
            return false;
        }
        return true;
    }
    
    function calculateTokenOwnership(uint256 totalTokensOwned, uint256 totalTokensFromTotalReflection, uint256 amount) public pure returns (uint256) {
        return amount.add(totalTokensOwned).mul(10000).div(totalTokensFromTotalReflection);
    }
    
    function checkLPBalance(address sender) public view returns (uint256){
        return IERC20(uniswapV2Pair).balanceOf(sender);
    }
    
    function getPairLPBalance() private view returns (uint256){
        return IERC20(uniswapV2Pair).totalSupply();
    }
    
    function getLPRate(address sender) public view returns (uint256){
        uint256 totalPoolTokens = getPairLPBalance();
        uint256 callerPoolTokens = checkLPBalance(sender);
        return callerPoolTokens.mul(10000).div(totalPoolTokens);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner() && from == uniswapV2Pair && to != address(uniswapV2Router) && cooldownEnabled) {
            require(cooldown[to] < block.number);
            //2 block number cooldown aka ~ 30 seconds
            cooldown[to] = block.number + 2;
        }
        
        //Wallet to wallet transfer restriction
        if(swapEnabled && from != uniswapV2Pair && from != address(uniswapV2Router) && to != address(uniswapV2Router) && to != uniswapV2Pair && to != address(this)) {
            require(!transferMoreThanOwnership(to, amount), "Address owns or will own more than 1% + pool_ownership of the token supply");
        }
        
        //Swapping eth for token restriction
        if(swapEnabled && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)) {
            require(!transferMoreThanOwnership(to, amount), "Address owns or will own more than 1% + pool_ownership of the token supply");
        }
	    
        swapTransaction(from,to,amount);
        
    }

    //Uniswap router conversion from Token to ETH
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendFee(uint256 amount) private {
        feeWallet1.transfer(amount);
    }
    
    //Start trading
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    //UniSwap transaction with fees
    function swapTransaction(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getAllValues(tAmount);
        
        if(tradingOpen && !feeExemption[recipient]) {
            reflectionOwners[sender] = reflectionOwners[sender].sub(rAmount);
            reflectionOwners[recipient] = reflectionOwners[recipient].add(rTransferAmount); 
            reflectionFee(rFee, tFee);
            teamFee(tTeam);
        }else{
            reflectionOwners[sender] = reflectionOwners[sender].sub(rAmount);
            reflectionOwners[recipient] = reflectionOwners[recipient].add(rAmount); 
        }
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /* ------- Fee Setup --------   */
    function teamFee(uint256 tTeam) private {
        uint256 currentRate = getSupplyRate();
        uint256 rTeam = tTeam.mul(currentRate);
        reflectionOwners[address(this)] = reflectionOwners[address(this)].add(rTeam);
    }

    function reflectionFee(uint256 rFee, uint256 tFee) private {
        reflectionsTotal = reflectionsTotal.sub(rFee);
        tokensFeeTotal = tokensFeeTotal.add(tFee);
    }

    /* ------- Fee Setup END --------   */

    receive() external payable {}
    
    function manualswap() external {
        require(senderAddress() == feeWallet1);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(senderAddress() == feeWallet1);
        uint256 contractETHBalance = address(this).balance;
        sendFee(contractETHBalance);
    }
    
    /* ------- Token, reflection and rate amount calculations  --------   */
    function _getAllValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTokenValues(tAmount);
        uint256 currentRate = getSupplyRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getReflectionValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTokenValues(uint256 tAmount) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(2).div(100);
        uint256 tTeam = tAmount.mul(3).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getReflectionValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function getSupplyRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = reflectionsTotal;
        uint256 tSupply = tokens;      
        if (rSupply < reflectionsTotal.div(tokens)) return (reflectionsTotal, tokens);
        return (rSupply, tSupply);
    }
    /* ------- Token, reflection and rate amount calculations END --------   */
}