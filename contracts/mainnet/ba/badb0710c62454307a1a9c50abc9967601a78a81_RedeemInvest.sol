/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: Special redeem, swap, LP, bond contract
// msg.sender needs to approve smart contract to take redeeming/input token from their wallet e.g. ALCX
// created by 0xfadedface
pragma solidity 0.8.7;
interface IERC20 {function transfer(address recipient, uint256 amount) external returns (bool);function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); function balanceOf(address account) external view returns (uint256);function approve(address spender, uint256 amount) external returns (bool);}
interface bondContract {function redeem(address _depositor) external returns (uint); function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);}
interface V2Router {function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);}
contract RedeemInvest {
    address public oneInchRouter = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    bool locked = false;
   
    struct Params {
        address[] redeems;
        uint[4] slippages;
        uint amountIn;
        address tokenIn;
        address tokenOut;
        bytes swapPayload;
        bool LP;
        address poolAddress;
        address bondContractAddress;
    }
    
    constructor() {
        owner = msg.sender;
    }
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner,"ow");
        _;
    }
    modifier protect() {
        if (locked) {
            revert();
        }
    locked = true;
    _;
    locked = false;  
    }
    function setOwner(address newOwner) external onlyOwner{
        owner = newOwner;
    }

    //if tokens ever get accidently sent to smart contract they can be recovered easily
    function saveTokens(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, _amount);
    }

    function redeemSwapLPBond(Params calldata _params) external protect{
        for(uint256 i = 0; i < _params.redeems.length; i++){bondContract(_params.redeems[i]).redeem(msg.sender);}
        //transfer desired tokens into smart contract
        IERC20(_params.tokenIn).transferFrom(msg.sender, address(this), _params.amountIn);
        //approve and swap token to bond token
        IERC20(_params.tokenIn).approve(oneInchRouter,2**256-1);
        (bool _success, ) = oneInchRouter.call(_params.swapPayload);
        require(_success);
        //addLiquidity
        uint bondSlippage=_params.slippages[3];
        if(_params.LP){

        IERC20(_params.tokenIn).approve(sushiRouter,2**256-1);
        IERC20(_params.tokenOut).approve(sushiRouter,2**256-1);

        uint amountADesired=_params.slippages[0];
        uint amountBDesired=_params.slippages[1];
        uint deadline = _params.slippages[2];
            V2Router(sushiRouter).addLiquidity(
                _params.tokenIn,//tokenA
                _params.tokenOut,//tokenB
                IERC20(_params.tokenIn).balanceOf(address(this)),//amountADesired
                IERC20(_params.tokenOut).balanceOf(address(this)),//amountBDesired
                amountADesired,//amountAMin
                amountBDesired,//amountBMin
                address(this),//to
                deadline//deadline
                );
            //approve and deposit LP
            IERC20(_params.poolAddress).approve(_params.bondContractAddress,2**256-1);
            bondContract(_params.bondContractAddress).deposit(IERC20(_params.poolAddress).balanceOf(address(this)),bondSlippage, msg.sender);
        }else{
            //approve and deposit non-LP
            IERC20(_params.tokenOut).approve(_params.bondContractAddress,2**256-1);
            bondContract(_params.bondContractAddress).deposit(IERC20(_params.tokenOut).balanceOf(address(this)), bondSlippage, msg.sender);
        }    
    }
}