// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/math/SafeMath.sol";

pragma solidity 0.6.12;
interface HermezVesting {
    function move(address recipient, uint256 amount) external;
    function changeAddress(address newAddress) external;
} 
interface HEZ {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BootstrapDistribution {
    using SafeMath for uint256;

    HEZ public constant TOKEN_ADDRESS = HEZ(0xEEF9f339514298C6A857EfCfC1A762aF84438dEE);
    HermezVesting public constant VESTING_0 = HermezVesting(0x8109dfB06D4d9e694a8349B855cBF493A0B22186);
    HermezVesting public constant VESTING_1 = HermezVesting(0xDd90cA911a5dbfB1624fF7Eb586901a9b4BFC53D);
    HermezVesting public constant VESTING_2 = HermezVesting(0xB213aeAeF76f82e42263fe896433A260EF018df2);
    HermezVesting public constant VESTING_3 = HermezVesting(0x3049399e1308db7d2b28488880C6cFE9Aa003275);
    address public constant MULTISIG_VESTING_2  = 0xC21BE548060cB6E07017bFc0b926A71b5E638e09;
    address public constant MULTISIG_VESTING_3  = 0x5Fa543E23a1B62e45d010f81AFC0602456BD1F1d;
    address public constant VESTING_0_ADDRESS_0 = 0x94E886bB17451A7B82E594db12570a5AdFC2D453;
    address public constant VESTING_0_ADDRESS_1 = 0x4FE10B3e306aC1F4b966Db07f031ae5780BC48fB;
    address public constant VESTING_0_ADDRESS_2 = 0x6629300128CCdda1e88641Ba2941a22Ce82F5df9;
    address public constant VESTING_0_ADDRESS_3 = 0xEb60e28Ce3aCa617d1E0293791c1903cF022b9Cd;
    address public constant VESTING_0_ADDRESS_4 = 0x9a415E0cE643abc4AD953B651b2D7e4db2FF3bEa;
    address public constant VESTING_0_ADDRESS_5 = 0x15b54c53093aF3e11d787db86e268a6C4F2F72A2;
    address public constant VESTING_0_ADDRESS_6 = 0x3279c71F132833190F6cd1D6a9975FFBf8d7C6dC;
    address public constant VESTING_0_ADDRESS_7 = 0x312e6f33155177774CDa1A3C4e9f077D93266063;
    address public constant VESTING_0_ADDRESS_8 = 0x47690A724Ed551fe2ff1A5eBa335B7c1B7a40990;
    address public constant VESTING_1_ADDRESS_0 = 0x80FbB6dd386FC98D2B387F37845A373c8441c069;
    address public constant VESTING_2_ADDRESS_0 = 0xBd48F607E26d94772FB21ED1d814F9F116dBD95C;
    address public constant VESTING_3_ADDRESS_0 = 0x520Cf70a2D0B3dfB7386A2Bc9F800321F62a5c3a;
    address public constant NO_VESTED_ADDRESS_0 = 0x4D4a7675CC0eb0a3B1d81CbDcd828c4BD0D74155;
    address public constant NO_VESTED_ADDRESS_1 = 0x9CdaeBd2bcEED9EB05a3B3cccd601A40CB0026be;
    address public constant NO_VESTED_ADDRESS_2 = 0x9315F815002d472A3E993ac9dc7461f2601A3c09;
    address public constant NO_VESTED_ADDRESS_3 = 0xF96A39d61F6972d8dC0CCd2A3c082eD922E096a7;
    address public constant NO_VESTED_ADDRESS_4 = 0xA93Bb239509D16827B7ee9DA7dA6Fc8478837247;
    address public constant NO_VESTED_ADDRESS_5 = 0x99Ae889E171B82BB04FD22E254024716932e5F2f;
    uint256 public constant VESTING_0_AMOUNT            = 20_000_000 ether;
    uint256 public constant VESTING_1_AMOUNT            = 10_000_000 ether;
    uint256 public constant VESTING_2_AMOUNT            =  6_200_000 ether;
    uint256 public constant VESTING_3_AMOUNT            = 17_500_000 ether;    
    uint256 public constant VESTING_0_ADDRESS_0_AMOUNT  = 12_000_000 ether;
    uint256 public constant VESTING_0_ADDRESS_1_AMOUNT  =  1_850_000 ether;
    uint256 public constant VESTING_0_ADDRESS_2_AMOUNT  =  1_675_000 ether;
    uint256 public constant VESTING_0_ADDRESS_3_AMOUNT  =  1_300_000 ether;
    uint256 public constant VESTING_0_ADDRESS_4_AMOUNT  =  1_000_000 ether;
    uint256 public constant VESTING_0_ADDRESS_5_AMOUNT  =    750_000 ether;
    uint256 public constant VESTING_0_ADDRESS_6_AMOUNT  =    625_000 ether;
    uint256 public constant VESTING_0_ADDRESS_7_AMOUNT  =    525_000 ether;
    uint256 public constant VESTING_0_ADDRESS_8_AMOUNT  =    275_000 ether;
    uint256 public constant VESTING_1_ADDRESS_0_AMOUNT  = 10_000_000 ether;
    uint256 public constant VESTING_2_ADDRESS_0_AMOUNT  =    500_000 ether;
    uint256 public constant VESTING_3_ADDRESS_0_AMOUNT  =    300_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_0_AMOUNT  = 19_000_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_1_AMOUNT  =  9_000_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_2_AMOUNT  =  7_500_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_3_AMOUNT  =  5_000_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_4_AMOUNT  =  3_000_000 ether;
    uint256 public constant NO_VESTED_ADDRESS_5_AMOUNT  =  2_800_000 ether;
    uint256 public constant INTERMEDIATE_BALANCE        = 46_300_000 ether;

