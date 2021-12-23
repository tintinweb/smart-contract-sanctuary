// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interfaces/ITournament.sol";
import "./Tournament.sol";

contract FactoryProxy {

    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "operator: wut?");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership (address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);

    }

    function createTournamentProxy(uint256 tn_counter, address baseToken, address operator_account) external returns(address tour){
        require(owner == msg.sender, "Not factory contract");

        // create tournament
        bytes memory bytecode = type(Tournament).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tn_counter, baseToken, operator_account));
        assembly {
            tour := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ITournament(tour).initialize(tn_counter, baseToken, operator_account);
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
    // Rank 1: 70 % of total balance
    // Rank 2: 27 % of total balance
    // Rank 3: 3 % of total balance
    uint256[] percentPerRank = [70, 27, 3];

    // Wallet => Reward Amount
    mapping(address => uint256) public playerRewards;
    
    // mapping
    mapping(address => bool) public userSubmitted;

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

    // Get Lineups
    function getLineups() public view returns(Library.LineUp[] memory) {
        Library.LineUp[] memory allLines = new Library.LineUp[](entry_counter);

        for(uint256 idx = 0; idx < entry_counter; idx++) allLines[idx] = lineups[idx];

        return allLines;
    }

    // Get Lineups
    function getUserLineups(address sender) public view returns(Library.LineUp[] memory userLineups) {
        uint256 userLinesCounter = 0;
        for(uint256 idx = 0; idx < entry_counter; idx++)
            if(lineups[idx].owner == sender) {
                userLineups[userLinesCounter] = lineups[idx];
                userLinesCounter++;
            }
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