pragma solidity ^0.4.24;
contract Game01 {
    //the address of our team
    address public teamAddress;
    //addresses of players
    address[] public players;
    //sum of players
    uint public sumOfPlayers;
    //minimum bet
    uint public lowestOffer;
    //target block number
    uint public blockNumber;
    //store the hash of the target block
    bytes32 public blcokHash;
    //store the decimal number of the hash
    uint public numberOfBlcokHash;
    //store the winer index
    uint public winerIndex;
    //store the address of the winner
    address public winer;
    //private function:hunt for the lucky dog
    function produceWiner() private {
        //get the blockhash of the target blcok number
        blcokHash = blockhash(blockNumber);
        //convert hash to decimal
        numberOfBlcokHash = uint(blcokHash);
        //make sure that the block has been generated
        require(numberOfBlcokHash != 0);
        //calculating index of the winer
        winerIndex = numberOfBlcokHash%sumOfPlayers;
        //get the winer address
        winer = players[winerIndex];
        //calculating the gold of team
        uint tempTeam = (this.balance/100)*10;
        //transfe the gold to the team
        teamAddress.transfer(tempTeam);
        //calculating the gold of winer
        uint tempBonus = this.balance - tempTeam;
        //transfer the gold to the winer
        winer.transfer(tempBonus);
    }
    //public function:hunt for the lucky dog
    function goWiner() public {
        produceWiner();
    }
    //public function:bet
    function betYours() public payable OnlyBet() {
        //make sure that the block has not been generated
        blcokHash = blockhash(blockNumber);
        numberOfBlcokHash = uint(blcokHash);
        require(numberOfBlcokHash == 0);
        //add the player to the player list
        sumOfPlayers = players.push(msg.sender);
    }
    //make sure you bet enough ETH
    modifier OnlyBet() {
        require(msg.value >= lowestOffer);
        _;
    }
    //constructor function
    constructor(uint _blockNumber) public payable {
        teamAddress = msg.sender;//initialize the team address
        sumOfPlayers = 1;//initialize the players
        players.push(msg.sender);//add the team address to the players
        lowestOffer = 10000000000000000;//minimum bet:0.01ETH
        blockNumber = _blockNumber;//initialize the target block number
    }
    //get the address of team
    function getTeamAddress() public view returns(address addr) {
        addr = teamAddress;
    }
    //get the minimum bet ETH
    function getLowPrice() public view returns(uint low) {
        low = lowestOffer;
    }
    //get the player address from the index
    function getPlayerAddress(uint index) public view returns(address addr) {
        addr = players[index];
    }
    //get sum of players
    function getSumOfPlayers() public view returns(uint sum) {
        sum = sumOfPlayers;
    }
    //get the target blcok number
    function getBlockNumber() public view returns(uint num) {
        num = blockNumber;
    }
    //get the balance of contract(bonus pools)
    function getBalances() public view returns(uint balace) {
        balace = this.balance;
    }
}