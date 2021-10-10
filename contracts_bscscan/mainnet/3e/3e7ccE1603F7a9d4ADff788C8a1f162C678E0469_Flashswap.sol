// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.6 <0.8.0;

import './SafeMath.sol';
import './UniswapV2Library.sol';
import './IERC20.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';


contract Flashswap {
    using SafeMath for uint;

    uint constant deadline = 1 days;

    address private owner;
    address private constant pancakeFactory = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
    address private constant bakery = 0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F;
    address private constant ape = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    IUniswapV2Router02 bakeryRouter = IUniswapV2Router02(bakery);
    IUniswapV2Router02 apeRouter = IUniswapV2Router02(ape);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    function withdrawToken(address _to, address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(_to, _amount);
    }

    function start(
        address token0,
        address token1,
        uint amount0,
        uint amount1
    ) external {
        address pairAddress = IUniswapV2Factory(pancakeFactory).getPair(token0, token1);
        require(pairAddress != address(0), 'This pool does not exist');

        IUniswapV2Pair(pairAddress).swap(
            amount0,
            amount1,
            address(this),
            bytes('not empty')
        );
    }

    function pancakeCall(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external {
        address[] memory path = new address[](2);

        // obtain an amout of token that you exchanged
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(msg.sender == UniswapV2Library.pairFor(pancakeFactory, token0, token1));
        require(_amount0 == 0 || _amount1 == 0);

        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        // IERC20 token that we will sell for otherToken
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        // token.approve(address(bakeryRouter), amountToken);
        token.approve(address(apeRouter), amountToken);

        // calculate the amount of token how much input token should be reimbursed
        uint amountRequired = UniswapV2Library.getAmountsIn(
            pancakeFactory,
            amountToken,
            path
        )[0];

        // swap token and obtain equivalent otherToken amountRequired as a result
        // need to receive amountRequired at minimum amount to pay back
        // uint amountReceived = bakeryRouter.swapExactTokensForTokens(
        uint amountReceived = apeRouter.swapExactTokensForTokens(
            amountToken,
            amountRequired,
            path,
            msg.sender,
            1665417574
        )[1];

        require(amountReceived > amountRequired); // fail if we didn't get enough tokens
        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        // otherToken.transfer(msg.sender, amountRequired);
        otherToken.transfer(owner, amountReceived.sub(amountRequired));
    }

    receive() external payable {}
}