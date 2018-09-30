pragma solidity ^0.4.22;

library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;
  
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract Staking is Ownable {
    using SafeMath for uint;
    
    uint BIGNUMBER = 10**18;
    uint DECIMAL = 10**3;

    struct stakingInfo {
        uint amount;
        bool requested;
        uint releaseDate;
        uint requestDate;
    }
    //mapping
    mapping (address => bool) public allowedTokens;
    mapping (address => mapping(address => stakingInfo)) public StakeMap;
    mapping (address => mapping(address => uint)) public userCummRewardPerStake; //tokenAddr to user to remaining claimable amount per stake
    mapping (address => uint) public tokenCummRewardPerStake; //tokenAddr to cummulative per token reward since the beginning or time
    mapping (address => uint) public tokenTotalStaked; //tokenAddr to total token claimed 
    
    event claimed(uint amount);
    
    
    address public StakeTokenAddr;
    
    modifier isValidToken(address _tokenAddr){
        require(allowedTokens[_tokenAddr]);
        _;
    }
    
    constructor(address _tokenAddr) public{
        StakeTokenAddr= _tokenAddr;
    }
    
    function addToken( address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = true;
    }
    
    /**
    * @dev remove approved token address from the mapping 
    */
    function removeToken( address _tokenAddr) onlyOwner external {
        allowedTokens[_tokenAddr] = false;
    }
    function stake(uint _amount, address _tokenAddr) isValidToken(_tokenAddr) external returns (bool){
        require(_amount != 0);
        //require(ERC20(StakeTokenAddr).transferFrom(msg.sender,this,_amount));
        
        if (StakeMap[_tokenAddr][msg.sender].amount ==0){
            StakeMap[_tokenAddr][msg.sender].amount = _amount;
            userCummRewardPerStake[_tokenAddr][msg.sender] = tokenCummRewardPerStake[_tokenAddr];
        }else{
            claim(_tokenAddr, msg.sender);
            StakeMap[_tokenAddr][msg.sender].amount = StakeMap[_tokenAddr][msg.sender].amount.add( _amount);
        }
        tokenTotalStaked[_tokenAddr] = tokenTotalStaked[_tokenAddr].add(_amount);
        return true;
    }
    
    function claim(address _tokenAddr, address _receiver) isValidToken(_tokenAddr)  public returns (uint) {
        uint stakedAmount = StakeMap[_tokenAddr][msg.sender].amount;
        //the amount per token for this user for this claim
        uint amountOwedPerToken = tokenCummRewardPerStake[_tokenAddr].sub(userCummRewardPerStake[_tokenAddr][msg.sender]);
        uint claimableAmount = stakedAmount.mul(amountOwedPerToken); //total amoun that can be claimed by this user
        claimableAmount = claimableAmount.mul(DECIMAL); //simulate floating point operations
        claimableAmount = claimableAmount.div(BIGNUMBER); //simulate floating point operations
        userCummRewardPerStake[_tokenAddr][msg.sender]=tokenCummRewardPerStake[_tokenAddr];
        // if (_receiver == address(0)){
        //     require(ERC20(_tokenAddr).transfer(msg.sender,claimableAmount));
        // }else{
        //     require(ERC20(_tokenAddr).transfer(_receiver,claimableAmount));
        // }
        emit claimed(claimableAmount);
        return claimableAmount;

    }
     
}