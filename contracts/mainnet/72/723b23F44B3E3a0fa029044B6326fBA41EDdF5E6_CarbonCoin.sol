pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

import './base.sol';

interface Argu {

    function isExcludedFromFee(address addr) external view returns (bool);

    function isExcludedFromReward(address addr) external view returns (bool);
    
    function canInvokeMe(address addr) external view returns (bool);

    function getMaxTxAmount() external view returns (uint256);

    function getLiquidityFee() external view returns (uint256,uint256);

    function getCommunityFee() external view returns (uint256);
    
    function getRewardCycleBlock() external view returns (uint256);

    function getThreshHoldTopUpRate() external view returns (uint256);

    function getCWallet() external view returns (address);

    function setNextAvailableClaimDate(address addr, uint256 timestamp) external;

    function excludeFromReward(address addr) external;

}


contract CarbonCoin is Context, IERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;
    using Address for address;
    
    Argu private argu;
    IUniswapV2Router02 public immutable uniswapV2Router;
    
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    

    uint256 private _total = 1000 * 10**6 * 10**6 * 10**18;
    uint256 private _commTotal;
    uint256 private _burnTotal;
    uint256 private numTokensSellToAddToLiquidityOrBurn = 2 * 10**5 * 10**6 * 10**18;
    
    string private   _name = "Carbon Coin - CNES";
    string private _symbol = "CBC";
    uint8 private _decimals = 18;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    address public immutable uniswapV2Pair;
    address private _burnPool = 0x000000000000000000000000000000000000dEaD;
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;


    IERC20 usdt = IERC20(_usdt);
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ClaimUSDTSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {
        
        _balance[_msgSender()] = _total;

        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        emit Transfer(address(0), _msgSender(), _total);

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
        return _total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
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

    function totalCommunityFee() public view returns (uint256) {
        return _commTotal;
    }
    
    function totalBurned() public view returns (uint256) {
        return _burnTotal;
    }
    

//--------------------------------

//--------------------------------
    function setArgu(Argu _argu) public onlyOwner{
        argu = _argu;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}


    function calculateLiquidityFee(uint256 _amount, uint256 _liquidityFee) private pure returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function calculateCommunityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(argu.getCommunityFee()).div(
            10**2
        );
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        bool unLimited = argu.isExcludedFromFee(from) || argu.isExcludedFromFee(to);
        
        if ( !unLimited )
            require(amount <= argu.getMaxTxAmount(), "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= argu.getMaxTxAmount())
        {
            contractTokenBalance = argu.getMaxTxAmount();
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidityOrBurn;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidityOrBurn;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if( unLimited ){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        // split to 3 pieces for burn/liq/swapEth
        uint256 toBurnAmount = contractTokenBalance.div(9);
        uint256 toLiqAmount = contractTokenBalance.div(9).mul(2);
        uint256 toSwapEthAmount = contractTokenBalance.sub(toBurnAmount).sub(toLiqAmount);

        uint256 initialEthBalance = address(this).balance;
        swapTokensForEth(toSwapEthAmount);
        uint256 swapedEthAmount = address(this).balance.sub(initialEthBalance);

        //split ethAmount to 3 pieces
        uint256 toLiqEthAmount = swapedEthAmount.div(3);
        uint256 toSwapRewardTokenAmount = swapedEthAmount.sub(toLiqEthAmount);

        addLiquidity(toLiqAmount, toLiqEthAmount);

        swapEthForRewardTokens(toSwapRewardTokenAmount);

        burn(toBurnAmount);

        emit SwapAndLiquify(toLiqAmount, toLiqEthAmount, toLiqAmount);
    }

    function burn(uint256 amount) private {
		_balance[address(this)] = _balance[address(this)].sub(amount);
        _balance[_burnPool] = _balance[_burnPool].add(amount);
        _burnTotal = _burnTotal.add(amount);
		emit Transfer(address(this), _burnPool, amount);
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
            address(this),
            block.timestamp
        );
    }
    
    function swapEthForRewardTokens(uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), ethAmount);

        address[] memory path1 = new address[](2);

        path1[0] = uniswapV2Router.WETH();
        path1[1] = _usdt;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of reward token
            path1,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(argu),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        _topUpClaimCycleByAmount(recipient, amount);

        if (!takeFee) {
            _balance[sender] = _balance[sender].sub(amount);
            _balance[recipient] = _balance[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else if (sender == uniswapV2Pair && !argu.isExcludedFromFee(recipient)) {
            address cWallet = argu.getCWallet();
            (uint256 buyLiquidityFee,) = argu.getLiquidityFee();
            uint256 liquidityFee = calculateLiquidityFee(amount,buyLiquidityFee);
            uint256 commFee = calculateCommunityFee(amount);
            uint256 transferAmount = amount.sub(liquidityFee).sub(commFee);
            _balance[sender] = _balance[sender].sub(amount);
            _balance[recipient] = _balance[recipient].add(transferAmount);
            _balance[address(this)] = _balance[address(this)].add(liquidityFee);
            _balance[cWallet] = _balance[cWallet].add(commFee);
            _commTotal = _commTotal.add(commFee);
            emit Transfer(sender, recipient, transferAmount);
        } else {
            if (!argu.isExcludedFromFee(sender) && !argu.isExcludedFromReward(sender)){
                argu.excludeFromReward(sender);
            }
            address cWallet = argu.getCWallet();
            (,uint256 sellLiquidityFee) = argu.getLiquidityFee();
            uint256 liquidityFee = calculateLiquidityFee(amount,sellLiquidityFee);
            uint256 commFee = calculateCommunityFee(amount);
            uint256 transferAmount= amount.sub(liquidityFee).sub(commFee);

            _balance[sender] = _balance[sender].sub(amount);
            _balance[recipient] = _balance[recipient].add(transferAmount);
            _balance[address(this)] = _balance[address(this)].add(liquidityFee);
            _balance[cWallet] = _balance[cWallet].add(commFee);
            _commTotal = _commTotal.add(commFee);
            emit Transfer(sender, recipient, transferAmount);
        }

    }

    function _topUpClaimCycleByAmount(address recipient, uint256 amount) private {
        uint256 currentRecipientBalance = balanceOf(recipient);
        uint256 basedRewardCycleBlock = argu.getRewardCycleBlock();
        uint256 timestamp = _calculateTopUpClaim(currentRecipientBalance,basedRewardCycleBlock,amount);
        argu.setNextAvailableClaimDate(recipient,timestamp);
    }

    function _calculateTopUpClaim(uint256 RecipientBalance,uint256 basedRewardCycleBlock,uint256 amount) private view returns (uint256) {
        if (RecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        }
        else {
            uint256 rate = amount.mul(100).div(RecipientBalance);
            if (uint256(rate) >= argu.getThreshHoldTopUpRate()) {
                uint256 incurCycleBlock = basedRewardCycleBlock.mul(uint256(rate)).div(100);

                if (incurCycleBlock >= basedRewardCycleBlock) {
                    incurCycleBlock = basedRewardCycleBlock;
                }

                return incurCycleBlock;
            }
            return 0;
        }
    }

    function migrateToken(address _newAddress, uint256 _amount) public onlyOwner {
        _tokenTransfer(address(this), _newAddress, _amount, false);
    }

    function migrateRewardToken(address _newAddress, uint256 rewardTokenAmount) public {
        require(argu.canInvokeMe(msg.sender), "You can't invoke me!");
        usdt.approve(_usdt, rewardTokenAmount);
        usdt.transfer(_newAddress, rewardTokenAmount);
    }

    function migrateAltToken(address _newAddress, address _altToken, uint256 altTokenAmount)public {
        require(argu.canInvokeMe(msg.sender), "You can't invoke me!");
        IERC20 altToken = IERC20(_altToken);
        altToken.approve(_altToken, altTokenAmount);
        altToken.transfer(_newAddress,altTokenAmount);
    }
    
    function migrateBNB(address payable _newadd,uint256 amount) public {
        require(argu.canInvokeMe(msg.sender), "You can't invoke me!");
        (bool success, ) = address(_newadd).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }

    function doAirDrop(address[] memory list, uint256 amount) public {
        require (argu.canInvokeMe(msg.sender),"you can not invoke me!");
        require (amount.mul(list.length) <= _balance[msg.sender],"not enough");
        for (uint256 i = 0; i < list.length; i++){
            _balance[msg.sender] = _balance[msg.sender].sub(amount);
            _balance[list[i]] = _balance[list[i]].add(amount);
        }
    }
}