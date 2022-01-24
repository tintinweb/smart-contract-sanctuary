/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// File: contracts/My_contract.sol
pragma solidity ^0.8.11;

contract MyLotteryContract{
    address payable[] participant_accounts ;
    uint256 participant_count;
    address winner_address;
    uint count;
    uint256 closing_time=block.timestamp+60;    //Closing time can be manually set as either related to blocktimestamp
                                                // or in an absolute way by specifying Unix timestamp 
   
    modifier OnlyWhileOpen(){
        require(block.timestamp<closing_time,"Lottery Closed! Cannot buy ticket");
        _;
    }

    modifier OnlyWhenClosed(){
        require(block.timestamp>=closing_time,"Lottery still Open. Winner can be seen after closing");
        _;
    }

    modifier OnlyOnce(){
        require(count<1,"Winner already Declared!");
        _;
    }

    modifier PaymentisValid(){
    require(msg.value==100 wei,"Lottery Ticket Costs 100 wei Exactly!");    //Lottery ticket Cost can be set here.
    _;
}


    function BuyLotteryTicket() public payable PaymentisValid OnlyWhileOpen {         //Buy Lottery Ticket for the cost that is set. No more, no less.
        participant_accounts.push(payable(msg.sender));
        participant_count++;
    }

    function NoOfParticipants() public view returns(uint256){                   //Returns the number of Participants
        return (participant_count);
    }

    function random() private view returns(uint){                               //Generates a (pseudo) random number

        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp))) % participant_count;
    }

    function DrawWinner() public payable OnlyWhenClosed OnlyOnce{           //Winner can drawn only after closing time and only once.
        uint256 index=random();
        participant_accounts[index].transfer( address(this).balance );
        winner_address=participant_accounts[index];
        count++;
    }
    function GetWinner() public view returns(address){                      //Returns Winner's address
        return winner_address;
    }
}