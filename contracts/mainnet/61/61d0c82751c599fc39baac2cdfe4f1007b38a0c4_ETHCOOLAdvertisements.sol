pragma solidity ^0.4.24;

contract ETHCOOLAdvertisements {

    using SafeMath for uint;

    struct Advertisement {
        address user;
        string text;
        string link;
        uint expiry;
    }

    address public owner;
    uint public display_rate;
    uint public owner_share;

    ETHCOOLMain main_contract;
    Advertisement[] public advertisements;
    
    constructor() public {
        owner = msg.sender;
    }

    function publicGetStatus() view public returns (uint) {
        return (advertisements.length);
    }

    function publicGetAdvertisement(uint index) view public returns (address, string, string, uint) {
        return (advertisements[index].user, advertisements[index].text, advertisements[index].link, advertisements[index].expiry);
    }

    function ownerConfig(address main, uint rate, uint share) public {
        if (msg.sender == owner) {
            display_rate = rate;
            owner_share = share;
            main_contract = ETHCOOLMain(main);
        }
    }

    function userCreate(string text, string link) public payable {
        if (msg.value > 0) {
            uint expiry = now.add(msg.value.div(display_rate));
            Advertisement memory ad = Advertisement(msg.sender, text, link, expiry);
            advertisements.push(ad);
        }
    }

    function userTransfer() public {
        if (address(this).balance > 0) {
            main_contract.contractBoost.value(address(this).balance)(owner_share);
        }
    }
}

contract ETHCOOLMain {
    function contractBoost(uint share) public payable {}
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}