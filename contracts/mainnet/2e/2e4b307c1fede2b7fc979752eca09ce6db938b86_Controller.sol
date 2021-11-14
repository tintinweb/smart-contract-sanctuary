/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Controller {
    //For now the only thing this contract does is return the uniswap router.
    address public immutable uniswapRouter;         //uniswapV2Router
    address public immutable pools;                 //The AddressList contract of the pools. For testing this can just be an arbitrary address
    string private revertMessage;                   //This controller is a temporary test contract. Is meant to be relaplaced. This message is for the functions not implemented yet
     
    constructor(address _uniswapV2Router, address _pools, string memory _revertMessage) public{
        uniswapRouter = _uniswapV2Router;
        pools = _pools;
        revertMessage = _revertMessage;
    }

    function aaveReferralCode() external view returns (uint16){
        revert(revertMessage);
    }

    function feeCollector(address) external view returns (address){
        revert(revertMessage);
    }

    function founderFee() external view returns (uint256){
        revert(revertMessage);
    }

    function founderVault() external view returns (address){
        revert(revertMessage);
    }

    function interestFee(address _x) external view returns (uint256){
        revert(revertMessage);
    }

    function isPool(address _x) external view returns (bool){
        revert(revertMessage);
    }

    function strategy(address _x) external view returns (address){
        revert(revertMessage);
    }

    function rebalanceFriction(address _x) external view returns (uint256){
        revert(revertMessage);
    }

    function poolRewards(address _x) external view returns (address){
        revert(revertMessage);
    }

    function treasuryPool() external view returns (address){
        revert(revertMessage);
    }


    function withdrawFee(address) external view returns (uint256){
        revert(revertMessage);
    }

}