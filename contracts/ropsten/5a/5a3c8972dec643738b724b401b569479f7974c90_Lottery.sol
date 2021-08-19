// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./lottery-lib.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./IERC20.sol";

contract Lottery{
    using SafeMath for uint256;
    
    mapping(uint256 => mapping(address => uint[])) private userTickets;
    mapping(uint256 => mapping(uint => bool)) private tickets;
    mapping(address => uint256) private rewards; // mapping rewards da usare per lo svuotametno tramite l'indirizzo
    mapping(uint256 => mapping(uint => address)) private ticketOwner;
    mapping(uint256 => uint[]) private ticketsArray;
    mapping(uint256 => LotteryLib.WinnersHistory) private winnerHistory;
    
    IERC20 public _token;
    uint256 private nonce = 0;
    uint256 public ticketPrice = 650000000000000000000;
    uint256 private rewardPlatform = 0;
    uint256 private rewardFirst = 0;
    uint256 private rewardSecond = 0;
    uint256 private rewardThird = 0;
    
    uint256 private startTime;
    uint256 private endTime;

    uint public loops;
    address private manager;
    
    constructor(IERC20 token){
        _token = token;
        startTime = block.timestamp;
        //endTime = block.timestamp + 7 days; // produzione 7 gioni
        endTime = block.timestamp + 1 days; // sviluppo 1 giorno
        loops = 1;
        manager = msg.sender;
    }
    
    function buyTickets(uint numTickets)external returns(uint[] memory){
        require(numTickets>0 && numTickets<=10, 'Number Tickets Error');
        uint256 amount = ticketPrice.mul(numTickets);
        address from = msg.sender;
        
        _token.allowance(from,  address(this));
        require(_token.transferFrom(from, address(this), amount), "Error during payment");

        LotteryLib.Rewards memory a = LotteryLib._getBalances(amount);
        rewardFirst += a.first; 
        rewardSecond += a.second;
        rewardThird += a.third;
        rewardPlatform += a.platform;
        return _getNewTicket(numTickets);   
    }
    
    function _getNewTicket(uint numTickets) internal returns(uint[] memory){ 
        uint[] memory resp = new uint[](numTickets);
        for(uint i=0; i<numTickets; i++)
        {
            uint rnd=0;
            do {
                rnd = LotteryLib._getRdnTicket(nonce++);
            } while (tickets[loops][rnd]); 
            tickets[loops][rnd]=true;
            userTickets[loops][msg.sender].push(rnd);
            ticketsArray[loops].push(rnd);
            resp[i]=rnd;
            ticketOwner[loops][rnd]=msg.sender;
        }
        return resp;
    }
    
    function getWinner() external returns(uint, uint, uint){ // funzione pubblica che chiunque puo' lanciare -- meglio usare un modificatore -- 
        require(block.timestamp > endTime, "Is not possible get Winner now");
        require(ticketsArray[loops].length >= 3, "Required 3 players for get Winners");
        LotteryLib.Winners memory w = LotteryLib._getWinners(ticketsArray[loops].length, nonce++, ticketsArray[loops]);
        
        address first = ticketOwner[loops][w.first];
        address second = ticketOwner[loops][w.second];
        address third = ticketOwner[loops][w.third];
        rewards[first] += rewardFirst;
        rewards[second] += rewardSecond;
        rewards[third] += rewardThird;
        
        /* - Winners - */
        LotteryLib.WinnersHistory memory wH;
        wH.first = first;
        wH.second = second;
        wH.third = third;
        wH.firstWin = rewardFirst;
        wH.secondWin = rewardSecond;
        wH.thirdWin = rewardThird;
        winnerHistory[loops]=wH;
        
        rewardFirst = 0;
        rewardSecond = 0;
        rewardThird = 0;
        
        startTime = block.timestamp;
        //endTime = block.timestamp + 7 days; // produzione 7 gioni
        endTime = block.timestamp + 1 days; // sviluppo 1 giorno
        loops ++;
        
        return (w.first, w.second, w.third);
    }
    
    function withdraw() external returns(bool){
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "This address hasn't rewards");
        rewards[msg.sender] = 0;
        _token.transfer(msg.sender, amount);
        return true;
    }
    
    function withdrawRewardsPlatform() external onlyOwner returns(bool){
        uint256 amount = rewardPlatform;
        require(amount > 0, "This address hasn't rewards");
        _token.transfer(msg.sender, amount);
        rewardPlatform = 0;
        return true;
    }
    
    function securityWithdrawRewardsPlatform(uint256 amount) external onlyOwner returns(bool){
        require(amount > 0, "incorrect amount");
        _token.transfer(msg.sender, amount);
        return true;
    }
    
    /* - Manager Function - */
    function chengePrice(uint256 newPrice) external onlyOwner returns(uint256){
        ticketPrice = newPrice;
        return ticketPrice;
    }
    
    /* - PUBLIC - */
    function thisUsersTickets(address owner) public view returns(uint[] memory)
    {
        return userTickets[loops][owner];
    }
    
    function rewardOwner(address owner) public view returns(uint256){
        return rewards[owner];
    }
    
    function thisTicketsList()public view returns(uint[] memory){
        return ticketsArray[loops];
    }
    
    function thisWinnerRewardsList() public view returns(uint256,uint256,uint256){
        return (rewardFirst, rewardSecond, rewardThird);
    }
    
    function oldWins(uint loop)public view returns(LotteryLib.WinnersHistory memory){
        return winnerHistory[loop];
    }
    
    /* Modifier */
    modifier onlyOwner(){
        require(msg.sender == manager, "user not manager");
        _;
    }

}