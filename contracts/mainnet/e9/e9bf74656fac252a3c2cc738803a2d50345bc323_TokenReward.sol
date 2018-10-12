pragma solidity ^0.4.24;

/*
    CryptoPrize(address _token_address)   // this will unlock the prize and send yum to user
  @author Yumerium Ltd
*/
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract YUM {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}


contract TokenReward {
    using SafeMath for uint256;
    uint256 public maxCount = 2 ** 256 - 1;
    uint256 public budget;
    uint256 public totalUnlocked;
    uint256 public startYum;
    uint256 public nextRewardAmount;
    uint256 public count;
    address public owner;
    YUM public token;

    event UnlockReward(address to, uint256 amount);
    event CalcNextReward(uint256 count, uint256 amount);
    event Retrieve(address to, uint256 amount);
    event AddBudget(uint256 budget, uint256 startYum);

    // start with 0 budget and 0 Yum for the prize
    constructor(address _token_address) public {
        budget = 0;
        startYum = 0;
        count = 0;
        owner = msg.sender;
        token = YUM(_token_address);
    }

    /* 
     * Calculate the next prize
     * TODO: Change the equation if needed
    */
    function calcNextReward() public returns (uint256) {
        uint256 oneYUM = 10 ** 8;
        uint256 amount = startYum.mul(oneYUM).div(count.mul(oneYUM).div(500).add(oneYUM)); // 100 YUM / (1 YUM / 500 + 1 YUM)
        emit CalcNextReward(count, amount);
        return amount;
    }
    
    // unlock the prize
    function sendNextRewardTo(address to) external {
        require(msg.sender==owner);
        uint256 amount = nextRewardAmount;
        require(amount > 0);
        uint256 total = totalUnlocked.add(amount);
        require(total<=budget);
        token.transfer(to, amount);
        budget = budget.sub(amount);
        if (count < maxCount)
            count++;
        totalUnlocked = total;
        nextRewardAmount = calcNextReward();
        emit UnlockReward(to, amount);
    }

    // change creator address
    function changeOwnerTo(address _creator) external {
        require(msg.sender==owner);
        owner = _creator;
    }

    // change creator address
    function changeYumAddressTo(address _token_address) external {
        require(msg.sender==owner);
        token = YUM(_token_address);
    }

    // Retrieve all YUM token left from the contract
    function retrieveAll() external {
        require(msg.sender==owner);
        uint256 amount = token.balanceOf(this);
        token.transfer(owner, amount);   
        emit Retrieve(owner, amount);   
    }

    // add more budget and reset startYum and count
    function addBudget(uint256 _budget, uint256 _startYum, uint256 _count) external {
        require(msg.sender==owner);
        require(token.transferFrom(msg.sender, this, _budget));
        budget = budget.add(_budget);
        startYum = _startYum;
        count = _count;
        nextRewardAmount = calcNextReward();
        emit AddBudget(budget, startYum);
    }
}