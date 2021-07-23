/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IPancakeSwapRouter{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
interface IAcryptosRouter{
    function exchange(int128 i,int128 j,uint256 dx,uint256 dy) external returns(uint256 result);
}
interface IDoppleRouter{
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}
contract MultiSwap {
    address MDEXRouter = 0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8;
    address MDEXToken  = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;
    struct Call {
        address target;
        address token0;
        address token1;
        uint8 index0;
        uint8 index1;
        uint256 dexType;
    }
    function execute(uint256 inputAmount,IBEP20 firstToken ,Call[] memory calls,bool mDex) public returns (bool success) {
        firstToken.transferFrom(msg.sender,address(this),inputAmount);
        address[] memory swapPath = new address[](2);
        uint256 balance = 0;
        for(uint256 i = 0; i < calls.length; i++) {
            balance = IBEP20(calls[i].token0).balanceOf(address(this));
            if(calls[i].dexType==0){
                swapPath[0] = calls[i].token0;
                swapPath[1] = calls[i].token1;
                IPancakeSwapRouter(calls[i].target).swapExactTokensForTokens(balance,0,swapPath,address(this),block.timestamp);
            }else if(calls[i].dexType==1){
                IAcryptosRouter(calls[i].target).exchange(int128(calls[i].index0),int128(calls[i].index1),balance,0);
            }else if(calls[i].dexType==2){
                IDoppleRouter(calls[i].target).swap(uint8(calls[i].index0),uint8(calls[i].index1),balance,0,block.timestamp);
            }
        }
        if(mDex){
            swapPath[0] = MDEXToken;
            swapPath[1] = address(firstToken);
            balance = IBEP20(MDEXToken).balanceOf(address(this));
            IPancakeSwapRouter(MDEXRouter).swapExactTokensForTokens(balance,0,swapPath,address(this),block.timestamp);
        }
        balance = firstToken.balanceOf(address(this));
        require(inputAmount<balance,'failed');
        firstToken.transfer(0x8902f80bbC72460C4F54373C7Ca6882fC81a6d47,balance);
        success = true;
    }
    function approve(IBEP20 token,address spender,uint256 amount)public returns(bool success){
        success = token.approve(spender,amount);
    }
    function withdraw(IBEP20 token) public returns (bool success){
        success = token.transfer(0x8902f80bbC72460C4F54373C7Ca6882fC81a6d47,token.balanceOf(address(this)));
    }
}