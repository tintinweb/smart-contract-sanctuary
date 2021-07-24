/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
        GDF Lotto
    --------------
    
    - 1 ticket = 1 Finney = 0.001 ETH = 1000000000000000 Wei = 1e15 Wei
    
    - tickets are calculated by (received balance / 1 finney) = no. of tickets
    
    - max no. of tickects to be obtained is 100 at a time
    
    - raffle draw is executed every [raffleBlocks], default is 6500 blocks, avg. 1 day
    
    - raffle winner takes 99% of the raffle jackpot, 1% goes to the contract address
    
    - after each draw, all sold tickets are reset 
    
    - completed raffle draw info are kept in [raffles] array [block no, pot, winner]
    
    - current running pot is in [jackpot]
    
*/


contract GDFLotto {
    
    // Public variables of the token
    address public admin;                                   // contract creator address
    address public gdf;                                     // gdf address to hold gdf 1% share
    
    string public name;
    string public symbol;
    uint public decimals;
    
    uint public raffleBlocks;                               // raffle execution cycle;
    
    uint public jackpot;                                    // holds total no. of tickets in pool
    
    mapping (address => uint) public playerTickets;         // holds number of tickets for each address
    address[] public raffleTickets;                         // puts addresses in raffle pool     
    address[] rafflePlayers;                                // holds addresses for current raffle

    uint denomination = 1000000000000000;                   // 1 finney in wei (1e15)
    
    // raffle history struct
    struct Raffle {
        uint        block;                                  // block number
        uint        pot;                                    // raffle pot prize
        address     winner;                                 // raffle winner address
    }
    
    Raffle[] public raffles;                                // raffles history array
    

    constructor() {
        admin = msg.sender;                                 // set admin owner address
        name = 'GDF Lotto';                                 // token name
        symbol = 'GDFL';                                    // token symbol
        decimals = 18;                                      // token decimals
        gdf = 0xf5374706FA64148b3Bf4FE8FbD054bCA10814C5D;   // address where 1% goes   
        raffleBlocks = 6500;                                // initial cycle every 1 day
        
        raffles.push(Raffle(block.number, 0, msg.sender));  // set to keep count of block numbers
    }

    // returns contract's balance
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }

    // buy raffle ticket
    function buyTicket() external payable returns (bool success) {
    
        // check for min. buy in
        require(msg.value > denomination);

        // generate tickets from sent value
        uint tickets = msg.value / denomination;
        
        // only 100 tickets could be bought at one timestamp
        require(tickets <= 100);

        // add tickets to player
        playerTickets[msg.sender] += tickets;
        
        // increment pool with new tickets
        jackpot += tickets;
        
        // add sender address to tickets pool
        for (uint i = 0; i < tickets; i++) {
            raffleTickets.push(msg.sender);
        }
        
        // check if player is in pool
        require(checkPlayer(msg.sender));
        
        // check if raffle draw is due (with min. 3 players)
        if((block.number - raffles[raffles.length - 1].block >= raffleBlocks) && (rafflePlayers.length > 3)) {
            raffleDraw();
        }

        return true;

    }
    
    // check if player address is in array 
    function checkPlayer(address _addr) private returns (bool success) {
        for (uint i = 0; i < rafflePlayers.length; i++) {
            if(rafflePlayers[i] == _addr) {
                return true;
            }
        }

        // if not, then add new player to pool
        rafflePlayers.push(_addr);

        return true;
    }
    
    // run the raffle draw 
    function raffleDraw() private returns (bool success) {
        
        // get winner random slot [array index]
        uint winnerIndex = random() % raffleTickets.length;
        
        // winner pot is 99% of the total pot
        uint winnerPot = (address(this).balance / 100) * 99;
        
        // winner address
        address winnerAddr = raffleTickets[winnerIndex];

        // record raffle winner
        raffles.push(Raffle(block.number, winnerPot, winnerAddr));
        
        // reset players balance
        for (uint i = 0; i < rafflePlayers.length; i++) {
            playerTickets[rafflePlayers[i]] = 0;
        }

        // reset raffle pool
        jackpot = 0;
        delete raffleTickets;
        delete rafflePlayers;
    
        // send pot to winner
        payable(winnerAddr).transfer(winnerPot);
        
        return true;
        
    }

    // generate a radnom pick from players pool [array index]
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, raffleTickets.length)));

    }
    
    // allows to inject ether into contract
    function inject() external payable returns (bool success){
        // only admin can enlist tokens
        require(msg.sender == admin);
        
        return true;
    }

    // allows to withdraw to GDF account
    function withdraw(uint _amount) external returns (bool success) {

        // only admin can enlist tokens
        require(msg.sender == admin);

         // send pot to winner
        payable(gdf).transfer(_amount);
       
        return true;
    }

    // can reset the raffle execution cycle 
    function setRaffleBlocks(uint _blocks) external returns (bool success) {
        // only admin can enlist tokens
        require(msg.sender == admin);
        
        raffleBlocks = _blocks;
        
        return true;
        
    }

    // can reset the gdf withdraw address 
    function setWithdrawAddr(address _addr) external returns (bool success) {
        // only admin can enlist tokens
        require(msg.sender == admin);
        
        gdf = _addr;
        
        return true;
        
    }
    
    // fallback functions
    fallback() external payable {}
    receive() external payable {}
    
}