pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  } 

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract LoveToken {
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function freeze(address target) public returns (bool);
  function release(address target) public returns (bool);
}

contract LoveContribution is Ownable {

  using SafeMath for uint256;

  //The token being given
  LoveToken  token;
  
  // contribution in wei
  mapping(address => uint256) public contributionOf;
  
  // array of contributors
  address[] contributors;
  
  // array of top contributed winners
   address[] topWinners=[address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0)];
  
  // array of random winners
  address[] randomWinners;
  
  // won amount in wei
  mapping(address => uint256) public amountWon;
  
  // ckeck whether the winner withdrawn the won amount
  mapping(address => bool) public claimed;
  
  // ckeck whether the contributor completed KYC
  mapping(address => bool) public KYCDone;

  // start and end timestamps
  uint256 public startTime;
  uint256 public endTime;

  // price of token in wei
  uint256 public rate = 10e14;

  // amount of wei raised
  uint256 public weiRaised;
  
  // amount of wei withdrawn by owner
  uint256 public ownerWithdrawn;
  
  event contributionSuccessful(address indexed contributedBy, uint256 contribution, uint256 tokenReceived);
  event FundTransfer(address indexed beneficiary, uint256 amount);
  event FundTransferFailed();
  event KYCApproved(address indexed contributor);

  function LoveContribution(uint256 _startTime, uint256 _endTime, LoveToken  _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    token = _token;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    contribute();
  }
    
   
  /**
   * @dev low level token purchase function
   */
  function contribute() internal {
    uint256 weiAmount = msg.value;
    require(msg.sender != address(0) && weiAmount >= 5e15);
    require(now >= startTime && now <= endTime);
    
    // calculate the number of tokens to be send. multipling with (10 ** 8) since the token used has 8 decimals
    uint256 numToken = getTokenAmount(weiAmount).mul(10 ** 8);
    
    // check whether the contract have enough token balance 
    require(token.balanceOf(this).sub(numToken) > 0 );
    
    // check whether the sender is contributing for the first time
    if(contributionOf[msg.sender] <= 0){
        contributors.push(msg.sender);
        token.freeze(msg.sender);
    }
    
    contributionOf[msg.sender] = contributionOf[msg.sender].add(weiAmount);
    
    token.transfer(msg.sender, numToken);
    
    weiRaised = weiRaised.add(weiAmount);
    
    updateWinnersList();
    
    contributionSuccessful(msg.sender,weiAmount,numToken);
  }

  // @return Number of tokens
  function getTokenAmount(uint256 weiAmount) internal returns(uint256) {
       uint256 tokenAmount;
       
        if(weiRaised <= 100 ether){
            rate = 10e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 100 ether && weiRaised <= 150 ether){
            rate = 15e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 150 ether && weiRaised <= 200 ether){
            rate = 20e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 200 ether && weiRaised <= 250 ether){
            rate = 25e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        else if(weiRaised > 250){
            rate = 30e14;
            tokenAmount = weiAmount.div(rate);
            return tokenAmount;
        }
        
  }
  
  // update winners list
  function updateWinnersList() internal returns(bool) {
      if(topWinners[0] != msg.sender){
       bool flag=false;
       for(uint256 i = 0; i < 10; i++){
           if(topWinners[i] == msg.sender){
               break;
           }
           if(contributionOf[msg.sender] > contributionOf[topWinners[i]]){
               flag=true;
               break;
           }
       }
       if(flag == true){
           for(uint256 j = 10; j > i; j--){
               if(topWinners[j-1] != msg.sender){
                   topWinners[j]=topWinners[j-1];
               }
               else{
                   for(uint256 k = j; k < 10; k++){
                       topWinners[k]=topWinners[k+1];
                   }
               }
            }
            topWinners[i]=msg.sender;
       }
       return true;
     }
  }

  // @return true if contract is expired
  function hasEnded() public view returns (bool) {
    return (now > endTime) ;
  }
  
  /**
   * @dev Function to find the winners
   */
  function findWinners() public onlyOwner {
    require(now >= endTime);
    
    // number of contributors
    uint256 len=contributors.length;
    
    // factor multiplied to get the deserved percentage of weiRaised for a winner
    uint256 mulFactor=50;
    
    // setting top ten winners with won amount 
    for(uint256 num = 0; num < 10 && num < len; num++){
      amountWon[topWinners[num]]=(weiRaised.div(1000)).mul(mulFactor);
      mulFactor=mulFactor.sub(5);
     }
     topWinners.length--;
       
    // setting next 10 random winners 
    if(len > 10 && len <= 20 ){
        for(num = 0 ; num < 20 && num < len; num++){
            if(amountWon[contributors[num]] <= 0){
            randomWinners.push(contributors[num]);
            amountWon[contributors[num]]=(weiRaised.div(1000)).mul(3);
            }
        }
    }
    else if(len > 20){
        for(uint256 i = 0 ; i < 10; i++){
            // finding a random number(winner) excluding the top 10 winners
            uint256 randomNo=random(i+1) % len;
            // To avoid multiple wining by same address
            if(amountWon[contributors[randomNo]] <= 0){
                randomWinners.push(contributors[randomNo]);
                amountWon[contributors[randomNo]]=(weiRaised.div(1000)).mul(3);
            }
            else{
                
                for(uint256 j = 0; j < len; j++){
                    randomNo=(randomNo.add(1)) % len;
                    if(amountWon[contributors[randomNo]] <= 0){
                        randomWinners.push(contributors[randomNo]);
                        amountWon[contributors[randomNo]]=(weiRaised.div(1000)).mul(3);
                        break;
                    }
                }
            }
        }    
    }
  }
  
    
  /**
   * @dev Generate a random using the block number and loop count as the seed of randomness.
   */
   function random(uint256 count) internal constant returns (uint256) {
    uint256 rand = block.number.mul(count);
    return rand;
  }
  
  /**
   * @dev Function to stop the contribution
   */
  function stop() public onlyOwner  {
    endTime = now ;
  }
  
  /**
   * @dev Function for withdrawing eth by the owner
   */
  function ownerWithdrawal(uint256 amt) public onlyOwner  {
    // Limit owner from withdrawing not more than 70% 
    require((amt.add(ownerWithdrawn)) <= (weiRaised.div(100)).mul(70));
    if (owner.send(amt)) {
        ownerWithdrawn=ownerWithdrawn.add(amt);
        FundTransfer(owner, amt);
    }
  }
  
  /**
   * @dev Function for approving contributors after KYC
   */
  function KYCApprove(address[] contributorsList) public onlyOwner  {
    for (uint256 i = 0; i < contributorsList.length; i++) {
        address addr=contributorsList[i];
        //set KYC Status
        KYCDone[addr]=true;
        KYCApproved(addr);
        token.release(addr);
    }
  }
  
  /**
   * @dev Function for withdrawing won amount by the winners
   */
  function winnerWithdrawal() public {
    require(now >= endTime);
    //check whether winner
    require(amountWon[msg.sender] > 0);
    //check whether winner done KYC
    require(KYCDone[msg.sender]);
    //check whether winner already withdrawn the won amount 
    require(!claimed[msg.sender]);

    if (msg.sender.send(amountWon[msg.sender])) {
        claimed[msg.sender]=true;
        FundTransfer(msg.sender,amountWon[msg.sender] );
    }
  }
  
  // @return Current token balance of this contract
  function tokensAvailable()public view returns (uint256) {
    return token.balanceOf(this);
  }
  
  // @return List of top winners
  function showTopWinners() public view returns (address[]) {
    require(now >= endTime);
        return (topWinners);
  }
  
  // @return List of random winners
  function showRandomWinners() public view returns (address[]) {
    require(now >= endTime);
        return (randomWinners);
  }
  
  /**
   * @dev Function to destroy contract
   */
  function destroy() public onlyOwner {
    require(now >= endTime);
    uint256 balance= this.balance;
    owner.transfer(balance);
    FundTransfer(owner, balance);
    uint256 balanceToken = tokensAvailable();
    token.transfer(owner, balanceToken);
    selfdestruct(owner);
  }
}