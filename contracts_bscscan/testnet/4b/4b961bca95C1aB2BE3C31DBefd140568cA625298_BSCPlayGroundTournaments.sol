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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract BSCPlayGroundTournaments is Ownable
{
    using SafeMath for uint256;

    struct Tournament 
    {
        uint256 id;
        string title;
        address owner;
        uint256 entryCost;
        uint256 rewardsPool;
        uint256 playersCount;
        mapping(address => uint256) players;
    }

    uint256 public addTournamentReward = 100000 * 10**18; // 100 000
    uint256 public ownerTournamentFees = 5; // 5% from tournament rewardsPool
    uint256 public prizePoolAdditionalReward = 50000 * 10**18; //50 000 will receive from prizePoolWallet
    
    IERC20 private _token; // BSCPlayground token address
    address public prizePoolWallet = 0x3e44881b4BC060FC3cF202b796147022Cd8e80C3; // rewards wallet

    mapping(string => Tournament) private _tournaments;
    string[] private tournamentNames;

    event TournamentFinilized(string title, uint256 rewards);
    event TournamentJoined(string title, address indexed player);
    event TournamentAdded(string title, address owner);

    constructor(address token_){
        if(token_ != address(0))
            _token = IERC20(token_);
    }

    function getTournaments() external view returns(string[] memory){
        return tournamentNames;
    }

    function updateTournamentEntry(string memory title_, uint256 cost) external onlyOwner returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        require(cost > 0, "Cost cannot be less zero");

        Tournament storage tournament = _tournaments[title_];
        tournament.entryCost = cost;
        return true;
    }

    function updateTournamentOwner(string memory title_, address owner_) external onlyOwner returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        require(owner_ != address(0), "Address cannot be zero");

        Tournament storage tournament = _tournaments[title_];
        tournament.owner = owner_;
        return true;
    }
    
    function updateTokenAddress(address token_) external onlyOwner{
        require(token_ != address(0));
        require(address(_token) != token_);
        _token = IERC20(token_);
    }

    function updateOwnerUploadReward(uint256 amount) external onlyOwner{
        require(amount > 0);
        require(amount != addTournamentReward);
        addTournamentReward = amount;
    }

    function updatePrizePoolAdditionalReward(uint256 amount) external onlyOwner{
        require(amount > 0);
        require(amount != prizePoolAdditionalReward);
        prizePoolAdditionalReward = amount;
    }   
    
    function updateOwnerTournamentFees(uint256 fees) external onlyOwner{
        require(fees > 0 && fees < 100);
        require(fees != ownerTournamentFees);
        ownerTournamentFees = fees;
    }

    function updateRewardsWalletAddress(address wallet_) external onlyOwner{
        require(wallet_ != address(0));
        require(prizePoolWallet != wallet_);
        prizePoolWallet = wallet_;
    }

    function addTournament(string memory title_, address owner_, uint256 entry_) external onlyOwner returns(bool)
    {
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length == 0, "Already exist game with this name");
        require(owner_ != address(0), "Owner cannot be zero");
        require(entry_ > 0, "Entry would be bigger than zero");

        Tournament storage tournament = _tournaments[title_];
        tournament.title = title_;
        tournament.id = 1;
        tournament.owner = owner_;
        tournament.entryCost = entry_;
        tournamentNames.push(title_);

        sendOwnerUploadReward(owner_);
        emit TournamentAdded(title_, owner_);
        return true;
    }

    function playerEntred(string memory title_) public view returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");

        Tournament storage tournament = _tournaments[title_];
        return tournament.players[msg.sender] == tournament.id;
    }

    function playgroundTournamentInfo(string memory title_) external view 
        returns(
            string memory title,
            address owner,
            uint256 entryCost,
            uint256 receivedTokens,
            uint256 numberOfGame,
            uint256 playersCount) 
        {
            require(bytes(title_).length != 0, "Title cannot be empty");
            require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        
            Tournament storage tournament = _tournaments[title_];
            return(
                tournament.title,
                tournament.owner,
                tournament.entryCost,
                tournament.rewardsPool,
                tournament.id,
                tournament.playersCount
            );
    }
    
    function joinTournament(string memory title_) public returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        require(!playerEntred(title_), "Player is already participating in the tournament");
        
        Tournament storage tournament = _tournaments[title_];
        address sender = msg.sender;
        
        if(_token.balanceOf(sender) < tournament.entryCost)
            revert('Player does not have enough tokens');

        if(_token.allowance(sender, address(this)) < tournament.entryCost){
            revert('Player does not approve');
        }

        bool success = _token.transferFrom(sender, address(this), tournament.entryCost);
        if(success)
        {
            tournament.rewardsPool = tournament.rewardsPool.add(tournament.entryCost);
            tournament.players[sender] = tournament.id;
            tournament.playersCount = tournament.playersCount.add(1);
            return true;
        }
        
        emit TournamentJoined(title_, sender);
        return false;
    }

    function finilizeTournament(string memory title_, address[] memory winners, uint256[] memory amounts) public onlyOwner returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        require(winners.length != 0 && amounts.length != 0);
        require(winners.length <= amounts.length);

        Tournament storage tournament = _tournaments[title_];
        
        uint256 amount = tournament.rewardsPool.add(receivePrizePoolReward());
        uint256 ownerFees = amount.mul(ownerTournamentFees).div(100);
        uint256 rewards = amount.sub(ownerFees);

        sendOwnerFees(tournament.owner, ownerFees);
        (uint256 tokensLeft, uint256 players) = sendWinnersByProcent(winners, amounts, title_, rewards);
        
        if(tokensLeft > 0){
            sendWinnersLeftTokens(winners, title_, tokensLeft, players);
        }

        tournament.rewardsPool = 0;
        tournament.playersCount = 0;
        tournament.id = tournament.id.add(1);
        emit TournamentFinilized(title_, amount);
        return true;
    }

    function receivePrizePoolReward() private returns(uint256){
        uint256 prizePoolReward = prizePoolAdditionalReward;
        uint256 balanceOf = _token.balanceOf(prizePoolWallet);
        
        if(balanceOf < prizePoolReward){
            prizePoolReward = balanceOf;
        }

        try _token.transferFrom(prizePoolWallet, address(this), prizePoolReward) {} catch{ prizePoolReward = 0;}
        return prizePoolReward;
    }

    function sendOwnerFees(address owner, uint256 amount) private {
        uint256 balanceOf = _token.balanceOf(address(this));
        if(balanceOf < amount){
            amount = balanceOf;
        }
        
        _token.transfer(owner, amount);
    }

    function sendOwnerUploadReward(address owner) private{
        uint256 balanceOf = _token.balanceOf(prizePoolWallet);
        uint256 reward = addTournamentReward;

        if(balanceOf < reward)
            reward = balanceOf;

        _token.transferFrom(prizePoolWallet, owner, reward);
    }

    function sendWinnersByProcent(address[] memory winners, uint256[] memory amounts, string memory title, uint256 tournamentBalance) private returns(uint256, uint256){
        
        uint256 balanceOf = _token.balanceOf(address(this));
        uint256 tokensLeft = tournamentBalance;
        uint256 winnerReward = 0;
        uint256 players = 0;
        
        Tournament storage tournament = _tournaments[title];


        if(balanceOf < tournamentBalance)  
            tournamentBalance = balanceOf;

        for(uint256 index = 0; index < winners.length; index++)
        {
             if(tournament.id != tournament.players[winners[index]])
                continue;
            
            winnerReward = tournamentBalance.mul(amounts[index]).div(100);
            tokensLeft = tokensLeft.sub(winnerReward);
            _token.transfer(winners[index], winnerReward);
            players = players.add(1);
      
        }

        return (tokensLeft, players);
    }

    function sendWinnersLeftTokens(address[] memory winners, string memory title, uint256 amounts, uint256 realPlayers) private {
        uint256 balanceOf = _token.balanceOf(address(this));
        Tournament storage tournament = _tournaments[title];

        if(balanceOf < amounts)  
            amounts = balanceOf;
        
        uint256 reward = amounts.div(realPlayers);
        for(uint256 index = 0; index < winners.length; index++)
        {
             if(tournament.id != tournament.players[winners[index]])
                continue;

            _token.transfer(winners[index], reward);
        }

    }

}