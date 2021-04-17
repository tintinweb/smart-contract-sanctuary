// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './SafeMath.sol';
import './Ownable.sol';
import './IERC20.sol';

abstract contract Behodler {
    address public Weth;

    function getConfiguration()
        virtual
        public
        view
        returns (
            uint256 transferFee,
            uint256 burnFee,
            address feeDestination
        );

    function addLiquidity(address inputToken, uint256 amount)
        virtual
        public
        payable
        returns (uint256 deltaSCX);

    function withdrawLiquidity(address outputToken, uint256 tokensToRelease)
        virtual
        public
        payable
        returns (uint256 deltaSCX);
    
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    )
        virtual
        public
        payable
        returns (bool success);
}

abstract contract UniswapV2Router02 {
    address public WETH;

    // function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    //     virtual
    //     public
    //     returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) virtual public;
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) virtual public;
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        virtual
        public
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        virtual
        public
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        public
        virtual
        returns (uint[] memory amounts);
}

contract Arbitrage is Ownable {
    using SafeMath for uint256;

    address public _behodler = 0x1B8568FbB47708E9E9D31Ff303254f748805bF21;
    Behodler private behodler = Behodler(_behodler);

    address public _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapV2Router02 private uniRouter = UniswapV2Router02(_uniRouter);

    function setBehodler(address _behodlerAddress) public onlyOwner {
        _behodler = _behodlerAddress;
        behodler = Behodler(_behodlerAddress);
    }

    function setUniRouter(address _uniAddress) public onlyOwner {
        _uniRouter = _uniAddress;
        uniRouter = UniswapV2Router02(_uniAddress);
    }

    function approve(address to, address token) public onlyOwner {
        uint256 min = 0;
        IERC20(token).approve(to, min-1);
    }

    function transferERC20(address token, address to, uint256 amount) public onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    receive() external payable {}

    function behodlerToUniEthScx(uint256 expectOutput, uint deadline) public payable onlyOwner {
        // send eth, receive scx on Behodler
        behodler.addLiquidity{value: msg.value}(behodler.Weth(), msg.value);

        // send scx, receive eth on Uni
        uint256 scxAmount = IERC20(_behodler).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _behodler;
        path[1] = uniRouter.WETH();
        // has assert in this function
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(scxAmount, expectOutput, path, msg.sender, deadline);
    }

    function uniToBehodlerEthScx(uint256 expectOutput, uint deadline) public payable onlyOwner {
        // send eth, receive scx on Uni
        address[] memory path = new address[](2);
        path[0] = uniRouter.WETH();
        path[1] = _behodler;
        uniRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline);

        // has assert in this function
        behodler.withdrawLiquidity(behodler.Weth(), expectOutput);
        msg.sender.transfer(address(this).balance);
    }

    function behodlerToUniTokenScx(address token, uint256 inputAmount, uint256 expectOutput, uint deadline) public onlyOwner {
        // send eth, receive scx on Behodler
        behodler.addLiquidity(token, inputAmount);

        // send scx, receive eth on Uni
        uint256 scxAmount = IERC20(_behodler).balanceOf(address(this));

        // address[] memory path = new address[](2);
        // path[0] = _behodler;
        // path[1] = token;
        // // has assert in this function
        // uniRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(scxAmount, expectOutput, path, msg.sender, deadline);
    }

    function uniToBehodlerTokenScx(address token, uint256 inputAmount, uint256 expectOutput, uint deadline) public onlyOwner {
        // send eth, receive scx on Uni
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = _behodler;
        uniRouter.swapExactTokensForTokens(inputAmount, 0, path, address(this), deadline);

        // has assert in this function
        behodler.withdrawLiquidity(token, expectOutput);
        uint256 outputAmout = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, outputAmout);
    }

    function behodlerToUniEthToken(address token, uint256 tokenAmount, uint256 expectOutput, uint deadline) public payable onlyOwner {
        // send eth, receive scx on Behodler
        behodler.swap{value: msg.value}(behodler.Weth(), token, msg.value, tokenAmount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniRouter.WETH();
        // has assert in this function
        uniRouter.swapExactTokensForETH(tokenAmount, expectOutput, path, msg.sender, deadline);
    }

    function uniToBehodlerEthToken(address token, uint256 expectOutput, uint deadline) public payable onlyOwner {
        // send eth, receive scx on Uni
        address[] memory path = new address[](2);
        path[0] = uniRouter.WETH();
        path[1] = token;
        uniRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline);

        uint256 tokenAmount = IERC20(token).balanceOf(address(this));

        // has assert in this function
        behodler.swap(token, behodler.Weth(), tokenAmount, expectOutput);
        msg.sender.transfer(address(this).balance);
    }

    function behodlerToUniTokenToken(address inputToken, uint256 inputAmount, address token, uint256 tokenAmount, uint256 expectOutput, uint deadline) public onlyOwner {
        // send eth, receive scx on Behodler
        behodler.swap(inputToken, token, inputAmount, tokenAmount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = inputToken;
        // has assert in this function
        uniRouter.swapExactTokensForTokens(tokenAmount, expectOutput, path, msg.sender, deadline);
    }

    function uniToBehodlerTokenToken(address inputToken, uint256 inputAmount, address token, uint256 expectOutput, uint deadline) public onlyOwner {
        // send eth, receive scx on Uni
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = token;
        uniRouter.swapExactTokensForTokens(inputAmount, 0, path, address(this), deadline);

        uint256 tokenAmount = IERC20(token).balanceOf(address(this));

        // has assert in this function
        behodler.swap(token, inputToken, tokenAmount, expectOutput);
        IERC20(inputToken).transfer(msg.sender, expectOutput);
    }
}