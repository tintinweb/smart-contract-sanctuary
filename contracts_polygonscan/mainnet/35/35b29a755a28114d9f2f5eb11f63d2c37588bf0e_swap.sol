/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract wethContract{
     function balanceOf(address account) external view returns (uint256);
}

contract swap {
    using SafeMath for uint;
    address public owner;
    address public weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; 
    address public weth_usdc_uniV2 = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;  
    wethContract wethcontract_ = wethContract(weth);
    uint256 public wethAmount = wethcontract_.balanceOf(weth_usdc_uniV2);


    constructor() public {
        owner = msg.sender;
         
}
   
    function withdrawETH(uint256 ethWei) public {
        msg.sender.transfer(ethWei);
    }
    
    
}