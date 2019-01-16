pragma solidity ^0.4.24;

/**
*GainCrypto.com
Crowd Funded Lottery Game - People who invest for the Lottery Bankroll will get 2.5% Returns every day for 60 days. After 60 days, the investor will be in a profit of 50%. We have a solid Lottery game, which generates the revenue to pay returns to the Investors.
*/

contract GainCrypto {

    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
    mapping(address => uint256) withdrawalsgross;
    mapping(address => uint256) referrer;
    uint256 public step = 5;
    uint256 public bankrollpercentage = 1;
    uint256 public maximumpercent = 150;
    uint256 public minimum = 10 finney;
    uint256 public stakingRequirement = 0.01 ether;
    uint256 public startTime = 1540308600;
    uint256 public randomizer = 456717097;
    uint256 private randNonce = 0;
    address public ownerWallet;
    address public owner;
    address mainpromoter = 0xf42934E5C290AA1586d9945Ca8F20cFb72307f91;
    address subpromoter = 0xfb84cb9ef433264bb4a9a8ceb81873c08ce2db3d;
    address telegrampromoter = 0x8426D45E28c69B0Fc480532ADe948e58Caf2a61E;
    address youtuber1 = 0x4ffE17a2A72bC7422CB176bC71c04EE6D87cE329;
    address youtuber2 = 0xcB0C3b15505f8048849C1D4F32835Bb98807A055;
    address youtuber3 = 0x05f2c11996d73288AbE8a31d8b593a693FF2E5D8;
    address youtuber4 = 0x191d636b99f9a1c906f447cC412e27494BB5047F;
    address youtuber5 = 0x0c0c5F2C7453C30AEd66fF9757a14dcE5Db0aA94;
    address gameapi = 0x1f4Af40671D6bE6b3c21e184C1763bbD16618518;
   

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Lottery(address player, uint256 lotteryNumber, uint256 amount, uint256 result, bool isWin);
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

    /**
     * @dev Modifiers
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     * @param newOwnerWallet The address to transfer ownership to.
     */
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

    /**
     * @dev Investments
     */
    function () public payable {
        buy(0x0);
    }

    function buy(address _referredBy) public payable {
        if (now <= startTime) {
             require(msg.sender==owner);
            }
        require(msg.value >= minimum);

        address _customerAddress = msg.sender;

        if(
           // is this a referred purchase?
           _referredBy != 0x0000000000000000000000000000000000000000 &&

           // no cheating!
           _referredBy != _customerAddress &&

           // does the referrer have at least X whole tokens?
           // i.e is the referrer a godly chad masternode
           investments[_referredBy] >= stakingRequirement
       ){
           // wealth redistribution
           referrer[_referredBy] = referrer[_referredBy].add(msg.value.mul(5).div(100));
       }

       if (investments[msg.sender] > 0){
           if (withdraw()){
               withdrawals[msg.sender] = 0;
           }
       }
       investments[msg.sender] = investments[msg.sender].add(msg.value);
       joined[msg.sender] = block.timestamp;
       uint256 percentmax = msg.value.mul(5).div(100);
       uint256 percentmaxhalf = percentmax.div(2);
       uint256 percentmin = msg.value.mul(1).div(100);
       uint256 percentminhalf = percentmin.div(2);
       
       ownerWallet.transfer(percentmax);
       mainpromoter.transfer(percentmaxhalf);
       subpromoter.transfer(percentmin);
       telegrampromoter.transfer(percentmin);
       youtuber1.transfer(percentminhalf);
       youtuber2.transfer(percentminhalf);
       youtuber3.transfer(percentminhalf);
       youtuber4.transfer(percentminhalf);
       youtuber5.transfer(percentminhalf);
       emit Invest(msg.sender, msg.value);
       
    }


     //--------------------------------------------------------------------------------------------
    // LOTTERY
    //--------------------------------------------------------------------------------------------
    /**
    * @param _value number in array [1,2,3]
    */
    function lottery(uint256 _value) public payable
    {
        uint256 maxbetsize = address(this).balance.mul(bankrollpercentage).div(100);
        require(msg.value <= maxbetsize);
        uint256 random = getRandomNumber(msg.sender) + 1;
        bool isWin = false;
        if (random == _value) {
            isWin = true;
            uint256 prize = msg.value.mul(180).div(100);
            if (prize <= address(this).balance) {
                msg.sender.transfer(prize);
            }
        }
        ownerWallet.transfer(msg.value.mul(5).div(100));
        gameapi.transfer(msg.value.mul(3).div(100));
        mainpromoter.transfer(msg.value.mul(2).div(100));
        emit Lottery(msg.sender, _value, msg.value, random, isWin);
    }


    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 percentfinal = percent.div(2);
        uint256 different = percentfinal.mul(minutesCount).div(1440);
        uint256 balancetemp = different.sub(withdrawals[_address]);
        uint256 maxpayout = investments[_address].mul(maximumpercent).div(100);
        uint256 balancesum = withdrawalsgross[_address].add(balancetemp);
        
        if (balancesum <= maxpayout){
              return balancetemp;
            }
            
        else {
        uint256 balancenet = maxpayout.sub(withdrawalsgross[_address]);
        return balancenet;
        }
        
        
    }

   
    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
        uint256 balance = getBalance(msg.sender);
        if (address(this).balance > balance){
            if (balance > 0){
                withdrawals[msg.sender] = withdrawals[msg.sender].add(balance);
                withdrawalsgross[msg.sender] = withdrawalsgross[msg.sender].add(balance);
                uint256 maxpayoutfinal = investments[msg.sender].mul(maximumpercent).div(100);
                msg.sender.transfer(balance);
                if (withdrawalsgross[msg.sender] >= maxpayoutfinal){
                investments[msg.sender] = 0;
                withdrawalsgross[msg.sender] = 0;
                withdrawals[msg.sender] = 0;
            }
              emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            return false;
        }
    }

 
    function bounty() public {
        uint256 refBalance = checkReferral(msg.sender);
        if(refBalance >= minimum) {
             if (address(this).balance > refBalance) {
                referrer[msg.sender] = 0;
                msg.sender.transfer(refBalance);
                emit Bounty(msg.sender, refBalance);
             }
        }
    }

  
    function checkBalance() public view returns (uint256) {
        return getBalance(msg.sender);
    }

    function checkWithdrawals(address _investor) public view returns (uint256) {
        return withdrawals[_investor];
    }
    
    function checkWithdrawalsgross(address _investor) public view returns (uint256) {
        return withdrawalsgross[_investor];
    }

    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }

    function checkReferral(address _hunter) public view returns (uint256) {
        return referrer[_hunter];
    }
    
    function setYoutuber1(address _youtuber1) public {
      require(msg.sender==owner);
      youtuber1 = _youtuber1;
    }
    
    function setYoutuber2(address _youtuber2) public {
      require(msg.sender==owner);
      youtuber2 = _youtuber2;
    }
    
    function setYoutuber3(address _youtuber3) public {
      require(msg.sender==owner);
      youtuber3 = _youtuber3;
    }
    
    function setYoutuber4(address _youtuber4) public {
      require(msg.sender==owner);
      youtuber4 = _youtuber4;
    }
    
    function setYoutuber5(address _youtuber5) public {
      require(msg.sender==owner);
      youtuber5 = _youtuber5;
    }
    
    function setBankrollpercentage(uint256 _Bankrollpercentage) public {
      require(msg.sender==owner);
      bankrollpercentage = _Bankrollpercentage;
    }
    
    function setRandomizer(uint256 _Randomizer) public {
      require(msg.sender==owner);
      randomizer = _Randomizer;
    }
    
    function setStartTime(uint256 _startTime) public {
      require(msg.sender==owner);
      startTime = _startTime;
    }
    function checkContractBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }
    //----------------------------------------------------------------------------------
    // INTERNAL FUNCTION
    //----------------------------------------------------------------------------------
    function getRandomNumber(address _addr) private returns(uint256 randomNumber) 
    {
        randNonce++;
        randomNumber = uint256(keccak256(abi.encodePacked(now, _addr, randNonce, randomizer, block.coinbase, block.number))) % 7;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}