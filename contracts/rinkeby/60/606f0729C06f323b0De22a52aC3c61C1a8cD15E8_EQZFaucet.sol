/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}


contract EQZFaucet {


    address[] tokens = [
    0xfC2Cca7326ab6bcF33ccF1911e1CdC37B2bbE21B,
    0x2c4CeD67fA1bb3612717484F016a5831FB20e690,
    0xF474A6482931bef44D161148A0905555b153FD18,
    0x2b37DB2f9bDE3993Aba2a3Dfb18826446F3feD65,
    0x1C99E66139836D24F97A57A5Cffcaa7668e05Dd5,
    0xEA8218bbE0D4A48AF14e91dff0E83100f236dd04,
    0xfe3eBaCE14DFE231e17c0A3B36A6c7Dd3B0a8eD2,
    0xBA74fd634725E3d275E508f41D5981220eaE13c5,
    0x02709F261A0A77C1E04455aBceC38A1364435855,
    0x65608b4fF7Ed8E45DBc0dc4c62C11Bb8444046a1,
    0x1437436A82CebA2d2c0324067d0ed3445A9Efc41,
    0x0e041a97C2c7C37aDa54B9Eea6D3B83ed7Cb4419,
    0xAA6E82177021011B29c285d8021f7344Dd7887A1,
    0xbf202177CbE7ABb34cE51C7e6B06Be83b81DBA10,
    0x2bE054308bd34588fC47B668Ed44CDbdd79b59fC,
    0x01F7FeEB77aE5e04d9606C209a7faFf2187Cd5c1
    ];

    mapping (address => bool) addressFilled;

    function random() public view returns (uint8, uint8, uint8)
    {
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        uint8 tlength = uint8(tokens.length);
        uint8 random1 = uint8(uint256(randomHash)% tlength);
        uint8 random2 = (random1 + tlength / 4)% tlength;
        uint8 random3 = (random1 + 2 * tlength / 4)% tlength;

        return (random1, random2, random3);

    }

    function faucet() public {
        require (addressFilled[msg.sender] == false, "Already Requested");
        addressFilled[msg.sender] = true;
        (uint8 index1, uint8 index2, uint8 index3) = random();

        require(IERC20(tokens[index1]).transfer(msg.sender, 1000 * 10 ** IERC20(tokens[index1]).decimals()), "transfer failed");
        require(IERC20(tokens[index2]).transfer(msg.sender, 1000 * 10 ** IERC20(tokens[index2]).decimals()), "transfer failed");
        require(IERC20(tokens[index3]).transfer(msg.sender, 1000 * 10 ** IERC20(tokens[index3]).decimals()), "transfer failed");

    }

    fallback () external {
        faucet();
    }
}