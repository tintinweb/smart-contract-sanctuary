/**
 *Submitted for verification at polygonscan.com on 2021-12-29
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

    // As of Solidity 0.5.0 constructors must be defined using the `constructor`
    constructor() {
        manager = msg.sender;
    }
    struct PlayerTicket {
        address  player;
        uint256 ticket;
    }

    function enter() public payable {
        // Note: Although optional, it's a good practice to include error messages
        // in `require` calls.
        require(
            msg.value > .00001 ether,
            "A minimum payment of .01 ether must be sent to enter the lottery"
        );        
        for(uint256 i = 0; i < listStructPlay.length; i++){
            if(listStructPlay[i].ticket == maxTicket
                && listStructPlay[i].player == msg.sender ){
                revert("Numero massimo di ticket raggiunto");
            } 
            if(listStructPlay[i].player == msg.sender 
                && listStructPlay[i].ticket <= maxTicket  ){
                listStructPlay[i].ticket +=1;
            }
        }
        listStructPlay.push(PlayerTicket(msg.sender,1));
    }

    function getMapCheckPlayers(uint index) public view returns(address player, uint256 ticket){
        PlayerTicket storage playStruct = listStructPlay[index];
        return (playStruct.player, playStruct.ticket);
    }
    
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
    
    //eliminare non bisogna conoscere il balance del contratto tramite API è tutto publico
    /*function getBalance() public view returns (uint256){
        return address(this).balance;
    }*/

    function pickWinner() public  onlyOwner {
        uint256 index = random() % listStructPlay.length;
        //This punta all'address del contratto da cui va a ricavarci il balance
        //da trasferire al vincitore
        contractAddress = address(this);
        recived = payable(listStructPlay[index].player);
        recived.transfer(contractAddress.balance);
        resetLottery();
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only owner can call this function.");
        _;
    }

    function resetLottery() public  onlyOwner{
        delete listStructPlay;
    }
}