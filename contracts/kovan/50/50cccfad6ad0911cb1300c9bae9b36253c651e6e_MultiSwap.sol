/**
 *Submitted for verification at Etherscan.io on 2021-07-23
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
        uint256 index0;
        uint256 index1;
        uint256 dexType;
    }
    Call public acryptos;
    Call public dopple;
    Call public mdex;
    event TestAcryptos(int128 i,int128 j,uint256 dx,uint256 dy);
    event TestDopple(uint8 tokenIndexFrom,uint8 tokenIndexTo,uint256 dx,uint256 minDy,uint256 deadline);
    event TestPancake(uint amountIn,int amountOutMin, address to,uint deadline);
    event MDEX(uint256 m,uint256 inputAmount,Call[] calls,IBEP20 firstToken);
    function approve(IBEP20 token,address spender,uint256 amount)public returns(bool success){
        success = token.approve(spender,amount);
    }
    function withdraw(IBEP20 token) public returns (bool success){
        success = token.transfer(0x8902f80bbC72460C4F54373C7Ca6882fC81a6d47,token.balanceOf(address(this)));
    }
    function execute(uint256 inputAmount,IBEP20 firstToken ,Call[] memory calls,uint256 mDex) public returns (bool success) {
        // address[] memory swapPath = new address[](2);
        // uint256 balance = 0;
        // for(uint256 i = 0; i < calls.length; i++) {
        //     balance = IBEP20(calls[i].token0).balanceOf(address(this));
        //     if(calls[i].dexType==0){
        //         // swapPath[0] = calls[i].token0;
        //         // swapPath[1] = calls[i].token1;
        //         // IPancakeSwapRouter(calls[i].target).swapExactTokensForTokens(balance,0,swapPath,address(this),block.timestamp);
        //         mdex.target = calls[i].target;
        //         mdex.token0 = calls[i].token0;
        //         mdex.token1 = calls[i].token1;
        //         mdex.index0 = calls[i].index0;
        //         mdex.index1 = calls[i].index1;
        //         mdex.dexType = calls[i].dexType;
        //     }else if(calls[i].dexType==1){
        //         acryptos.target = calls[i].target;
        //         acryptos.token0 = calls[i].token0;
        //         acryptos.token1 = calls[i].token1;
        //         acryptos.index0 = calls[i].index0;
        //         acryptos.index1 = calls[i].index1;
        //         acryptos.dexType = calls[i].dexType;
        //         // emit TestAcryptos(int128(calls[i].index0),int128(calls[i].index1),balance,0);
        //         // IAcryptosRouter(calls[i].target).exchange(int128(calls[i].index0),int128(calls[i].index1),balance,0);
        //     }else if(calls[i].dexType==2){
        //         mdex.target = calls[i].target;
        //         mdex.token0 = calls[i].token0;
        //         mdex.token1 = calls[i].token1;
        //         mdex.index0 = calls[i].index0;
        //         mdex.index1 = calls[i].index1;
        //         mdex.dexType = calls[i].dexType;
        //         // emit TestDopple(uint8(calls[i].index0),uint8(calls[i].index1),balance,0,block.timestamp);
        //         //IDoppleRouter(calls[i].target).swap(uint8(calls[i].index0),uint8(calls[i].index1),balance,0,block.timestamp);
        //     }
        // }
        if(mDex>0){
            emit MDEX(mDex,inputAmount,calls,firstToken);
        }else{
            emit TestAcryptos(1,1,1,1);
        }
        success = true;
    }
    
}