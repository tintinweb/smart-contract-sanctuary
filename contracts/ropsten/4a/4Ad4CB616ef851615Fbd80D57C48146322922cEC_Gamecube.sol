// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./IPancakeswapV2Router02.sol";
import "./IPancakeswapV2Factory.sol";
import "./Ownable.sol";

contract Gamecube is IBEP20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    address public bnbPoolAddress;
    
    uint256 private constant _tTotal = 1 * 10**8 * 10**18;
    string private constant _name = "Game Cube (GCU)";
    string private constant _symbol = "GCU";
    uint8 private constant _decimals = 18;
    
    uint256 public _rewardPoolFee = 55;
    uint256 private _previousTransactionFee = _rewardPoolFee;
    
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;
    

    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    address[] public exPair;
    
    bool inSwapAndLiquify;
    bool public sendFeeToRewardLiquidityPoolEnabled = true;
    bool public presaleEnded = false;
    uint256 private numTokensToSwap =  25000 * 10**18;
    uint256 public swapCoolDownTime = 20;
    
    uint256 private lastSwapTime;

    event sendFeeToRewardLiquidityPoolEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event UpdateFees(uint256 bnbFee, uint256 liquidityFee);
    event UpdateNumtokensToSwap(uint256 amount);
    event UpdateBNBPoolAddress(address account);
    event AddExPairAddress(address pairAddress);
    event SwapAndCharged(uint256 token, uint256 liquidAmount, uint256 bnbPool,  uint256 bnbLiquidity);
    event UpdatedCoolDowntime(uint256 timeForContract);
    event UpdatedPresaleStatus(bool status);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        //Mian Net
        // IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        //testnet
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
        //     .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
        // exPair.push(pancakeswapV2Pair);

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }
    
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function setBNBPoolAddress(address account) external onlyOwner {
        require(account != bnbPoolAddress, 'This address was already used');
        bnbPoolAddress = account;
        emit UpdateBNBPoolAddress(account);
    }

    function addExPairAddress(address pairAddress) external onlyOwner {
        require(pairAddress == address(pairAddress),"Invalid address");
        exPair.push(pairAddress);
        emit AddExPairAddress(pairAddress);
    }

    function setCoolDownTime(uint256 timeForContract) external onlyOwner {
        require(swapCoolDownTime != timeForContract, "This cool down time is active already");
        swapCoolDownTime = timeForContract;
        emit UpdatedCoolDowntime(timeForContract);
    }

    function updatePresaleStatus(bool status) external onlyOwner {
        presaleEnded = status;
        emit UpdatedPresaleStatus(status);
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }
    
    function setFees(uint256 bnbFee, uint256 liquidityFee) external onlyOwner() {
        require(_rewardPoolFee != bnbFee || _liquidityFee != liquidityFee, "Same as existing fee");
        require(bnbFee + liquidityFee <= 100, "Total fee cannot be more than 10%");
        _rewardPoolFee = bnbFee;
        _liquidityFee = liquidityFee;
        emit UpdateFees(bnbFee, liquidityFee);
    }
    
    function setNumTokensToSwap(uint256 amount) external onlyOwner() {
        require(numTokensToSwap != amount);
        numTokensToSwap = amount;
        emit UpdateNumtokensToSwap(amount);
    }

    function setSendFeeToRewardLiquidityPoolEnabled(bool _enabled) external onlyOwner {
        sendFeeToRewardLiquidityPoolEnabled = _enabled;
        emit sendFeeToRewardLiquidityPoolEnabledUpdated(_enabled);
    }

     //to receive ETH from pancakeswapV2Router when swapping
    receive() external payable {}

    function _getFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = tAmount.mul(_rewardPoolFee + _liquidityFee).div(10**3);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function removeAllFee() private {
        if(_rewardPoolFee == 0 && _liquidityFee == 0) return;
        
        _previousTransactionFee = _rewardPoolFee;
        _previousLiquidityFee = _liquidityFee;
        
        _rewardPoolFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _rewardPoolFee = _previousTransactionFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (to == pancakeswapV2Pair && balanceOf(pancakeswapV2Pair) == 0) {
            require(presaleEnded == true, "You are not allowed to add liquidity before presale is ended");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 tokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = tokenBalance >= numTokensToSwap;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            sendFeeToRewardLiquidityPoolEnabled &&
            block.timestamp >= lastSwapTime + swapCoolDownTime
        ) {
            tokenBalance = numTokensToSwap;
            swapAndCharge(tokenBalance);
            lastSwapTime = block.timestamp;
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        // Take fee from exchange pairs
        for (uint i = 0; i <= exPair.length - 1; i++) {
            if (balanceOf(exPair[i]) > 0 && (from == exPair[i] || to == exPair[i])){
                takeFee = true;
            }
        }
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax and liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndCharge(uint256 tokenBalance) private lockTheSwap {

        uint256 initialBalance = address(this).balance;

        uint256 liquidBalance = tokenBalance.mul(_liquidityFee).div(_liquidityFee + _rewardPoolFee).div(2);
        tokenBalance = tokenBalance.sub(liquidBalance);
        swapTokensForEth(tokenBalance); 

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 bnbForLiquid = newBalance.mul(liquidBalance).div(tokenBalance);
        addLiquidity(liquidBalance, bnbForLiquid);

        (bool success, ) = payable(bnbPoolAddress).call{value: address(this).balance}("");
        require(success == true, "Transfer failed.");
        emit SwapAndCharged(tokenBalance, liquidBalance, address(this).balance, bnbForLiquid);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        uint256 tTransferAmount = _getFeeValues(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);   
        _balances[address(this)] = _balances[address(this)].add(amount.sub(tTransferAmount));
        emit Transfer(sender, recipient, tTransferAmount);

        if(!takeFee)
            restoreAllFee();
    }
}