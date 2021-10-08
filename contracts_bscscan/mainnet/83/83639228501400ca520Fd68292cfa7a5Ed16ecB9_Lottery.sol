/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





contract Lottery
{
    address public owner;
    address constant routerAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 router;
    constructor(){
        owner=msg.sender;
        router=IUniswapV2Router02(routerAddress);
    }
    modifier onlyOwner{
        
        require(msg.sender==owner);
        _;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Lottery///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public TicketPrice=(10**18)/1000; //StartPrize Lottery 0.1 BNB


    event OnBuyTicket(address account);
    event OnDrawWinner(address winner, uint256 amount);
    address[] participants;
    uint8 RoundCount;
    uint8 ParticipantsPerRound=3;
    uint LastBuyTimestamp;
    function BuyTicket() public payable{
        require(msg.value==TicketPrice);
        RoundCount++;
        participants.push(msg.sender);
        LastBuyTimestamp=block.timestamp;
        if(RoundCount>=ParticipantsPerRound){ 
            RoundCount==0;
            _drawWinner();
        }
        emit  OnBuyTicket(msg.sender);
    }
    
    
    function SetParticipantCount(uint8 count) public onlyOwner  {
        ParticipantsPerRound=count;
    }
    function SetTIcketPrice(uint256 price) public onlyOwner  {
        TicketPrice=price;
    }
    
    
    function ManuallyDrawWinner() public{
        require(LastBuyTimestamp+5 minutes<=block.timestamp,"Can only draw winner 5 minutes after last buy");
        require(participants.length>0,"No participants");
        _drawWinner();
    }
    function _drawWinner() private{
        uint winner=_getPseudoRandomNumber(participants.length);
        uint256 totalAmount=address(this).balance;
        _buybackLuckyPig(totalAmount*2/10);
        (bool sent,)=owner.call{value:totalAmount/10}("");
        require(sent);
        uint winAmount=address(this).balance;
        address winnerAddress=participants[winner];
        (sent,)=winnerAddress.call{value:winAmount}("");
        require(sent);
        participants= new address[](0);
        emit OnDrawWinner(winnerAddress,winAmount);
    }
    
    function _buybackLuckyPig(uint256 amount) private{
         if(amount==0) return;
        //Buy BM
        address[] memory path = new address[](2);
        path[1] = address(0xF16e1Ad313E3Bf4E3381b58731b45fA116ECF53f);
        path[0] = router.WETH();
        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:amount}(
            0,
            path,
            address(0xdead),
            block.timestamp
        ){}catch{}
    }
    function _getPseudoRandomNumber(uint256 modulo) private view returns(uint256) {
        //uses WBNB-Balance to add a bit unpredictability
        uint256 WBNBBalance = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        
        //generates a PseudoRandomNumber
        uint256 randomResult = uint256(keccak256(abi.encodePacked(
            WBNBBalance + 
            block.timestamp + 
            block.difficulty +
            block.gaslimit
            ))) % modulo;
            
        return randomResult;    
    }

}