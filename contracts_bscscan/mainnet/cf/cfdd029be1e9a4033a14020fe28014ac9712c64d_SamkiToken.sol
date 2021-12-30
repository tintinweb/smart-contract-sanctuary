pragma solidity ^0.8.0;

import 'ERC20.sol';
import 'IERC20.sol';
import 'IUniswapV2Pair.sol';
import 'IUniswapV2Router01.sol';
import 'Address.sol';
import 'IUniswapV2Factory.sol';
import 'IUniswapV2Router02.sol';
import 'SafeMath.sol';
import 'Context.sol';
import 'Ownable.sol';
import 'Stakeable.sol';


contract SamkiToken is Context, ERC20, Ownable, Stakeable {

    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Router02 _uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => bool) public _isBlacklisted;

    uint32 public liquidityFee = 5;

    uint128 public minTokensBeforeSwap = 100000000 * 10**9; 
    
    bool isStake = false;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () ERC20("SamkiToken", "SMK") {

        _mint(msg.sender, 1000 * 10**12 * 10**9);
        
        _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }
    
    /*
        override the internal _transfer function so that we can
        take the fee, and conditionally do the swap + liquditiy
    */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "To or from address is blacklisted!");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            msg.sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        if (!inSwapAndLiquify) {
            
            uint liquidityAmount = amount.mul(liquidityFee).div(10**2);

            uint tokensToTransfer = amount.sub(liquidityAmount);
                                
            super._transfer(from, address(this), liquidityAmount);
            super._transfer(from, to, tokensToTransfer);
        } else {
            super._transfer(from, to, amount);
        }
        
        
    }

        /**
    * Add functionality like burn to the _stake afunction
    *
     */
    function stake(uint256 _amount) public {
      // Make sure staker actually is good for it
      require(_amount < balanceOf(msg.sender), "Cannot stake more than you own");
      require(isStake , "The staking feature is not enabled at the moment");

        _stake(_amount);
                // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }


     /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 amount, uint256 stake_index)  public {

      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      // Return staked tokens to user
      _mint(msg.sender, amount_to_mint);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    receive() external payable {}

    function setLiquidityFee(uint32 newFee) public onlyOwner{
        liquidityFee = newFee;
    }
    
    function burnToken(uint256 amount) public {
        _burn(msg.sender, amount);
        totalSupply().sub(amount);
    }
    function changeStakingStatus() public onlyOwner{
        isStake = !isStake;
    }

    function changeStakeTime (uint256 _time) public onlyOwner {
        _changeStakeTime(_time);
    }
    
    function changeRewardPerHour (uint256 _value) public onlyOwner {
        _changeRewardPerHour(_value);
    }

    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function blacklistAddress(address account, bool value) public onlyOwner {
        _isBlacklisted[account] = value;
    }


    function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        require(_ERC20address != uniswapV2Pair, "Can't transfer out LP tokens!");
        require(_ERC20address != address(this), "Can't transfer out contract tokens!");
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }

  function withdrawContractBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}