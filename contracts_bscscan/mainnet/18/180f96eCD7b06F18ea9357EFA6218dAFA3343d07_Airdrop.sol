/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: Unlicensed
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

    uint256 millionConstant = 1000000;          //One million
    uint256 decimalSuffix = (10**6);
    uint256 magnitude = 450000*millionConstant*decimalSuffix;   //Maximun number of coins that community can claim. However we predict the real claimed numbers might be a lot less than that.
    uint256 Maximun_Claimable = 200*millionConstant*decimalSuffix; //Maximun tokens claimable in a single claiming transaction: 200 million.
     
    address public shibaInuAddress = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;
    address public pigAddress = 0x8850D2c68c632E3B258e612abAA8FadA7E6958E5;
    address public babyDogeAddress = 0xc748673057861a797275CD8A068AbB95A902e8de;
    
    address public APGAddress = 0xDcD13B809bb94875B5517A728931a17E9A9e621e;
    
    address public contractOwner;
    
    mapping(address => uint256) public shillingCompetition;
    mapping(address=>bool) hasClaimed;
    
    bool public airdropOn = false;
   
    constructor() public {
       contractOwner = msg.sender;
    }
    
    function tokenClaimable (address _address, address contractAddress) public view returns (uint256){
        return Itoken(contractAddress).balanceOf(_address).mul(magnitude).div(Itoken(contractAddress).totalSupply());
    }
    
    function tokensGet(address _address) public view returns (uint256){
        
        uint256 Claimable = 0;
        
        uint256 ShibaClaimable = tokenClaimable(_address,shibaInuAddress);
        
        uint256 PigClaimable = tokenClaimable(_address,pigAddress);
        
        uint256 babyDogeClaimable = tokenClaimable(_address,babyDogeAddress);  
        
        Claimable = ShibaClaimable + PigClaimable + babyDogeClaimable;
        
        //Angel Pig is precious and fragile, there is possibility that you break some APG tokens when claiming
        //We use a pseudo-random number generator to realize this functionality
        uint256 Ratio = uint256(keccak256(abi.encodePacked(block.difficulty, now, block.timestamp))) % 100; 
        Claimable = Claimable.mul(Ratio).div(100);
        
        return Claimable;
    
    }
   
    function claimAirdrop() public onlyDuringAirdrop {
        uint256 pendingClaimable;
        
        require(hasClaimed[msg.sender]!=true, 'APG Airdrop: the address has claimed!');
        
        uint256 CommunityClaimabe = tokensGet(msg.sender);
        uint256 ShillingClaimable = shillingCompetition[msg.sender];
        pendingClaimable = CommunityClaimabe + ShillingClaimable;
        pendingClaimable = pendingClaimable > Maximun_Claimable ? Maximun_Claimable : pendingClaimable;
        hasClaimed[msg.sender]=true;
        require(IAPG(APGAddress).transfer(msg.sender, pendingClaimable), 'APG Airdrop: airdrop transfer failed!');
    }
    
    function setShillingWinner(address winnnerAddress, uint256 _type) public {
        require(msg.sender==contractOwner,'APG airdrop: only owner can uptate shilling winnder!');
        
        if (_type == 1) {
            shillingCompetition[winnnerAddress] = 30*millionConstant*decimalSuffix;  //First Prize 30 million
        } else if (_type ==2) {
            shillingCompetition[winnnerAddress] = 10*millionConstant*decimalSuffix;  //First Prize 10 million
        } else {
            shillingCompetition[winnnerAddress] = 5*millionConstant*decimalSuffix;   //Third Prize 5 million
        }
    }
    
    function updateTContractAddress (address _address, uint256 _type) public {
         require(msg.sender==contractOwner,'APG airdrop: only owner can uptate airdrop targeted contract address!');
         if (_type == 1) {
            shibaInuAddress = _address;  //First Prize 30 million
        } else if (_type ==2) {
            pigAddress = _address;  //First Prize 10 million
        } else {
            babyDogeAddress = _address;   //Third Prize 5 million
        }
    }
    
    function checkClaimable() public view returns (uint256){
        uint256 pendingClaimable = 0;
        
        if (hasClaimed[msg.sender] == true){
            return 0;
        }
        
        uint256 CommunityClaimable = tokensGet(msg.sender);
        uint256 ShillingClaimable = shillingCompetition[msg.sender];
        pendingClaimable = CommunityClaimable + ShillingClaimable;
        pendingClaimable = pendingClaimable > Maximun_Claimable ? Maximun_Claimable : pendingClaimable;
        return pendingClaimable;
    }
    
    function closeAirdrop() public{
        require(msg.sender==contractOwner,'APG airdrop: only owner can close airdrop!');
        require(airdropOn, 'APG airdrop: airdrop already closed!');
        airdropOn = false;
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