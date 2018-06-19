pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StorageBase is Ownable {

    function withdrawBalance() external onlyOwner returns (bool) {
        // The owner has a method to withdraw balance from multiple contracts together,
        // use send here to make sure even if one withdrawBalance fails the others will still work
        bool res = msg.sender.send(address(this).balance);
        return res;
    }
}

// owner of ActivityStorage should be ActivityCore contract address
contract ActivityStorage is StorageBase {

    struct Activity {
        // accept bid or not
        bool isPause;
        // limit max num of monster buyable per address
        uint16 buyLimit;
        // price (in wei)
        uint128 packPrice;
        // startDate (in seconds)
        uint64 startDate;
        // endDate (in seconds)
        uint64 endDate;
        // packId => address of bid winner
        mapping(uint16 => address) soldPackToAddress;
        // address => number of success bid
        mapping(address => uint16) addressBoughtCount;
    }

    // limit max activityId to 65536, big enough
    mapping(uint16 => Activity) public activities;

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
    {
        // activity should not exist and can only be initialized once
        require(activities[_activityId].buyLimit == 0);

        activities[_activityId] = Activity({
            isPause: false,
            buyLimit: _buyLimit,
            packPrice: _packPrice,
            startDate: _startDate,
            endDate: _endDate
        });
    }

    function sellPackToAddress(
        uint16 _activityId, 
        uint16 _packId, 
        address buyer
    ) 
        external 
        onlyOwner
    {
        Activity storage activity = activities[_activityId];
        activity.soldPackToAddress[_packId] = buyer;
        activity.addressBoughtCount[buyer]++;
    }

    function pauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = true;
    }

    function unpauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = false;
    }

    function deleteActivity(uint16 _activityId) external onlyOwner {
        delete activities[_activityId];
    }

    function getAddressBoughtCount(uint16 _activityId, address buyer) external view returns (uint16) {
        return activities[_activityId].addressBoughtCount[buyer];
    }

    function getBuyerAddress(uint16 _activityId, uint16 packId) external view returns (address) {
        return activities[_activityId].soldPackToAddress[packId];
    }
}