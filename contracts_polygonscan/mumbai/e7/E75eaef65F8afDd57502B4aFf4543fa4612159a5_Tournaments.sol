/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
// File: contracts/Helper.sol


pragma solidity ^0.8.0;

contract Helper{

      function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }
}
// File: contracts/Ownable.sol


pragma solidity ^0.8.0;

contract Ownable{
    
      
      mapping(address => uint256) owners;
      
      
      
      modifier onlyOwner{
            require(owners[msg.sender]==1,"Permission denied"); 
            _;
       }
  
    constructor(){
      //deployer is owner
      owners[msg.sender]=1;
    }

    function addOwner(address toAdd) public onlyOwner {
        owners[toAdd]=1;
    }

     function removeOwner(address toRemove) public onlyOwner {
        owners[toRemove]=0;
    }
    
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/Tournaments.sol


pragma solidity ^0.8.0;

/// @title Banger games NFT contract
/// @author Banger games


//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


//import "./Teams.sol";


contract Tournaments is Ownable,Helper {
   
   
using SafeMath for uint;
    uint tournamentId=0;
    struct Tournament{
        uint id;
        address ownerAddress;
        uint pricePerPlayer;
        uint playersPerTeam;
        uint numberOfTeams;
        
        
        uint[] teamIds;
        uint status; //0 announced 1 registration 2 pendingstart 3 started 4 finished 7 canceled
        //uint statusChangeBlock;
        uint prizeAmount;
        uint[] placements; //team id from 1st to last 
        IERC20 prizeToken;
        uint[] distributionRules;
        
        
    }

    struct TournamentWallet{
        
        mapping (address=>uint) deposited; //each tournament has its own wallet
    }

    Tournament[] tournaments;
    TournamentWallet[] tournamentWallets;

       uint teamId=0;
     
    struct Team{
        uint id;
        address teamOwner;
        string name; //temp maybe
        //address[] memberAddress;

    }

    Team[] teams;

    function createTournament(uint _pricePerPlayer, uint _playersPerTeam, uint _numberOfTeams) public onlyOwner returns (uint){
            
            uint[] memory tempIds;
            uint[] memory tempDr;
            uint[] memory tempPlacements;
            IERC20 testToken= IERC20(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
            Tournament memory t = Tournament(tournamentId,msg.sender,_pricePerPlayer,_playersPerTeam,_numberOfTeams,tempIds,0,0,tempPlacements,testToken,tempDr);
            tournaments.push(t);
            
            tournamentId++;
            return tournamentId;

    }


    function createTeam(address _teamOwner, string memory _name) public {
        
        Team memory t = Team(teamId,_teamOwner,_name);
        teams.push(t);
        teamId++;
    }

    function setStatus(uint _tournamentId, uint _status) public {
        require(owners[msg.sender]==1 || msg.sender==tournaments[_tournamentId].ownerAddress,"Permission denied"); 
        tournaments[_tournamentId].status=_status;

    }


    function depositPrizeTokens(uint _tournamentId, uint _amount) public {
        IERC20 testToken= IERC20(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
       // testToken.approve(address(this),_amount); //this should be called by user front directly on tokens contract
        testToken.transferFrom(msg.sender,address(this),_amount);
        tournaments[_tournamentId].prizeAmount+=_amount;
        tournamentWallets[_tournamentId].deposited[msg.sender]=_amount;
        
    }

    function cancelTournament(uint _tournamentId) public onlyOwner {  //onlyOwner for now

        //iterate through all team addresses and tour owner address... unable to find other payments due to mapping (not using arrays)
        address adr=tournaments[_tournamentId].ownerAddress;
        uint amount=tournamentWallets[_tournamentId].deposited[adr];
        if (amount>0) sendToken(adr,amount);
        for (uint i=0;i<tournaments[_tournamentId].teamIds.length;i++){
            adr=teams[tournaments[_tournamentId].teamIds[i]].teamOwner;
            amount=amount=tournamentWallets[_tournamentId].deposited[adr];
            if (amount>0) sendToken(adr,amount);
        }
        tournaments[_tournamentId].status=7;

    }


    function joinTournament(uint _teamId, uint _tournamentId, uint _amount) public {
        require(msg.sender==teams[_teamId].teamOwner ,"Permission denied"); //prolly just team owner
        require(tournaments[_tournamentId].status==1,"Tournament not in registration status");
        require(_amount>=tournaments[_tournamentId].pricePerPlayer, "Insufficient funds");
        //require((teams[_teamId].memberAddress.length+1)==tournaments[_tournamentId].playersPerTeam,"Team size doesn't match");
        tournaments[_tournamentId].teamIds.push(_teamId);
        depositPrizeTokens(_tournamentId,_amount);


    }

    function setDistributionRules(uint _tournamentId, uint[] memory _distribution) public {
        require(msg.sender==tournaments[_tournamentId].ownerAddress || owners[msg.sender]==1, "Permission denied");
        uint sum=0;
        for (uint i=0;i<_distribution.length;i++){
            sum+=_distribution[i];
        }
        require(sum==100, "Distribution not equal 100");
        tournaments[_tournamentId].distributionRules=_distribution;
    }

      function setPlacements(uint _tournamentId, uint[] memory _placements) public {
        require(msg.sender==tournaments[_tournamentId].ownerAddress || owners[msg.sender]==1, "Permission denied");
        tournaments[_tournamentId].placements=_placements;
    }


     function distributeRewards(uint _tournamentId) public {
         Tournament memory tour=tournaments[_tournamentId];
        require(msg.sender==tour.ownerAddress || owners[msg.sender]==1, "Permission denied");
        require(tour.placements.length==tour.distributionRules.length,"Distribution rules or placements not set");
        

        for (uint i=0;i<tour.distributionRules.length;i++){
            
            uint amount=tour.prizeAmount.div(100).mul(tour.distributionRules[i]);
            sendToken(teams[tour.placements[i]].teamOwner,amount); //just teamowner recieves the prize (at the moment)

        }

        tournaments[_tournamentId].status=4;

    }
    
    function sendToken(address _to, uint _amount) private {
        IERC20 testToken= IERC20(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
        testToken.transfer(_to,_amount);

    }

    function getTournament(uint _tournamentId) public view returns(Tournament memory){
        return tournaments[_tournamentId];
    }

     function getTournaments() public view returns(Tournament[] memory){
        return tournaments;
    }

     function getTeams() public view returns(Team[] memory){
        return teams;
    }

     function getTeam(uint _teamId) public view returns(Team memory){
        return teams[_teamId];
    }

  function getDistributionRules(uint _tournamentId) public view returns(uint[] memory){
        return tournaments[_tournamentId].distributionRules;
    }

  
 
}