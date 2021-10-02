pragma solidity ^0.8.0;

import "./Lotty.sol";

contract Lottery is Lotty {

    address public admin;
    
    struct Entrant {
        bool isEntered;
        uint ethAmount;
        uint entrantAge;
    }
    
    mapping(address => Entrant) public entrantStruct;
    
//creating one array for current lottery participants
//and one array for participants who have already won
    address[] public previousEntrantWinners;
    address[] public entrants;

    event Winner(address indexed from, address indexed to, uint value);

//Assign admin rights to specific address
    constructor(address _admin) 
    { 
        admin = _admin; 
    }
    
//enables admin address to change admin   
    function changeAdmin(address newAdmin) 
        public 
        onlyAdmin() 
    {
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
        require(
            msg.value == 0.0013 ether, //1300000000000000 wei --> $5.00 USD at time of writing 
            "Wrong amount of ether"
        );
        entrantStruct[entrantAddress].isEntered = true;
        entrantStruct[entrantAddress].ethAmount += msg.value;
        entrantStruct[entrantAddress].entrantAge = _entrantAge;
        entrants.push(entrantAddress);
    }

//picks winner from entrant array
    function pickWinner() 
        public 
        onlyAdmin() 
    {
        uint index = _random() % entrants.length;
        for(uint i = 0; i < entrants.length; i++) {
            delete(entrantStruct[entrants[i]]);
        }
        previousEntrantWinners.push(entrants[index]);
        _mint(entrants[index]);
        emit Winner(admin, entrants[index], address(this).balance);
        (bool sent, ) = payable(entrants[index]).
            call{value:(address(this).balance)}("");
        require(sent, "Transaction Failed");
        entrants = new address[](0);
    }
//returns the eth stored in contract
    function getLotteryBalance() 
        public view 
        returns(uint)  
    {
        return address(this).balance;
    }
    
//view current lottery participants
    function getEntrants() 
        public view 
        returns
        (address[] memory)  
    {
        return entrants;
    }
    function getNumOfEntrants()
        public view 
        returns(uint) 
    {
        return entrants.length;
    }

//view previous lottey winners
    function getPreviousEntrantWinners() 
        public view 
        returns(address[] memory) 
    {
        return previousEntrantWinners;
    }
    
//Helper function for pickwinner to mint Lotty tokens to winner
// function taken from Lotty contract
    function _mint(address lotteryWinner) 
        private
    {
        balances[lotteryWinner] += 10;
        totalSupply += 10;
    }
    
//Helper function for pickWinner(). *Unsecure* Subject to change
    function _random() 
        private view 
        returns(uint) 
    {
        return uint(keccak256(abi.encodePacked(
            block.difficulty, 
            block.timestamp,
            entrants
        )));
    }
/*function helper disabling any address other than 
admin to call functions when this is applied*/
    modifier 
        onlyAdmin() 
    {
        require(
            msg.sender == admin,
            "only admin can call this function"
        );
        _;
    }
}