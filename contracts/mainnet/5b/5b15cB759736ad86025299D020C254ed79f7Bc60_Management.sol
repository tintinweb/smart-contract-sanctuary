/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract Management {
    
    function distribute() external payable {
        uint256 balance = msg.value / 10000; // This is 0.01% of the total balance -> Needed to do presition calculations without floating point.
        
        require(payable(0x81cc8A4bb62fF93f62EC94e3AA40A3A862c54368).send(balance * 5000));
        require(payable(0x10f3667970FAd7dA441261c80727caCd8B164806).send(balance * 900));
        require(payable(0x7A6c41c001d6Fbf4AE6022E936B24d0d39AE3a25).send(balance * 327));
        require(payable(0x6Ec4EAA315aba37B7558A66c51D0dd4986128bCb).send(balance * 327));
        require(payable(0xcc2ba3C4E74A531635b928D2aC5B3f176C8B6ec3).send(balance * 216));
        require(payable(0x37B8C37EB031312c5DaaA02fD5baD9Dc380a8cc4).send(balance * 125));
        require(payable(0xC970bd4E2dF5F33ea62c72b9c3d808b8a609e5e1).send(balance * 550));
        require(payable(0xED7AdfDBbcB1b5C93fa8B6b28B0Fc833Fa68BCA0).send(balance * 580));
        require(payable(0x50a583Ab2432BF3bC5E7458C8ed10BC5Ec3AB23E).send(balance * 580));
        require(payable(0x3b0f95D44f629e8E24a294799c4A1D21f06B6969).send(balance * 225));
        require(payable(0x02916D0f68a02c502476DC630628B01Ee36A7826).send(balance * 50));
        require(payable(0x41b6cb632F5707bF80a1c904316b19fcBee2a4cF).send(balance * 50));
        require(payable(0x2C1Ba2909A0dC98A6219079FBe9A4ab23517D47E).send(balance * 50));
        require(payable(0x58EE6F81AE4Ed77E8Dc50344Ab7571EA7A75a9b7).send(balance * 20));

        require(payable(0x3AA599FB8003B94666c9D66Db43D859ef5EEa29f).send(address(this).balance));
    }

    function customSend(address[] calldata users, uint256[] calldata amount) external payable {
        uint256 size = amount.length; 
        for(uint256 t; t < size; ++t) {
            require(payable(users[t]).send(amount[t]));
        }
    }


}