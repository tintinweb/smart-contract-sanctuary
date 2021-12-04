/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// File: contracts/3_Ballot.sol

pragma solidity ^0.6.2;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface Itoken{
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IAPG{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop{
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private CommunityToAirdrop;
    uint256 millionConstant = 1000000;          //One million
    uint256 decimalSuffix = (10**6);
    uint256 magnitude = 600000*millionConstant*decimalSuffix;   //Maximun number of coins that community can claim. However we predict the real claimed numbers might be a lot less than that.
    uint256 Maximun_Claimable = 2000*millionConstant*decimalSuffix; //Maximun tokens claimable in a single claiming transaction: 2 billion.
     
    address public shibaInuAddress = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;
    address public pigAddress = 0x8850D2c68c632E3B258e612abAA8FadA7E6958E5;
    address public babyDogeAddress = 0xc748673057861a797275CD8A068AbB95A902e8de;
    
    address public APGAddress = 0x81ebb4f219948107De942ffd69764b8bF9b2111E;
    
    address public contractOwner;
    
    mapping(address=>bool) hasClaimed;
    
    bool public airdropOn = false;
   
    constructor() public {
       contractOwner = msg.sender;
       CommunityToAirdrop.set(shibaInuAddress,8);
       CommunityToAirdrop.set(pigAddress,10);
       CommunityToAirdrop.set(babyDogeAddress,5);
    }
    
    function tokenClaimable (address _address, address contractAddress) public view returns (uint256){
        uint weight = CommunityToAirdrop.get(contractAddress);
        uint weightTotal = 0;
        address key;
        for(uint i=0; i<CommunityToAirdrop.size(); i++){
        key = CommunityToAirdrop.getKeyAtIndex(i);
        weightTotal = weightTotal + CommunityToAirdrop.get(key);
     }
        return Itoken(contractAddress).balanceOf(_address).mul(magnitude).mul(weight).div(Itoken(contractAddress).totalSupply().div(weightTotal));
    }
    
    function tokensGet(address _address) public view returns (uint256){

        uint256 Claimable = 0;
        
        for(uint i=0; i<CommunityToAirdrop.size(); i++){
        Claimable = Claimable + tokenClaimable(_address, CommunityToAirdrop.getKeyAtIndex(i));
     }
        
        return Claimable;
    
    }
   
    function claimAirdrop() public onlyDuringAirdrop {
        uint256 pendingClaimable = 0;
        
        require(hasClaimed[msg.sender]!=true, 'APG Airdrop: the address has claimed!');
        
        pendingClaimable = tokensGet(msg.sender);
        pendingClaimable = pendingClaimable > Maximun_Claimable ? Maximun_Claimable : pendingClaimable;
        hasClaimed[msg.sender]=true;
        require(IAPG(APGAddress).transfer(msg.sender, pendingClaimable), 'APG Airdrop: airdrop transfer failed!');
    }
    
    
    function updateNewCommunity (address key, uint val) public {
        require(msg.sender==contractOwner,'APG airdrop: only owner can uptate airdrop targeted contract address!');
        CommunityToAirdrop.set(key,val);
        
    }

    function removeCommunity (address key) public {
        require(msg.sender==contractOwner,'APG airdrop: only owner can uptate airdrop targeted contract address!');
        CommunityToAirdrop.remove(key);
        
    }
    
    function closeAirdrop() public{
        require(msg.sender==contractOwner,'APG airdrop: only owner can close airdrop!');
        require(IAPG(APGAddress).transfer(msg.sender, IAPG(APGAddress).balanceOf(address(this))), 'APG Airdrop: closing transfer failed');
    }
    
    function setAirdropSwitch(bool airdropSet) public {
        require(msg.sender==contractOwner,'APG airdrop: only owner can start airdrop!');
        airdropOn = airdropSet;
    }
    
    modifier onlyDuringAirdrop {
        require(airdropOn, "Airdrop is only claimable on ThanksGiving day!");
        _;
    }
}