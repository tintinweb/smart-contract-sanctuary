//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Lotty.sol";

contract Lottery is Lotty {
    struct Entrant {
        bool isEntered;
        uint ethAmount;
        uint entrantAge;
    }
    
    address public admin;

    mapping(address => Entrant) public entrantStruct;
    
//creating one array for current lottery participants
//and one array for participants who have already won
    address[] public entrants;
    address[] public previousEntrantWinners;

    event Winner(address indexed from, address indexed to, uint value);

//Assign admin rights to specific address on creation of contract
    constructor(address _admin) { 
        admin = _admin; 
    }
    
//enables admin address to change who the admin is
    function changeAdmin(address newAdmin) public onlyAdmin() {
        for(uint i = 0; i < entrants.length; i++) {
            require(
                newAdmin != entrants[i],
                "Lottery entrant cannot be made to admin"
            );
        }
        require(
            newAdmin != admin,
            "This address is already the admin"
        );
        admin = newAdmin;
    }

//Allows any address to add any address into the Lottery except the admin address
    function enterLottery(
        address entrantAddress,
        uint _entrantAge
    ) 
        public payable 
    {
        require(
            entrantAddress != admin,
            "Admin cannot participate in Lottery"
        );
        require(
            entrantStruct[entrantAddress].isEntered != true,
            "This address has already been enterd"
        );
//function invoker has to send along the specified amount of Ether with their function call *subject to change*
        require(
            msg.value == 0.0013 ether, //1300000000000000 wei --> $5.00 USD at time of writing 
            "Wrong amount of ether"
        );
//Creates new struct and with entrant information and pushes it into an array of entrant structs
        entrantStruct[entrantAddress].isEntered = true;
        entrantStruct[entrantAddress].ethAmount += msg.value;
        entrantStruct[entrantAddress].entrantAge = _entrantAge;
        entrants.push(entrantAddress);
    }

//picks winner from entrant array and clears all fields regarding this lottery
    function pickWinner() public onlyAdmin() {
        uint index = _random() % entrants.length;
//Deletes entrant struct array for new lottery pook
        for(uint i = 0; i < entrants.length; i++) {
            delete(entrantStruct[entrants[i]]);
        }
        previousEntrantWinners.push(entrants[index]);
//calls private function that creates new Lotty tokens for Lottery winner
        _mint(entrants[index]);
        emit Winner(admin, entrants[index], address(this).balance);
//sends either to Lottery winner
        (bool sent, ) = payable(entrants[index]).
            call{value:(address(this).balance)}("");
        require(sent, "Transaction Failed");
//clears the array entrant array
        entrants = new address[](0);
    }
//returns the current amount of eth in lottery pool
    function getLotteryBalance() public view returns(uint) {
        return address(this).balance;
    }
    
//view current lottery participants
    function getEntrants() public view returns(address[] memory) {
        return entrants;
    }

//returns the number of entrants there currently are in the lottery
    function getNumOfEntrants() public view returns(uint) {
        return entrants.length;
    }

//view previous lottey winners
    function getPreviousEntrantWinners() public view returns(address[] memory) {
        return previousEntrantWinners;
    }
    
//creates new tokens and gives them to lottery winner.
//this function is executed in the pickeWinner function
    function _mint(address lotteryWinner) private {
        balances[lotteryWinner] += 10;
        totalSupply += 10;
    }
    
//Helper function for pickWinner(). *Unsecure* Subject to change
    function _random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(
            block.difficulty, 
            block.timestamp,
            entrants
        )));
    }
//function helper disabling any address other than 
//admin to call functions when this is applied
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "only admin can call this function"
        );
        _;
    }
}