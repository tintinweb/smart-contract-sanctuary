pragma solidity ^0.4.18;

//
// EtherPiggyBank
// (etherpiggybank.com)
//        
//   <`--&#39;\>______
//   /. .  `&#39;     \
//  (`&#39;)  ,        @
//   `-._,        /
//      )-)_/--( >  
//     &#39;&#39;&#39;&#39;  &#39;&#39;&#39;&#39;
//
// Invest Ethereum into a long term stable solution where
// your investment can grow organically as the system expands.
// You will gain +1.5% of your invested Ethereum every day that
// you leave it in the Ether Piggy Bank!
// You can withdraw your investments at any time but it will
// incur a 20% withdrawal fee (~13 days of investing).
// You can also invest your profits back into your account and
// your gains will compound the more you do this!
// 
// Big players can compete for the investment positions available,
// every time someone makes a deposit into the Ether Piggy Bank,
// they will receive a percentage of that sale in their
// affiliate commision.
// You can buy this position off anyone and double it&#39;s current
// buying price but every 3-7 days (depending on the position),
// the buying price will halve until it reaches 0.125 ether.
// Upon buying, the previous investor gets 75% of the buying price,
// the dev gets 5% and the rest goes into the contract to encourage
// an all round balanced ecosystem!
//
// You will also receive a 5% bonus, which will appear in your
// affiliate commission, by referring another player to the game 
// via your referral URL! It&#39;s a HYIP on a smart contract, fully
// transparent and you&#39;ll never need to worry about an exit scam or
// someone taking all the money and leaving!


