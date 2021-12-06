// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ITournament.sol";
// import "./AuthorityGranter.sol";
import "./Tournament.sol";
import "./utils/StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "./libraries/Library.sol";

contract Factory is Ownable {
    
    // Price per Lineup creation
    uint256 public price = 1 * 10 ** 18; // 1 ETH
    // Fee rate: 2% 
    uint256 public feeAmount = 1 * 10 ** 17;
    // Reward per player per lineup
    uint256 public playerRewardAmount = 1 * 10 ** 18;
    
    // Week include 4 numbers
    // ex: 4th week in 2021 => 2104
    uint256 public week;

    /** Entry = Lineup
      * How many lineups does this tournament have in max? 1 Lineup has 9 players combination.
      */
    uint256 public MAX_ENTRIES = 125;
    // Players Limit for lineup
    uint256 public MAX_PLAYERS = 9;
    
    // Fee account
    address public fee_account = 0xe789B319f4f89Bc032e403F6b2bC06B927ACEa52;
    // Token address
    address public baseToken = 0xe789B319f4f89Bc032e403F6b2bC06B927ACEa52;

    // Tournament counter
    uint256 private tn_counter;

    // Mapping
    // Tournament Name => bool
    mapping(string => bool) public isTouranmentCreated;
    // Tournament ID => Player Name => PlayerId;
    mapping(uint256 => mapping(string => uint256)) public playerId;
    // TournamentInfo. 
    // week nounce => TournamentInfo
    mapping(uint256 => mapping(uint256 => Library.TournamentInfo)) public tournamentInfos;

    // Tours info array
    Library.Tour[] private tours;
    // Players array
    // TourId, PlayerID => Player
    Library.Player[][] playerList;
    // Points array
    // weekNounce, TourId, playerId
    uint256[][][] public points;


    // Event
    event TournamentCreate(string title, uint256 createdTime);
    event PriceUpdated (uint256 _price);
    // Player name, tournament Id, player Id
    event PlayerAdded(string name, uint256 tId, uint256 pId);

    // Create tournament contract
    function createTournament (string memory title) external returns (address tour){
        require(!isTouranmentCreated[title], "Create Tournament: already created");
        isTouranmentCreated[title] = true;

        // create tournament
        bytes memory bytecode = type(Tournament).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tn_counter, baseToken));
        assembly {
            tour := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        address operatorAddress = owner();
        ITournament(tour).initialize(tn_counter, baseToken, operatorAddress);

        // Add tournament list
        Library.Tour memory tournament;
        tournament.title = title;
        tournament.addr = tour;
        tournament.isActive = true;

        tours[tn_counter] = tournament;

        tn_counter++;

        // fee_rate, price
        emit TournamentCreate(title, block.timestamp);
    }

    /**
      * Add player into spec tournament
      */
    function addPlayer (string memory name, uint256 tId, Library.Role role_, address wallet_) external onlyOwner {
        require(!StringUtils.equal(name, ""), "Name should not be empty");
        require(playerList[tId][playerId[tId][name]].isActive == false, "This name is already registered");
        
        // Get total count in spec tournament
        uint256 totalNumber = playerList[tId].length;
        // PlayerID
        uint256 pId = totalNumber;
        
        Library.Player storage player = playerList[tId][pId];
        player.name = name;
        player.isActive = true;
        player.role = role_;
        player.wallet = wallet_;
        
        // mapping (TournamentID > Name > PlayerID);
        playerId[tId][name] = pId;

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
        tourInfo.isActive = false;
    }

    // Tournament Id, Player Id
    function setPlayerPoints (uint256 tId, uint256 pId, uint256 point) external onlyOwner {
        Library.TournamentInfo memory tournamentInfo = tournamentInfos[week][tId];
        require(tournamentInfo.isActive, "This tournament is not available now");
        require(tournamentInfo.startTime <= block.timestamp, "Not started yet");

        points[week][tId][pId] = point;
    }

    // ======== Set properties ========= //
    // Change Price
    function setPrice (uint256 _price) external onlyOwner { price = _price; emit PriceUpdated(price); }
    // Change fee rate
    function setPlayerRewardAmount (uint256 _playerRewardAmount) external onlyOwner { playerRewardAmount = _playerRewardAmount; }
    // Change fee rate
    function setFeeRate (uint256 _feeAmount) external onlyOwner { feeAmount = _feeAmount; }
    // Update the baseToken
    function setBaseToken (address _baseToken) external onlyOwner { baseToken = _baseToken; }

    // =========== Get Data ========= //
    // Get tournament list
    function getTournaments () external view returns (Library.Tour[] memory) {
        return tours;
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
        uint256 pId = playerId[tId][name];
        return pId;
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
      * 1 Defense
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
    function MAX_ENTRIES() external view returns(uint256);
    function MAX_PLAYERS() external view returns(uint256);
    function price() external view returns(uint256);
    function feeAmount() external view returns(uint256);
    function playerRewardAmount() external view returns(uint256);    
    function week() external view returns(uint256);
    function fee_account() external view returns(address);
    function getTournamentInfo (uint256 tId, uint256 wId) external view returns (Library.TournamentInfo memory);

    // Get from function
    // function checkClaimAble (uint256 tId, uint256 wId) external view returns (bool);
    function getPlayerById (uint256 tId, uint256 pId) external view returns (Library.Player memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import "./AuthorityGranter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IFactory.sol";
import "./libraries/Library.sol";
// import "./utils/QuickSort.sol";

contract Tournament is Ownable {
    using SafeMath for uint256;

    IFactory public factory;

    // Token for payable 
    IERC20 public baseToken;

    // Line entries
    Library.LineUp[] public lineups;

    // Tournament ID0
    uint256 public tourId;
    address public operatorAddress;
    /**
      * Increase entry number whenever user submit lineup
      */
    uint256 public entry_counter = 0;
    // Admin can withdraw fee
    uint256 public feeAmount;
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
    bool public isSorted = false;
    // === Events ===
    event LineupSubmit (address indexed creator, uint256 _timestamp);
    
    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }
    // modifier
    modifier marketNotFilled {
        uint256 maxElems = factory.MAX_ENTRIES();
        require(entry_counter <= maxElems, "Exceed the max entries");
        _;
    }

    modifier marketStarted {
        uint256 maxElems = factory.MAX_ENTRIES();

        uint256 wId = factory.week();
        Library.TournamentInfo memory tournamentInfo = factory.getTournamentInfo(tourId, wId);
        require(tournamentInfo.startTime > block.timestamp, "Market started already");
        _;
    }

    modifier claimable {
        require(userSubmitted[msg.sender], "Claim: you have no right to claim");

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
    ) external onlyOwner{
        tourId = _tourId;
        baseToken = IERC20(_baseToken);
        operatorAddress = _operatorAddress;
    }

    // Check if input one player twice
    function isValidPlayers(uint256[] memory playerIds) internal view returns(bool) {
        // It was fixed with 9
        if(playerIds.length == factory.MAX_PLAYERS()) return false;
        
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
        uint QB = 0;
        uint WR = 0;
        uint RB = 0;
        uint TE = 0;
        uint Defense = 0;
        uint K = 0;        

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
        if(Defense != 1) return false;
        
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
    function SubmitLineup(uint256[] memory playerIds) marketNotFilled marketStarted external {
        require(isValidPlayers(playerIds), "Submit: Lineup is not valid");

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
        feeAmount = feeAmount + factory.feeAmount();

        // add amount to get total balance of tokens
        totalTokenBalance += factory.price();

        // add lineups
        Library.LineUp storage lineup = lineups[entry_counter];
        lineup.owner = msg.sender;
        lineup.playerIds = playerIds;

        emit LineupSubmit(msg.sender, block.timestamp);
    }


    // get send amount. This is for approve token transfer from user's wallet.
    function getSendAmount (uint256 _amount) external view returns(uint256) {
        uint256 fee = _amount.mul(factory.feeAmount()).div(100);
        return _amount.add(fee);
    }

    // Sort out result based on total point
    // This should be called only once 
    function sortLineUps() external onlyOperator {
        require(isSorted == false, "Already sorted Lines");
        isSorted = true;
        Library.LineUp[] memory memoLineups = lineups;
        sort(memoLineups);

        for(uint256 idx = 0; idx < lineups.length; idx++) {
            lineups[idx] = memoLineups[idx];
        }
        // lineups = sort(memoLineups);
    }

    function getTop3Lineups() public view returns(Library.LineUp[] memory topLines) {
        uint arrIdx = 0;
        uint cnt = 0;
        uint curPoint = 10 ** 18; // Set Max
        for(uint idx = 0; idx < lineups.length; idx++) {
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
    
    // function totalPoint
    function quickSort(Library.LineUp[] memory arr, uint left, uint right) pure internal {
        uint i = left;
        uint j = right;
        if (i == j) return;

        uint pivot = arr[uint(left + (right - left) / 2)].totalPoint;
        while (i <= j) {
            while (arr[uint(i)].totalPoint < pivot) i++;
            while (pivot < arr[uint(j)].totalPoint) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function sort(Library.LineUp[] memory data) internal pure {
        for(uint idx = 0; idx < data.length; idx++) {
            uint sum = 0;
            for(uint idy = 0; idy < data[idx].playerIds.length; idy++) {
                sum = data[idx].playerIds[idy];
            }
            data[idx].totalPoint = sum;
        }
        quickSort(data, 0, data.length - 1);
        // return data;
    }

    // Calculate the reward by rank and same rank counts
    // For example
    // Rank 1: 70 % of total balance
    // Rank 2: 27 % of total balance
    // Rank 3: 3 % of total balance

    function getRewardAmountByRank (uint rank, uint sameRankCount) internal view returns(uint256) {
        uint256 reward = (totalTokenBalance * percentPerRank[rank] / 100) / sameRankCount;

        if(reward > baseToken.balanceOf(address(this))) reward = baseToken.balanceOf(address(this));
        return reward;
    }

    function getRewardAmount(address sender) public view returns(uint256) {
        Library.LineUp[] memory topLines = getTop3Lineups();

        uint256 sum = 0;
        for(uint idx = 0; idx < topLines.length; idx++) {
            if(topLines[idx].owner == sender) {
                uint256 sameRankCount = 0;
                for(uint idy = 0; idy < topLines.length; idy++) {
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
        uint256 fee = baseToken.balanceOf(address(this)) > feeAmount? feeAmount: baseToken.balanceOf(address(this));
        baseToken.transfer(factory.fee_account(), fee);
    }

    // Claim the reward from customers
    function claim() external claimable {
        userSubmitted[msg.sender] = false;

        uint256 prize_amount = getRewardAmount(msg.sender);
        require(baseToken.balanceOf(address(this)) >= prize_amount, "Claim: not enough");

        baseToken.transfer(msg.sender, prize_amount);          
    }

    // Withdraw token for player
    function withdrawForPlayer() external claimable {
        uint amount = playerRewards[msg.sender];
        playerRewards[msg.sender] = 0;
        require(amount > 0, "Withdraw: not enough");

        baseToken.transfer(msg.sender, amount);
    }

    // Refund the deposit
    function refund() refundable external {
        userSubmitted[msg.sender] = false;

        uint256 submittedLineupCount = 0;
        uint256 pricePerLineup = factory.price() + factory.feeAmount() + factory.playerRewardAmount() * factory.MAX_PLAYERS();

        for(uint idx = 0; idx < entry_counter; idx++) {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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