/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20Token {
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}
contract POLCVault {
    IERC20Token POLCToken =  IERC20Token(0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37);  // VERIFY ME!!!
    address public kwallet = 0x4ecC91cCAd7b4b78489792818814e995F562A947;  // VERIFY ME!!
    uint256 public currentStep = 1;
    uint256 public stepAmount = 187500 ether;
    uint256 public stepSize = 30 days;  // VERIFY ME!!!
    uint256 counterStart = 1638230400;
    bool iDone = false;

    function initialClaim() public {
        require(iDone == false);
        require(counterStart < block.timestamp, "Must wait claim date");
        iDone = true;
        POLCToken.transfer(kwallet, (250000 ether));
    }

    function claimStep() public {
        require(counterStart > 0, "Contract is not initialized");
        uint256 nClaim = counterStart + (currentStep * stepSize);
        require(nClaim < block.timestamp, "Must wait the next claim date" );
        currentStep += 1;
        require(POLCToken.transfer(kwallet, stepAmount), "ERC20 transfer error");
    }

    function nextPayment() public view returns (uint256 paymentDate){
        paymentDate = counterStart + (currentStep * stepSize);
    }

}