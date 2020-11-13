// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

library Constants {
    address constant CDP_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address constant PROXY_ACTIONS = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
    address constant MCD_JOIN_ETH_A = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address constant MCD_JOIN_USDC_A = 0xA191e578a6736167326d05c119CE0c90849E84B7;
    address constant MCD_JOIN_DAI = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address constant MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_END = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address constant UNISWAPV2_ROUTER2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bytes32 constant USDC_A_ILK = bytes32("USDC-A");
    bytes32 constant ETH_A_ILK = bytes32("ETH-A");
}
