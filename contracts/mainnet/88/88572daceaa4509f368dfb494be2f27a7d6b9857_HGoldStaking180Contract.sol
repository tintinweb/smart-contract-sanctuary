/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

/**
*
*  d88    8bP    d8888P'                   ’8b8        ’8b8
*  88P'   88P  d88                         ’8b8        ’8b8
*  d88'   88P d88                          ’8b8        ’8b8
*  ?88888d88’ d88     dd8888P     d8888b   ’8b8    8b8P’8b8            
*  88P   88P  d8P      8P 8P   d8P'   ?88  ,8b8  d8b.  ’8b8
*  d88   88P  d8P     8P  8P   88b    d88  ,8b8  d88b. ’8b8
*  d88'  88P   d8P88P88   8P   `?8888P’.   ,8b8   d88bP88b8
*                                                                                                
*
* 
* SmartWay HGold
* https://www.holly.gold/
* (only for HGold members)
* 
**/


pragma solidity >=0.4.22 <0.6.0;



library SafeMath {
    
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a >= b ? a: b;
    }
    function min64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a < b ? a: b;
    }
    function max256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a >= b ? a: b;
    }
    function min256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a: b;
    }
}

contract ERC20 {
    function totalSupply() public  returns (uint);
    function balanceOf(address tokenOwner) public returns (uint balance);
    function allowance(address tokenOwner, address spender) public  returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract HGoldStaking180Contract {
     /****
     *
     *This value is staking reword and lock days
     *     
     ****/
     int constant stakingDays = 180;
     int constant reward = 50000;
     int calcDays = 0;
     
     /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;
     
     mapping (address => bool) public allowedTokens;
     mapping (address => address) public Mediator;
     
     modifier isValidToken(address _tokenAddr){
        require(allowedTokens[_tokenAddr]);
        _;
    }
    modifier isMediator(address _tokenAddr){
        require(Mediator[_tokenAddr] == msg.sender);
        _;
    }
    
      /**
    * @dev add approved token address to the mapping 
    */
    
    function addToken( address _tokenAddr) external {
        allowedTokens[_tokenAddr] = true;
    }
    
    /**
    * @dev remove approved token address from the mapping 
    */
    function removeToken( address _tokenAddr) external {
        allowedTokens[_tokenAddr] = false;
    }
    
    address ContractOwner = 0xAbfb22cEA4034a7d5B5B2A2a707578c60a3097bb;
    
    address public owner;
    mapping(address => Member) public users;
    mapping(uint => Member) public userIds;
    uint public contractFeedBack = 8;
    uint private userCount;
    
     struct Member {
        uint member_id;
        address member_address;
		uint referrer_id;
        address referrer_address;
    }
    
    
    constructor() public { 
        owner = msg.sender;
    }
    
    
    function transfer(address token,uint coin) public {
        // add the deposited coin into existing balance 
        // transfer the coin from the sender to this contract
        //ERC20(token).transferFrom(msg.sender, address(this), coin);
        address receiver =  ContractOwner;
        ERC20(token).transfer(receiver, coin);
    }
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
    
    
    struct stakingInfo {
        uint amount;
        bool requested;
        uint releaseDate;
    }
    mapping (address => mapping(address => stakingInfo)) public StakeMap; //tokenAddr to user to stake amount
    mapping (address => mapping(address => uint)) public userCummRewardPerStake; //tokenAddr to user to remaining claimable amount per stake
    mapping (address => uint) public tokenCummRewardPerStake; //tokenAddr to cummulative per token reward since the beginning or time
    mapping (address => uint) public tokenTotalStaked; //tokenAddr to total token claimed 
    
    function stake(uint _amount, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool){
            require(_amount != 0);
            //require(ERC20(StakeTokenAddr).transferFrom(msg.sender,this,_amount));
            int feedbackReward = 0;
            if (stakingDays < 180){
                calcDays++;
            }
            else{
               feedbackReward = reward;
            }
            
            if (StakeMap[_tokenAddr][msg.sender].amount ==0){
                StakeMap[_tokenAddr][msg.sender].amount = _amount;
                userCummRewardPerStake[_tokenAddr][msg.sender] = tokenCummRewardPerStake[_tokenAddr];
                return false;
            }else{
              
                StakeMap[_tokenAddr][msg.sender].amount = _amount;
           
                return true;
            }
    }
  
    function initWithdraw(address _tokenAddr) isValidToken(_tokenAddr)  external returns (bool){
        require(StakeMap[_tokenAddr][msg.sender].amount >0 );
        require(! StakeMap[_tokenAddr][msg.sender].requested );
        StakeMap[_tokenAddr][msg.sender].releaseDate = now + 4 weeks;
        return true;

    }
    
     /**
    * @notice The accumulated rewards for each stakeholder.
    */
   mapping(address => uint256) internal rewards;
  
   /**
    * @notice A method to allow a stakeholder to check his rewards.
    * @param _stakeholder The stakeholder to check rewards for.
    */
   function rewardOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return rewards[_stakeholder];
   }

   /**
    * @notice A method to the aggregated rewards from all stakeholders.
    * @return uint256 The aggregated rewards from all stakeholders.
    */
   function totalRewards()
       public
       view
       returns(uint256)
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = rewards[stakeholders[s]];
       }
       return _totalRewards;
   }
    
}