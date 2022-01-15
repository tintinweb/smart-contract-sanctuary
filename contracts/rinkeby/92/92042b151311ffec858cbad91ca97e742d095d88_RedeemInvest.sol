/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: Special redeem, swap, LP, bond contract
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;
interface IERC20 {function transfer(address recipient, uint256 amount) external returns (bool);function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); function balanceOf(address account) external view returns (uint256);function approve(address spender, uint256 amount) external returns (bool);}
interface bondContract {function redeem(address _depositor) external returns (uint); function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);}
interface V2Router {function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);}
contract RedeemInvest {
    address public oneInchRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    bool locked;
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
    // msg.sender needs to approve smart contract to take redeeming/input token from their wallet e.g. ALCX
    // owner needs to approve 1inch to take input tokens from smart contract in order to swap along the most efficiednt path
    // owner needs to approve sushi to take tokenA/B to addLiquidity e.g ALCX wETH
    // e.g. Now ALCX - ETH has the ability to take ALCX and wETH to return SLP
    // owner needs to approve bondContract to take respective token/pool address LP e.g. ALCX-ETH SLP can now take ALCX-ETH SLP from smart contract and deposit on behalf of msg.sender
    // note: end user only needs to approve smart contract, owner needs repeat steps above to add additional redeeming tokens and bondContract(s), this process needs to be done once per new redeeming token
    function approve(address _spender, address _token, uint256 _amount) external onlyOwner{
        IERC20(_token).approve(_spender, _amount);
    }
    //Function so that if tokens ever get accidently sent to smart contract, they can be recovered easily
    function saveTokens(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, _amount);
    }
    function redeemSwapLPBond(bytes memory params) external protect{
        (address[] memory redeems,
         uint[4] memory slippages, uint amountIn, address tokenIn, address tokenOut, bytes memory swapPayload,
         bool LP, address poolAddress,
         address bondContractAddress) = abi.decode(params,(address[],uint[4],uint,address,address,bytes, bool, address, address));
        //redeems
        for(uint256 i = 0; i < redeems.length; i++){bondContract(redeems[i]).redeem(tx.origin);}
        //transfer desired tokens into smart contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        //swap token to bond token
        (bool _success, ) = oneInchRouter.call(swapPayload);
        require(_success);
        //addLiquidity
        uint bondSlippage=slippages[3];
        if(LP){
        uint amountADesired=slippages[0];
        uint amountBDesired=slippages[1];
        uint deadline = slippages[2];
            V2Router(sushiRouter).addLiquidity(
                tokenIn,//tokenA
                tokenOut,//tokenB
                IERC20(tokenIn).balanceOf(address(this)),//amountADesired
                IERC20(tokenOut).balanceOf(address(this)),//amountBDesired
                amountADesired,//amountAMin
                amountBDesired,//amountBMin
                address(this),//to
                deadline//deadline
                );
            //deposit LP
            bondContract(bondContractAddress).deposit(IERC20(poolAddress).balanceOf(address(this)),bondSlippage, msg.sender);
        }else{
            //deposit non-LP
            bondContract(bondContractAddress).deposit(IERC20(tokenOut).balanceOf(address(this)), bondSlippage, msg.sender);
        }    
    }
}