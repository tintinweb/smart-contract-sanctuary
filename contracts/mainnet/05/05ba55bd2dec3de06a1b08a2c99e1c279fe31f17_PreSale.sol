/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.8.4;

contract PreSale {
    event Buy(
        address indexed buyer,
        uint indexed packType,
        uint256 count
    );

    bool public isLocked = false;
    address public owner;

    uint256 public costCommon;
    uint256 public costRare;
    uint256 public costLegendary;

    uint256 public boughtCommonCount = 0;
    uint256 public boughtRareCount = 0;
    uint256 public boughtLegendaryCount = 0;

    uint256 public limitCommon;
    uint256 public limitRare;
    uint256 public limitLegendary;

    mapping (address => uint) public boughtCommon;
    mapping (address => uint) public boughtRare;
    mapping (address => uint) public boughtLegendary;

    address[] buyersCommon;
    address[] buyersRare;
    address[] buyersLegendary;

    uint256 public presaleStartTimestamp;

    constructor(
        uint256 _costCommon,
        uint256 _limitCommon,
        uint256 _costRare,
        uint256 _limitRare,
        uint256 _costLegendary,
        uint256 _limitLegendary,
        uint256 _presaleStartTimestamp) {
        owner = msg.sender;
        setParams(_costCommon, _limitCommon, _costRare, _limitRare, _costLegendary, _limitLegendary, _presaleStartTimestamp);
    }

    function setLocked(bool _isLocked) public onlyOwner{
        isLocked = _isLocked;
    }

    function setParams(uint256 _costCommon, uint256 _limitCommon, uint256 _costRare, uint256 _limitRare, uint256 _costLegendary, uint256 _limitLegendary, uint256 _presaleStartTimestamp) public onlyOwner {
        costCommon = _costCommon;
        costRare = _costRare;
        costLegendary = _costLegendary;
        limitCommon = _limitCommon;
        limitRare = _limitRare;
        limitLegendary = _limitLegendary;
        presaleStartTimestamp = _presaleStartTimestamp;
    }

    receive() external payable {
        require(false, 'Invalid payment value');
    }

    function buyCommonPacks() public payable saleIsRunning {
        uint256 packCount = msg.value / costCommon;
        require(packCount * costCommon == msg.value, "Invalid payment value");

        if (boughtCommon[msg.sender] == 0) {
            buyersCommon.push(msg.sender);
        }
        boughtCommon[msg.sender] += packCount;
        boughtCommonCount += packCount;
        require(boughtCommonCount <= limitCommon, "Not enough packs");
        emit Buy(msg.sender, 1, packCount);
    }

    function buyRarePacks() public payable saleIsRunning {
        uint256 packCount = msg.value / costRare;
        require(packCount * costRare == msg.value, "Invalid payment value");

        if (boughtRare[msg.sender] == 0) {
            buyersRare.push(msg.sender);
        }
        boughtRare[msg.sender] += packCount;
        boughtRareCount += packCount;
        require(boughtRareCount <= limitRare, "Not enough packs");
        emit Buy(msg.sender, 2, packCount);
    }

    function buyLegendaryPacks() public payable saleIsRunning {
        uint256 packCount = msg.value / costLegendary;
        require(packCount * costLegendary == msg.value, "Invalid payment value");

        if (boughtLegendary[msg.sender] == 0) {
            buyersLegendary.push(msg.sender);
        }
        boughtLegendary[msg.sender] += packCount;
        boughtLegendaryCount += packCount;
        require(boughtLegendaryCount <= limitLegendary, "Not enough packs");
        emit Buy(msg.sender, 3, packCount);
    }

    function getCommonResults(uint256 index) external view returns(address, uint256) {
        address addr = buyersCommon[index];
        return (addr, boughtCommon[addr]);
    }
    function getRareResults(uint256 index) external view returns(address, uint256) {
        address addr = buyersRare[index];
        return (addr, boughtRare[addr]);
    }
    function getLegendaryResults(uint256 index) external view returns(address, uint256) {
        address addr = buyersLegendary[index];
        return (addr, boughtLegendary[addr]);
    }
    function collectFunds(address payable transferTo) public onlyOwner {
        transferTo.send(address(this).balance);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier saleIsRunning {
        require(
            presaleStartTimestamp <= block.timestamp && isLocked == false,
            "Presale is not running"
        );
        _;
    }
}