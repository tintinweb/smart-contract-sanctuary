pragma solidity ^0.4.21;

/*
*         ##### ##         #####    ##     ###          ##                       ###   ###     
*      ######  /###     ######  /  #### / /####       ####  /                     ###   ###    
*     /#   /  /  ###   /#   /  /   ####/ /   ###      /####/                       ##    ##    
*    /    /  /    ### /    /  /    # #        ###    /   ##                        ##    ##    
*        /  /      ##     /  /     #           ###  /                              ##    ##    
*       ## ##      ##    ## ##     #            ###/         ###  /###     /###    ##    ##    
*       ## ##      ##    ## ##     #             ###          ###/ #### / / ###  / ##    ##    
*     /### ##      /     ## ########             /###          ##   ###/ /   ###/  ##    ##    
*    / ### ##     /      ## ##     #            /  ###         ##       ##    ##   ##    ##    
*       ## ######/       ## ##     ##          /    ###        ##       ##    ##   ##    ##    
*       ## ######        #  ##     ##         /      ###       ##       ##    ##   ##    ##    
*       ## ##               /       ##       /        ###      ##       ##    ##   ##    ##    
*       ## ##           /##/        ##      /          ###   / ##       ##    ##   ##    ##    
*       ## ##          /  #####      ##    /            ####/  ###       ######    ### / ### / 
*  ##   ## ##         /     ##            /              ###    ###       ####      ##/   ##/  
* ###   #  /          #                                                                        
*  ###    /            ##                                                                      
*   #####/                                                                                     
*     ###                                                                                      
*  
*       ____
*      /\&#39; .\    _____
*     /: \___\  / .  /\
*     \&#39; / . / /____/..\
*      \/___/  \&#39;  &#39;\  /
*               \&#39;__&#39;\/
*
* // Probably Unfair //
*
* //*** Developed By:
*   _____       _         _         _ ___ _         
*  |_   _|__ __| |_  _ _ (_)__ __ _| | _ (_)___ ___ 
*    | |/ -_) _| &#39; \| &#39; \| / _/ _` | |   / (_-</ -_)
*    |_|\___\__|_||_|_||_|_\__\__,_|_|_|_\_/__/\___|
*   
*   &#169; 2018 TechnicalRise.  Written in March 2018.  
*   All rights reserved.  Do not copy, adapt, or otherwise use without permission.
*   https://www.reddit.com/user/TechnicalRise/
*  
*/

contract PHXReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract PHXInterface {
    function balanceOf(address who) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
}

contract usingMathLibraries {
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        require(a + b >= a);
        return a + b;
    }

    function safeSub(uint a, uint b) pure internal returns (uint) {
        require(b <= a);
        return a - b;
    } 

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }
}

