pragma solidity ^0.8.0;

interface ITier {
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE
    }
    struct Father {
        uint256 son;
        uint256 daughter;
        uint256 wife;
    }
}

contract TestEnum {

    ITier.Tier one = ITier.Tier.ONE;
    mapping(ITier.Tier => uint256) public test1;
    mapping(uint8 => uint256) public test2;

    struct IOS {
        uint lame;
        ITier.Tier tier;
    }

    mapping(uint => IOS) public strange;

    function getTier1(ITier.Tier tier) public view returns (uint256 value) {
        value = test1[tier];
    }

    function getTier2(uint8 tier) public view returns (uint256 value) {
        value = test2[tier];
    }

    function setTier1(ITier.Tier tier, uint256 value) public {
        test1[tier] = value;
    }

    function setTier2(uint8 tier, uint256 value) public {
        test2[tier] = value;
    }

    function returnTier() public view returns (ITier.Tier) {
        return one;
    }

    function writeTier() public view returns (ITier.Tier tier) {
        tier = returnTier();
    }

    function setStrange(uint index,IOS memory ios) external {
        strange[index] = ios;
    }

}