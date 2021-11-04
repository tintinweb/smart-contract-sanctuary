/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IPancakeV2Router01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}

interface IPancakeV2Router02 is IPancakeV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


contract Ownable {
    address public _owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

    // Protocol by BloctechSolutions.com

contract SPIN_ADA_Token is BEP20, Ownable {
    using SafeMath for uint256;

    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    uint256 public fee1stPhaseBuyMarketing     = 3;
    uint256 public fee1stPhaseBuyDevelopment   = 2;
    uint256 public fee1stPhaseBuyStaking       = 0;
    uint256 public fee1stPhaseSellMarketing     = 4;
    uint256 public fee1stPhaseSellDevelopment   = 3;
    uint256 public fee1stPhaseSellStaking       = 0;

    uint256 public fee2ndPhaseBuyMarketing     = 2;
    uint256 public fee2ndPhaseBuyDevelopment   = 1;
    uint256 public fee2ndPhaseBuyStaking       = 2;
    uint256 public fee2ndPhaseSellMarketing     = 2;
    uint256 public fee2ndPhaseSellDevelopment   = 2;
    uint256 public fee2ndPhaseSellStaking       = 3;

    uint256 public fee3rdPhaseBuyMarketing     = 1;
    uint256 public fee3rdPhaseBuyDevelopment   = 0;
    uint256 public fee3rdPhaseBuyStaking       = 4;
    uint256 public fee3rdPhaseSellMarketing     = 1;
    uint256 public fee3rdPhaseSellDevelopment   = 0;
    uint256 public fee3rdPhaseSellStaking       = 6;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    uint256 public _totalSupply = 100000000 * (10**18);

    address public walletMarketing;
    address public walletDevelopment;
    address public walletStakingReward;

    uint256 public launchTime;
    
    bool inSwapAndLiquify;   
    bool public swapAndLiquifyEnabled; 
    uint256 private numTokensSellToMarketingAndDevelopment = 10000 * 10**18;
    uint256 accumulatedForMarketing;
    uint256 accumulatedForDev;
    uint256 accumulatedForStake;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () BEP20("SPINADA", "SPIN") {
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancake Mainnet
        //IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Pancake Testnet
        // Create a pancake pair for this new token
        address _pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());

        pancakeV2Router = _pancakeV2Router;
        pancakeV2Pair = _pancakeV2Pair;

        // exclude from paying fees
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;

        walletMarketing = owner();
        walletDevelopment = owner();
        walletStakingReward = owner();

        _mint(owner(), _totalSupply);

    }

    receive() external payable {}

    function setWalletMarketing(address wallet) external onlyOwner() {
        require(wallet != address(0), "Marketing wallet can't be the zero address");
        walletMarketing = wallet;
    }

    function setWalletDevelopment(address wallet) external onlyOwner() {
        require(wallet != address(0), "Development wallet can't be the zero address");
        walletDevelopment = wallet;
    }

    function setWalletStakingReward(address wallet) external onlyOwner() {
        require(wallet != address(0), "Staking wallet can't be the zero address");
        walletStakingReward = wallet;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function includeOrExcludeFromFee(address account, bool value) public onlyOwner {
        _isExcludedFromFees[account] = value;
    }

    function updateSwapLimit(uint256 value) public onlyOwner {
        numTokensSellToMarketingAndDevelopment = value;
    }

    function updateSwapAndLiquifyEnabled(bool value) public onlyOwner {
        swapAndLiquifyEnabled = value;
    }

    function update1stPhaseTax(uint256 buyMarketingFee, uint256 buyDevelopmentFee, uint256 buyStakingRewardFee,
        uint256 sellMarketingFee, uint256 sellDevelopmentFee, uint256 sellStakingRewardFee) public onlyOwner {
        require(buyMarketingFee.add(buyDevelopmentFee).add(buyStakingRewardFee) <=7, "Total buying tax should less then 8%");
        require(sellMarketingFee.add(sellDevelopmentFee).add(sellStakingRewardFee) <=7, "Total selling tax should less then 8%");

        fee1stPhaseBuyMarketing     = buyMarketingFee;
        fee1stPhaseBuyDevelopment   = buyDevelopmentFee;
        fee1stPhaseBuyStaking       = buyStakingRewardFee;

        fee1stPhaseSellMarketing     = sellMarketingFee;
        fee1stPhaseSellDevelopment   = sellDevelopmentFee;
        fee1stPhaseSellStaking       = sellStakingRewardFee;
    }

    function update2ndPhaseTax(uint256 buyMarketingFee, uint256 buyDevelopmentFee, uint256 buyStakingRewardFee,
        uint256 sellMarketingFee, uint256 sellDevelopmentFee, uint256 sellStakingRewardFee) public onlyOwner {
        require(buyMarketingFee.add(buyDevelopmentFee).add(buyStakingRewardFee) <=7, "Total buying tax should less then 8%");
        require(sellMarketingFee.add(sellDevelopmentFee).add(sellStakingRewardFee) <=7, "Total selling tax should less then 8%");

        fee2ndPhaseBuyMarketing     = buyMarketingFee;
        fee2ndPhaseBuyDevelopment   = buyDevelopmentFee;
        fee2ndPhaseBuyStaking       = buyStakingRewardFee;

        fee2ndPhaseSellMarketing     = sellMarketingFee;
        fee2ndPhaseSellDevelopment   = sellDevelopmentFee;
        fee2ndPhaseSellStaking       = sellStakingRewardFee;
    }

    function update3rdPhaseTax(uint256 buyMarketingFee, uint256 buyDevelopmentFee, uint256 buyStakingRewardFee,
        uint256 sellMarketingFee, uint256 sellDevelopmentFee, uint256 sellStakingRewardFee) public onlyOwner {
        require(buyMarketingFee.add(buyDevelopmentFee).add(buyStakingRewardFee) <=7, "Total buying tax should less then 8%");
        require(sellMarketingFee.add(sellDevelopmentFee).add(sellStakingRewardFee) <=7, "Total selling tax should less then 8%");

        fee3rdPhaseBuyMarketing     = buyMarketingFee;
        fee3rdPhaseBuyDevelopment   = buyDevelopmentFee;
        fee3rdPhaseBuyStaking       = buyStakingRewardFee;

        fee3rdPhaseSellMarketing     = sellMarketingFee;
        fee3rdPhaseSellDevelopment   = sellDevelopmentFee;
        fee3rdPhaseSellStaking       = sellStakingRewardFee;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(launchTime == 0){
            require(from == owner(), "Only owner can transfer before launching");
        }
        
        uint256 swapAmount = balanceOf(address(this));
        bool overMinTokenBalance = swapAmount >= numTokensSellToMarketingAndDevelopment;
        if (
            !inSwapAndLiquify &&
            from != pancakeV2Pair &&
            overMinTokenBalance &&
            swapAndLiquifyEnabled
        ) {
            swapTokensForEth(swapAmount);
            uint256 balance = address(this).balance;
            uint256 marketingAmount = balance.mul(accumulatedForMarketing).div(swapAmount);
            uint256 stakeAmount = balance.mul(accumulatedForStake).div(swapAmount);
            uint256 devAmount = balance.sub(marketingAmount).sub(stakeAmount);

            accumulatedForMarketing = 0;
            accumulatedForStake = 0;
            accumulatedForDev = 0;

            payable(walletMarketing).transfer(marketingAmount);
            payable(walletStakingReward).transfer(stakeAmount);
            payable(walletDevelopment).transfer(devAmount);
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 feeMarketing;
            uint256 feeDevelop;
            uint256 feeStaking;

            if(block.timestamp <= launchTime.add(30 days)){
                if(to == pancakeV2Pair){ //SELLING
                    feeMarketing    = fee1stPhaseSellMarketing;
                    feeDevelop      = fee1stPhaseSellDevelopment;
                    feeStaking      = fee1stPhaseSellStaking;
                }else{
                    feeMarketing    = fee1stPhaseBuyMarketing;
                    feeDevelop      = fee1stPhaseBuyDevelopment;
                    feeStaking      = fee1stPhaseBuyStaking;
                }
            } else if(block.timestamp > launchTime.add(30 days) && block.timestamp <= launchTime.add(90 days)){
                if(to == pancakeV2Pair){ //SELLING
                    feeMarketing    = fee2ndPhaseSellMarketing;
                    feeDevelop      = fee2ndPhaseSellDevelopment;
                    feeStaking      = fee2ndPhaseSellStaking;
                }else{
                    feeMarketing    = fee2ndPhaseBuyMarketing;
                    feeDevelop      = fee2ndPhaseBuyDevelopment;
                    feeStaking      = fee2ndPhaseBuyStaking;
                }
            } else {
                if(to == pancakeV2Pair){ //SELLING
                    feeMarketing    = fee3rdPhaseSellMarketing;
                    feeDevelop      = fee3rdPhaseSellDevelopment;
                    feeStaking      = fee3rdPhaseSellStaking;
                }else{
                    feeMarketing    = fee3rdPhaseBuyMarketing;
                    feeDevelop      = fee3rdPhaseBuyDevelopment;
                    feeStaking      = fee3rdPhaseBuyStaking;
                }
            }

            uint256 feeAmountMarketing      = amount.mul(feeMarketing).div(100);
            uint256 feeAmountDevelopment    = amount.mul(feeDevelop).div(100);
            uint256 feeAmountStakingReward  = amount.mul(feeStaking).div(100);

            accumulatedForMarketing = accumulatedForMarketing.add(feeAmountMarketing);
            accumulatedForStake = accumulatedForStake.add(feeAmountStakingReward);
            accumulatedForDev = accumulatedForDev.add(feeAmountDevelopment);
            
            uint256 fee = feeAmountMarketing.add(feeAmountDevelopment).add(feeAmountStakingReward);
            super._transfer(from, address(this), fee);

            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap{
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300
        );
    }

    //Recover token
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IBEP20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }

    //Recover bnb
    function recoverBnb(uint256 _tokenAmount) external onlyOwner {
        payable(msg.sender).transfer(_tokenAmount);
    }

    //Launch, let others to trade
    function launch() external onlyOwner {
        launchTime = block.timestamp;
        swapAndLiquifyEnabled = true;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}