// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./libraries/Library.sol";
import "./utils/StringUtils.sol";
import "./interfaces/IFactoryProxy.sol";

contract Factory {
    
    // Price per Lineup creation
    uint256 public price = 1 * 10 ** 18;
    // Fee rate: 2% 
    uint256 public feeAmount = 1 * 10 ** 17;
    // Reward per player per lineup
    uint256 public playerRewardAmount = 1 * 10 ** 18;    
    // Week include 4 numbers
    // ex: 4th week in 2021 => 2104
    uint256 public week;
    // Players Limit for lineup
    uint256 public MAX_PLAYERS = 9;

    // Tournament counter
    uint256 public tn_counter;

    // Fee account
    address public fee_account;
    // Operator address
    address public operator_account;
    // Token address
    address public baseToken;
    // owner address
    address public owner;
    
    IFactoryProxy public proxyContract;
    // Mapping
    // Tournament Name => bool
    mapping(string => bool) public isTouranmentCreated;
    // TournamentInfo. 
    // week nounce => TournamentInfo
    mapping(uint256 => mapping(uint256 => Library.TournamentInfo)) public tournamentInfos;
    // Tours info array
    // tourId => tour
    mapping(uint256 => Library.Tour) public tours;
    
    // Tournament ID => Player Name => PlayerId;
    mapping(uint256 => mapping(string => uint256)) public playerId;
    // Player counts per tournament group
    // TourId => Player count
    mapping(uint256 => uint256) public playerCount;
    // Players array
    // TourId, PlayerID => Player
    mapping(uint256 => mapping(uint256 => Library.Player)) public playerList;

    // Points array
    // weekNounce => TourId => playerId => points
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public points;
    // uint256[1000][2000][10000] public points;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "operator: wut?");
        _;
    }
    // Event
    event TournamentCreate(string title, uint256 createdTime);
    // Player name, tournament Id, player Id
    event PlayerAdded(string name, uint256 tId, uint256 pId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address _operator, address _feeAccount, address _baseToken, address _proxyContract) {
        require(_operator != address(0x0), "Operator: address should be 0x0");
        require(_feeAccount != address(0x0), "Fee account: address should be 0x0");
        require(_baseToken != address(0x0), "BaseToken: address should be 0x0");

        operator_account = _operator;
        fee_account = _feeAccount;
        baseToken = _baseToken;
        owner = msg.sender;
        proxyContract = IFactoryProxy(_proxyContract);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Create tournament contract
    function createTournament (string memory title) external onlyOwner returns (address tour){
        require(!isTouranmentCreated[title], "Create Tournament: already created");
        isTouranmentCreated[title] = true;
        
        tour = proxyContract.createTournamentProxy(tn_counter, baseToken, operator_account);

        // Add tournament list
        Library.Tour storage newTour = tours[tn_counter];
        newTour.title = title;
        newTour.addr = tour;
        newTour.isActive = true;

        // Increase 'tournament' count
        tn_counter++;

        // fee_rate, price
        emit TournamentCreate(title, block.timestamp);
    }

    /**
      * Add player into spec tournament
      */
    function addPlayer (string memory name, uint256 tId,  Library.Role role_, address wallet_) external onlyOwner {
        require(!StringUtils.equal(name, ""), "Name should not be empty");

        uint256 player_id = playerId[tId][name];
        Library.Player memory playerInfo = playerList[tId][player_id];

        require(!StringUtils.equal(playerInfo.name, name), "This player has already been registered");
        
        // Get total count in spec tournament
        uint256 totalPlayerNumber = playerCount[tId];
        // PlayerID
        uint256 pId = totalPlayerNumber;
        
        Library.Player storage player = playerList[tId][pId];
        player.name = name;
        player.isActive = true;
        player.role = role_;
        player.wallet = wallet_;
        
        // mapping (TournamentID > Name > PlayerID);
        playerId[tId][name] = pId;

        // Update player count
        playerCount[tId] = totalPlayerNumber + 1;

        emit PlayerAdded(name, tId, pId);
    }

    /**
      * Update Player's Name
      */
    function updatePlayerName (uint256 tId, uint256 pId, string memory new_name) external onlyOwner {
        require(!StringUtils.equal(new_name, ""), "New name should not be empty");
        
        Library.Player storage player = playerList[tId][pId];
        require(!StringUtils.equal(player.name, ""), "This player does not exist");
        require(!StringUtils.equal(player.name, new_name), "This state was already set");

        player.name = new_name;
    }

    /**
     * Activate/Deactivate player's state
     */
    function updatePlayerState (uint256 tId, uint256 pId, bool state) external onlyOwner {
        Library.Player storage player = playerList[tId][pId];

        require(!StringUtils.equal(player.name, ""), "This name does not exist");
        require(player.isActive != state, "This state was already set");

        player.isActive = state;
    }

    /**
     * Update player's role
     */
    function updatePlayerRole (uint256 tId, uint256 pId, Library.Role role_) external onlyOwner {
        Library.Player storage player = playerList[tId][pId];

        require(!StringUtils.equal(player.name, ""), "This name does not exist");
        require(player.role != role_, "This role was already set");

        player.role = role_;
    }

    /**
     * Update address player's address
     */
    function updatePlayerAddress (uint256 tId, uint256 pId, address wallet_) external onlyOwner {
        Library.Player storage player = playerList[tId][pId];

        require(!StringUtils.equal(player.name, ""), "This name does not exist");
        require(player.wallet != wallet_, "This wallet was already set");

        player.wallet = wallet_;
    }

    /**
      * Increase week nounce
      */
    function increaseWeekNounce () external onlyOwner {
        week++;
    }
    /**
      * Decrease week nounce
      */
    function decreaseWeekNounce () external onlyOwner {
        week--;
    }

    // Update start time per tournament
    // Tournament ID, Week ID
    function updateTournamentStartPoint (uint256 tId, uint256 wId, uint256 start_ts) external  onlyOwner {
        Library.TournamentInfo storage tourInfo = tournamentInfos[wId][tId];

        require(tourInfo.startTime != start_ts, "This value has already been set");
        tourInfo.startTime = start_ts == 0 ? block.timestamp : start_ts;
    }
    
    // Update end time per tournament
    // Tournament ID, Week ID
    function updateTournamentEndPoint (uint256 tId, uint256 wId, uint256 end_ts) external  onlyOwner {
        Library.TournamentInfo storage tourInfo = tournamentInfos[wId][tId];

        require(tourInfo.endTime != end_ts, "This value has already been set");
        tourInfo.endTime = end_ts == 0 ? block.timestamp : end_ts;
    }

    // Cancel the tournament
    function setTourCancellation (uint256 tId, uint256 wId, bool _state) external onlyOwner {
        Library.TournamentInfo storage tourInfo = tournamentInfos[wId][tId];
        require(tourInfo.cancelled != _state, "This value has already been set");
        tourInfo.cancelled = _state;
    }

    // Update the tournament as active or not
    function setTourActive (uint256 tId, uint256 wId, bool _state) external onlyOwner {
        Library.TournamentInfo storage tourInfo = tournamentInfos[wId][tId];
        require(tourInfo.isActive != _state, "This value has already been set");
        tourInfo.isActive = _state;
    }

    // Tournament Id, Player Id
    function setPlayerPoints (uint256 tId, uint256 pId, uint256 point) external onlyOwner {
        Library.TournamentInfo memory tournamentInfo = tournamentInfos[week][tId];
        require(tournamentInfo.isActive, "This tournament is not available now");
        require(tournamentInfo.startTime <= block.timestamp, "Not started yet");
        require(points[week][tId][pId] != point, "Update point: same point");

        points[week][tId][pId] = point;
    }

    // Update operator address
    function updateOperatorAccount(address _operator) external onlyOwner {
        require(_operator != address(0x0), "Address should be 0x0");
        require(operator_account != _operator, "Operator: already exist");
        operator_account = _operator;
    }

    // Update fee account
    function updateFeeAccount(address _feeAccount) external onlyOwner {
        require(_feeAccount != address(0x0), "Address should be 0x0");
        require(fee_account != _feeAccount, "FeeAccount: already exist");
        fee_account = _feeAccount;
    }

    // Update baseToken address
    function updateBaseToken(address _baseToken) external onlyOwner {
        require(_baseToken != address(0x0), "Address should not be 0x0");
        require(baseToken != _baseToken, "Already exist token");
        baseToken = _baseToken;
    }

    // ======== Set properties ========= //
    // Change Price
    function setPrice (uint256 _price) external onlyOwner { 
        require(price != _price, "Price update: same price");
        price = _price; 
    }
    // Change fee rate
    function setPlayerRewardAmount (uint256 _playerRewardAmount) external onlyOwner { 
        require(playerRewardAmount != _playerRewardAmount, "Reward update: same reward");
        playerRewardAmount = _playerRewardAmount; 
    }
    // Change fee rate
    function setFeeRate (uint256 _feeAmount) external onlyOwner { 
        require(feeAmount != _feeAmount, "Fee update: same fee");
        feeAmount = _feeAmount; 
    }

    // =========== Get Data ========= //
    // Get tournament list
    function getTournaments () external view returns (Library.Tour[] memory tourList) {
        tourList = new Library.Tour[](tn_counter);
        for(uint256 idx = 0; idx < tn_counter; idx++) 
            tourList[idx] = tours[idx];
    }

    // Get one tournament info
    // tournament id and week id
    function getTournamentInfo (uint256 tId, uint256 wId) external view returns (Library.TournamentInfo memory tournamentInfo) {
        tournamentInfo = tournamentInfos[wId][tId];
    }

    // Get player's points
    function getPlayerPoint(uint256 wId, uint256 tId, uint256 pId) external view returns(uint256) {
        return points[wId][tId][pId];
    }

    // Get Player Info from player id
    // tId: Tournament ID,  pId: Player ID
    function getPlayerById (uint256 tId, uint256 pId) external view returns (Library.Player memory player) {
        player = playerList[tId][pId];
    }

    // Get Players
    function getPlayers (uint256 tId) external view returns (Library.Player[] memory) {
        uint256 player_count = playerCount[tId];
        Library.Player[] memory players = new Library.Player[](player_count);
        for(uint256 idx = 0; idx < player_count; idx++) {
            players[idx] = playerList[tId][idx];
        }

        return players;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Library {
    /**
      * 1 QB
      * 2 WR
      * 2 RB
      * 1 TE
      * 1 K
      * 2 Defense
      */
    enum Role { QB, WR, RB, TE, K, Defense }

    struct Player {
        string name;
        bool isActive;
        address wallet;
        Role role;
    }

    // Each tournament event weekly
    struct TournamentInfo {
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool cancelled;
    }

    // Define Tournament property
    struct Tour {
        string title;
        address addr; // address
        bool isActive;
    }

    struct LineUp {
        address owner;
        uint256[] playerIds;
        uint256 totalPoint;
        uint256 rank;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFactoryProxy {
    function createTournamentProxy(uint256 tn_counter, address baseToken, address operator_account) external returns(address tour);
}