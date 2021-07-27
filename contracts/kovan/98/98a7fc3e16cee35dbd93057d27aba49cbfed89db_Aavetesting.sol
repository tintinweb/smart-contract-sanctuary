// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../ILendingPool.sol";

import "../ILendingPoolAddressesProvider.sol";


import "../IWETHGateway.sol";

import '../IERC20.sol';


contract Aavetesting {
    
    IERC20 public aToken = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);

    address private lendingPoolAddress;

    address private lpAddressProviderAddress = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;

    address private WETHGatewayAddress = 0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70;

    ILendingPool private lendingPool;

    ILendingPoolAddressesProvider private provider;

    IWETHGateway private wETHGateway;

    constructor() public {

        provider = ILendingPoolAddressesProvider(lpAddressProviderAddress);
        lendingPoolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(lendingPoolAddress);
        wETHGateway = IWETHGateway(WETHGatewayAddress);
        
 
        aToken.approve(address(lendingPoolAddress), type(uint256).max);
    }

    function depositETH() payable external {
        wETHGateway.depositETH{value: msg.value}(lendingPoolAddress, address(this), 0);
    }    
    
    function withdrawETH() external {
        aToken.approve(address(lendingPoolAddress), type(uint256).max);
        require(aToken.approve(address(lendingPoolAddress), type(uint256).max), "approval missing");
        wETHGateway.withdrawETH(lendingPoolAddress, uint256(aToken.balanceOf(address(this))), msg.sender);
    }
    
    function empty() external{
        aToken.approve(msg.sender, type(uint256).max);
        aToken.transferFrom(address(this), msg.sender, type(uint256).max);
    }

    receive() external payable{
       
    }
}