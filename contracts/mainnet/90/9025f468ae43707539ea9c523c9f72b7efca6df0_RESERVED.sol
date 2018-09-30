/*
 * Project RESERVED
 * Here you can see the code with comments
 * Enjoy :)
 **/
pragma solidity ^0.4.24;
contract RESERVED {
   
    address owner; //address of contract creator
    address investor; //address of user who just invested money to the contract
    mapping (address => uint256) balances; //amount of investment for each address
    mapping (address => uint256) timestamp; //time from the last payment for each address
    mapping (address => uint16) rate; //rate for each address 
    mapping (address => uint256) referrers; //structure for checking whether investor had referrer or not
    uint16 default_rate = 300; //default rate (minimal rate) for investors
    uint16 max_rate = 1000; //maximal possible rate
    uint256 eth = 1000000000000000000; //eth in wei
    uint256 jackpot = 0; //amount of jackpot
    uint256 random_number; //random number from 1 to 100
    uint256 referrer_bonus; //amount of referrer bonus
    uint256 deposit; //amount of investment
    uint256 day = 86400; //seconds in 24 hours
    bytes msg_data; //referrer address
    
    //Store owner as a person created that contract
    constructor() public { owner = msg.sender;}
    
    //Function calls in the moment of investment
    function() external payable{
        
        deposit = msg.value; //amount of investment
        
        investor = msg.sender; //address of investor
        
        msg_data = bytes(msg.data); //address of referrer
        
        owner.transfer(deposit / 10); //transfers 10% to the advertisement fund
        
        tryToWin(); //jackpot
        
        sendPayment(); //sends payment to investors
        
        updateRate(); //updates rates of investors depending on amount of investment
        
        upgradeReferrer(); //sends bonus to referrers and upgrates their rates, also increases the rate of referral
        
        
    }
    
    //Collects jackpot and sends it to lucky investor
    function tryToWin() internal{
        random_number = uint(blockhash(block.number-1))%100 + 1;
        if (deposit >= (eth / 10) && random_number<(deposit/(eth / 10) + 1) && jackpot>0) {
            investor.transfer(jackpot);
            jackpot = deposit / 20;
        }
        else jackpot += deposit / 20;
    }
    
    //Sends payment to investor
    function sendPayment() internal{
        if (balances[investor] != 0){
            uint256 paymentAmount = balances[investor]*rate[investor]/10000*(now-timestamp[investor])/day;
            investor.transfer(paymentAmount);
        }
        timestamp[investor] = now;
        balances[investor] += deposit;
    }
    
    //Assigns a rate depending on the amount of the deposit
    function updateRate() internal{
        require (balances[investor]>0);
        if (balances[investor]>=(10*eth) && rate[investor]<default_rate+75){
                    rate[investor]=default_rate+75;
                }
                else if (balances[investor]>=(5*eth) && rate[investor]<default_rate+50){
                        rate[investor]=default_rate+50;
                    }
                    else if (balances[investor]>=eth && rate[investor]<default_rate+25){
                            rate[investor]=default_rate+25;
                        }
                        else if (rate[investor]<default_rate){
                                rate[investor]=default_rate;
                            }
    }
    
    //Sends bonus to referrers and upgrates their rates, also increases the rate of referral
    function upgradeReferrer() internal{
        if(msg_data.length == 20 && referrers[investor] == 0) {
            address referrer = bytesToAddress(msg_data);
            if(referrer != investor && balances[referrer]>0){
                referrers[investor] = 1;
                rate[investor] += 50; 
                referrer_bonus = deposit * rate[referrer] / 10000;
                referrer.transfer(referrer_bonus); 
                if(rate[referrer]<max_rate){
                    if (deposit >= 10*eth){
                        rate[referrer] = rate[referrer] + 100;
                    }
                    else if (deposit >= 3*eth){
                            rate[referrer] = rate[referrer] + 50;
                        }
                        else if (deposit >= eth / 2){
                                rate[referrer] = rate[referrer] + 25;
                            }
                            else if (deposit >= eth / 10){
                                    rate[referrer] = rate[referrer] + 10;
                                }
                }
            }
        }    
        referrers[investor] = 1; //Protection from the writing referrer address with the next investment
    }
    
    //Transmits bytes to address
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }
    
}