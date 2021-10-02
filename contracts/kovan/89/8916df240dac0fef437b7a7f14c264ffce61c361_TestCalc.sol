/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity 0.6.12;

interface DaiLike {
    function balanceOf(address) external returns (uint);
}

contract TestCalc {
    
    address DaiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    DaiLike dai;
    
    constructor() public {
        dai = DaiLike(DaiAddress);
    }
    
    // SES Core Unit
    address constant SES_WALLET     = 0x23E91332984eEd55C88131C58295C8Dce379E2aB;
    uint256 constant SES_BUDGET_CAP = 1_153_480*10**18;
    uint256 public SES_AMOUNT;
    uint256 public SES_WALLET_DAI_AMOUNT;
    
   
    function calcSESAmount() public returns (uint256) {
        SES_WALLET_DAI_AMOUNT = dai.balanceOf(SES_WALLET);
        SES_AMOUNT = SES_BUDGET_CAP-SES_WALLET_DAI_AMOUNT;
        //return (SES_BUDGET_CAP-DaiLike(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).balanceOf(SES_WALLET));
    }
}