contract EtherPiggyBank {
    
    // investment tracking for each address
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    
    // for referrals and investor positions
    mapping (address => uint256) public affiliateCommision;
    uint256 REF_BONUS = 4; // 4% of the ether invested
    // goes into the ref address&#39; affiliate commision
    uint256 DEV_TAX = 1; // 1% of all ether invested
    // goes into the dev address&#39; affiliate commision
    
    uint256 BASE_PRICE = 0.125 ether; // 1/8 ether
    uint256 INHERITANCE_TAX = 75; // 75% will be returned to the
    // investor if their position is purchased, the rest will
    // go to the contract and the dev
    uint256 DEV_TRANSFER_TAX = 5;
    // this means that when purchased the sale will be distrubuted:
    // 75% to the old position owner
    // 5% to the dev
    // and 20% to the contract for all the other investors
    // ^ this will encourage a healthy ecosystem
    struct InvestorPosition {
        address investor;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
        uint256 percentageCut;
    }

    InvestorPosition[] investorPositions; 
    address dev;

    // start up the contract!
    function EtherPiggyBank() public {
        
        // set the dev address
        dev = msg.sender;
        
        // make the gold level investor
        investorPositions.push(InvestorPosition({
            investor: dev,
            startingLevel: 5, // 1/8 ether * 2^5 = 4 ether
            startingTime: now,
            halfLife: 7 days, // 7 days until the level decreases
            percentageCut: 5 // with 5% cut of all investments
            }));

        // make the silver level investor
        investorPositions.push(InvestorPosition({
            investor: dev,
            startingLevel: 4, // 1/8 ether * 2^4 = 2 ether
            startingTime: now,
            halfLife: 5 days, // 5 days until the level decreases
            percentageCut: 3 // with 3% cut of all investments
            }));

        // make the bronze level investor
        investorPositions.push(InvestorPosition({
            investor: dev,
            startingLevel: 3, // 1/8 ether * 2^3 = 1 ether
            startingTime: now,
            halfLife: 3 days, // 3 days until the level decreases
            percentageCut: 1 // with 1% cut of all investments
            }));
    }
    
    function investETH(address referral) public payable {
        
        require(msg.value >= 0.01 ether);
        
        if (getProfit(msg.sender) > 0) {
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;

        // handle all of our investor positions first
        bool flaggedRef = (referral == msg.sender || referral == dev); // ref cannot be the sender or the dev
        for(uint256 i = 0; i < investorPositions.length; i++) {
            
            InvestorPosition memory position = investorPositions[i];

            // check that our ref isn&#39;t an investor too
            if (position.investor == referral) {
                flaggedRef = true;
            }
            
            // we cannot claim on our own investments
            if (position.investor != msg.sender) {
                uint256 commision = SafeMath.div(SafeMath.mul(amount, position.percentageCut), 100);
                affiliateCommision[position.investor] = SafeMath.add(affiliateCommision[position.investor], commision);
            }

        }

        // now for the referral (if we have one)
        if (!flaggedRef && referral != 0x0) {
            uint256 refBonus = SafeMath.div(SafeMath.mul(amount, REF_BONUS), 100); // 4%
            affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], refBonus);
        }
        
        // hand out the dev tax
        uint256 devTax = SafeMath.div(SafeMath.mul(amount, DEV_TAX), 100); // 1%
        affiliateCommision[dev] = SafeMath.add(affiliateCommision[dev], devTax);

        
        // now put it in your own piggy bank!
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], amount);
        lastInvest[msg.sender] = now;

    }
    
    function divestETH() public {

        uint256 profit = getProfit(msg.sender);
        
        // 20% fee on taking capital out
        uint256 capital = investedETH[msg.sender];
        uint256 fee = SafeMath.div(capital, 5);
        capital = SafeMath.sub(capital, fee);
        
        uint256 total = SafeMath.add(capital, profit);

        require(total > 0);
        investedETH[msg.sender] = 0;
        lastInvest[msg.sender] = now;
        msg.sender.transfer(total);

    }
    
    function withdraw() public{

        uint256 profit = getProfit(msg.sender);

        require(profit > 0);
        lastInvest[msg.sender] = now;
        msg.sender.transfer(profit);

    }

    function withdrawAffiliateCommision() public {

        require(affiliateCommision[msg.sender] > 0);
        uint256 commision = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commision);

    }
    
    function reinvestProfit() public {

        uint256 profit = getProfit(msg.sender);

        require(profit > 0);
        lastInvest[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], profit);

    }

    function inheritInvestorPosition(uint256 index) public payable {

        require(investorPositions.length > index);
        require(msg.sender == tx.origin);

        InvestorPosition storage position = investorPositions[index];
        uint256 currentLevel = getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife);
        uint256 currentPrice = getCurrentPrice(currentLevel);

        require(msg.value >= currentPrice);
        uint256 purchaseExcess = SafeMath.sub(msg.value, currentPrice);
        position.startingLevel = currentLevel + 1;
        position.startingTime = now;

        // now do the transfers
        uint256 inheritanceTax = SafeMath.div(SafeMath.mul(currentPrice, INHERITANCE_TAX), 100); // 75%
        position.investor.transfer(inheritanceTax);
        position.investor = msg.sender; // set the new investor address

        // now the dev transfer tax
        uint256 devTransferTax = SafeMath.div(SafeMath.mul(currentPrice, DEV_TRANSFER_TAX), 100); // 5%
        dev.transfer(devTransferTax);

        // and finally the excess
        msg.sender.transfer(purchaseExcess);

        // after this point there will be 20% of currentPrice left in the contract
        // this will be automatically go towards paying for profits and withdrawals

    }

    function getInvestorPosition(uint256 index) public view returns(address investor, uint256 currentPrice, uint256 halfLife, uint256 percentageCut) {
        InvestorPosition memory position = investorPositions[index];
        return (position.investor, getCurrentPrice(getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife)), position.halfLife, position.percentageCut);
    }

    function getCurrentPrice(uint256 currentLevel) internal view returns(uint256) {
        return BASE_PRICE * 2**currentLevel; // ** is exponent, price doubles every level
    }

    function getCurrentLevel(uint256 startingLevel, uint256 startingTime, uint256 halfLife) internal view returns(uint256) {
        uint256 timePassed = SafeMath.sub(now, startingTime);
        uint256 levelsPassed = SafeMath.div(timePassed, halfLife);
        if (startingLevel < levelsPassed) {
            return 0;
        }
        return SafeMath.sub(startingLevel,levelsPassed);
    }

    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now, lastInvest[customer]);
        return SafeMath.div(SafeMath.mul(secondsPassed, investedETH[customer]), 5760000); // = days * amount * 0.015 (+1.5% per day)
    }
    
    function getAffiliateCommision() public view returns(uint256){
        return affiliateCommision[msg.sender];
    }
    
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }

}

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