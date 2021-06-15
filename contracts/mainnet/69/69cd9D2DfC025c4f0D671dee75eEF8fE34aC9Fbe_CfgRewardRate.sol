/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.4.23 >=0.5.15;

// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

contract CfgRewardRate is Auth {

    uint256 public investorRewardRate;
    uint256 public aoRewardRate;

    event RateUpdate(uint256 newInvestorRewardRate, uint256 newAoRewardRate);

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function get() public view returns (uint256, uint256) {
        return (investorRewardRate, aoRewardRate);
    }
    
    function set(uint256 investorRewardRate_, uint256 aoRewardRate_) public auth {
        investorRewardRate = investorRewardRate_;
        aoRewardRate = aoRewardRate_;
        emit RateUpdate(investorRewardRate, aoRewardRate);
    }

}