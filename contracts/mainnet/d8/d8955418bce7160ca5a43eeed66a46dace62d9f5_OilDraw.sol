/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT License

/*
░███████╗░█████╗░██╗██╗░░░░░  ██████╗░██████╗░░█████╗░░██╗░░░░░░░██╗
██╔██╔══╝██╔══██╗██║██║░░░░░  ██╔══██╗██╔══██╗██╔══██╗░██║░░██╗░░██║
╚██████╗░██║░░██║██║██║░░░░░  ██║░░██║██████╔╝███████║░╚██╗████╗██╔╝
░╚═██╔██╗██║░░██║██║██║░░░░░  ██║░░██║██╔══██╗██╔══██║░░████╔═████║░
███████╔╝╚█████╔╝██║███████╗  ██████╔╝██║░░██║██║░░██║░░╚██╔╝░╚██╔╝░
╚══════╝░░╚════╝░╚═╝╚══════╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░
By: BR33D                                                         */

pragma solidity ^0.8.11;

interface iOIL {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burn(address from_, uint amount) external;
}

contract OilDraw {

    address public owner;
    address[] public players;
    
    uint256 public ticketPrice = 20000000000000000000000; // 20,000ETH
    uint256 public drawId;
	uint256 public maxTicketsPerTx = 10;
    
    bool public drawLive = false;

    mapping (uint => address) public pastDraw;
    mapping (address => uint256) public userEntries;


    constructor() {
        owner = msg.sender;
        drawId = 1;
    }

    address public oilAddress;
    iOIL public Oil;
    function setOil(address _address) external onlyOwner {
        oilAddress = _address;
        Oil = iOIL(_address);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /*  ======================
        |---Entry Function---|
        ======================
    */

    function enterDraw(uint256 _numOfTickets) public payable {
        uint256 totalTicketCost = ticketPrice * _numOfTickets;
        require(Oil.balanceOf(msg.sender) >= ticketPrice * _numOfTickets, "insufficent $Oil");
        require(drawLive == true, "cannot enter at this time");
        require(_numOfTickets <= maxTicketsPerTx, "too many per TX");

        uint256 ownerTicketsPurchased = userEntries[msg.sender];
        require(ownerTicketsPurchased + _numOfTickets <= maxTicketsPerTx, "only allowed 10 tickets");
        Oil.burn(msg.sender, totalTicketCost);

        // player ticket purchasing loop
        for (uint256 i = 1; i <= _numOfTickets; i++) {
            players.push(msg.sender);
            userEntries[msg.sender]++;
        }
        
    }

    /*  ======================
        |---View Functions---|
        ======================
    */

    function getRandom() public view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase)));
        uint index = rand % players.length;
        return index;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function drawEntrys() public view returns (uint) {
        return players.length;
    }

    function getWinnerByDraw(uint _drawId) public view returns (address) {
        return pastDraw[_drawId];
    }

    // Retrieves total entries of players address
    function playerEntries(address _player) public view returns (uint256) {
        address addressOfPlayer = _player;
        uint arrayLength = players.length;
        uint totalEntries = 0;
        for (uint256 i; i < arrayLength; i++) {
            if(players[i] == addressOfPlayer) {
                totalEntries++;
            }
            
        }
        return totalEntries;
    }


    /*  ============================
        |---Owner Only Functions---|
        ============================
    */

    // Salt should be a random number from 1 - 1,000,000,000,000,000
    function pickWinner(uint _firstSalt, uint _secondSalt) public onlyOwner {
        uint rand = getRandom();
        uint firstWinner = (rand + _firstSalt) % players.length;
        uint secondWinner = (firstWinner + _secondSalt) % players.length;

        pastDraw[drawId] = players[firstWinner];
        drawId++;
        pastDraw[drawId] = players[secondWinner];
        drawId++;
    }

    function setTicketPrice(uint256 _newTicketPrice) public onlyOwner {
        ticketPrice = _newTicketPrice;
    }

    function setMaxTicket(uint256 _maxTickets) public onlyOwner {
        maxTicketsPerTx = _maxTickets;
    }

    function startEntries() public onlyOwner {
        drawLive = true;
    }

    function stopEntries() public onlyOwner {
        drawLive = false;
    }

    function transferOwnership(address _address) public onlyOwner {
        owner = _address;
    }

}