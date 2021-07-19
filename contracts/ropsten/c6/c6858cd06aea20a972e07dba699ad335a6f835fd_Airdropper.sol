/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

pragma solidity ^0.8.6;

interface IERC20 { function transfer(address recipient, uint amount) external returns (bool); }

contract Airdropper {
    uint private constant TRANSFER_AMOUNT = 5000 * 10**9;
    address private immutable OWNER;
    IERC20 private immutable MMM;

    constructor(IERC20 _MMM) {
        OWNER = msg.sender;
        MMM = _MMM;
    }

    function distribute() external {
        require(msg.sender == OWNER);

        address[5] memory accounts = [
            0xE052eBc2624E62576Ca8a1B88bAAdE663b8a6174,
            0x643d7E1C51381133CF93aA97b4E2753a01383f90,
            0x26dc2cC02A184F75008e0601c21153684A0C6534,
            0xA5Ba7Caf7bF0C5c1C4Cb1fc7e75BA2310dbf013d,
            0x6CB4cAa27b0ce8a2778Eb19Da472Be1F09D25574
        ];

        for (uint i; i < accounts.length; i++) {
            MMM.transfer(accounts[i], TRANSFER_AMOUNT);
        }
    }
}