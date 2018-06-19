pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Etharea {
    using SafeMath for uint;
    struct Area {
        string id;
        uint price;
        address owner;
        uint lastUpdate;
    }

    address manager;
    Area[] public soldAreas;
    mapping(string => address) areaIdToOwner;
    mapping(string => uint) areaIdToIndex;
    mapping(string => bool) enabledAreas;
    uint public defaultPrice = 0.01 ether;

    modifier onlyOwner() {
        require(manager == msg.sender);
        _;
    }

    modifier percentage(uint percents) {
        require(percents >= 0 && percents <= 100);
        _;
    }

    function Etharea() public {
        manager = msg.sender;
    }

    function buy(string areaId) public payable {
        require(msg.sender != address(0));
        require(!isContract(msg.sender));
        require(areaIdToOwner[areaId] != msg.sender);
        require(enabledAreas[areaId]);
        if (areaIdToOwner[areaId] == address(0)) {
            firstBuy(areaId);
        } else {
            buyFromOwner(areaId);
        }
        manager.transfer(address(this).balance);
    }

    function firstBuy(string areaId) private {
        uint priceRisePercent;
        (priceRisePercent,) = getPriceRiseAndFeePercent(defaultPrice);
        require(msg.value == defaultPrice);
        Area memory newArea = Area({
            id: areaId,
            price: defaultPrice.div(100).mul(priceRisePercent.add(100)),
            owner: msg.sender,
            lastUpdate: now
            });

        uint index = soldAreas.push(newArea).sub(1);
        areaIdToIndex[areaId] = index;
        areaIdToOwner[areaId] = msg.sender;
    }

    function buyFromOwner(string areaId) private {
        Area storage areaToChange = soldAreas[areaIdToIndex[areaId]];
        require(msg.value == areaToChange.price);

        uint priceRisePercent;
        uint transactionFeePercent;
        (priceRisePercent, transactionFeePercent) = getPriceRiseAndFeePercent(areaToChange.price);
        address oldOwner = areaIdToOwner[areaId];
        uint payment = msg.value.div(100).mul(uint(100).sub(transactionFeePercent));
        uint newPrice = areaToChange.price.div(100).mul(priceRisePercent.add(100));

        areaToChange.owner = msg.sender;
        areaToChange.lastUpdate = now;
        areaIdToOwner[areaId] = msg.sender;
        areaToChange.price = newPrice;
        oldOwner.transfer(payment);
    }

    function getSoldAreasCount() public view returns (uint) {
        return soldAreas.length;
    }

    function getBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

    function getAreaOwner(string areaId) public view returns (address) {
        return areaIdToOwner[areaId];
    }

    function getAreaIndex(string areaId) public view returns (uint) {
        uint areaIndex = areaIdToIndex[areaId];
        Area memory area = soldAreas[areaIndex];
        require(keccak256(area.id) == keccak256(areaId));
        return areaIndex;
    }

    function setDefaultPrice(uint newPrice) public onlyOwner {
        defaultPrice = newPrice;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        manager.transfer(address(this).balance);
    }

    function getPriceRiseAndFeePercent(uint currentPrice)
    public pure returns (uint, uint)
    {
        if (currentPrice >= 0.01 ether && currentPrice < 0.15 ether) {
            return (100, 10);
        }

        if (currentPrice >= 0.15 ether && currentPrice < 1 ether) {
            return (60, 6);
        }

        if (currentPrice >= 1 ether && currentPrice < 4 ether) {
            return (40, 5);
        }

        if (currentPrice >= 4 ether && currentPrice < 10 ether) {
            return (30, 4);
        }

        if (currentPrice >= 10 ether) {
            return (25, 3);
        }
    }

    function enableArea(string areaId) public onlyOwner {
        require(!enabledAreas[areaId]);
        enabledAreas[areaId] = true;
    }

    function isAreaEnabled(string areaId) public view returns (bool) {
        return enabledAreas[areaId];
    }

    function isContract(address userAddress) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(userAddress) }
        return size > 0;
    }
}