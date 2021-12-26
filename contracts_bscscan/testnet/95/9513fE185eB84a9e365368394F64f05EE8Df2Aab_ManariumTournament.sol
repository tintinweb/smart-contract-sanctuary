// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./core/interfaces/IERC20Burnable.sol";

contract ManariumTournament is Ownable
{
    using SafeMath for uint256;

    struct Tournament 
    {
        string title;
        address owner;
        uint256 num;
        uint256 version;
        uint256 entry;
        uint256 pool;
        uint256 countPlayers;
        bool paused;
        mapping(address => uint256) players;
    }

    IERC20Burnable private _token;

    uint256 public addTournamentReward = 50000 * 10**18; // 50 000
    uint256 public prizePoolReward = 15000 * 10**18; // 15 000 will receive from prizePoolWallet

    uint256 public ownerFees = 6; // 6%
    uint256 public developmentFees = 3; // 3%
    uint256 public burnFees = 1; // 1%

    uint16 constant public PROCENT_DENOMINATOR = 100; // 100%

    address public developmentWallet = 0x1664a715B15345C50bdd3b92Bf3EB7a4E4d39B4A;
    address public prizePoolWallet = 0x3e44881b4BC060FC3cF202b796147022Cd8e80C3; 

    mapping(string => Tournament) private _tournaments;
    string[] private tournamentNames;

    event TournamentFinilized(string title, uint256 rewards);
    event TournamentJoined(string title, address indexed player, uint256 entry);
    event TournamentAdded(string title, address owner);
    event TournamentPauseStateChanged(string title, bool status);

    constructor(address token_){
        _token = IERC20Burnable(token_);
    }

    function getTournaments() public view returns(string[] memory){
        return tournamentNames;
    }
    
    function getTotalPlayers() public view returns(uint256){ 
        uint256 players = 0;
        for(uint256 i = 0; i < tournamentNames.length; i++){
            Tournament storage tournament = _tournaments[tournamentNames[i]];
            players = players.add(tournament.countPlayers);
        }

       return players;
    }

    function getTotalRewards() public view returns(uint256){ 
        uint256 total = 0;
        for(uint256 i = 0; i < tournamentNames.length; i++){
            Tournament storage tournament = _tournaments[tournamentNames[i]];
            total = total.add(tournament.pool);
        }
       return total;
    }

    function getTournamentInfo(string memory title_) public view 
        returns(
               string memory title,
               address owner,
               bool paused,
               uint256 num,
               uint256 version,
               uint256 entry,
               uint256 pool,
               uint256 countPlayers
            ) 
        {
            require(bytes(_tournaments[title_].title).length != 0, "Not Found");   
            Tournament storage tournament = _tournaments[title_];
            return(
                tournament.title,
                tournament.owner,
                tournament.paused,
                tournament.num,
                tournament.version,
                tournament.entry,
                tournament.pool,
                tournament.countPlayers
            );
    }



    function updateOwnerUploadReward(uint256 amount_) external onlyOwner{
        require(amount_ >= 0);
        require(amount_ != addTournamentReward);
        addTournamentReward = amount_;
    }

    function updatePrizePoolReward(uint256 amount_) external onlyOwner{
        require(amount_ >= 0);
        require(amount_ != prizePoolReward);
        prizePoolReward = amount_;
    }   

    function updateOwnerFees(uint256 fees_) external onlyOwner{
        require(fees_ >= 0 && fees_ < PROCENT_DENOMINATOR);
        require(fees_ != ownerFees);
        ownerFees = fees_;
    }

    function updateDevelopmentFees(uint256 fees_) external onlyOwner{
        require(fees_ >= 0 && fees_ < PROCENT_DENOMINATOR);
        require(fees_ != developmentFees);
        developmentFees = fees_;
    }

    function updateBurnFees(uint256 fees_) external onlyOwner{
        require(fees_ >= 0 && fees_ < PROCENT_DENOMINATOR);
        require(fees_ != burnFees);
        burnFees = fees_;
    }

    function updateTokenAddress(address token_) external onlyOwner{
        require(token_ != address(0));
        require(address(_token) != token_);
        _token = IERC20Burnable(token_);
    }
   
    function updatePrizePoolWallet(address wallet_) external onlyOwner{
        require(wallet_ != address(0));
        require(prizePoolWallet != wallet_);
        prizePoolWallet = wallet_;
    }

    function updateDevelopmentWallet(address wallet_) external onlyOwner{
        require(wallet_ != address(0));
        require(developmentWallet != wallet_);
        developmentWallet = wallet_;
    }


    function addTournament(string memory title_, address owner_, uint256 entry_) external onlyOwner returns(bool)
    {
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length == 0, "Already exist game with this name");
        require(_tournaments[title_].num == 0);
        require(owner_ != address(0), "Owner cannot be zero");
        require(entry_ >= 0, "Entry would be bigger than zero");

        tournamentNames.push(title_);

        // GET REWARDS FOR GAME
        uint256 amount = receivePrizePoolReward();

        Tournament storage tournament = _tournaments[title_];
        tournament.title = title_;
        tournament.owner = owner_;
        tournament.paused = false;
        tournament.num = 1;
        tournament.version = 1;
        tournament.entry = entry_;
        tournament.pool = tournament.pool.add(amount);
        
        sendOwnerUploadReward(owner_);

        emit TournamentAdded(title_, owner_);
        return true;
    }

 
    function sendOwnerUploadReward(address owner) private{
        uint256 balanceOf = _token.balanceOf(prizePoolWallet);
        uint256 reward = addTournamentReward;

        if(balanceOf < reward)
            reward = balanceOf;

        _token.transferFrom(prizePoolWallet, owner, reward);
    }

    function updateTournamentVersion(string memory title_, uint256 version) external onlyOwner returns(bool){
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        Tournament storage tournament = _tournaments[title_];
        tournament.version = version;
        return true;
    }

    function updateTournamentEntry(string memory title_, uint256 entry_) external onlyOwner returns(bool){
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        require(entry_ >= 0, "Entry cannot be less zero");

        Tournament storage tournament = _tournaments[title_];
        tournament.entry = entry_;
        return true;
    }

    function updateTournamentOwner(string memory title_, address owner_) external onlyOwner returns(bool){
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        require(owner_ != address(0), "Address cannot be zero");

        Tournament storage tournament = _tournaments[title_];
        tournament.owner = owner_;
        return true;
    }

    function pauseTournament(string memory title_, bool paused_) external onlyOwner returns(bool) {
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        
        Tournament storage tournament = _tournaments[title_];
        tournament.paused = paused_;

        emit TournamentPauseStateChanged(title_, paused_);
        return true;
    }

    function removeTournament(string memory title_) external onlyOwner returns(bool) {
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        require(_tournaments[title_].countPlayers == 0);

        Tournament storage tournament = _tournaments[title_];
        tournament.title = "";
        tournament.paused = true;
        
        if(tournament.pool > 0){
            _token.transfer(prizePoolWallet, tournament.pool);
            tournament.pool = 0;
        }

        return true;        
    }

    function playerEntred(string memory title_, address player) public view returns(bool){
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        
        Tournament storage tournament = _tournaments[title_];
        return tournament.players[player] == tournament.num;
    }

    function tournamentEntryCost(string memory title_) external view returns(uint256){
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        
        Tournament storage tournament = _tournaments[title_];
        return tournament.entry;
    }

    function tournamentPlayersCount(string memory title_) external view returns(uint256){
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        Tournament storage tournament = _tournaments[title_];
        return tournament.countPlayers;
    }

    function tournamentPool(string memory title_) external view returns(uint256){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        
        Tournament storage tournament = _tournaments[title_];
        return tournament.pool;
    }
    
    function joinTournament(string memory title_, uint256 version) public returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not found game with name");
        require(!playerEntred(title_, msg.sender), "Player is already participating in the tournament");
        
        Tournament storage tournament = _tournaments[title_];
        require(tournament.version == version, "Update Game Version");

        address sender = msg.sender;
        if(_token.balanceOf(sender) < tournament.entry)
            revert('Player does not have enough tokens');

        bool success = _token.transferFrom(sender, address(this), tournament.entry);
        if(success)
        {
            tournament.pool = tournament.pool.add(tournament.entry);
            tournament.players[sender] = tournament.num;
            tournament.countPlayers = tournament.countPlayers.add(1);
            emit TournamentJoined(title_, sender, tournament.entry);
            return true;
        }
        
        return false;
    }

    function finilizeTournament(string memory title_, address[] memory winners, uint256[] memory amounts) public onlyOwner returns(bool){
        require(bytes(title_).length != 0, "Title cannot be empty");
        require(bytes(_tournaments[title_].title).length != 0, "Not Found");
        require(winners.length != 0 && amounts.length != 0);
        require(winners.length <= amounts.length);

        Tournament storage tournament = _tournaments[title_];
        
        uint256 tokens = tournament.pool;
        uint256 ownerAmount = tokens.mul(ownerFees).div(PROCENT_DENOMINATOR); 
        uint256 developmentAmount = tokens.mul(developmentFees).div(PROCENT_DENOMINATOR); 
        uint256 burnAmount = tokens.mul(burnFees).div(PROCENT_DENOMINATOR); 
        tokens = tokens.sub(ownerAmount).sub(developmentAmount).sub(burnAmount);


        (uint256[] memory winnerTokens, uint256 additionalAmount) = calculateWinnerRewards(winners, amounts, tokens, tournament);
        uint256 tokensLeft = sendWinnerTokens(winners, winnerTokens, additionalAmount, tokens);

        sendOwnerFees(tournament.owner, ownerAmount);
        sendDevelopmentFees(developmentAmount);
        sendBurnFees(burnAmount);

        uint256 prizePoolAdditionalReward = receivePrizePoolReward();

        tournament.pool = tokensLeft.add(prizePoolAdditionalReward);
        tournament.countPlayers = 0;
        tournament.num = tournament.num.add(1);

        emit TournamentFinilized(title_, tournament.pool);
        return true;
    }

    function calculateWinnerRewards(
                address[] memory winners, 
                uint256[] memory amounts, 
                uint256 tokens,
                Tournament storage tournament) private view returns(uint256[] memory, uint256){
        
        uint256[] memory winnerTokens = new uint256[](winners.length);
        uint256 allTokens = tokens;
        uint256 tokensLeft = allTokens;
        uint256 players = 0;
        uint256 additionalReward = 0;
        uint256 maxProcent = 0;
        uint256 balanceOf = _token.balanceOf(address(this));

        if(balanceOf < tokens)  {
            allTokens = balanceOf;
            tokensLeft = allTokens;
        }

        for(uint256 index = 0; index < winners.length; index++)
        {
            if(tournament.num != tournament.players[winners[index]])
                continue;
            
            winnerTokens[index] = allTokens.mul(amounts[players]).div(PROCENT_DENOMINATOR);
            tokensLeft = tokensLeft.sub(winnerTokens[index]);
            maxProcent = maxProcent.add(amounts[players]);
            players = players.add(1);           
        }

        require(maxProcent <= PROCENT_DENOMINATOR && players > 0);

        if(tokensLeft > 0){
            additionalReward = tokensLeft.div(players);
        }

        return (winnerTokens, additionalReward);
    }

    function sendOwnerFees(address owner, uint256 amount) private {
        uint256 balanceOf = _token.balanceOf(address(this));
        if(balanceOf < amount){
            amount = balanceOf;
        }
        
        _token.transfer(owner, amount);
    }

    function sendDevelopmentFees(uint256 amount) private{
        uint256 balanceOf = _token.balanceOf(address(this));
        if(balanceOf < amount){
            amount = balanceOf;
        }

        _token.transfer(developmentWallet, amount);
    }

    function sendBurnFees(uint256 amount ) private{
        uint256 balanceOf = _token.balanceOf(address(this));
        if(balanceOf < amount){
            amount = balanceOf;
        }

        _token.burn(amount);
    }

    function receivePrizePoolReward() private returns(uint256){
        uint256 reward = prizePoolReward;
        uint256 balanceOf = _token.balanceOf(prizePoolWallet);
        
        if(balanceOf < reward){
            reward = balanceOf;
        }

        try _token.transferFrom(prizePoolWallet, address(this), reward) {} catch{ reward = 0;}
        return reward;
    }

    function sendWinnerTokens(address[] memory winners, uint256[] memory winnerTokens, uint256 additionalAmount, uint256 tokens) private returns(uint256){
        
        uint256 tokensLeft = tokens;
        
        for(uint256 index = 0; index < winners.length; index++)
        {
            if(winnerTokens[index] <= 0)
                continue;
            
            uint256 reward = winnerTokens[index].add(additionalAmount);
            tokensLeft = tokensLeft.sub(reward);
            _token.transfer(winners[index], reward);
        }

        require(tokensLeft >= 0);
        return tokensLeft;
    }

}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/interfaces/IERC20.sol";

pragma solidity 0.8.4;

interface IERC20Burnable is IERC20 {
     
    /**
     * @dev Burn the amount of tokens
    */
    function burn(uint256 amount) external;
}