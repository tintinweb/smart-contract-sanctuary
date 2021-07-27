// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../ILendingPool.sol";

import "../ILendingPoolAddressesProvider.sol";


import "../IWETHGateway.sol";

contract AaveDeBo {

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
    }

    function depositETH() payable external {
        wETHGateway.depositETH(address(this), 0);
    }    

}