/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

abstract contract Context {
    function messageSender() internal view virtual returns (address) {
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
        address msgSender = messageSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == messageSender(), "Ownable: caller is not the owner");
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

contract Pedigree is Context, IERC20, Ownable {
    using SafeMath for uint256;
    //Token attributes
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant tokens = 10000000000000 * 10**9;
    uint256 private reflectionsTotal = (MAX - (MAX % tokens));
    string private constant _name = "OURTESTv7.2.0";
    string private constant _symbol = "ORTv7.2.0";
    uint8 private constant _decimals = 9;
    
    uint256 public collectedReflexFee;
    uint256 public collectedTeamFee;
    //Fees for transactions
    uint256 private reflexFee = 1;
    uint256 private teamFee = 4;
    uint256 private liquidityFee = 5;
    //Fee wallet
    address payable private feeWallet1;
    
    mapping (address => uint256) private reflectionOwners;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => bool) private feeExemption;
    mapping (address => uint) private cooldown;
   
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

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
        emit Transfer(address(0), address(this), tokens);
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
        _transfer(messageSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(messageSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, messageSender(), allowances[sender][messageSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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

    function transferMoreThanOwnership(address account, uint256 amount) private view returns (bool) {
        uint256 totalTokensFromTotalReflection = tokenFromReflection(reflectionsTotal);
        uint256 totalTokensOwned = balanceOf(account);
        uint256 additionalRateAllowed = getLPRate(account);
        
        if(calculateTokenOwnership(totalTokensOwned, totalTokensFromTotalReflection, amount) <= 150 + additionalRateAllowed){
            return false;
        }
        return true;
    }
    
    function getBuySellFees(address from, address to) private view returns(uint256, uint256) {
        if(!tradingOpen || feeExemption[from] || feeExemption[to]) {
            return (0, 0);
        }
        
        if(from == uniswapV2Pair) {
            return (reflexFee, teamFee);
        }
        
        if(to == uniswapV2Pair) {
            return (reflexFee, teamFee + liquidityFee);
        }
        
        return (0, 0);
    }
    
    function calculateTokenOwnership(uint256 totalTokensOwned, uint256 totalTokensFromTotalReflection, uint256 amount) private pure returns (uint256) {
        return amount.add(totalTokensOwned).mul(10000).div(totalTokensFromTotalReflection);
    }
    
    function checkLPBalance(address sender) public view returns (uint256){
        return IERC20(uniswapV2Pair).balanceOf(sender);
    }
    
    function getPairLPBalance() private view returns (uint256){
        return IERC20(uniswapV2Pair).totalSupply();
    }
    
    function getLPRate(address sender) private view returns (uint256){
        uint256 totalPoolTokens = getPairLPBalance();
        uint256 callerPoolTokens = checkLPBalance(sender);
        return callerPoolTokens.mul(10000).div(totalPoolTokens);
    }
    
    function transferERC20(IERC20 tokenContract, address to, uint256 amount) public {
        require(messageSender() == feeWallet1 || messageSender() == owner(), "Only fee owner can withdraw funds"); 
        uint256 erc20balance = tokenContract.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        tokenContract.transfer(to, amount);
        emit Transfer(msg.sender, to, amount);
    }
    
    function balanceOfERC20(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function setTeamFee(uint256 feePercentage) public {
        require(feePercentage <= teamFee, "New fee cannot be higher than the previous fee");
        require(messageSender() == feeWallet1, "Only fee wallet can call this function");
        teamFee = feePercentage;
    }
    
    function setLiquidityFee(uint256 feePercentage) public {
        require(feePercentage <= liquidityFee, "New fee cannot be higher than the previous fee");
        require(messageSender() == feeWallet1, "Only fee wallet can call this function");
        liquidityFee = feePercentage;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!feeExemption[from] && !feeExemption[to] && from == uniswapV2Pair && to != address(uniswapV2Router) && cooldownEnabled) {
            require(cooldown[to] < block.number);
            //2 block number cooldown aka ~ 30 seconds
            cooldown[to] = block.number + 2;
        }
        
        //Wallet to wallet transfer restriction
        if(swapEnabled && from != uniswapV2Pair && to != uniswapV2Pair && from != address(uniswapV2Router) && !feeExemption[to]) {
            require(!transferMoreThanOwnership(to, amount), "Address owns or will own more than 1,5% + pool_ownership of the token supply");
        }
        
        //Swapping eth for token restriction
        if(swapEnabled && from == uniswapV2Pair && !feeExemption[to]) {
            require(!transferMoreThanOwnership(to, amount), "Address owns or will own more than 1,5% + pool_ownership of the token supply");
        }
	    
        transferTokensSupportingFees(from, to, amount);
        
    }
    
     //UniSwap transaction with fees
    function transferTokensSupportingFees(address sender, address recipient, uint256 tAmount) private {
        (uint256 _reflexFee, uint256 _totalTeamFee) = getBuySellFees(sender, recipient);
        uint256 sumFees = _reflexFee + _totalTeamFee;
        
        (uint256 rAmount, uint256 rTransferAmount) = _getAllValues(tAmount, sumFees);
        reflectionOwners[sender] = reflectionOwners[sender].sub(rAmount);
        reflectionOwners[recipient] = reflectionOwners[recipient].add(rTransferAmount); 
        applyReflectionFee(rAmount, _reflexFee);
        applyTotalFees(rAmount, _totalTeamFee);
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
        uniswapV2Router.addLiquidityETH { 
            value: address(this).balance 
        }
        (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        feeExemption[address(uniswapV2Router)] = true;
    }

     /* ------- Fee Setup --------   */
    function applyTotalFees(uint256 rAmount, uint256 rSumFees) private {
        uint256 collectedFee = rAmount.mul(rSumFees).div(100);
        uint256 collectedFeeTokens = tokenFromReflection(collectedFee);
        reflectionOwners[address(this)] = reflectionOwners[address(this)].add(collectedFee);
        collectedTeamFee = collectedTeamFee.add(collectedFeeTokens);
    }
    

    function applyReflectionFee(uint256 rAmount, uint256 rReflexFee) private {
        uint256 collectedFee = rAmount.mul(rReflexFee).div(100);
        uint256 collectedFeeTokens = tokenFromReflection(collectedFee);
        reflectionsTotal = reflectionsTotal.sub(collectedFee);
        collectedReflexFee =  collectedReflexFee.add(collectedFeeTokens);
    }
    /* ------- Fee Setup END --------   */

    receive() external payable {}
    
    function manualswap(uint256 amount) external {
        require(messageSender() == feeWallet1);
        require(amount <= balanceOf(address(this)));
        uint256 contractBalance = amount;
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(messageSender() == feeWallet1);
        uint256 contractETHBalance = address(this).balance;
        sendFee(contractETHBalance);
    }
    
    /* ------- Token, reflection, fees and rate amount calculations  --------   */
    function _getAllValues(uint256 tAmount, uint256 fees) private view returns (uint256, uint256) {
        uint256 tTransferAmount = _getTokenValues(tAmount, fees);
        uint256 currentRate = getSupplyRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getReflectionValues(tAmount, tTransferAmount, currentRate);
        return (rAmount, rTransferAmount);
    }

    function _getTokenValues(uint256 tAmount, uint256 fees) private pure returns (uint256) {
        uint256 tFees = tAmount.mul(fees).div(100);
        uint256 tTransferAmount = tAmount - tFees;
        return tTransferAmount;
    }

    function _getReflectionValues(uint256 tAmount, uint256 tTransferAmount, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        return (rAmount, rTransferAmount);
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
    /* ------- Token, reflection, fees and rate amount calculations END --------   */
}