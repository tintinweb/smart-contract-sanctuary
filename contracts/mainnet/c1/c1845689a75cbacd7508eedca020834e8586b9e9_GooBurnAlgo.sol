/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.4.25;

/**
 * 
 * World War Goo - Competitive Idle Game
 * 
 */

contract GooBurnAlgo {
    
    Bankroll constant bankroll = Bankroll(0x66a9f1e53173de33bec727ef76afa84956ae1b25);
    GooToken constant goo = GooToken(0xdf0960778c6e6597f197ed9a25f12f5d971da86c);
    
    // Updated naive algorithm, splitting eth equally between totalSupply
    function priceOf(uint256 amount) external view returns(uint256 payment) {
        payment = (bankroll.gooPurchaseAllocation() * amount) / goo.totalSupply();
    }
    
    function price() external view returns(uint256 gooPrice) {
        gooPrice = bankroll.gooPurchaseAllocation() / goo.totalSupply();
    }
    
}


contract Bankroll {
    uint256 public gooPurchaseAllocation; // Wei destined to pay to burn players' goo
}

contract GooToken {
    function totalSupply() external view returns(uint256);
}