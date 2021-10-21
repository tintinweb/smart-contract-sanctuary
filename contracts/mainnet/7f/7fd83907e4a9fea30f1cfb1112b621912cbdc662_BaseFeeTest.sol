/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBaseFee {
    function basefee_global() external view returns (uint256);
}

contract BaseFeeTest {
    // Provider to read current block's base fee
    IBaseFee internal constant baseFeeProvider = IBaseFee(0xf8d0Ec04e94296773cE20eFbeeA82e76220cD549);

    // Max acceptable base fee to take more debt or harvest
    uint256 public maxAcceptableBaseFee;

    constructor() public {
        maxAcceptableBaseFee = 60 * 1e9;
    }
    
    function setMaxAcceptableBaseFee(uint256 _maxAcceptableBaseFee) external {
        maxAcceptableBaseFee = _maxAcceptableBaseFee;
    }
    
    // Check if current block's base fee is under max allowed base fee
    function isCurrentBaseFeeAcceptable() public view returns (bool) {
        uint256 baseFee;
        try baseFeeProvider.basefee_global() returns (uint256 currentBaseFee) {
            baseFee = currentBaseFee;
        } catch {
            // Useful for testing until ganache supports london fork
            // Hard-code current base fee to 1000 gwei
            // This should also help keepers that run in a fork without
            // baseFee() to avoid reverting and potentially abandoning the job
            baseFee = 1000 * 1e9;
        }

        return baseFee <= maxAcceptableBaseFee;
    }
    
}