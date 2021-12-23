pragma solidity ^0.8.0;

contract TestEnum {
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE
    }

    mapping(Tier => uint256) public test1;
    mapping(uint8 => uint256) public test2;

    function getTier1(Tier tier) public view returns (uint256 value) {
        value = test1[tier];
    }

    function getTier2(uint8 tier) public view returns (uint256 value) {
        value = test2[tier];
    }

    function setTier1(Tier tier, uint256 value) public {
        test1[tier] = value;
    }
    function setTier2(uint8 tier, uint256 value) public {
        test2[tier] = value;
    }

}