/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBaseFee {
    function basefee_global() external view returns (uint256);
}

contract BaseFeeOracle {
    // Provider to read current block's base fee
    IBaseFee internal constant baseFeeProvider = IBaseFee(0xf8d0Ec04e94296773cE20eFbeeA82e76220cD549);

    // Max acceptable base fee for the operation
    uint256 public maxAcceptableBaseFee;

    // Daddy can grant and revoke access to the setter
    address internal constant gov = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
    
    // SMS is authorized by default
    address internal constant brain = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;
    
    // Addresses that can set the max acceptable base fee
    mapping(address => bool) public authorizedAddresses;
    
    constructor() public {
        maxAcceptableBaseFee = 80 gwei;
        authorizedAddresses[brain] = true;
    }
    
    function isCurrentBaseFeeAcceptable() public view returns (bool) {
        uint256 baseFee;
        try baseFeeProvider.basefee_global() returns (uint256 currentBaseFee) {
            baseFee = currentBaseFee;
        } catch {
            // Useful for testing until ganache supports london fork
            // Hard-code current base fee to 1000 gwei
            // This should also help keepers that run in a fork without
            // baseFee() to avoid reverting and potentially abandoning the job
            baseFee = 1000 gwei;
        }

        return baseFee <= maxAcceptableBaseFee;
    }
    
    function setMaxAcceptableBaseFee(uint256 _maxAcceptableBaseFee) external {
        _onlyAuthorized();
        maxAcceptableBaseFee = _maxAcceptableBaseFee;
    }
    
    function setAuthorized(address _target) external {
        _onlyGovernance();
        authorizedAddresses[_target] = true;
    }

    function revokeAuthorized(address _target) external {
        _onlyGovernance();
        authorizedAddresses[_target] = false;
    }
    
    function _onlyAuthorized() internal view {
        require(authorizedAddresses[msg.sender] == true, "!authorized");
    }

    function _onlyGovernance() internal view {
        require(msg.sender == gov, "!governance");
    }
    
}