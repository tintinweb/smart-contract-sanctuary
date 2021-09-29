/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity 0.6.12;

interface DaiLike {
    function balanceOf(address) external returns (uint);
}

contract TestCalc {

    // SES Core Unit
    address constant SES_WALLET     = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    uint256 constant SES_BUDGET_CAP = 1_153_480;

    function calcSESAmount() public returns (uint256) {
        return (SES_BUDGET_CAP-DaiLike(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa).balanceOf(SES_WALLET));
    }
}