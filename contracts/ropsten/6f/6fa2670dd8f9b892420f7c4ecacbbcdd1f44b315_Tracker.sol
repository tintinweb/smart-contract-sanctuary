pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}


/*
House smart contract interface
*/
interface HouseContract {
     function owner() external view returns (address); 
     function isHouse() external view returns (bool);
     function isPlayer(address playerAddress) external view returns(bool);
}

/*
 * Kryptium Tracker Samrt Contract.  Copyright &#169; 2018 by Kryptium Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c7aea9a1a887acb5beb7b3aeb2aae9aea8">[email&#160;protected]</a>>.
 * Author: Giannis Zarifis <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f79d8d96859e919e84b79c858e87839e829ad99e98">[email&#160;protected]</a>>.
 */
contract Tracker is SafeMath, Owned {




    enum Action { added, updated}

    struct House {            
        uint upVotes;             
        uint downVotes;
        bool isActive;
        address oldAddress;
        address owner;
    }

    struct TrackerData { 
        string  name;
        string  creatorName;
        bool  managed;
        uint trackerVersion;
    }    


    TrackerData public trackerData;

    // This creates an array with all balances
    mapping (address => House) public houses;

    // Player has upvoted a House
    mapping (address => mapping (address => bool)) public playerUpvoted;

    // Player has downvoted a House
    mapping (address => mapping (address => bool)) public playerDownvoted;

    // Notifies clients that a house has insterted/altered
    event TrackerChanged(address indexed  newHouseAddress, Action action);

    // Notifies clients that a new tracker is launched
    event TrackerCreated();

    // Notifies clients that a Tracker names has has changed
    event TrackerNamesUpdated();    


    /**
     * Constructor function
     * Initializes Tracker data
     */
    constructor(string memory trackerName, string memory trackerCreatorName, bool trackerIsManaged, uint version) public {
        trackerData.name = trackerName;
        trackerData.creatorName = trackerCreatorName;
        trackerData.managed = trackerIsManaged;
        trackerData.trackerVersion = version;
        emit TrackerCreated();
    }

     /**
     * Update Tracker Data function
     *
     * Updates trackersstats
     */
    function updateTrackerNames(string memory newName, string memory newCreatorName) onlyOwner public {
        trackerData.name = newName;
        trackerData.creatorName = newCreatorName;
        emit TrackerNamesUpdated();
    }    

     /**
     * Add House function
     *
     * Adds a new house
     */
    function addHouse(address houseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(!houses[houseAddress].isActive,"There is a new version of House already registered");    
        HouseContract houseContract = HouseContract(houseAddress);
        require(houseContract.isHouse(),"Invalid House");
        houses[houseAddress].isActive = true;
        houses[houseAddress].owner = houseContract.owner();
        emit TrackerChanged(houseAddress,Action.added);
    }

    /**
     * Update House function
     *
     * Updates a house 
     */
    function updateHouse(address newHouseAddress,address oldHouseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(houses[oldHouseAddress].owner==msg.sender || houses[oldHouseAddress].owner==oldHouseAddress,"Caller isn&#39;t the owner of old House");
        require(!houses[newHouseAddress].isActive,"There is a new version of House already registered");  
        HouseContract houseContract = HouseContract(newHouseAddress);
        require(houseContract.isHouse(),"Invalid House");
        houses[oldHouseAddress].isActive = false;
        houses[newHouseAddress].isActive = true;
        houses[newHouseAddress].owner = houseContract.owner();
        houses[newHouseAddress].upVotes = houses[oldHouseAddress].upVotes;
        houses[newHouseAddress].downVotes = houses[oldHouseAddress].downVotes;
        houses[newHouseAddress].oldAddress = oldHouseAddress;
        emit TrackerChanged(newHouseAddress,Action.added);
        emit TrackerChanged(oldHouseAddress,Action.updated);
    }

     /**
     * Remove House function
     *
     * Removes a house
     */
    function removeHouse(address houseAddress) public {
        require(!trackerData.managed || msg.sender==owner,"Tracker is managed");
        require(houses[houseAddress].owner==msg.sender,"Caller isn&#39;t the owner of House");  
        houses[houseAddress].isActive = false;
        emit TrackerChanged(houseAddress,Action.updated);
    }

     /**
     * UpVote House function
     *
     * UpVotes a house
     */
    function upVoteHouse(address houseAddress) public {
        require(HouseContract(houseAddress).isPlayer(msg.sender),"Caller hasn&#39;t placed any bet");
        require(!playerUpvoted[msg.sender][houseAddress],"Has already Upvoted");
        playerUpvoted[msg.sender][houseAddress] = true;
        houses[houseAddress].upVotes += 1;
        emit TrackerChanged(houseAddress,Action.updated);
    }

     /**
     * DownVote House function
     *
     * DownVotes a house
     */
    function downVoteHouse(address houseAddress) public {
        require(HouseContract(houseAddress).isPlayer(msg.sender),"Caller hasn&#39;t placed any bet");
        require(!playerDownvoted[msg.sender][houseAddress],"Has already Downvoted");
        playerDownvoted[msg.sender][houseAddress] = true;
        houses[houseAddress].downVotes += 1;
        emit TrackerChanged(houseAddress,Action.updated);
    }    

    /**
     * Kill function
     *
     * Contract Suicide
     */
    function kill() onlyOwner public {
        selfdestruct(owner); 
    }

}