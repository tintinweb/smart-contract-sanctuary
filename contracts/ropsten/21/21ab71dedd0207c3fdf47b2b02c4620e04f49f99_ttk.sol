pragma solidity ^0.4.0;
contract ttk {
    
    struct Badge {
        string eventName;
    }
    
    Badge[] public badgeList;
    mapping (uint => uint) badgeToTkUser;
    
    mapping (uint => uint) tkUserBadgeCount;
    mapping(uint =>uint[]) public tkUserToBadge;
    
    function addBadge(string _eventName, uint _tkUserId){
        uint id = badgeList.push( Badge(_eventName));
        tkUserToBadge[_tkUserId].push(id-1);
        badgeToTkUser[id] = _tkUserId;
        tkUserBadgeCount[id]++;
    }
    
    function getBadgeByKtUserId(uint _tkUserId) external view returns(uint[]){
        return tkUserToBadge[_tkUserId];
    }
}