/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

contract lot{

     // lottery project
    // users buy ticket with random number
    // users can buy many tickets
    // users can own more than one ticket of the same number
    // when winning ticket number is chosen jackpot balance
    // is split between all winning ticket holders
    // send winnings to winners

    address private admin;
    uint    private numbers = 10;   // possible ticket numbers 0 - 9
    uint    public  balance;        // jackpot balance
    uint    public  winningTicket;  // winning ticket number

      using SafeMath for uint256;  //SafeMath for underflows
  struct data {


        uint ticketNumber;  //The ticketNumber. not necessarily required
        address[] owners;  // address of the owners that got this ticketNumber
        mapping(address => uint) getWinners;     // mapping of address to the numbers of tickets they bought (The count of the same ticket number)




    }
    struct dat{
          mapping(uint => uint) viewTicketCount;  // mapping of ticketcount by ticketNumber

    }

    mapping(uint => data) public detailsByTicket;   // mapping to struct by uint --- this is ticket number in the range from 1 to 10
    mapping(address => dat)  viewer;                // address to struct mapping for return ticket details of owner


    constructor() {
        admin = msg.sender;
        }
        
        
        receive() external payable {}

        
    function buyTicket() external payable
    {
        require(msg.value >= 1 ether);      // ticket price
        balance += msg.value;               // add value to balance
        uint ticket = _random() % numbers;  // random ticket number
        // ownerTickets[msg.sender][ticket]++; // add ticket to owner
        // ticketOwners[ticket][msg.sender]++; // add owner to ticket
        // myTickets[msg.sender].push(ticket); // add ticket for view function
        // ticketSupply[ticket]++;             // increase count per ticket

        // getTickets[msg.sender] = ticket;
        viewer[msg.sender].viewTicketCount[ticket]++;   // count of a specific ticket is updated

        // The below states check if the whether the a same ticket is already bought the address if yes ... it does not store that address again,
        // If no the address will be stored.
        bool check=false;

        for(uint i = 0; i < detailsByTicket[ticket].owners.length;i++) // loops through the address[] array in the data struct
        {
             if(detailsByTicket[ticket].owners[i] == msg.sender) {   // checks if the person already bought that the same ticket number. if he did, his address will not be recorded again
                    check = true;
         }
        }
        if(check == false){
             detailsByTicket[ticket].owners.push(payable(msg.sender));  // address is now recorded in owners of data struct
         }


        detailsByTicket[ticket].getWinners[msg.sender]++; // The count of that same ticket number is increased


    }
    function pickWinner() public adminOnly {
        winningTicket = _random() % numbers;            // pick random winning ticket

        // HELP: can I send winnings automatically here?
    }

    // the below function calculates the prize money that should be awarded to each based the ticket count (the ticket that has won)
    function claimPrize() public {
         uint totalCount =0;
        for(uint i=0;i<detailsByTicket[winningTicket].owners.length;i++)
        {
            uint singleCount = detailsByTicket[winningTicket].getWinners[detailsByTicket[winningTicket].owners[i]]; // passing the address to getWinners to get the count of the number thas has won
            totalCount = totalCount + singleCount;                        //summing them all
        }
        for(uint i =0; i<detailsByTicket[winningTicket].owners.length;i++){            //loop through all the  address in the data struct and transfer money based the ticket number count(ticket numbet that has won)
            uint newTemp = detailsByTicket[winningTicket].getWinners[detailsByTicket[winningTicket].owners[i]];
            uint giveAway = (balance/totalCount) * newTemp;
            payable(detailsByTicket[winningTicket].owners[i]).transfer(giveAway);
            // transaction...


        }
    }

    //The below function returns the array ..

    //The array consists of ticketcount of the ticket ( eg : res[1] = 5) is the msg.sender bought 1st ticket 5 times;
    //This can be handled in the server side....

     function viewTickets() public view returns(uint[] memory) {

      uint[] memory res = new uint[](10);
      for(uint i=0;i<10;i++){
        res[i]= viewer[msg.sender].viewTicketCount[i];
    }
    return res;
     }
         // random not random number generator
    function _random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    // admin permission role
    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }


}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}