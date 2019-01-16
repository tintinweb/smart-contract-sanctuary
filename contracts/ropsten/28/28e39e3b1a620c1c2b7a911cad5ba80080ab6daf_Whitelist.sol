pragma solidity >=0.4.22 <0.6.0;
///AddressSet stores based on:
///https://ethereum.stackexchange.com/questions/30305/how-to-create-an-array-of-unique-addresses
contract AddressSet {
    mapping (address => uint) index;
    address[] store;

    constructor() public {
        // We will use position 0 to flag invalid address
        store.push(address(0x0));
    }

    function pushAddress(address a) public {
        if (!inArray(a)) {
            index[a] = store.length;
            store.push(a);
        }
    }

    function inArray(address a) public view returns (bool) {
        if (a != address(0x0) && index[a] > 0) {
            return true;
        }
        return false;
    }
    
    function getLength() public view returns (uint) {
        return store.length - 1;
    }
}

contract Whitelist {
    
     ///Store the addresses of voters
     AddressSet voters = new AddressSet();
     
    ///Store reported actions along with the set of addresses that reported them
    mapping(bytes32 => address) actionsPool;
    
    ///Store the whitelist
    bytes32[] whitelist;
    
    ///Keep track of actions in the whitelist
    mapping(bytes32 => bool) whitelisted;
    
    uint minVoters = 3;
    
    function reportAction(bytes32 actionId) public{
        uint actionReports;
        uint totalVoters;
        
        ///Keep track of voters addresses.
        voters.pushAddress(msg.sender);
        
        ///Register the vote for this action.
        AddressSet set;
        if (actionsPool[actionId] == address(0x0)){
            set = new AddressSet();
            actionsPool[actionId] = address(set);
        } else {
            set = AddressSet(actionsPool[actionId]);
        }
        set.pushAddress(msg.sender);
        
        ///Get the number of votes for this action
        actionReports = set.getLength();
        
        ///Get the number of total voters
        totalVoters = voters.getLength();
        
        ///If this action has been reported by more than the half of voters, it&#39;s added to the whitelist.
        if ((totalVoters >= minVoters) && (!whitelisted[actionId]) && (totalVoters -  actionReports < actionReports)){
            whitelisted[actionId] = true;
            whitelist.push(actionId);
        }
    }
    
    function getWhitelist() public view returns(bytes32[] memory){
        ///Return the whitelist
        return whitelist;
    }
}