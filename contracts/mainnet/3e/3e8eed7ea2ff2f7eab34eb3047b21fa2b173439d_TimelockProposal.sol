/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    weth.transfer(wildDeployer, 288e18);

    // **** Salaries and operational expenses ****

    // Amount: 8.893 ETH + 1,500 USDC

    // Block range: 13240927 to 13830462
    // Last done at https://etherscan.io/address/0x682525E2AA0B4A07ED98aB9EA847556004b6914f#code

    // Transactions:

    // 0xecb579e39b3a552112ee4f9f33f15d2c809e9fecb96b309cf33221e146eba7c8
    // 0xdbdf9dde905b98daea3ea7f1c04c87a130a43984e114ec14c8b52a83c3d76bcd
    // 0xbd36e2c5664172774aa53d39412edfbd91e30ab0d9f25e4e5a0b7fb254408b08

    // 0x3c13d5aef598982094c0c389abad02f920d83ae499e5201ae88050aed461c243
    // 0x164726dd1b728cc62d91952c0f2d8b1e4239df21eb0abc25c98b004331374cdb
    // 0x85d55df576aeff251cbd729b8494ff67f1d3f55a22f34e70a9402cc8cb6e50a5
    // 0xc6d48143a449bfb1b44abf7a82496b01b511d3406479decf323a49938a927f8c
    // 0x1d6a49aa5bc8b3220de85601590fadbce5b09d141a515a80bd6500183a2a1d47
    // 0x5b9716c7ffe96aff3f56e195144e2ca69e0753cf49d963cc7e99139dc43dfd74
    // 0x8bc5aaeb5653596c4478913afe021920d3dfc51b5f25ae82aedcb66ddce67698
    // 0x89ae7ceb2cc08e051db7eb231d831c1a6909c5d810503d3bb3c6e33e720daeec
    // 0xb81f26b53924919858df8afbdf4ae6ac7a6cb3d0e8952026ca6e19c1e15881c9
    // 0xdccdc47a5698472c6ccd4bfffd5ba582a56734f36cd25e5cb614e7ae70793ac7
    // 0x1efc27a9e9bf40432ceef460756526be9fc330ff90116f9c49e3fb7ab6b80027
    // 0x7346a2f3c3c0580af2471f5b8fa4b14c008789fc98991442cd224892495d3463
    // 0x4f02e2751164b731ad7222d11b41cf0ee94ceef598acb4e8276ead0388d3de0a


    // ** Gas expenses **

    // Amount: 15.554 ETH

    // Block range: 13177424 to 13830462
    // Last done at https://etherscan.io/address/0xCaD102287eF073D68c029234FFB38D3aC2F74123#code


    // **** Protocol owned liquidity ****

    // Amount: 263.15 ETH

    // Use $1M of ETH + equal USD amount of WILD to lock ETH/WILD liquidity
    // $1,000,000 @ $3,800 per ETH = ~263.15 ETH


    // **** TOTAL: Expenses + liquidity ****

    // 24.842 + 263.15 = ~ 288 ETH
  }
}