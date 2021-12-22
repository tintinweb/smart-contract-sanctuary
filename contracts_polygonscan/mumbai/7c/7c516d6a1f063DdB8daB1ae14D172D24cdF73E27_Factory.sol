// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ITournament.sol";
import "./Tournament.sol";
import "./utils/StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    
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

    // Event
    event TournamentCreate(string title, uint256 createdTime);
    // Player name, tournament Id, player Id
    event PlayerAdded(string name, uint256 tId, uint256 pId);

    constructor (address _operator, address _feeAccount, address _baseToken) {
        require(_operator != address(0x0), "Operator: address should be 0x0");
        require(_feeAccount != address(0x0), "Fee account: address should be 0x0");
        require(_baseToken != address(0x0), "BaseToken: address should be 0x0");

        operator_account = _operator;
        fee_account = _feeAccount;
        baseToken = _baseToken;
    }

    // Create tournament contract
    function createTournament (string memory title) external onlyOwner returns (address tour){
        require(!isTouranmentCreated[title], "Create Tournament: already created");
        isTouranmentCreated[title] = true;

        // create tournament
        bytes memory bytecode = type(Tournament).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tn_counter, baseToken, operator_account));
        assembly {
            tour := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ITournament(tour).initialize(tn_counter, baseToken, operator_account);

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

    // Get one tournament
    function getTournament (uint256 idx) external view returns (Library.Tour memory tour) {
        tour = tours[idx];
    }

    // Get one tournament info
    // tournament id and week id
    function getTournamentInfo (uint256 tId, uint256 wId) external view returns (Library.TournamentInfo memory tournamentInfo) {
        tournamentInfo = tournamentInfos[wId][tId];
    }

    // Get Player Id from player name
    // tId: Tournament ID,  name: Player Name
    function getPlayerIdByName (uint256 tId, string memory name) external view returns (uint256) {
        return playerId[tId][name];
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

interface ITournament {
    function initialize (uint256 _tourId, address _baseToken, address _operatorAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/Library.sol";

interface IFactory{
    // Get
    function MAX_PLAYERS() external view returns(uint256);
    function price() external view returns(uint256);
    function feeAmount() external view returns(uint256);
    function playerRewardAmount() external view returns(uint256);    
    function week() external view returns(uint256);
    function fee_account() external view returns(address);
    function getTournamentInfo (uint256 tId, uint256 wId) external view returns (Library.TournamentInfo memory);
    // function points(uint256 weekNounce, uint256 tourId, uint256 playerId) external view returns(uint256);
    function getPlayerPoint(uint256 wId, uint256 tId, uint256 pId ) external view returns(uint256);
    // Get Player Info from player id
    function getPlayerById (uint256 tId, uint256 pId) external view returns (Library.Player memory);
    // function playerList(uint256 tourId, uint256 playerId) external view returns (Library.Player memory player);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFactory.sol";

contract Tournament {

    IFactory public factory;

    // Token for payable 
    IERC20 public baseToken;
    /** Entry = Lineup
      * How many lineups does this tournament have in max? 1 Lineup has 9 players combination.
      */
    uint256 constant public MAX_ENTRIES = 125;
    // Line entries
    Library.LineUp[MAX_ENTRIES] public lineups;

    // Tournament ID0
    uint256 public tourId;
    address public operatorAddress;

    address public factory_address;
    /**
      * Increase entry number whenever user submit lineup
      */
    uint256 public entry_counter = 0;
    // Admin can withdraw fee
    uint256 public totalFeeCollected;
    // Pool total balance
    uint256 public totalTokenBalance = 0;

    // Calculate the reward by rank and same rank counts
    // For example
    // Rank 1: 70 % of total balance
    // Rank 2: 27 % of total balance
    // Rank 3: 3 % of total balance
    uint256[] percentPerRank = [70, 27, 3];

    // Players' balance from lineup
    // Wallet => Reward Amount
    mapping(address => uint256) playerRewards;
    
    // mapping
    mapping(address => bool) userSubmitted;

    // isSorted
    // bool public isSorted = false;
    // === Events ===
    event LineupSubmit (address indexed creator, uint256 _timestamp);
        
    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }

    // modifier
    modifier marketNotFilled {
        require(entry_counter <= MAX_ENTRIES, "Exceed the max entries");
        _;
    }

    modifier marketStarted {
        uint256 wId = factory.week();
        Library.TournamentInfo memory tournamentInfo = factory.getTournamentInfo(tourId, wId);
        require(tournamentInfo.startTime > block.timestamp, "Market started already");
        _;
    }

    modifier claimable {
        uint256 wId = factory.week();
        Library.TournamentInfo memory tournamentInfo = factory.getTournamentInfo(tourId, wId);
        bool claimable_ = tournamentInfo.endTime < block.timestamp;
        require(claimable_, "Not able to claim yet");
        require(tournamentInfo.cancelled == false, "Claim: market cancelled");
        _;
    }

    modifier refundable {
        require(userSubmitted[msg.sender], "Refund: you have no right to refund");
        
        uint256 wId = factory.week();
        Library.TournamentInfo memory tournamentInfo = factory.getTournamentInfo(tourId, wId);
        require(tournamentInfo.cancelled, "Refund: not cancelled");
        _;
    }

    constructor () {
        factory = IFactory(msg.sender);
        factory_address = msg.sender;
    }

    /**
      * This contract will be created by Factory contract.
      * _title: Tournament name
      * _baseToken: Token for pay
      * _price: Price for lineup creation
      */
    function initialize (
        uint256 _tourId, 
        address _baseToken,
        address _operatorAddress
    ) external {
        require(factory_address == msg.sender, "Not factory contract");

        tourId = _tourId;
        baseToken = IERC20(_baseToken);
        operatorAddress = _operatorAddress;
    }

    // Check if input one player twice
    function isValidPlayers(uint256[] memory playerIds) internal view returns(bool) {
        // It was fixed with 9
        if(playerIds.length != factory.MAX_PLAYERS()) return false;
        
        // check if customer submit same player in a line up
        for(uint256 idx = 0; idx < playerIds.length; idx++) {
            // check if player can be selected
            Library.Player memory player = factory.getPlayerById(tourId, playerIds[idx]);
            if(player.isActive == false) return false;

            for(uint256 idy = idx + 1; idy < playerIds.length; idy++) {
                if(playerIds[idx] == playerIds[idy]) return false;
            }
        }
        return true;
    }

    // Check if the pair has valid roles
    function isValidPair(uint256[] memory playerIds) internal view returns(bool) {
        uint256 QB = 0;
        uint256 WR = 0;
        uint256 RB = 0;
        uint256 TE = 0;
        uint256 Defense = 0;
        uint256 K = 0;        

        for(uint256 idx = 0; idx < playerIds.length; idx++) {
            // check if player can be selected
            Library.Player memory player = factory.getPlayerById(tourId, playerIds[idx]);

            if(player.role == Library.Role.QB) QB++;
            if(player.role == Library.Role.WR) WR++;
            if(player.role == Library.Role.RB) RB++;
            if(player.role == Library.Role.TE) TE++;
            if(player.role == Library.Role.Defense) Defense++;
            if(player.role == Library.Role.K) K++;
        }

        if(QB != 1) return false;
        if(WR != 2) return false;
        if(RB != 2) return false;
        if(TE != 1) return false;
        if(K != 1) return false;
        if(Defense != 2) return false;
        
        return true;
    }

    // Update Rewards per player
    function updatePlayerRewards (uint256[] memory playerIds) internal {
        for(uint256 idx = 0; idx < playerIds.length; idx++) {
            Library.Player memory player = factory.getPlayerById(tourId, playerIds[idx]);

            playerRewards[player.wallet] = playerRewards[player.wallet] + factory.playerRewardAmount();
        }
    }

    // This value will be used for approve token in the client side.
    function GetTotalPriceForLineup () external view returns (uint256 totalAmount) {
        totalAmount = factory.price() + factory.playerRewardAmount() * factory.MAX_PLAYERS() + factory.feeAmount();
    }

    // User submits a lineup to contract
    function SubmitLineup(uint256[] calldata playerIds) marketNotFilled marketStarted external {
        require(isValidPlayers(playerIds), "Submit: Lineup is not valid: double seleted");
        require(isValidPair(playerIds), "Submit: Lineup is not valid pair");

        userSubmitted[msg.sender] = true;

        // Need to approve token transfer
        // Calculate total amount for lineup price + player's price
        // This amount would be come into contract
        uint256 amount = factory.price() + factory.feeAmount() + factory.playerRewardAmount() * factory.MAX_PLAYERS();
        baseToken.transferFrom(msg.sender, address(this), amount);

        // Update the rewards for players
        updatePlayerRewards(playerIds);

        // uint256 fee = factory.feeAmount();
        // sendFeeToAccount(msg.sender, fee);
        totalFeeCollected = totalFeeCollected + factory.feeAmount();

        // add amount to get total balance of tokens
        totalTokenBalance += factory.price();

        // add lineups
        Library.LineUp storage lineup = lineups[entry_counter];
        lineup.owner = msg.sender;
        lineup.playerIds = playerIds;
        
        entry_counter++;

        emit LineupSubmit(msg.sender, block.timestamp);
    }

    // Get top Lineups
    function getTop3Lineups() public view returns(Library.LineUp[] memory topLines) {
        uint256 arrIdx = 0;
        uint256 cnt = 0;
        uint256 curPoint = 10 ** 18; // Set Max
        for(uint256 idx = 0; idx < entry_counter; idx++) {
            // we will take only 3
            if(cnt > 2) break;
            if( lineups[idx].totalPoint <= curPoint) {
                topLines[arrIdx] = lineups[idx];
                topLines[arrIdx].rank = cnt;

                arrIdx++;          
                if( lineups[idx].totalPoint <= curPoint) {
                    cnt++;
                    curPoint = lineups[idx].totalPoint;
                }
            }
        }
    }

    // Sort out result based on total point
    // This should be called only once 
    function sortLineUps() external onlyOperator {
        // require(isSorted == false, "Already sorted Lines");
        // isSorted = true;
        Library.LineUp[] memory memoLineups = new Library.LineUp[](entry_counter);

        for(uint256 idx = 0; idx < entry_counter; idx++) {
            memoLineups[idx] = lineups[idx];
        }
        sort(memoLineups);

        for(uint256 idx = 0; idx < entry_counter; idx++) {
            lineups[idx] = memoLineups[idx];
        }
    }


    function sort(Library.LineUp[] memory data) internal view {
        for(uint256 idx = 0; idx < data.length; idx++) {
            uint256 sum = 0;
            for(uint256 idy = 0; idy < data[idx].playerIds.length; idy++) {
                uint256 playerId = data[idx].playerIds[idy];
                uint256 wId = factory.week();
                
                uint256 point = factory.getPlayerPoint(wId, tourId, playerId);
                // Calculate the sum of points
                sum = sum + point; // 
            }
            data[idx].totalPoint = sum;
        }
        quickSort(data, 0, data.length - 1);
        // return data;
    }

    // function totalPoint
    function quickSort(Library.LineUp[] memory arr, uint256 left, uint256 right) pure internal {
        uint256 i = left;
        uint256 j = right;
        if (i == j) return;

        uint256 pivot = arr[left + (right - left) / 2].totalPoint;
        while (i <= j) {
            while (arr[i].totalPoint < pivot) i++;
            while (pivot < arr[j].totalPoint) j--;
            if (i <= j) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    // Calculate the reward by rank and same rank counts
    // For example
    // Rank 1: 70 % of total balance
    // Rank 2: 27 % of total balance
    // Rank 3: 3 % of total balance

    function getRewardAmountByRank (uint256 rank, uint256 sameRankCount) internal view returns(uint256) {
        uint256 reward = (totalTokenBalance * percentPerRank[rank] / 100) / sameRankCount;

        if(reward > baseToken.balanceOf(address(this))) reward = baseToken.balanceOf(address(this));
        return reward;
    }

    function getRewardAmount(address sender) public view returns(uint256) {
        Library.LineUp[] memory topLines = getTop3Lineups();

        uint256 sum = 0;
        for(uint256 idx = 0; idx < topLines.length; idx++) {
            if(topLines[idx].owner == sender) {
                uint256 sameRankCount = 0;
                for(uint256 idy = 0; idy < topLines.length; idy++) {
                    if(topLines[idy].rank == topLines[idx].rank) {
                        sameRankCount++;
                    }
                }
                sum = getRewardAmountByRank(topLines[idx].rank, sameRankCount);
            }
        }
        return sum;
    }

    // send fee of net to fee account
    function withdrawFee () claimable external onlyOperator {
        uint256 fee = baseToken.balanceOf(address(this)) >= totalFeeCollected? totalFeeCollected: baseToken.balanceOf(address(this));
        require(fee > 0, "No enough token to withdraw");

        totalFeeCollected = 0;
        baseToken.transfer(factory.fee_account(), fee);
    }

    // Claim the reward from customers/users
    function claim() external claimable {
        require(userSubmitted[msg.sender], "Claim: you have no right to claim");
        userSubmitted[msg.sender] = false;

        uint256 prize_amount = getRewardAmount(msg.sender);
        require(baseToken.balanceOf(address(this)) >= prize_amount, "Claim: not enough");

        baseToken.transfer(msg.sender, prize_amount);          
    }

    // Withdraw token for player
    function withdrawForPlayer() external claimable {
        uint256 amount = playerRewards[msg.sender];
        require(amount > 0, "Withdraw: not enough");
        playerRewards[msg.sender] = 0;

        baseToken.transfer(msg.sender, amount);
    }

    // Refund the deposit
    function refund() refundable external {
        userSubmitted[msg.sender] = false;

        uint256 submittedLineupCount = 0;
        uint256 pricePerLineup = factory.price() + factory.feeAmount() + factory.playerRewardAmount() * factory.MAX_PLAYERS();

        for(uint256 idx = 0; idx < entry_counter; idx++) {
            Library.LineUp storage lineup = lineups[entry_counter];
            if(lineup.owner == msg.sender) {
                submittedLineupCount++;
            }
        }

        uint256 refundAmount = pricePerLineup *  submittedLineupCount;
        refundAmount = baseToken.balanceOf(address(this)) > refundAmount? refundAmount: baseToken.balanceOf(address(this));

        baseToken.transfer(msg.sender, refundAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}