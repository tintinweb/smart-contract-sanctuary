/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

/*
         ___.                                                                       .__                 .__                 __    
        \_ |__  __ __   ____  ____ _____    ____   ____   ___________        ___  _|__|_____           |  |   ____   ____ |  | __
         | __ \|  |  \_/ ___\/ ___\\__  \  /    \_/ __ \_/ __ \_  __ \       \  \/ /  \____ \          |  |  /  _ \_/ ___\|  |/ /
         | \_\ \  |  /\  \__\  \___ / __ \|   |  \  ___/\  ___/|  | \/        \   /|  |  |_> >         |  |_(  <_> )  \___|    < 
         |___  /____/  \___  >___  >____  /___|  /\___  >\___  >__|            \_/ |__|   __/          |____/\____/ \___  >__|_ \
             \/            \/    \/     \/     \/     \/     \/                       |__|                              \/     \/
 
 **************************************************************************
 MAKE SURE WHEN SENDING 0 -- TO THE CONTRACT AKA WITHDRAWING -- TO UP THE GAS
 **************************************************************************
 IF A FAILURE OCCURS, IT IS BECAUSE OF LOW GAS!!!
 **************************************************************************
 
 So, you're here to review code. Let's make it easy for you.
 
 There are four unlock periods, hence four bools. And four bools for, if the recipient received them.
 
 All that has to happen is a standard payable receivable function that is triggered when 0 eth is sent (any more than 0 is reverted).
 
 Alternatively, if the VIP has access to the contract through etherscan, they can trigger the sendOut function for payment.
 
 That receivable function triggers a simple internal function for updating the bools accordingly in a cascading list of if/else.
 
 That internal function triggers the sendOut() function that actually sends out the token (paid for by the VIP aka gas).
 
 The sendOut function is significantly cheaper to use than sending 0 in terms of gas. 
 
 If gas issues persist (erros), set gas rate to 800k.
 
*/


//TEST TO MAINNET CONVERSION
//CHANGE - V2 ADDRESS, LOCKS, BUMPS AND WITHDRAWL ADDRESS

pragma solidity ^0.4.24;