contract PHXroll is PHXReceivingContract, usingMathLibraries {
    
    /*
     * checks player profit, bet size and player number is within range
    */
    modifier betIsValid(uint _betSize, uint _playerNumber) {      
        require(((((_betSize * (100-(safeSub(_playerNumber,1)))) / (safeSub(_playerNumber,1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize < maxProfit && _betSize > minBet && _playerNumber > minNumber && _playerNumber < maxNumber);        
		_;
    }

    /*
     * checks game is currently active
    */
    modifier gameIsActive {
        require(gamePaused == false);
		_;
    }    

    /*
     * checks payouts are currently active
    */
    modifier payoutsAreActive {
        require(payoutsPaused == false);
		_;
    }    

    /*
     * checks only owner address is calling
    */
    modifier onlyOwner {
         require(msg.sender == owner);
         _;
    }

    /*
     * checks only treasury address is calling
    */
    modifier onlyTreasury {
         require(msg.sender == treasury);
         _;
    }    

    /*
     * game vars
    */ 
    uint constant public maxProfitDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;    
    uint constant public maxNumber = 99; 
    uint constant public minNumber = 2;
	bool public gamePaused;
    address public owner;
    bool public payoutsPaused; 
    address public treasury;
    uint public contractBalance;
    uint public houseEdge;     
    uint public maxProfit;   
    uint public maxProfitAsPercentOfHouse;                    
    uint public minBet; 
    //init discontinued contract data        
    int public totalBets = 0;
    //init discontinued contract data 
    uint public totalTRsWon = 0;
    //init discontinued contract data  
    uint public totalTRsWagered = 0;    

    /*
     * player vars
    */
    uint public rngId;
    mapping (uint => address) playerAddress;
    mapping (uint => uint) playerBetId;
    mapping (uint => uint) playerBetValue;
    mapping (uint => uint) playerDieResult;
    mapping (uint => uint) playerNumber;
    mapping (uint => uint) playerProfit;

    /*
     * events
    */
    /* log bets + output to web3 for precise &#39;payout on win&#39; field in UI */
    event LogBet(uint indexed BetID, address indexed PlayerAddress, uint indexed RewardValue, uint ProfitValue, uint BetValue, uint PlayerNumber);      
    /* output to web3 UI on bet result*/
    /* Status: 0=lose, 1=win, 2=win + failed send, 3=refund, 4=refund + failed send*/
	event LogResult(uint indexed BetID, address indexed PlayerAddress, uint PlayerNumber, uint DiceResult, uint Value, int Status);   
    /* log manual refunds */
    event LogRefund(uint indexed BetID, address indexed PlayerAddress, uint indexed RefundValue);
    /* log owner transfers */
    event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);               

    address public constant PHXTKNADDR = 0x14b759A158879B133710f4059d32565b4a66140C;
    PHXInterface public PHXTKN;

    /*
     * init
    */
    function PHXroll() public {
        owner = msg.sender;
        treasury = msg.sender;
        // Initialize the PHX Contract
        PHXTKN = PHXInterface(PHXTKNADDR); 
        /* init 990 = 99% (1% houseEdge)*/
        ownerSetHouseEdge(990);
        /* init 10,000 = 1%  */
        ownerSetMaxProfitAsPercentOfHouse(10000);
        /* init min bet (0.1 PHX) */
        ownerSetMinBet(100000000000000000);        
    }

    // This is a supercheap psuedo-random number generator
    // that relies on the fact that "who" will mine and "when" they will
    // mine is random.  This is usually vulnerable to "inside the block"
    // attacks where someone writes a contract mined in the same block
    // and calls this contract from it -- but we don&#39;t accept transactions
    // from other contracts, lessening that risk.  It seems like someone
    // would therefore need to be able to predict the block miner and
    // block timestamp in advance to hack this.  
    // 
    // &#175;\_(ツ)_/&#175; 
    // 
    uint seed3;
    function _pRand(uint _modulo) internal view returns (uint) {
        require((1 < _modulo) && (_modulo <= 1000));
        uint seed1 = uint(block.coinbase); // Get Miner&#39;s Address
        uint seed2 = now; // Get the timestamp
        seed3++; // Make all pRand calls unique
        return uint(keccak256(seed1, seed2, seed3)) % _modulo;
    }

    /*
     * public function
     * player submit bet
     * only if game is active & bet is valid
    */
    function _playerRollDice(uint _rollUnder, TKN _tkn) private 
        gameIsActive
        betIsValid(_tkn.value, _rollUnder)
	{
        // Note that msg.sender is the Token Contract Address
    	// and "_from" is the sender of the tokens
    	require(_humanSender(_tkn.sender)); // Check that this is a non-contract sender
    	require(_phxToken(msg.sender)); // Check that this is a PHX Token Transfer
	    
	    // Increment rngId
	    rngId++;
	    
        /* map bet id to this wager */
		playerBetId[rngId] = rngId;
        /* map player lucky number */
		playerNumber[rngId] = _rollUnder;
        /* map value of wager */
        playerBetValue[rngId] = _tkn.value;
        /* map player address */
        playerAddress[rngId] = _tkn.sender;
        /* safely map player profit */   
        playerProfit[rngId] = 0; 
  
        /* provides accurate numbers for web3 and allows for manual refunds */
        emit LogBet(playerBetId[rngId], playerAddress[rngId], safeAdd(playerBetValue[rngId], playerProfit[rngId]), playerProfit[rngId], playerBetValue[rngId], playerNumber[rngId]);       
        
        /* map Die result to player */
        playerDieResult[rngId] = _pRand(100) + 1;

        /* total number of bets */
        totalBets += 1;
        
        /* total wagered */
        totalTRsWagered += playerBetValue[rngId];                                                           

        /*
        * pay winner
        * update contract balance to calculate new max bet
        * send reward
        */
        if(playerDieResult[rngId] < playerNumber[rngId]){ 
            /* safely map player profit */   
            playerProfit[rngId] = ((((_tkn.value * (100-(safeSub(_rollUnder,1)))) / (safeSub(_rollUnder,1))+_tkn.value))*houseEdge/houseEdgeDivisor)-_tkn.value;
            
            /* safely reduce contract balance by player profit */
            contractBalance = safeSub(contractBalance, playerProfit[rngId]); 

            /* update total Rises won */
            totalTRsWon = safeAdd(totalTRsWon, playerProfit[rngId]);              

            emit LogResult(playerBetId[rngId], playerAddress[rngId], playerNumber[rngId], playerDieResult[rngId], playerProfit[rngId], 1);                            

            /* update maximum profit */
            setMaxProfit();
            
            // Transfer profit plus original bet
            PHXTKN.transfer(playerAddress[rngId], playerProfit[rngId] + _tkn.value);
            
            return;
        } else {
            /*
            * no win
            * send 1 Rise to a losing bet
            * update contract balance to calculate new max bet
            */
            emit LogResult(playerBetId[rngId], playerAddress[rngId], playerNumber[rngId], playerDieResult[rngId], playerBetValue[rngId], 0);                                

            /*  
            *  safe adjust contractBalance
            *  setMaxProfit
            *  send 1 Rise to losing bet
            */
            contractBalance = safeAdd(contractBalance, (playerBetValue[rngId]-1));                                                                         

            /* update maximum profit */
            setMaxProfit(); 

            /*
            * send 1 Rise               
            */
            PHXTKN.transfer(playerAddress[rngId], 1);

            return;            
        }

    } 
    
    // !Important: Note the use of the following struct
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes _data) public {
        if(_from == treasury) {
            contractBalance = safeAdd(contractBalance, _value);        
            /* safely update contract balance */
            /* update the maximum profit */
            setMaxProfit();
            return;
        } else {
            TKN memory _tkn;
            _tkn.sender = _from;
            _tkn.value = _value;
            _playerRollDice(parseInt(string(_data)), _tkn);
        }
    }
            
    /*
    * internal function
    * sets max profit
    */
    function setMaxProfit() internal {
        maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxProfitDivisor;  
    } 

    /* only owner adjust contract balance variable (only used for max profit calc) */
    function ownerUpdateContractBalance(uint newContractBalanceInTRs) public 
		onlyOwner
    {        
       contractBalance = newContractBalanceInTRs;
    }    

    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint newHouseEdge) public 
		onlyOwner
    {
        houseEdge = newHouseEdge;
    }

    /* only owner address can set maxProfitAsPercentOfHouse */
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public 
		onlyOwner
    {
        /* restrict each bet to a maximum profit of 1% contractBalance */
        require(newMaxProfitAsPercent <= 10000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    /* only owner address can set minBet */
    function ownerSetMinBet(uint newMinimumBet) public 
		onlyOwner
    {
        minBet = newMinimumBet;
    }       

    /* only owner address can transfer PHX */
    function ownerTransferPHX(address sendTo, uint amount) public 
		onlyOwner
    {        
        /* safely update contract balance when sending out funds*/
        contractBalance = safeSub(contractBalance, amount);		
        /* update max profit */
        setMaxProfit();
        require(!PHXTKN.transfer(sendTo, amount));
        emit LogOwnerTransfer(sendTo, amount); 
    }

    /* only owner address can set emergency pause #1 */
    function ownerPauseGame(bool newStatus) public 
		onlyOwner
    {
		gamePaused = newStatus;
    }

    /* only owner address can set emergency pause #2 */
    function ownerPausePayouts(bool newPayoutStatus) public 
		onlyOwner
    {
		payoutsPaused = newPayoutStatus;
    } 

    /* only owner address can set treasury address */
    function ownerSetTreasury(address newTreasury) public 
		onlyOwner
	{
        treasury = newTreasury;
    }         

    /* only owner address can set owner address */
    function ownerChangeOwner(address newOwner) public 
		onlyOwner
	{
        owner = newOwner;
    }

    /* only owner address can selfdestruct - emergency */
    function ownerkill() public 
		onlyOwner
	{
        PHXTKN.transfer(owner, contractBalance);
		selfdestruct(owner);
	}    

    function _phxToken(address _tokenContract) private pure returns (bool) {
        return _tokenContract == PHXTKNADDR; // Returns "true" of this is the PHX Token Contract
    }
    
    // Determine if the "_from" address is a contract
    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly {
          codeLength := extcodesize(_from)
      }
      return (codeLength == 0); // If this is "true" sender is most likely a Wallet
    }

}