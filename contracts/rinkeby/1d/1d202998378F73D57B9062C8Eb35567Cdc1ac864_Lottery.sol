/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    // As of Solidity 0.5.0 the `address` type was split into `address` and
    // `address payable`, where only `address payable` provides the transfer
    // function. We therefore need to explicity use the `address payable[]`
    // array type for the players array.
    address public manager;
    address payable[] public players;
    uint256 public maxTicket = 2;
    PlayerTicket[] public listStructPlay;
    address payable recived;
    address contractAddress;
    address[] public playerWinnerExtract;
    string message;

    // As of Solidity 0.5.0 constructors must be defined using the `constructor`
    constructor() {
        manager = msg.sender;
    }
    struct PlayerTicket {
        address  player;
        uint256 ticket;
    }

    function enter(uint256 numberTicket) public payable {
        //Aggiungere altri controlli se necessario START 
        require(
            msg.value  == .0001 ether * numberTicket,
            "A minimum payment of .01 ether must be sent to enter the lottery"
        ); 
        //Aggiungere altri controlli se necessario END
        //CHECK MACX TICKET FOR ADDRESS START
        
        for(uint256 i = 0; i < listStructPlay.length; i++){
            
            if(listStructPlay[i].ticket == maxTicket
                && listStructPlay[i].player == msg.sender ){
                revert("Numero massimo di ticket raggiunto");
            }
            require(listStructPlay[i].ticket+numberTicket == maxTicket,"Numero di Ticket massimo raggiunto 20");
            require(listStructPlay[i].ticket+numberTicket < maxTicket,"hai raggiunto il limite prova con un numero di ticket inferiore");
            if(listStructPlay[i].player == msg.sender 
                && listStructPlay[i].ticket <= maxTicket){
                listStructPlay[i].ticket +=numberTicket;
                playerWinnerExtract.push(msg.sender);
                break;
            }
        }
        //CHECK MACX TICKET FOR ADDRESS END        
        playerWinnerExtract.push(msg.sender);//EXTRACT PLAYER WINNER IN "pickWinner"
        listStructPlay.push(PlayerTicket(msg.sender,numberTicket));

    }
    //Return struct Player -> ticket
    function getMapCheckPlayers(uint index) public view returns(address player, uint256 ticket){
        PlayerTicket storage playStruct = listStructPlay[index];
        return (playStruct.player, playStruct.ticket);
    }
    //generate number random to extract winneer in "pickWinner"
    function random() private view returns (uint256) {
        // For an explanation of why `abi.encodePacked` is used here, see
        // https://github.com/owanhunte/ethereum-solidity-course-updated-code/issues/1
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, players)
                )
            );
    }
    //EXTRACT PLAYER WINNER LOTTERY
    function pickWinner() public  onlyOwner {
        uint256 index = random() % playerWinnerExtract.length;
        //This punta all'address del contratto da cui va a ricavarci il balance
        //da trasferire al vincitore
        contractAddress = address(this);
        recived = payable(playerWinnerExtract[index]);
        recived.transfer(contractAddress.balance);//modificare con variabile in cui si trova il premio
        resetLottery();//resetta la lottery dopo aver estratto il vincitore ed aver trasferito il premio
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only owner can call this function.");
        _;
    }
    //empty the two lists to reuse the contract
    function resetLottery() public  onlyOwner{
        delete playerWinnerExtract;
        delete listStructPlay;
    }
}