    function distribute() public {
        require(
            TOKEN_ADDRESS.balanceOf(address(this)) == (100_000_000 ether), 
            "BootstrapDistribution::distribute NOT_ENOUGH_BALANCE"
        );

        // Vested Tokens
        // Transfer HEZ tokens
        TOKEN_ADDRESS.transfer(address(VESTING_0),VESTING_0_AMOUNT);
        TOKEN_ADDRESS.transfer(address(VESTING_1),VESTING_1_AMOUNT);
        TOKEN_ADDRESS.transfer(address(VESTING_2),VESTING_2_AMOUNT);
        TOKEN_ADDRESS.transfer(address(VESTING_3),VESTING_3_AMOUNT);
        // Transfer vested tokens
        transferVestedTokens0();
        transferVestedTokens1();
        transferVestedTokens2();
        transferVestedTokens3();

        // Check intermediate balance
        require(
            TOKEN_ADDRESS.balanceOf(address(this)) == INTERMEDIATE_BALANCE,
            "BootstrapDistribution::distribute NOT_ENOUGH_NO_VESTED_BALANCE"
        );

        // No Vested Tokens
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_0, NO_VESTED_ADDRESS_0_AMOUNT);
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_1, NO_VESTED_ADDRESS_1_AMOUNT);
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_2, NO_VESTED_ADDRESS_2_AMOUNT);
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_3, NO_VESTED_ADDRESS_3_AMOUNT);
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_4, NO_VESTED_ADDRESS_4_AMOUNT);
        TOKEN_ADDRESS.transfer(NO_VESTED_ADDRESS_5, NO_VESTED_ADDRESS_5_AMOUNT);

        require(
            TOKEN_ADDRESS.balanceOf(address(this)) == 0, 
            "BootstrapDistribution::distribute PENDING_BALANCE"
        );
    }

    function transferVestedTokens0() internal {
        VESTING_0.move(VESTING_0_ADDRESS_0, VESTING_0_ADDRESS_0_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_1, VESTING_0_ADDRESS_1_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_2, VESTING_0_ADDRESS_2_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_3, VESTING_0_ADDRESS_3_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_4, VESTING_0_ADDRESS_4_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_5, VESTING_0_ADDRESS_5_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_6, VESTING_0_ADDRESS_6_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_7, VESTING_0_ADDRESS_7_AMOUNT);
        VESTING_0.move(VESTING_0_ADDRESS_8, VESTING_0_ADDRESS_8_AMOUNT);
        VESTING_0.changeAddress(address(0));
    }

    function transferVestedTokens1() internal {
        VESTING_1.move(VESTING_1_ADDRESS_0, VESTING_1_ADDRESS_0_AMOUNT);
        VESTING_1.changeAddress(address(0));
    }

    function transferVestedTokens2() internal {
        VESTING_2.move(VESTING_2_ADDRESS_0, VESTING_2_ADDRESS_0_AMOUNT);
        VESTING_2.changeAddress(MULTISIG_VESTING_2);    
    }

    function transferVestedTokens3() internal {
        VESTING_3.move(VESTING_3_ADDRESS_0, VESTING_3_ADDRESS_0_AMOUNT);
        VESTING_3.changeAddress(MULTISIG_VESTING_3);  
    }
}