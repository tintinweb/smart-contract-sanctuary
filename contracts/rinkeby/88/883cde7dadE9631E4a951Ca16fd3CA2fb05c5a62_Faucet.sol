/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.6;

interface ITestERC20 {
    function mint(address to, uint256 amount) external;
}

contract Faucet {
    function mint(address to) external {
        // DAI
        ITestERC20(0x3d7f960fCFb7B22A583a80a776436A8D3C08e07d).mint(to, 10000 ether);

        // RBN
        ITestERC20(0x8799b1095ba49f499ab66B9bfA8F6d2AC4e62E6B).mint(to, 10_000 ether);

        // UDSC
        ITestERC20(0xF1c735564171B8728911aDaACbEcA1A23294aA98).mint(to, 10 gwei);

        // WBTC
        ITestERC20(0x3A9C311DB4545D72AE0e47d2fd89c51A4501Abe4).mint(to, 1000000);

        // YFI
        ITestERC20(0xa8Daa10c0E6dDF98c5E64f1Ee5331b1368581e54).mint(to, 1 ether);
    }
}