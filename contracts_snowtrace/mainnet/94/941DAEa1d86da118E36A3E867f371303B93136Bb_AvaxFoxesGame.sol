/**
 *Submitted for verification at snowtrace.io on 2021-12-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IKongz

abstract contract AvaxFoxes {
	function balanceOf(address _user) external view returns(uint256) {}
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {}
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

abstract contract AvaxFoxesToken {
    function getTotalClaimable(address _user) public view returns(uint256){}
    function getReward(address _from) public {}
    function burn(address _from, uint256 _amount) external {}
	function balanceOf(address _user) external view returns(uint256) {}
    function mint(address _to, uint256 _amount) external {}    
}

/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



//pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */


// File @openzeppelin/contracts/math/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

//pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */


// File @openzeppelin/contracts/access/[email protected]

//pragma solidity >=0.6.0 <0.8.0;

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
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        //emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



// File: SlyFox.sol

contract AvaxFoxesGame is Ownable {
	using SafeMath for uint256;	
	uint256 public joinPVPprice = 0.5 ether;
    uint256 public joinPVPTokenPrice = 1 ether;	
    address private _admin;
    
	mapping(uint256 => int256) public Attack;
    mapping(uint256 => int256) public Health;
    mapping(uint256 => int256) public Critical;
    mapping(uint256 => int256) public Hitrate;
    mapping(uint256 => int256) public Evasion;

	mapping(uint256 => uint256) public lastBattle;

    uint256 public teamSize = 2;
    address[] public team1 = new address[](teamSize);
    address[] public team2 = new address[](teamSize);
    uint256[] public team1ids = new uint256[](teamSize);
    uint256[] public team2ids = new uint256[](teamSize);

    address[] public lastteam1 = new address[](teamSize);
    address[] public lastteam2 = new address[](teamSize);
    uint256[] public lastteam1ids = [9956,9957];
    uint256[] public lastteam2ids = [9958,9959];
    bool public lastwinner = false;

    uint256[] public bestFoxes = [1388,6386,6600];
    uint256 public temp = 100;
	//AvaxFox public  AvaxFoxesContract;
    AvaxFoxes AvaxFoxesContract = AvaxFoxes(0x9E073C3613cF70ebB666431f27cC2CD97b9F0ddB);
	AvaxFoxesToken AvaxFoxesTokenC = AvaxFoxesToken(0xeE06eDA32Eee4e8A3b64d331Acc9866a51F0AB6e);
   
    constructor() {
        
        _admin = msg.sender;        
    }
	
    function setTeamSize(uint256 size) external onlyOwner{
		teamSize = size;
        team1 = new address[](teamSize);
        team2 = new address[](teamSize);
        team1ids = new uint256[](teamSize);
        team2ids = new uint256[](teamSize);
	}
    function setjoinPVPprice(uint256 price) external onlyOwner{
		joinPVPprice = price;
	}
    function setjoinPVPTokenPrice(uint256 price) external onlyOwner{
		joinPVPTokenPrice = price;
	}
    function getLevel(uint256 id) public view returns(int256){
        return Attack[id]+Health[id]+Critical[id]+Hitrate[id]+Evasion[id];
    }
    
    function increaseStats(uint256 id, uint256 attack, uint256 health, uint256 critical, uint256 hitrate, uint256 evasion) external {        
        require(AvaxFoxesContract.ownerOf(id) == msg.sender, "AvaxFoxes: You can only increase stats of your own Avax Fox");
        require(attack!=0 || health!=0 || critical!=0 || hitrate!=0 || evasion!=0, "AvaxFoxes: All stats are given 0");
        int256 requiredToken = 0;
        for(int256 i = 0; i<int256(attack); i++){
            requiredToken += Attack[id]+i+1;
        }
        for(int256 i = 0; i<int256(health); i++){
            requiredToken += Health[id]+i+1;
        }
        for(int256 i = 0; i<int256(critical); i++){
            requiredToken += Critical[id]+i+1;
        }
        for(int256 i = 0; i<int256(hitrate); i++){
            requiredToken += Hitrate[id]+i+1;
        }
        for(int256 i = 0; i<int256(evasion); i++){
            requiredToken += Evasion[id]+i+1;
        }
        require(this.balanceOf(msg.sender) >= uint256(requiredToken)*1000000000000000000, "AvaxFoxes: you dont have enough tokens");
        AvaxFoxesTokenC.burn(msg.sender, uint256(requiredToken)*1000000000000000000);
        Attack[id]+=int256(attack);
        Health[id]+=int256(health);
        Critical[id]+=int256(critical);
        Hitrate[id]+=int256(hitrate);
        Evasion[id]+=int256(evasion);

        if(getLevel(id)>getLevel(bestFoxes[0]))
        {
            bestFoxes[2] = bestFoxes[1];
            bestFoxes[1] = bestFoxes[0];
            bestFoxes[0] = id;
        }else if(getLevel(id)>getLevel(bestFoxes[1])){
            bestFoxes[2] = bestFoxes[1];
            bestFoxes[1] = id;
        }else if(getLevel(id)>getLevel(bestFoxes[2])){
            bestFoxes[2] = id;
        }
    }


    struct Team{
        int256 totalAttack;
        int256 totalHealth;        
        int256 totalCritical;
        int256 totalHitrate;        
        int256 totalEvasion;
    }   
    
    function PVPfight() private {
        Team memory team_1 = Team(1,1,1,1,1);
        Team memory team_2 = Team(1,1,1,1,1);        
        uint256 nonce = 1; 
        
        for(uint playerNo = 0; playerNo < teamSize; playerNo++){
            team_1.totalAttack += Attack[team1ids[playerNo]];
            team_1.totalHealth += Health[team1ids[playerNo]];
            team_1.totalCritical += Critical[team1ids[playerNo]];
            team_1.totalHitrate += Hitrate[team1ids[playerNo]];
            team_1.totalEvasion += Evasion[team1ids[playerNo]];

            team_2.totalAttack += Attack[team2ids[playerNo]];
            team_2.totalHealth += Health[team2ids[playerNo]];
            team_2.totalCritical += Critical[team2ids[playerNo]];
            team_2.totalHitrate += Hitrate[team2ids[playerNo]];
            team_2.totalEvasion += Evasion[team2ids[playerNo]];
        }
        team_1.totalAttack = team_1.totalAttack*100;
        team_1.totalHealth = team_1.totalHealth*100;
        team_2.totalAttack = team_2.totalAttack*100;
        team_2.totalHealth = team_2.totalHealth*100;

        int256 miss_chance = 20;
        uint256 turn = 0;
        uint256 rand=0;
        int256 att = 0;
        while(team_1.totalHealth>0 && team_2.totalHealth>0 && turn<10){
            turn++;
            if(int256(_getRandom(nonce++) % temp) > miss_chance-team_1.totalHitrate+team_2.totalEvasion){               
                rand =  80+(_getRandom(nonce++) % 20);
                att = team_1.totalAttack*int256(rand)/100;
                if(int256(_getRandom(nonce++) % temp) < team_1.totalCritical){
                    team_2.totalHealth -= int256(att)*2;
                }else{    
                    team_2.totalHealth -= int256(att);
                }
                
            }
            if(int256(_getRandom(nonce++) % temp) > miss_chance-team_2.totalHitrate+team_1.totalEvasion){
                rand =  80+(_getRandom(nonce++) % 20);
                att = team_2.totalAttack*int256(rand)/100;
                if(int256(_getRandom(nonce++) % temp) < team_2.totalCritical){                    
                    team_1.totalHealth -= int256(att)*2;
                }else{                    
                    team_1.totalHealth -= int256(att);
                }
            }           
        }
        
        if(team_2.totalHealth<team_1.totalHealth){
            for (uint i = 0; i < teamSize; i++){
                payable(team1[i]).transfer(joinPVPprice.mul(18).div(10));
                               
            }
            lastwinner = false; 
        }
        else if(team_2.totalHealth>team_1.totalHealth){
            for (uint i = 0; i < teamSize; i++){
                payable(team2[i]).transfer(joinPVPprice.mul(18).div(10));
                               
            }
            lastwinner = true; 
        }
        else{
            if(_getRandom(nonce++) % temp >49){
               for (uint i = 0; i < teamSize; i++){
                payable(team2[i]).transfer(joinPVPprice.mul(18).div(10));                
                }
                lastwinner = true;  
            }else{
                for (uint i = 0; i < teamSize; i++){
                   payable(team1[i]).transfer(joinPVPprice.mul(18).div(10));                    
                }
                lastwinner = false; 
            }
        }        
        for (uint i = 0; i < teamSize; i++) {
            lastteam1[i] = team1[i];
            lastteam2[i] = team2[i];
            lastteam1ids[i] = team1ids[i];
            lastteam2ids[i] = team2ids[i];
        }
        team1 = new address[](teamSize);
        team2 = new address[](teamSize);
        team1ids = new uint256[](teamSize);
        team2ids = new uint256[](teamSize);        
    }
    function canJoinPVP(address _user , uint256 id) public view returns(bool) {
       bool state=true;
       if(SafeMath.sub(block.timestamp, lastBattle[id])<86400){
           state=false;
       }
       for (uint i = 0; i < teamSize; i++) {
            if(team1[i]==_user || team2[i]==_user){
                state=false;
            }            
        } 

       return state;
	}
    function canJoinHunt(uint256 id) public view returns(bool) {
       bool state=true;
       if(SafeMath.sub(block.timestamp, lastBattle[id])<86400){
           state=false;
       }      

       return state;
	}

    function energy(uint256 id) public view returns(uint256) {       
       return SafeMath.sub(block.timestamp, lastBattle[id]);
	}

    function Hunt(uint256 id) external{        
        require(AvaxFoxesContract.ownerOf(id) == msg.sender, "AvaxFoxes: You can only join with your own Avax Fox");        
        require(canJoinHunt(id), "Avax Foxes: You cant join hunt");
        lastBattle[id]=block.timestamp;
        uint256 rand = _getRandom(1) % temp ;
        if(rand>89){
            AvaxFoxesTokenC.mint(msg.sender, 5000000000000000000);
        }
        else if(rand>9){
            AvaxFoxesTokenC.mint(msg.sender, 1000000000000000000);
        }

    }

    function HuntwithAll(address user) external{        
        uint256[] memory ids = AvaxFoxesContract.walletOfOwner(user);       
        uint256 totalReward = 0;
        uint256 rand = 0;
        uint256 nonce = 0;
        for (uint i = 0; i < ids.length; i++){
            if(canJoinHunt(ids[i])){
                lastBattle[ids[i]] = block.timestamp;
                rand = _getRandom(nonce++) % temp ;
                if(rand>89){
                    totalReward += 5;
                }
                else if(rand>9){
                    totalReward += 1;
                }
            }            
        }        
        AvaxFoxesTokenC.mint(user, totalReward*1000000000000000000);
    }

    function joinPVP(uint256 id) external payable{
        require(joinPVPprice == msg.value, "AvaxFoxes: invalid ether value");
        require(this.balanceOf(msg.sender) > joinPVPTokenPrice, "AvaxFoxes: you dont have enough tokens");
        require(AvaxFoxesContract.ownerOf(id) == msg.sender, "AvaxFoxes: You can only join with your own Avax Fox");        
        require(canJoinPVP(msg.sender, id), "Avax Foxes: You cant join pvp");        
        AvaxFoxesTokenC.burn(msg.sender, joinPVPTokenPrice);
        lastBattle[id]=block.timestamp;

        for (uint i = 0; i < teamSize; i++) {
            if(team1[i]==address(0)){
                team1[i]=msg.sender;
                team1ids[i]=id;
                break;
            }
            if(team2[i]==address(0)){
                team2[i]=msg.sender;
                team2ids[i]=id;
                break;
            }
        }
        if(team2[teamSize-1]!=address(0)){
            PVPfight();
        }
        
    }   

	
    function getTotalClaimable(address _user) public view returns(uint256) {       
       return AvaxFoxesTokenC.getTotalClaimable(_user);
	}
    
    function balanceOf(address _user) external view returns(uint256) {
        return AvaxFoxesTokenC.balanceOf(_user);
    }
    
	function getReward(address _from) public {
		AvaxFoxesTokenC.getReward(_from);
	}

	        
    function _getRandom(uint256 nonce) internal view returns (uint256) {        
    return
      uint256(
        keccak256(
          abi.encodePacked(nonce, block.timestamp, temp)
        )
      );
    }
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
	
}