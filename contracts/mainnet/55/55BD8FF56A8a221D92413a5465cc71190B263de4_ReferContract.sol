pragma solidity ^0.4.18;

contract Ownable {
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}







contract ReferContractInterface {
    function decrement(address _who) public;
    function mint(address _to, uint _value) public;
    function getBalance(address _who) public view returns(uint);
}

contract ReferConstants {
    uint public constant FIRST_USER_CUT = 40;
    uint public constant SECOND_USER_CUT = 25;
    uint public constant THIRD_USER_CUT = 15;
    uint public constant FOURTH_USER_CUT = 10;
    uint public constant OWNER_CUT = 10;
    event Bought(address user, address directParent, address indirectParent, uint money, uint tokens, uint level);
    event LevelUpdated(address user, uint money, uint level);
    
    using SafeMath for uint;
}

contract ReferContract is ReferConstants, Ownable {
    ReferContractInterface referContractInterface;
    uint public baseRate;
    
    mapping (address => uint) public etherBalance;
    mapping (address => address) public userReferrer;
    mapping (address => uint8) public userLevel;
    mapping (address => uint) public tokensBought;
    
    constructor(address _tokenAddress) public {
        referContractInterface = ReferContractInterface(_tokenAddress);
        baseRate = 3000000000000000;
        // to be consistent with game
        userReferrer[owner] = owner;
        userLevel[owner] = 4;
    }
    
     // Update only if contract is not getting traction or got more
     // traction that initially thought.
     // increase the price if there is huge traffic to compensate more people
     // decrease the price if there is less traffic to attract more users.
    function updateRate(uint _newRate) onlyOwner public {
        require(baseRate != 0);
        // rate shouldn&#39;t be less than half or more than twice.
        require(_newRate.mul(2) > baseRate && baseRate.mul(2) > _newRate);
        baseRate = _newRate;
    }
    
    function getRate(uint level) public view returns (uint) {
        if (level == 4) {
            return baseRate.mul(6);
        } else if (level == 3) {
            return baseRate.mul(5);
        } else if (level == 2) {
            return baseRate.mul(3);
        } else if (level == 1) {
            return baseRate.mul(2);
        } else {
            return baseRate.mul(6);
        } 
    }
    
    function fundAccount(address ref, uint eth, uint level) internal {
        if (ref != address(0x0) && userLevel[ref] >= level) {
            etherBalance[ref] += eth;
        } else {
            etherBalance[owner] += eth;
        }
    }
    
    function distributeMoney(address ref, address parent1, uint money) internal {
        // since we are calculating percentage which will be 
        // (money * x)/100
        money = money.div(100);
        
        fundAccount(ref, money.mul(FIRST_USER_CUT), 1);
        fundAccount(parent1, money.mul(SECOND_USER_CUT), 2);
        fundAccount(userReferrer[parent1], money.mul(THIRD_USER_CUT), 3);
        fundAccount(userReferrer[userReferrer[parent1]], money.mul(FOURTH_USER_CUT), 4);
        fundAccount(owner, money.mul(OWNER_CUT), 0);
    }
    
    function buyReferTokens(address ref, uint8 level) payable public {
        require(level > 0 && level < 5);
        
        if (userLevel[msg.sender] == 0) { // new user
            userLevel[msg.sender] = level;
            if (getTokenBalance(ref) < 1) {  // The referee doesn&#39;t have a token 
                ref = owner; // change referee
            }
            userReferrer[msg.sender] = ref; // permanently set owner as the referrer
            referContractInterface.decrement(userReferrer[msg.sender]);
        } else { // old user
            require(userLevel[msg.sender] == level);
            if (getTokenBalance(userReferrer[msg.sender]) < 1) { // The referee doesn&#39;t have a token
                ref = owner; // only change the parent but don&#39;t change gradparents
            } else {
                ref = userReferrer[msg.sender];
            }
            referContractInterface.decrement(ref);
        }
        
        uint tokens = msg.value.div(getRate(level));
        require(tokens >= 5);
        referContractInterface.mint(msg.sender, tokens);
        distributeMoney(ref, userReferrer[userReferrer[msg.sender]] , msg.value);
        tokensBought[msg.sender] += tokens;
        emit Bought(msg.sender, ref, userReferrer[userReferrer[msg.sender]], msg.value, tokens, level);
    }
    
    function upgradeLevel(uint8 level) payable public {
        require(level <= 4);
        require(userLevel[msg.sender] != 0 && userLevel[msg.sender] < level);
        uint rateDiff = getRate(level).sub(getRate(userLevel[msg.sender]));
        uint toBePaid = rateDiff.mul(tokensBought[msg.sender]);
        require(msg.value >= toBePaid);
        userLevel[msg.sender] = level;
        distributeMoney(userReferrer[msg.sender], userReferrer[userReferrer[msg.sender]] , msg.value);
        emit LevelUpdated(msg.sender, msg.value, level);
    }
    
    function getAmountToUpdate(uint8 level) view public returns (uint) {
        uint rate = getRate(level).mul(tokensBought[msg.sender]);
        uint ratePaid = getRate(userLevel[msg.sender]).mul(tokensBought[msg.sender]);
        return rate.sub(ratePaid);
    }
    
    function withdraw() public {
        uint amount = etherBalance[msg.sender];
        etherBalance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function getTokenBalance(address _who) public view returns(uint) {
        return referContractInterface.getBalance(_who);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}