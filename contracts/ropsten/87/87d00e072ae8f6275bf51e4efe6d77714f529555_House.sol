pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}

/*
Oracle smart contract interface
*/
interface OracleContract {
    function owner() external view returns (address);
    function getEventForHousePlaceBet(uint id) external view returns (uint closeDateTime, uint freezeDateTime, bool isCancelled); 
    function getEventOutcomeIsSet(uint eventId, uint outputId) external view returns (bool isSet);
    function getEventOutcome(uint eventId, uint outputId) external view returns (uint outcome); 
    function getEventOutcomeNumeric(uint eventId, uint outputId) external view returns(uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6);
}

/*
House smart contract interface
*/
interface HouseContract {
    function owner() external view returns (address); 
    function isHouse() external view returns (bool); 
}



/*
 * Kryptium Tracker Samrt Contract.  Copyright &#169; 2018 by Kryptium Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5930373f3619322b20292d302c34773036">[email&#160;protected]</a>>.
 * Author: Giannis Zarifis <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4aebea5b6ada2adb784afb6bdb4b0adb1a9eaadab">[email&#160;protected]</a>>.
 */
contract House is SafeMath, Owned {

    //enum Category { football, basket }

    enum BetType { headtohead, multiuser, poolbet }

    enum BetEvent { placeBet, callBet, removeBet, refuteBet, settleWinnedBet, settleCancelledBet, increaseWager, cancelledByHouse }

    uint private betNextId;

    struct Bet { 
        uint id;
        address oracleAddress;
        uint eventId;
        uint outputId;
        uint outcome;
        bool isOutcomeSet;
        uint closeDateTime;
        uint freezeDateTime;
        bool isCancelled;
        uint256 minimumWager;
        uint256 maximumWager;
        uint256 payoutRate;
        address createdBy;
        BetType betType;
    } 


    struct HouseData { 
        bool managed;
        string  name;
        string  creatorName;
        string  countryISO; 
        address oracleAddress;
        address oldOracleAddress;       
        bool  newBetsPaused;
        uint  housePercentage;
        uint oraclePercentage;   
        uint version;
        string shortMessage;              
    } 

    address public _newHouseAddress;

    HouseData public houseData;  

    // This creates an array with all bets
    mapping (uint => Bet) public bets;

    //Total bets
    uint public totalBets;

    //Total amount played on bets
    uint public totalAmountOnBets;

    //Total amount on Bet
    mapping (uint => uint256) public betTotalAmount;

    //Totalbets on bet
    mapping (uint => uint) public betTotalBets;

    //Bet Refutes amount
    mapping (uint => uint256) public betRefutedAmount;

    //Total amount placed on a bet forecast
    mapping (uint => mapping (uint => uint256)) public betForcastTotalAmount;    

    //Player bet total amount on a Bet
    mapping (address => mapping (uint => uint256)) public playerBetTotalAmount;

    //Player bet total bets on a Bet
    mapping (address => mapping (uint => uint)) public playerBetTotalBets;

    //Player wager for a Bet.Output.Forcast
    mapping (address => mapping (uint => mapping (uint => uint256))) public playerBetForecastWager;

    //Player output(Cause or win or refund)  of a bet
    mapping (address => mapping (uint => uint256)) public playerOutputFromBet;    

    //Player bet Refuted
    mapping (address => mapping (uint => bool)) public playerBetRefuted;    

    //Player bet Settled
    mapping (address => mapping (uint => bool)) public playerBetSettled; 


    //Total bets placed by player
    mapping (address => uint) public totalPlayerBets;


    //Total amount placed for bets by player
    mapping (address => uint256) public totalPlayerBetsAmount;

    // User balances
    mapping (address => uint256) public balance;

    // Stores the house owners percentage as part per thousand 
    mapping (address => uint) public ownerPerc;

    //The array of house owners
    address[] public owners;

    //The House and Oracle Edge has been paid
    mapping (uint => bool) public housePaid;

    //The total remaining House amount collected from fees for Bet
    mapping (uint => uint256) public houseEdgeAmountForBet;

    //The total remaining Oracle amount collected from fees for Bet
    mapping (uint => uint256) public oracleEdgeAmountForBet;

    //The total House fees
    uint256 public houseTotalFees;

    //The total Oracle fees
    mapping (address => uint256) public oracleTotalFees;

    // Notifies clients that a new house is launched
    event HouseCreated();

    // Notifies clients that a house data has changed
    event HousePropertiesUpdated();    

    event BetPlacedOrModified(uint id, address sender, BetEvent betEvent, uint256 amount, uint forecast, string createdBy, uint closeDateTime);


    event transfer(address indexed wallet, uint256 amount,bool inbound);


    /**
     * Constructor function
     * Initializes House contract
     */
    constructor(bool managed, string memory houseName, string memory houseCreatorName, string memory houseCountryISO, address oracleAddress, address[] memory ownerAddress, uint[] memory ownerPercentage, uint housePercentage,uint oraclePercentage, uint version) public {
        require(add(housePercentage,oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        houseData.managed = managed;
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;
        houseData.housePercentage = housePercentage;
        houseData.oraclePercentage = oraclePercentage; 
        houseData.oracleAddress = oracleAddress;
        houseData.shortMessage = "";
        houseData.newBetsPaused = true;
        houseData.version = version;
        uint ownersTotal = 0;
        for (uint i = 0; i<ownerAddress.length; i++) {
            owners.push(ownerAddress[i]);
            ownerPerc[ownerAddress[i]] = ownerPercentage[i];
            ownersTotal += ownerPercentage[i];
            }
        require(ownersTotal == 1000);    
        emit HouseCreated();
    }

    /**
     * Check if valid house contract
     */
    function isHouse() public pure returns(bool response) {
        return true;    
    }

     /**
     * Updates House Data function
     *
     */
    function updateHouseProperties(string memory houseName, string memory houseCreatorName, string memory houseCountryISO) onlyOwner public {
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;     
        emit HousePropertiesUpdated();
    }    

    /**
     * Updates House Oracle function
     *
     */
    function changeHouseOracle(address oracleAddress, uint oraclePercentage) onlyOwner public {
        require(add(houseData.housePercentage,oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        if (oracleAddress != houseData.oracleAddress) {
            houseData.oldOracleAddress = houseData.oracleAddress;
            houseData.oracleAddress = oracleAddress;
        }
        houseData.oraclePercentage = oraclePercentage;
        emit HousePropertiesUpdated();
    } 

    /**
     * Updates House percentage function
     *
     */
    function changeHouseEdge(uint housePercentage) onlyOwner public {
        require(housePercentage != houseData.housePercentage,"New percentage is identical with current");
        require(add(housePercentage,houseData.oraclePercentage)<1000,"House + Oracle percentage should be lower than 100%");
        houseData.housePercentage = housePercentage;
        emit HousePropertiesUpdated();
    } 


    function updateBetDataFromOracle(uint betId) private {
        if (!bets[betId].isOutcomeSet) {
            (bets[betId].isOutcomeSet) = OracleContract(bets[betId].oracleAddress).getEventOutcomeIsSet(bets[betId].eventId,bets[betId].outputId); 
            if (bets[betId].isOutcomeSet) {
                (bets[betId].outcome) = OracleContract(bets[betId].oracleAddress).getEventOutcome(bets[betId].eventId,bets[betId].outputId); 
            }
        }     
        
        //The below statement removed in order to fix https://gitlab.com/ZKBet/docs/issues/238       
        // if (!bets[betId].isCancelled) {
        (bets[betId].closeDateTime, bets[betId].freezeDateTime, bets[betId].isCancelled) = OracleContract(bets[betId].oracleAddress).getEventForHousePlaceBet(bets[betId].eventId);      
        // }  
        if (!bets[betId].isOutcomeSet && bets[betId].freezeDateTime <= now) {
            bets[betId].isCancelled = true;
        }
    }


    /*
     * Place a Bet
     */
    function placeBet(uint eventId, BetType betType,uint outputId, uint forecast, uint256 wager, uint closingDateTime, uint256 minimumWager, uint256 maximumWager, uint256 payoutRate, string memory createdBy) public {
        require(wager>0,"Wager should be greater than zero");
        require(balance[msg.sender]>=wager,"Not enough balance");
        require(!houseData.newBetsPaused,"Bets are paused right now");
        betNextId += 1;
        bets[betNextId].id = betNextId;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].outputId = outputId;
        bets[betNextId].eventId = eventId;
        bets[betNextId].betType = betType;
        bets[betNextId].createdBy = msg.sender;
        updateBetDataFromOracle(betNextId);
        require(!bets[betNextId].isCancelled,"Event has been cancelled");
        require(!bets[betNextId].isOutcomeSet,"Event has already an outcome");
        if (closingDateTime>0) {
            bets[betNextId].closeDateTime = closingDateTime;
        }  
        require(bets[betNextId].closeDateTime >= now,"Close time has passed");
        if (minimumWager != 0) {
            bets[betNextId].minimumWager = minimumWager;
        } else {
            bets[betNextId].minimumWager = wager;
        }
        if (maximumWager != 0) {
            bets[betNextId].maximumWager = maximumWager;
        }
        if (payoutRate != 0) {
            bets[betNextId].payoutRate = payoutRate;
        }       

        playerBetTotalBets[msg.sender][betNextId] = 1;
        betTotalBets[betNextId] = 1;
        betTotalAmount[betNextId] = wager;
        totalBets += 1;
        totalAmountOnBets += wager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betNextId] += mulByFraction(wager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betNextId] += mulByFraction(wager, houseData.oraclePercentage, 1000);
        }

        balance[msg.sender] -= wager;

 
        betForcastTotalAmount[betNextId][forecast] = wager;

        playerBetTotalAmount[msg.sender][betNextId] = wager;

        playerBetForecastWager[msg.sender][betNextId][forecast] = wager;

        totalPlayerBets[msg.sender] += 1;

        totalPlayerBetsAmount[msg.sender] += wager;

        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, wager, forecast, createdBy, bets[betNextId].closeDateTime);
    }  

    /*
     * Call a Bet
     */
    function callBet(uint betId, uint forecast, uint256 wager, string memory createdBy) public {
        require(wager>0,"Wager should be greater than zero");
        require(balance[msg.sender]>=wager,"Not enough balance");
        require(playerBetForecastWager[msg.sender][betId][forecast] == 0,"Already placed a bet for this forecast, use increaseWager method instead");
        require(bets[betId].betType != BetType.headtohead || betTotalBets[betId] == 1,"Head to head bet has been already called");
        require(wager>=bets[betId].minimumWager,"Wager is lower than the minimum accepted");
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,"Wager is higher then the maximum accepted");
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        require(bets[betId].closeDateTime >= now,"Close time has passed");
        betTotalBets[betId] += 1;
        betTotalAmount[betId] += wager;
        totalAmountOnBets += wager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betId] += mulByFraction(wager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betId] += mulByFraction(wager, houseData.oraclePercentage, 1000);
        }

        balance[msg.sender] -= wager;

        playerBetTotalBets[msg.sender][betId] += 1;

        betForcastTotalAmount[betId][forecast] += wager;

        playerBetTotalAmount[msg.sender][betId] += wager;

        playerBetForecastWager[msg.sender][betId][forecast] = wager;

        totalPlayerBets[msg.sender] += 1;

        totalPlayerBetsAmount[msg.sender] += wager;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.callBet, wager, forecast, createdBy, bets[betId].closeDateTime);   
    }  

    /*
     * Increase wager
     */
    function increaseWager(uint betId, uint forecast, uint256 additionalWager, string memory createdBy) public {
        require(additionalWager>0,"Increase wager amount should be greater than zero");
        require(balance[msg.sender]>=additionalWager,"Not enough balance");
        require(playerBetForecastWager[msg.sender][betId][forecast] > 0,"Haven&#39;t placed any bet for this forecast. Use callBet instead");
        require(bets[betId].betType != BetType.headtohead || betTotalBets[betId] == 1,"Head to head bet has been already called");
        uint256 wager = playerBetForecastWager[msg.sender][betId][forecast] + additionalWager;
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,"The updated wager is higher then the maximum accepted");
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,"Bet has been cancelled");
        require(!bets[betId].isOutcomeSet,"Event has already an outcome");
        require(bets[betId].closeDateTime >= now,"Close time has passed");
        betTotalAmount[betId] += additionalWager;
        totalAmountOnBets += additionalWager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betId] += mulByFraction(additionalWager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betId] += mulByFraction(additionalWager, houseData.oraclePercentage, 1000);
        }

        balance[msg.sender] -= additionalWager;

        betForcastTotalAmount[betId][forecast] += additionalWager;

        playerBetTotalAmount[msg.sender][betId] += additionalWager;

        playerBetForecastWager[msg.sender][betId][forecast] += additionalWager;

        totalPlayerBetsAmount[msg.sender] += additionalWager;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.increaseWager, additionalWager, forecast, createdBy, bets[betId].closeDateTime);       
    }

    /*
     * Remove a Bet
     */
    function removeBet(uint betId, string memory createdBy) public {
        require(bets[betId].createdBy == msg.sender,"Caller and player created don&#39;t match");
        require(playerBetTotalBets[msg.sender][betId] > 0, "Player should has placed at least one bet");
        require(betTotalBets[betId] == playerBetTotalBets[msg.sender][betId],"The bet has been called by other player");
        updateBetDataFromOracle(betId);  
        bets[betId].isCancelled = true;
        uint256 wager = betTotalAmount[betId];
        betTotalBets[betId] = 0;
        betTotalAmount[betId] = 0;
        totalBets -= playerBetTotalBets[msg.sender][betId];
        totalAmountOnBets -= wager;
        houseEdgeAmountForBet[betId] = 0;
        oracleEdgeAmountForBet[betId] = 0;
        balance[msg.sender] += wager;
        playerBetTotalAmount[msg.sender][betId] = 0;
        totalPlayerBets[msg.sender] -= playerBetTotalBets[msg.sender][betId];
        totalPlayerBetsAmount[msg.sender] -= wager;
        playerBetTotalBets[msg.sender][betId] = 0;
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.removeBet, wager, 0, createdBy, bets[betId].closeDateTime);      
    } 

    /*
     * Refute a Bet
     */
    function refuteBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0,"Caller hasn&#39;t placed any bet");
        require(!playerBetRefuted[msg.sender][betId],"Already refuted");
        updateBetDataFromOracle(betId);  
        require(bets[betId].isOutcomeSet, "Refute isn&#39;t allowed when no outcome has been set");
        require(bets[betId].freezeDateTime > now, "Refute isn&#39;t allowed when Event freeze has passed");
        playerBetRefuted[msg.sender][betId] = true;
        betRefutedAmount[betId] += playerBetTotalAmount[msg.sender][betId];
        if (betRefutedAmount[betId] >= betTotalAmount[betId]) {
            bets[betId].isCancelled = true;   
        }
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.refuteBet, 0, 0, createdBy, bets[betId].closeDateTime);    
    } 

    /*
     * Calculates bet outcome for player
     */
    function calculateBetOutcome(uint betId, bool isCancelled, uint forecast) public view returns (uint256 betOutcome) {
        require(playerBetTotalAmount[msg.sender][betId]>0, "Caller hasn&#39;t placed any bet");
        if (isCancelled) {
            return playerBetTotalAmount[msg.sender][betId];            
        } else {
            if (betForcastTotalAmount[betId][forecast]>0) {
                uint256 totalBetAmountAfterFees = betTotalAmount[betId] - houseEdgeAmountForBet[betId] - oracleEdgeAmountForBet[betId];
                return mulByFraction(totalBetAmountAfterFees, playerBetForecastWager[msg.sender][betId][forecast], betForcastTotalAmount[betId][forecast]);            
            } else {
                return playerBetTotalAmount[msg.sender][betId] - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.housePercentage, 1000) - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.oraclePercentage, 1000);
            }
        }
    }

    /*
     * Settle a Bet
     */
    function settleBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0, "Caller hasn&#39;t placed any bet");
        require(!playerBetSettled[msg.sender][betId],"Already settled");
        updateBetDataFromOracle(betId);
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,"Bet should be cancelled or has an outcome");
        require(bets[betId].freezeDateTime <= now,"Bet payments are freezed");
        BetEvent betEvent;
        if (bets[betId].isCancelled) {
            betEvent = BetEvent.settleCancelledBet;
            houseEdgeAmountForBet[betId] = 0;
            oracleEdgeAmountForBet[betId] = 0;
            playerOutputFromBet[msg.sender][betId] = playerBetTotalAmount[msg.sender][betId];            
        } else {
            if (!housePaid[betId] && houseEdgeAmountForBet[betId] > 0) {
                for (uint i = 0; i<owners.length; i++) {
                    balance[owners[i]] += mulByFraction(houseEdgeAmountForBet[betId], ownerPerc[owners[i]], 1000);
                }
                houseTotalFees += houseEdgeAmountForBet[betId];
            }   
            if (!housePaid[betId] && oracleEdgeAmountForBet[betId] > 0) {
                address oracleOwner = HouseContract(bets[betId].oracleAddress).owner();
                balance[oracleOwner] += oracleEdgeAmountForBet[betId];
                oracleTotalFees[bets[betId].oracleAddress] += oracleEdgeAmountForBet[betId];
            }
            if (betForcastTotalAmount[betId][bets[betId].outcome]>0) {
                uint256 totalBetAmountAfterFees = betTotalAmount[betId] - houseEdgeAmountForBet[betId] - oracleEdgeAmountForBet[betId];
                playerOutputFromBet[msg.sender][betId] = mulByFraction(totalBetAmountAfterFees, playerBetForecastWager[msg.sender][betId][bets[betId].outcome], betForcastTotalAmount[betId][bets[betId].outcome]);            
            } else {
                playerOutputFromBet[msg.sender][betId] = playerBetTotalAmount[msg.sender][betId] - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.housePercentage, 1000) - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.oraclePercentage, 1000);
            }
            if (playerOutputFromBet[msg.sender][betId] > 0) {
                betEvent = BetEvent.settleWinnedBet;
            }
        }
        housePaid[betId] = true;
        playerBetSettled[msg.sender][betId] = true;
        balance[msg.sender] += playerOutputFromBet[msg.sender][betId];
        emit BetPlacedOrModified(betId, msg.sender, betEvent, playerOutputFromBet[msg.sender][betId],0, createdBy, bets[betId].closeDateTime);  
    } 

    function() external payable {
        balance[msg.sender] = add(balance[msg.sender],msg.value);
        emit transfer(msg.sender,msg.value,true);
    }


    /**
    * Checks if a player has betting activity on House 
    */
    function isPlayer(address playerAddress) public view returns(bool) {
        return (totalPlayerBets[playerAddress] > 0);
    }

    function updateShortMessage(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        emit HousePropertiesUpdated();
    }

    function startNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

    function stopNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

    function linkToNewHouse(address newHouseAddress) onlyOwner public {
        require(newHouseAddress!=address(this),"New address is current address");
        require(HouseContract(newHouseAddress).isHouse(),"New address should be a House smart contract");
        _newHouseAddress = newHouseAddress;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

    function unLinkNewHouse() onlyOwner public {
        _newHouseAddress = address(0);
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

    function cancelBet(uint betId) onlyOwner public {
        require(bets[betId].freezeDateTime > now,"Freeze time passed");
        require(houseData.managed, "Cancel available on managed Houses");
        bets[betId].isCancelled = true;
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.cancelledByHouse, 0, 0, "", bets[betId].closeDateTime);  
    }


    function withdraw(uint256 amount) public {
        require(address(this).balance>=amount,"Insufficient House balance. Shouldn&#39;t have happened");
        require(balance[msg.sender]>=amount,"Insufficient balance");
        balance[msg.sender] = sub(balance[msg.sender],amount);
        msg.sender.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }

    function withdrawToAddress(address payable destinationAddress,uint256 amount) public {
        require(address(this).balance>=amount);
        require(balance[msg.sender]>=amount,"Insufficient balance");
        balance[msg.sender] = sub(balance[msg.sender],amount);
        destinationAddress.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }

}