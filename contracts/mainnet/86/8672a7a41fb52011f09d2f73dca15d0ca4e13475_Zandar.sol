//visit our site at:
//https://xandar.herokuapp.com/
pragma solidity ^0.4.21;

contract Zandar {
    uint8 public constant MAINTENANCE_FEE_PERCENT = 5;
    uint8 public constant REFUND_PERCENT = 80;
    
    address admin;
    uint public admin_profit = 0;
    uint public currentActiveGameID = 0;

    struct Game {
        uint ticketPrice;
        
        uint bettingPhaseStart; //unix time
        uint bettingPhaseEnd;   //unix time
        uint claimingPhaseStart;//unix time
        uint claimingPhaseEnd;  //unix time
    
        mapping(address => uint8) tickets;
        uint8 numTickets;
        uint8 numPrizeClaimed;
        uint8 winningMultiplier;
    
        uint balance; //balance of each game
    }
    
    Game[] public games;
    
    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }
    
    function Zandar() public{
        admin = msg.sender;
    }
    
    //fallback function for handling unexpected payment
    //if any ether is sent to the address, credit the admin balance
    function() external payable{
        admin_profit += msg.value;
    }
    
    function createGame(uint _ticketPrice, uint _bettingStartUnixTime,
        uint _bettingPhaseDays, uint _waitingPhaseDays,
        uint _claimingPhaseDays, uint8 _winningMultiplier) adminOnly external{
        
        uint bettingPhaseEnd = _bettingStartUnixTime + _bettingPhaseDays * 1 days;
        uint claimingPhaseStart = bettingPhaseEnd + _waitingPhaseDays * 1 days;
        uint claimingPhaseEnd = claimingPhaseStart + _claimingPhaseDays * 1 days;

        Game memory g = Game({
            ticketPrice: _ticketPrice,
            bettingPhaseStart: _bettingStartUnixTime,
            bettingPhaseEnd: bettingPhaseEnd,
            claimingPhaseStart: claimingPhaseStart,
            claimingPhaseEnd: claimingPhaseEnd,
            numTickets:0,
            numPrizeClaimed:0,
            balance:0,
            winningMultiplier: _winningMultiplier
        });

        games.push(g);
    }

    function setCurrentActiveGameID(uint _id) adminOnly external{
        currentActiveGameID = _id;
    }
    
    function getNumGames() external view returns (uint){
        return games.length;
    }

    function getNumTicketsPurchased(uint _gameID, address _address) external view returns (uint8){
        return games[_gameID].tickets[_address];
    } 
    
    function getContractBalance() external view returns (uint){
        return address(this).balance;
    }

    function purchaseTicket(uint _gameID) external payable {
        require(msg.value >= games[_gameID].ticketPrice);
        require(now >= games[_gameID].bettingPhaseStart &&
            now < games[_gameID].bettingPhaseEnd);
        games[_gameID].tickets[msg.sender] += 1;
        games[_gameID].numTickets += 1;
        uint admin_fee = games[_gameID].ticketPrice * MAINTENANCE_FEE_PERCENT/100;
        admin_profit += admin_fee;
        games[_gameID].balance += msg.value - admin_fee;
    }        

    function claimProfit(uint _gameID) external {
        require(now >= games[_gameID].claimingPhaseStart &&
            now < games[_gameID].claimingPhaseEnd);
        require(games[_gameID].tickets[msg.sender]>0);
        require(games[_gameID].numPrizeClaimed <
            games[_gameID].numTickets/games[_gameID].winningMultiplier);
        
        games[_gameID].numPrizeClaimed += 1;
        games[_gameID].tickets[msg.sender] -= 1;
        uint reward = games[_gameID].ticketPrice *
            games[_gameID].winningMultiplier * (100-MAINTENANCE_FEE_PERCENT) / 100;
        msg.sender.transfer(reward);
        games[_gameID].balance -= reward;
    }
    
    // get back the BET before claimingPhase
    function getRefund(uint _gameID) external {
        require(now < games[_gameID].claimingPhaseStart - 1 days);
        require(games[_gameID].tickets[msg.sender]>0);
        games[_gameID].tickets[msg.sender] -= 1;
        games[_gameID].numTickets -= 1;
        uint refund = games[_gameID].ticketPrice * REFUND_PERCENT / 100;
        uint admin_fee = games[_gameID].ticketPrice *
            (100 - REFUND_PERCENT - MAINTENANCE_FEE_PERCENT) / 100;
        admin_profit += admin_fee;
        games[_gameID].balance -= games[_gameID].ticketPrice *
            (100 - MAINTENANCE_FEE_PERCENT) / 100;
        msg.sender.transfer(refund);
    }

    // call by admin to get maintenance fee
    function getAdminFee() adminOnly external {
        require(admin_profit > 0);
        msg.sender.transfer(admin_profit);
        admin_profit = 0;
    }
    
    // admin can claim unclaimed fund after the claiming phase, if any
    function getUnclaimedEtherIfAny(uint _gameID) adminOnly external {
        require(now >= games[_gameID].claimingPhaseEnd);
        require(games[_gameID].balance > 0);
        msg.sender.transfer(games[_gameID].balance);
        games[_gameID].balance = 0;
    }

     //transfer ownership of the contract
 	function transferOwnership(address _newAdmin) adminOnly external {
    	admin = _newAdmin;
 	}
}