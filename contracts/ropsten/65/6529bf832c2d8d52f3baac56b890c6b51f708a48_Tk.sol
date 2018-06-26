pragma solidity ^0.4.0;


contract TkAccessControl {
    address public owner;
    address public operatorAddress;

    constructor () public{
        owner = msg.sender;
        operatorAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function setOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));
        operatorAddress = _newOperator;
    }
}

contract Tk is TkAccessControl {

    string public name;

    struct Badge {
        uint24 date;
        int16 lat;
        int16 lng;
        uint24 memberCount;
        uint badgeId;
        string badgeName;
        string championName;
        string eventName;
    }


    Badge[] public badgeList;
    mapping (uint => uint) badgeToTkUser;

    mapping (uint => uint) tkUserBadgeCount;
    mapping(uint =>uint[]) public tkUserToBadge;

    function addBadge(
        uint24 _date,
        int16 _lat,
        int16 _lng,
        uint24 _memberCount,
        uint _badgeId,
        string _badgeName,
        string _championName,
        string _eventName,
        uint _tkUserId) public onlyOwner{
        uint id = badgeList.push( Badge(
                _date,
                _lat,
                _lng,
                _memberCount,
                _badgeId,
                _badgeName,
                _championName,
                _eventName
            ));
        tkUserToBadge[_tkUserId].push(id-1);
        badgeToTkUser[id] = _tkUserId;
        tkUserBadgeCount[id]++;
    }

    function getBadgeByKtUserId(uint _tkUserId) external view returns(uint[]){
        return tkUserToBadge[_tkUserId];
    }
    function getBadgeInfo(uint _badgeId) external view returns(
    // uint24,
    // int16,
    // int16,
    // uint24,
        uint badge_id,
        string badge_name,
        string champion_name
    // string
    ){
        return  (
        // badgeList[_badgeId].date,
        // badgeList[_badgeId].lat,
        // badgeList[_badgeId].lng,
        // badgeList[_badgeId].memberCount,
        badgeList[_badgeId].badgeId,
        badgeList[_badgeId].badgeName,
        badgeList[_badgeId].championName
        // badgeList[_badgeId].eventName
        );
    }
    function getEventInfo(uint _badgeId) external view returns(
        uint24 event_date,
        int16 lat,
        int16 lng,
        uint24 players_count,
    // uint,
    // string,
    // string,
        string event_name){
        return  (
        badgeList[_badgeId].date,
        badgeList[_badgeId].lat,
        badgeList[_badgeId].lng,
        badgeList[_badgeId].memberCount,
        // badgeList[_badgeId].badgeId,
        // badgeList[_badgeId].badgeName,
        // badgeList[_badgeId].championName,
        badgeList[_badgeId].eventName
        );
    }

}