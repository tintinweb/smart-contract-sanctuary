/**
 *Submitted for verification at Etherscan.io on 2017-12-25
 */

pragma solidity ^0.8.0;

contract EtherRock {
    struct Rock {
        address owner;
        bool currentlyForSale;
        uint256 price;
        uint256 timesSold;
    }

    struct RockInfo {
        address owner;
        bool currentlyForSale;
        uint256 price;
        uint256 timesSold;
    }

    event LogString(string output);

    mapping(uint256 => Rock) public rocks;

    mapping(address => uint256[]) public rockOwners;

    uint256 public latestNewRockForSale;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        rocks[0].price = 10**15;
        rocks[0].currentlyForSale = true;

        rocks[1].price = 10**15;
        rocks[1].currentlyForSale = true;

        rocks[2].price = 10**15;
        rocks[2].currentlyForSale = true;

        rocks[3].price = 10**15;
        rocks[3].currentlyForSale = true;

        owner = msg.sender;
    }

    function getRockInfo(uint256 rockNumber)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        return (
            rocks[rockNumber].owner,
            rocks[rockNumber].currentlyForSale,
            rocks[rockNumber].price,
            rocks[rockNumber].timesSold
        );
    }

    function getRockInfo2(uint256 rockNumber)
        public
        view
        returns (RockInfo memory)
    {
        RockInfo memory rock1 = RockInfo(
            rocks[rockNumber].owner,
            rocks[rockNumber].currentlyForSale,
            rocks[rockNumber].price,
            rocks[rockNumber].timesSold
        );
        return rock1;
    }

    function getRockInfoPrice(uint256 rockNumber)
        public
        view
        returns (uint256)
    {
        return rocks[rockNumber].price;
    }

    // function getRockInfo2(uint256 rockNumber) public view returns (address) {
    //     return rocks[rockNumber].owner;
    // }

    function rockOwningHistory(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return rockOwners[_address];
    }

    function buyRock(uint256 rockNumber) public payable {
        require(rocks[rockNumber].currentlyForSale == true);
        require(msg.value == rocks[rockNumber].price);
        rocks[rockNumber].currentlyForSale = false;
        rocks[rockNumber].timesSold++;
        if (rockNumber != latestNewRockForSale) {
            address payable ownerRock = payable(rocks[rockNumber].owner);
            ownerRock.transfer(rocks[rockNumber].price);
        }
        rocks[rockNumber].owner = msg.sender;
        rockOwners[msg.sender].push(rockNumber);
        if (rockNumber == latestNewRockForSale) {
            if (rockNumber != 99) {
                latestNewRockForSale++;
                rocks[latestNewRockForSale].price =
                    10**15 +
                    (latestNewRockForSale**2 * 10**15);
                rocks[latestNewRockForSale].currentlyForSale = true;
            }
        }
    }

    function sellRock(uint256 rockNumber, uint256 price) public payable {
        require(msg.sender == rocks[rockNumber].owner);
        require(price > 0);
        rocks[rockNumber].price = price;
        rocks[rockNumber].currentlyForSale = true;
    }

    function dontSellRock(uint256 rockNumber) public payable {
        require(msg.sender == rocks[rockNumber].owner);
        rocks[rockNumber].currentlyForSale = false;
    }

    function giftRock(uint256 rockNumber, address receiver) public payable {
        require(msg.sender == rocks[rockNumber].owner);
        rocks[rockNumber].owner = receiver;
        rockOwners[receiver].push(rockNumber);
    }

    function withdraw() public payable onlyOwner {
        // owner.transfer(this.balance);
        payable(owner).transfer(address(this).balance);
    }
}

