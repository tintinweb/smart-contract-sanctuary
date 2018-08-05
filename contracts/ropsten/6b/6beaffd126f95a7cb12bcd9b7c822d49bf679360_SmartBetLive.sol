pragma solidity ^0.4.21;

contract SmartBetLive {
    //What percentage of the raised amount will be given to the last player
    uint public winnerPercentage;

    //What percentage of the raised amount will be given to the other players
    uint public othersPercentage;

    //The expiration time of the game, expressed in seconds from Jan 1st, 1970
    uint public expirationTime;

    //The last player&#39;s address
    address public currentWinner;

    //Minimum amount to send to the contract
    uint public minimumAmount;

    //All the players&#39; addresses
    address[] public uniquePlayers;

    //This to avoid duplicates into uniquePlayers array
    mapping (address=>bool) private allPlayers;

    //The contract owner
    address public owner;

    //The amount of total raised money
    uint public totalRaised;

    //Event to trigger the website GUI each time a new payment arrives
    event NotifyNewPayment();

    //Contract creation, with all the main rules of the game
    constructor(uint wP, uint oP, uint ma, uint gameDurationInMinutes) public {
        //Winner percentage must be a number between 1% and 100%
        require(wP > 0 && wP < 101);
        winnerPercentage = wP;

        //Others percentage must be a number between 1% and 100%
        require(oP > 0 && oP < 101);
        othersPercentage = oP;

        //Owner of the Contract is who created it (a.k.a. the sender of first transacion for contract deployment)
        owner = msg.sender;

        //Set the minimum amount every player must send to join the game
        minimumAmount = ma;

        //To set expiration Time, we must convert minutes in seconds, then sum to the actual time (also expressed in seconds)
        expirationTime = (gameDurationInMinutes * 60) + now;
    }

    //The function that will be called every time someone sends eths to the contract
    function () public payable {
        
        //First of all, if you play after the conclusion of the game, you will be refunded
        require(expirationTime > now);

        //You can send at least the designed minimum amount
        require(msg.value >= minimumAmount);

        //Save old winner (if not already inserted)
        if(allPlayers[msg.sender] == false) {
            allPlayers[msg.sender] = true;
            uniquePlayers.push(msg.sender);
        }
        
        //Now you are the current winner!
        currentWinner = msg.sender;

        //Total amount raised is updated
        totalRaised += msg.value;

        //Let&#39;s notify all the users on our Website that a new player donated
        emit NotifyNewPayment();
    }

    //Now let&#39;s send the prizes to all players
    function sendPrizes() public {

        //First of all, we can do it just if the game has ended
        require(expirationTime < now);

        //Secondly, only the owner of the contract can do this, for security reasons
        require(msg.sender == owner);

        //Get the total amount raised from the Contract
        uint amount = address(this).balance;

        //Continue only if there are some money into Contract&#39;s wallet
        require(amount > 0);

        //Let&#39;s extract the prize for the winner
        uint prizeForWinner = amount * winnerPercentage / 100;

        //Send first prize to the Winner
        currentWinner.transfer(prizeForWinner);

        //Remaining money will be sent to the organization team
        uint remainingMoneyForTeam = amount - prizeForWinner;

        //if there is more than one player (we hope so!!!)
        if(uniquePlayers.length > 1) {

            //Let&#39;s extract the TOTAL prize for other players first
            uint prizeForOthers = amount * othersPercentage / 100;

            //Decrease money for the team
            remainingMoneyForTeam = remainingMoneyForTeam - prizeForOthers;

            //Now let&#39;s calculate how much eths will be sent to EVERY single non-winner player
            prizeForOthers = prizeForOthers / (uniquePlayers.length - 1);

            //Now send prizes to other players
            for(uint i = 0; i < uniquePlayers.length; i++) {
                //Of Course, current Winner must be excluded because he has already received money
                if(uniquePlayers[i] != currentWinner) {
                    uniquePlayers[i].transfer(prizeForOthers);
                }
            }
        }

        //Finally, send remaining contract money to the owner
        owner.transfer(remainingMoneyForTeam);

        //Let&#39;s notify all the users on our Website that the contract paid everybody
        emit NotifyNewPayment();
    }

    //Get all the data for our website GUI
    /* Returns:
    ** Winner Percentage, set at Contract Deploy
    ** Percentage for other players, set at Contract Deploy
    ** Minimum amount to send, set at Contract Deploy
    ** Address of the current Winner
    ** Number of total players
    ** Expiration time, expressed in seconds since Jan 1st, 1970
    ** Total raised
    ** Total balance of the Contract (to verify that Contract paid everybody)
    ** Prize for winner
    ** Eventual prize for other players
     */
    function getData() public view returns (uint, uint, uint, address, uint, uint, uint, uint, uint, uint) {
        //Let&#39;s extract the prize for the winner
        uint prizeForWinner = totalRaised * winnerPercentage / 100;

        //Let&#39;s assume that only one player joined the game, so there are no other players
        uint prizeForOthers = 0;

        //if there is more than one player (we hope so!!!)
        if(uniquePlayers.length > 1) {
            //Let&#39;s extract the TOTAL prize for other players first
            prizeForOthers = totalRaised * othersPercentage / 100;

            //Now let&#39;s calculate how much eths will be sent to EVERY single non-winner player
            prizeForOthers = prizeForOthers / (uniquePlayers.length - 1);
        }
        return (
            winnerPercentage, 
            othersPercentage, 
            minimumAmount, 
            currentWinner, 
            uniquePlayers.length, 
            expirationTime,
            totalRaised,
            prizeForWinner, 
            prizeForOthers,
            address(this).balance
        );
    }
}