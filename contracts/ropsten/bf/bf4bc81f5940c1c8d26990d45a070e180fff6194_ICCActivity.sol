pragma solidity ^0.4.24;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ICCActivity is Ownable {
    constructor () public {
        emit ActivityCreatedEvent();
    }
    
    struct Activity {
        string activityID;
        string content;
    }

    Activity[] public activities;

    event ActivityRecordedEvent(uint256 length, string activityID, string content);
    event ActivityCreatedEvent();

    function getNumActivities() public view returns (uint) {
        return activities.length;
    }

    function getActivity(uint activityInt) public view returns (string activityID, string content) {
        if (activities.length > 0) {
            Activity storage a = activities[activityInt];
            return (a.activityID, a.content);
        }
    }

    function addActivity(string activityID, string content) public onlyOwner {
        Activity memory activity;
        activity.activityID = activityID;
        activity.content = content;
        activities.push(activity);
        emit ActivityRecordedEvent(activities.length, activityID, content);
    }
}