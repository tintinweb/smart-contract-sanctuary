pragma solidity ^0.4.18;

/*

__/\\\\\\\\\\\\_____/\\\\\\\\\\\__/\\\________/\\\_____/\\\\\\\\\\\_________________________________                 
 _\/\\\////////\\\__\/////\\\///__\/\\\_______\/\\\___/\\\/////////\\\_______________________________                
  _\/\\\______\//\\\_____\/\\\_____\//\\\______/\\\___\//\\\______\///________________________________               
   _\/\\\_______\/\\\_____\/\\\______\//\\\____/\\\_____\////\\\_______________________________________              
    _\/\\\_______\/\\\_____\/\\\_______\//\\\__/\\\_________\////\\\____________________________________             
     _\/\\\_______\/\\\_____\/\\\________\//\\\/\\\_____________\////\\\_________________________________            
      _\/\\\_______/\\\______\/\\\_________\//\\\\\_______/\\\______\//\\\________________________________           
       _\/\\\\\\\\\\\\/____/\\\\\\\\\\\______\//\\\_______\///\\\\\\\\\\\/_________________________________          
        _\////////////_____\///////////________\///__________\///////////___________________________________         
         __________________________________________________________________________/\\\_____/\\\\\\\\\\\\____        
          ________________________________________________________________________/\\\\\____\/\\\////////\\\__       
           ______________________________________________________________________/\\\/\\\____\/\\\______\//\\\_      
            ____________________________________________________________________/\\\/\/\\\____\/\\\_______\/\\\_     
             __________________________________________________________________/\\\/__\/\\\____\/\\\_______\/\\\_    
              ________________________________________________________________/\\\\\\\\\\\\\\\\_\/\\\_______\/\\\_   
               _______________________________________________________________\///////////\\\//__\/\\\_______/\\\__  
                _________________________________________________________________________\/\\\____\/\\\\\\\\\\\\/___ 
                 _________________________________________________________________________\///_____\////////////_____

                                   
                              ____  ██╗    ██████╗  █████╗ ██╗   ██╗    ██████╗  ██████╗ ██╗ _____
                           _______ ███║    ██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔═══██╗██║ ________
╚                         ________  ██║    ██║  ██║███████║ ╚████╔╝     ██████╔╝██║   ██║██║ _________
                           _______  ██║    ██║  ██║██╔══██║  ╚██╔╝      ██╔══██╗██║   ██║██║ ________
                             _____  ██║    ██████╔╝██║  ██║   ██║       ██║  ██║╚██████╔╝██║ ______
                               ___  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═╝ ____
                                _______________________________________________________________
                                                  _____________________________
                                                 |      www.Divs4D.com/1Day    |
                                                 | 100% return every 24 hours  |
                                                 |        ROI in 1 day         |
                                                 |    5% Referral commision    |
                                                 |_____________________________|                            
*/
contract Divs4D{
       
                                             /*=====================================      
                                              |-|-|-|-|-|-|--MAPPINGS--|-|-|-|-|-|-|                   
                                              =====================================*/      

    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    mapping (address => uint256) public affiliateCommision;
    
    address dev = 0xF5c47144e20B78410f40429d78E7A18a2A429D0e;
    address promoter = 0xC7a4Bf373476e265fC1b428CC4110E83aE32e8A3;
    
    
    bool public started;


                                             /*____________________________________
                                              |   ONLY DEV CAN START THE MADNESS   |
                                              |____________________________________*/
    
    
    modifier onlyDev() {
        require(msg.sender == dev);
        _;
    }


                                             /*=====================================
                                              ||||||||||||||FUNCTIONS|||||||||||||||             
                                              =====================================*/

    function start() public onlyDev {
        started = true;
    }
                                             /*____________________________________
                                              |   Minimum of 0.01 ETHER deposit    |
                                              |  And game must be started by dev   |      
                                              |____________________________________*/
    
    
    function investETH(address referral) public payable {

        require(msg.value >= 0.01 ether);
        require(started);
                              
        if(getProfit(msg.sender) > 0){
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;
        uint256 commision = SafeMath.div(amount, 20);
        if(referral != msg.sender && referral != 0x1 && referral != dev && referral != promoter){
            affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], commision);
        }
        
        affiliateCommision[dev] = SafeMath.add(affiliateCommision[dev], commision);
        affiliateCommision[promoter] = SafeMath.add(affiliateCommision[promoter], commision);
        
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], amount);
        lastInvest[msg.sender] = now;
    }
                                             /*____________________________________
                                              |    Players can withdraw profit     |
                                              |  anytime as long as there is ETH   |      
                                              |____________________________________*/
    
    function withdraw() public{
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        msg.sender.transfer(profit);
    }
    
    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now, lastInvest[customer]);
        return SafeMath.div(SafeMath.mul(secondsPassed, investedETH[customer]), 86400);
    }
    
    function reinvestProfit() public {
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], profit);
    }
    
    function getAffiliateCommision() public view returns(uint256){
        return affiliateCommision[msg.sender];
    }
    
    function withdrawAffiliateCommision() public {
        require(affiliateCommision[msg.sender] > 0);
        uint256 commision = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commision);
    }
    
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}



                                             /*======================================
                                              ||||||GOTTA HAVE THAT SAFE MATH||||||||             
                                              ======================================*/

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