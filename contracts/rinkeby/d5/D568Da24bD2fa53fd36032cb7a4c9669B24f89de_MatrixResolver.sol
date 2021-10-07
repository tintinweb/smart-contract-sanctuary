/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IInsuranceFund {
    function getAllAmms() external view returns (IAmm[] memory);
}

interface IAmm {
    function nextFundingTime() external view returns (uint256);
}

interface IClearingHouse {
    function payFunding(address _amm) external;
}


contract MatrixResolver {

    IInsuranceFund constant insuranceFund  = IInsuranceFund(0x216099A1beB788Dbd126E05707daC38cD9ecC378);
    IClearingHouse constant clearingHouse = IClearingHouse(0x6c9E2c0787404A308704164BFc8441eB5040D56b);

    
    function checker() public view returns(bool canExec, bytes memory execData) {
        IAmm[] memory amms = insuranceFund.getAllAmms();
        
        for (uint256 i; i < amms.length; i++) {
            uint256 nextFundingTime = amms[i].nextFundingTime();
            if (nextFundingTime <= block.timestamp) return (true, abi.encodeWithSelector(IClearingHouse.payFunding.selector, amms[i]));
        }
        
        return (false, bytes("No AMMs nextFundingTime is reached"));
    }


}