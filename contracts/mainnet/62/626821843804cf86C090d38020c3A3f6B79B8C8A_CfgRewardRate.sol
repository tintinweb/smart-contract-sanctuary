/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-14
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

    uint256 public dropInvestorRewardRate;
    uint256 public tinInvestorRewardRate;
    uint256 public aoRewardRate;

    event RateUpdate(uint256 newDropInvestorRewardRate, uint256 newTinInvestorRewardRate, uint256 newAoRewardRate);

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function get() public view returns (uint256, uint256, uint256) {
        return (dropInvestorRewardRate, tinInvestorRewardRate, aoRewardRate);
    }
    
    function set(uint256 dropInvestorRewardRate_, uint256 tinInvestorRewardRate_, uint256 aoRewardRate_) public auth {
        dropInvestorRewardRate = dropInvestorRewardRate_;
        tinInvestorRewardRate = tinInvestorRewardRate_;
        aoRewardRate = aoRewardRate_;
        emit RateUpdate(dropInvestorRewardRate, tinInvestorRewardRate, aoRewardRate);
    }

}