interface BuccV2 {
    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/* All variables set ot private to prevent additional contracts from interacting with variables, they are set in stone */
contract BuccaneerVIPLOCK {
    //Could use/would use a constructor but I didn't want to, all variables initialized at runtime
    
    /* VARIABLES */
    
    //BUCC contract
    BuccV2 private buccInstance;
    
    //address of tokens - change for testnet and mainnet
    address private v2Address = address(0xd5a7d515fb8b3337acb9b053743e0bc18f50c855);
    
    //Time Locks - change for testnet and mainnet
    //84 days = 12 weeks / 28 days = one month
    uint256 private initialLock = 84 days;
    uint256 private timeBump = 28 days;
    uint256 private timeofCreation = now;
    
    //Withdrawer 
    address private userWithdrawlAddress = address(0x0aD7A09575e3eC4C109c4FaA3BE7cdafc5a4aDBa);
    
    //Deposit Slip (as proof of deposit)
    uint256 private depositSlip;
    
    //Bools for withdrawl
    bool private withdrawl1 = false;
    bool private withdrawl2 = false;
    bool private withdrawl3 = false;
    bool private withdrawl4 = false;
    
    
    //Was it sent?
    bool private payment1 = false;
    bool private payment2 = false;
    bool private payment3 = false;
    bool private payment4 = false;

    /* FUNCTIONS */

    //For showing number of tokens - there are ten decimals in the Bucc contract
    function displayBalanceToShow() public view returns (uint256) {
        return depositSlip / 10000000000; 
    }
    
    
    //One way deposit function
    function depositToLOCK(uint256 amountToDeposit) public returns (bool) {
        buccInstance = BuccV2(v2Address);
        depositSlip += amountToDeposit;
        return buccInstance.transferFrom(msg.sender, address(this), amountToDeposit);
    }
    
    
    //return timestamp of contract creation
    function returnTimeofCreation() public view returns (uint256) {
        return timeofCreation;
    }
    
    
    //Just to observe the EVM's internal clock for testing purposes
    function returnTimeNow() public view returns (uint256) {
        return now;
    }
    
    
    //Lookup if payment was sent
    function lookUpPaymentBool(uint256 lookupPayment) public view returns (bool) {
        if (lookupPayment == 1) {
            return payment1;
        } else if (lookupPayment == 2) {
            return payment2;
        } else if (lookupPayment == 3) {
            return payment3;
        } else if (lookupPayment == 4) {
            return payment4;
        }
    }
    
    
    //Can the VIP withdraw?
    function VIEWisUnlocked(uint256 lookupPayment) public view returns (bool) {
        //to prevent infection of the time keeping variable
        uint256 calculate = timeofCreation;
        if ((lookupPayment == 1) && (now > (calculate += initialLock))) {
            return true;
        }
        
        if ((lookupPayment == 2) && (now > (calculate += initialLock + timeBump))) {
            return true;
        }
        
        if ((lookupPayment == 3) && (now > (calculate += initialLock + (timeBump * 2)))) {
            return true;
        } 
        
        if ((lookupPayment == 4) && (now > (calculate += initialLock + (timeBump * 3)))) {
            return true;
        }
        //default
        return false;
    }
    
    
    
    /* THREE STEPS, TRIGGER, UNLOCK, SENDOUT */
    
    // 1.
    //Trigger function for when the user sends in zero
    function () payable external {
    //To not allow the VIP to send money to this contract on accident
    if (msg.value > 0) {
        revert();
    }
    
    //
    if (msg.sender == userWithdrawlAddress) {
        //run the transfer out function
        sendOut();
    } else {
        revert();
    }
    }
    
    
    
    // 2.
    //Internal bool adjustment function for changing based on the time expired locks
    //Aka, if time expires past the lock, allow the unlock to happen in a rolling fashion, missed the first lock? You'll get both when you unlock.
    //All conditions are separated to act as separate conditionals so that if a lock expires, it shouldn't require multiple txs
    //However, one instance where a third lock was not sent out was encountered. It was patched but if such an issue persisits, simply resend
    function isUnlocked() internal {
        //to prevent infection of the time keeping variable
        uint256 calculate = timeofCreation;
        if (!withdrawl1 && (now > (calculate += initialLock))) {
            withdrawl1 = true;
        }
        
        if (!withdrawl2 && (now > (calculate += initialLock + timeBump))) {
            withdrawl2 = true;
        }
        
        if (!withdrawl3 && (now > (calculate += initialLock + (timeBump * 2)))) {
            withdrawl3 = true;
        } 
        
        if (!withdrawl4 && (now > (calculate += initialLock + (timeBump * 3)))) {
            withdrawl4 = true;
        }
    }
    
    
    
    // 3.
    //When the lock expires, withdraw
    //All conditions are separated to act as separate conditionals so that if a lock expires, it wouldn't require multiple txs
    function sendOut() public returns (bool) {
        //Update variables if need be
        isUnlocked();
        
        //doublecheck
        require (userWithdrawlAddress == msg.sender);
        
        //temp variable to enact sending
        uint256 baseAmount = 1000000000000000;
        uint256 toSendtoVIP = 0;
        
        //time lock displayed here
        //Ethereum gets very weird with if/else statements at least in the older versions, hence the brackets
        if ((withdrawl1) && (!payment1)) {
            toSendtoVIP += baseAmount;
            payment1 = true;
        }
        
        if ((withdrawl2) && (!payment2)) {
            toSendtoVIP += baseAmount;
            payment2 = true;
        }
        
        if ((withdrawl3) && (!payment3)) {
            toSendtoVIP += baseAmount;
            payment3 = true;
        }
        
        if ((withdrawl4) && (!payment4)) {
            toSendtoVIP += baseAmount;
            payment4 = true;
        }
        
        //Now execute
        buccInstance = BuccV2(v2Address);
        depositSlip -= toSendtoVIP;
        if (depositSlip == 0) {
            buccInstance.transfer(userWithdrawlAddress, toSendtoVIP);
            //will return gas to VIP for contract self destruct upon completion of all tokens being sent
            selfdestruct(this);
            return true;
        } else {
            return buccInstance.transfer(userWithdrawlAddress, toSendtoVIP);
        }
    }
}



                                                                                                                                                                                               
                                                                        /**(((&@@@@&@#/                                                                                      
                                                     (#@@@@@/   (@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                                                                              
                                              .&@@#...........,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                                            
                                           (@@........(&&@@#(,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##,,,#@@@                                                             
                                        @@([email protected]@@@@@@@@@@@@@@@@@%....,@@@@@@@@@@@@@@@@@@@@@@@@@@.,&@@@@@@@@,,@                                                            
                                    *@@*....,&@@@@@@@@@@@@@@@@@@@@@@@%....&@@@@@@@@@@@@@@@@@@@@*../@@@@@@@@@@&[email protected]
[email protected]@%...,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.../@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@&.#@                                                           
                              @@,....%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,...#@@@@@@@@@@@@@,[email protected]@@@@@@@@@@@@@@/,%@                                                          
                          ,@@([email protected]@@@@@@@@@@@@(@@@/@@[email protected]*@@@@@@@@@@@@@@@@/[email protected]@@@@@@@@@@,[email protected]@@@@@@@@@@@@@@@@@[email protected]&                                                         
                      /@@@/....,@@@@@@@@@@@@@@@@#*@@&#(@[email protected]@@@@@@@@@@@@@@@@@....(@@@@@@@@@..,@@@@@@@@@@@@@@@@@@@,*@@                                                       
                  /@@%.....,@@@@@@@@@@@@@@@@@@@@/@&@@((**@@@@@@@[email protected]@@@@@@@@@@@@%[email protected]@@@@@@@,.(@@@@@@@@@@@@@@@@@@@@@..,@@*                                                   
              ,@@#...../&@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@..&@@@@@@@@@@@@@@@@,[email protected]@@@@@@@,[email protected]@@@@@@@@@@@@@@@@@@@@@@@,.*@@@#.                                              
          ,@@%.....*@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@%@@@@@@,@@@@@@@@@@@@@@@@@@(..(@@@@@@@@,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&/..,@@&*                                         
       [email protected]@@..../%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@%@@@@@@@@@@@@@@@@@@@@@@@,[email protected]@@@@@@@@%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#...#@@,                                     
      @%...#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@.(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,..,@@                                   
   [email protected]/[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..%@@@@@@@@@@@..(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,..&@.                                
   @#./@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@/.#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,..(@*                              
   &@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..,@@@@@@@@@@@,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.,@                              
     ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#..*@@@@@@@@@,..,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]                              
          ,*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&...*%%&&%,...&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                              
                 ,@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.....,#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    
                         .*(((,,,,(@%%%%%%%%%@%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                    
                                 @%%%%@@@@&%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%@                                                    
                               %@%%%%%%%%%%&@@@@@@@%#####&@######&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%(@@@#                                                 
                                ,@&%%%@################@&##@@%#####%%%#####%@@@@@@@@@@@@@@@@@@@@@@@@@@@@###%@@@@@@@&##@@@@@&                                                
                             (@@&%%%%%@&#############%@#(@######%%%#(((((#(((((#((#&@@@@@@@@@@@@@@@@###@@#######%@@@@@@@@@                                                  
                          %@@%%%@@@@@%%@&#############%%(@@@&,      @@@*@@@@@@@@@@       @&%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                  
                        ,@%%%@@####%@%%&@###############%%%%%%%&@& @@@@@@@@@    @@(       *@##@#%@@@@@@@@@@@@@@@@@@@@@@@@@@,,@/                                             
                       @&%%@@#######@&%%@%###########%%%%%###@@(##(@@@@&&@@@@#&@@@,        *@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@,  @@                                            
                     @@%%&@&########%@%%&@########%%%%%#####%&&%@&######&@@@@@@@@/        %@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@%  (@@                                            
                   %@%%%@@##########%@%%&@#######%%%#######@@@@@@%#@@&############%%%%######(@@&@@@@@@@@@@@@@@@@@@@@@@@@@%  *@@(                                            
                 #@%%%&@@###########%@%%&@#####%%%########@@@################%&&@@@@@@@@@@@%###%@@@@@@@@@@@@@@@@@@@@@@@@. @@@@                                              
                &@%%%%@@(###########@%%%&@###%%%####(#%&%##&@@@@@@@@@##################@&########&@@@@@@@@@@@@@@@@@@@##@@@@                                                 
                    ,,@(###########@@@@@@##%%####################%@@@@@@###########(&@###################%@@%%%%%####@@@@@.                                                 
                     @%############################@@@@&&&##########@@@@@@@###@@@&##########%%%#############&#####&@@@@@#@#@.                                               
                    %&##########################&@#&@&@@@@&###########&@@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@###@@@@@@@%#@&##@.                                              
                    @(#############################@####&#####%@@@@&%#(#########%%%&@@@@@@@@@@@@%####%@@@@@@@@@@@@@@###@###@#                                               
                   ,@###############################@@####&@@&%##########%&@@@@&%#####################&@@@@@@%######%@%##@/                                                 
                   @###################################@@&#######&@@@####################%&&&&@@@@@@@@@@@@@@@@@@@&%####@@                                                   
                  [email protected](#######################################@@%###########%@@@&@@@@@@@%#############################@&##%@                                                  
                (@@@############################################%@@&##########################%%&&&&%%%&@@@@&%%%#######%@                                                   
             /@@@@@(##################################################@@&############################################%@                                                     
            &*@@@@@#########################################################&@@@@@@@%############################%@@%#@                                                     
            @*,/@@@#####################################################################(,.,/(########################@                                                     
            @&@%,,,/@&%############################################################,,,,*,****//*,*, /@@@@@@&@@&%%@&###@%                                                      
            @&&&@@//,,**,%@@@%##################################################(.,,/,*.,.... ..****.&,,/@&#######@(                                                        
           [email protected]&&&&&&&@@***,***,,**#@@@@@########################################,**,.,./,*,,...,/,.,,*@@((#,@######(%@@.                                                     
           ,@&&&&&&&&&&&@@@@&/,,,,,,,,**,*******%@@@@@@@@%###################,/*.(,,,**.**,..(,@@@@##@@#(@(@%##########@@.                                                 
           *@&&&&&&&&&&&@@&&&@@&&&&&&&&&@@@@@&&&((**,,,*,,,*@&################,/,*,,**(.*(,*.*&####(@###%@/%@@@ @@(%@&#####%@.                                              
           %@&&&&&&&&&&@..&&@,#&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@#############,(.*,**(#,,,****(@%##%@@&,,@@(  @@@%###########@.                                            
           @&&&&&&&&&&&&%@&&@@&&&&&&&&&&&&&&&@@@@@@@@@@@@@(@#&@@ .*@@##&######(.*,,..*.***#*,,./,/,,**&@@@//&@(################@,                                          
          #@&&&&&&&&&&&&#@#@%(@&&&&&&&&&&&&&&&@&@#@@&@@@@@@@@@@@@*[email protected]&%@#####@@. *****#(////,****,.//@# @&%@@@&&@################@                                         
          @@&&&&&&&&&&@(@&@@@@#@&&&&&&&&&&&&&&&&@@@%@@@@@@@@@@@&@%@ [email protected]#%%##@@ .&@# ,,**,/,**,**,.*%/%@  @###@@&@@/@@###############@,                                       
          @&&&&&&&&&&&@@&&&@@@@@&&&&&&&&&&&&&&&&&&@@&/@@@@@@@@@@#@%@ [email protected]##%@. @%@&(@@&/..,///***(######@@%######(@,.,@@%###@@########@                                      
          @&&&&&&&&&&&&&&@@&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@(@[email protected]*@@..&( ,@*&@@&(@@@&&&&@############@@###%@###%@&(@@@(/(*@@&####@                                     
          @&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&/@@@@@@@(@@ %%.#@.   @&@@@@@@*&#@@@% @(###############%@#####%@(###@@%*@######@                                    
                                                                                                                                   
                    ________         .__                        __  .__                        ___.                    __   
                    \_____  \   ____ |  | ___.__.             _/  |_|  |__   ____              \_ |__   ____   _______/  |_ 
                     /   |   \ /    \|  |<   |  |             \   __\  |  \_/ __ \              | __ \_/ __ \ /  ___/\   __\
                    /    |    \   |  \  |_\___  |              |  | |   Y  \  ___/              | \_\ \  ___/ \___ \  |  |  
                    \_______  /___|  /____/ ____|              |__| |___|  /\___  >             |___  /\___  >____  > |__|  
                            \/     \/     \/                             \/     \/                  \/     \/     \*/