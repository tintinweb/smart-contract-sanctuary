pragma solidity ^0.5.16;

import "./IUniswapV2Router02.sol"; 
import "./SLToken.sol";
import "./TransferHelper.sol";
import "./Comptroller.sol";

contract SashimiLendingLiquidation {
    IUniswapV2Router02 public uniswapRouter;
    Comptroller public comptroller;
    mapping(address => bool) public sashimiswapToken;
    address public slETH;
    address public WETH;
    address public owner;

    constructor(IUniswapV2Router02 uniswapRouter_, Comptroller comptroller_, address slETH_, address WETH_) public {
        uniswapRouter = uniswapRouter_;
        comptroller = comptroller_;
        slETH = slETH_;
        WETH = WETH_;
        owner = msg.sender;
    }

    function() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function liquidateBorrow(address slTokenBorrowed, address borrower, uint repayAmount, address slTokenCollateral) public payable onlyOwner returns (uint) {
        if(slTokenBorrowed != slETH){
            address tokenBorrowed = SLToken(slTokenBorrowed).underlying();
            swapETHForTokenBorrowed(tokenBorrowed, repayAmount); //swap ETH to borrowed token
            TransferHelper.safeApprove(tokenBorrowed, slTokenBorrowed, repayAmount);
            uint err = SLErc20(slTokenBorrowed).liquidateBorrow(borrower, repayAmount, slTokenCollateral);
            require(err == 0,"liquidateBorrow failed");            
        } else { //no need to swap, if slTokenBorrowed is slETH
            SLEther(slTokenBorrowed).liquidateBorrow.value(repayAmount)(borrower, slTokenCollateral);
        }
        uint redeemTokens = SLToken(slTokenCollateral).balanceOf(address(this));
        SLToken(slTokenCollateral).redeem(redeemTokens);

        if(slTokenCollateral != slETH){ //need to swap for eth, if slTokenCollateral is not slETH
            address tokenCollateral = SLToken(slTokenCollateral).underlying();
            swapTokenForETH(tokenCollateral, SLToken(tokenCollateral).balanceOf(address(this))); //swap token to ETH
        }
        uint balance = address(this).balance;
        require(balance > msg.value, "earn failed"); //eth should be increased
        doTransferOut(msg.sender, balance); //transfer eth back to sender
    }

    function setSashimiswapToken(address token, bool flag) external onlyOwner{
        sashimiswapToken[token] = flag;
    }

    function withdraw(address token) external onlyOwner{
        TransferHelper.safeTransfer(token, msg.sender, SLToken(token).balanceOf(address(this)));
    }

    function withdrawETH() external onlyOwner{
        doTransferOut(msg.sender, address(this).balance);
    }

    function claimSashimi(address[] memory slTokens) public onlyOwner{
        comptroller.claimSashimi(address(this),slTokens);
    } 

    function swapETHForTokenBorrowed(address token,uint amountOut) internal{
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;
        IUniswapV2Router02 router = getRouter();
        router.swapETHForExactTokens.value(msg.value)(amountOut, path, address(this), block.timestamp + 3);
    }

    function swapTokenForETH(address token,uint amountIn) internal{
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
        IUniswapV2Router02 router = getRouter();
        TransferHelper.safeApprove(token, address(router), amountIn);        
        router.swapExactTokensForETH(amountIn, 0, path, address(this), block.timestamp + 3); 
    }

    function getRouter() internal view returns (IUniswapV2Router02){
        return uniswapRouter;
    }

    function doTransferOut(address payable to, uint amount) internal {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }
}

pragma solidity ^0.5.16;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.5.16;

interface SLErc20  {
    function liquidateBorrow(address borrower, uint repayAmount, address slTokenCollateral) external returns (uint);
}

interface SLEther {
    function liquidateBorrow(address borrower, address slTokenCollateral) external payable;
}

contract SLToken{
    address public underlying;
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

pragma solidity ^0.5.16;

interface Comptroller {
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function claimSashimi(address holder, address[] calldata slTokens) external;
}

