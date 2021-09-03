// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

interface IStaking {
    function distribute() external payable;
}

contract CashSwap is Ownable, ERC20 {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    address public stakingPool;
    uint256 public taxFee = 300;
    uint256 public taxFeeTotal;

    bool public isTaxActive = true;
    mapping(address => bool) public isTaxless;

    uint256 public minTokenBeforeSwap = 10e18;
    bool private inSwap;
    bool public isSwapEnabled;
    
    uint256 public totalEthDistributed;

    event SwapedTokenForEth(uint256 ethAmount, uint256 tokenAmount);
    event StakingPoolSet(address stakingPoolAddress);
    event TaxFeeSet(uint256 taxFee);
    event SwapEnabled(bool status);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address swapRouter) ERC20("CashSwap Token","CSWAP") public {
        uniswapV2Router = IUniswapV2Router02(swapRouter);
        _mint(_msgSender(),100_000e18);
        isTaxless[address(this)] = true;
        isTaxless[_msgSender()] = true;
    }

    function setPairAddress(address pair) external onlyOwner {
        uniswapV2Pair = pair;
        isSwapEnabled = true;
    }
    
    function setTaxActive(bool _value) external onlyOwner {
        isTaxActive = _value;
    }

    function setTaxless(address account, bool _value) external onlyOwner {
        isTaxless[account] = _value;
    }

    function setTaxFee(uint256 _taxFee) external onlyOwner {
        require(_taxFee > 0 && _taxFee <= 1000, "CashSwap: Tax Fee out of range!");
        taxFee = _taxFee;

        emit TaxFeeSet(_taxFee);
    }

    function setStakingPool(address _stakingPool) external onlyOwner {
        require(stakingPool == address(0), "Staking pool already set.");
        
        stakingPool = _stakingPool;
        isTaxless[_stakingPool] = true;

        emit StakingPoolSet(_stakingPool);
    }
    
    function setSwapEnabled(bool _value) external onlyOwner {
        isSwapEnabled = _value;
        
        emit SwapEnabled(_value);
    }
    
    function setMinTokenBeforeSwap(uint256 amount) external onlyOwner {
        minTokenBeforeSwap = amount;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if(_msgSender() == stakingPool) return true; //If stakingPool is set to staking contract, this line is safe.

        _approve(sender, _msgSender(), allowance(sender,_msgSender()).sub(amount, "CashSwap: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if(isSwapEnabled && !inSwap && sender != uniswapV2Pair){
            swapAndDistribute();
        }
        uint256 transferAmount = amount;
        if(isTaxActive && !isTaxless[sender] && !isTaxless[recipient]) {
            uint256 fee = amount.mul(taxFee).div(10_000);
            super._transfer(sender,address(this),fee);
            transferAmount = amount.sub(fee);
            taxFeeTotal = taxFeeTotal.add(fee);
        }
        super._transfer(sender, recipient, transferAmount);
    }

    function swapAndDistribute() private lockTheSwap {
        uint256 tokenAmount = balanceOf(address(this));
        if(tokenAmount < minTokenBeforeSwap) return;

        uint256 ethAmount = address(this).balance;
        
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
        
        ethAmount = address(this).balance.sub(ethAmount);
        emit SwapedTokenForEth(tokenAmount,ethAmount);
        
        uint256 amountToDistribute = address(this).balance;
        totalEthDistributed = totalEthDistributed.add(amountToDistribute);
        IStaking(stakingPool).distribute{value: amountToDistribute}();
    }
    
    receive() external payable {}
}