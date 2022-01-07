/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// File: contracts\ClaimVecrvFees.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFeeClaim{
    function claim(address) external;
    function claim_many(address[20] calldata ) external;
    function last_token_time() external view returns(uint256);
    function time_cursor() external view returns(uint256);
    function time_cursor_of(address) external view returns(uint256);
    function user_epoch_of(address) external view returns(uint256);
    function user_point_epoch(address) external view returns(uint256);
    function earmarkFees() external returns(bool);
    function balanceOf(address) external view returns(uint256);
}

//Claim vecrv fees and distribute
contract ClaimVecrvFees{

    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant vecrv = address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
    address public constant feeClaim = address(0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc);
    address public constant account = address(0x989AEb4d175e16225E39E87d0D97A3360524AD80);
    address public constant tokenaddress = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    uint256 public lastTokenTime;

    constructor() public {}

    function getName() external pure returns (string memory) {
        return "ClaimVecrvFees V1.0";
    }

    function claimFees() external {
        uint256 tokenTime = IFeeClaim(feeClaim).last_token_time();
        require(tokenTime > lastTokenTime, "not time yet");
        uint256 bal = IFeeClaim(tokenaddress).balanceOf(account);
        IFeeClaim(feeClaim).claim(account);

        while(IFeeClaim(tokenaddress).balanceOf(account) <= bal){
            IFeeClaim(feeClaim).claim(account);
        }

        IFeeClaim(booster).earmarkFees();
        lastTokenTime = tokenTime;
    }

}