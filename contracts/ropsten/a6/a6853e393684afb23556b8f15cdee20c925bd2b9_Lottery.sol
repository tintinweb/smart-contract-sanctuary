pragma solidity ^0.4.25;
contract Lottery{
    address[] public players;
 
// Makes way more sense to use builtin&#39;s for arrays
//  function newBidder(address id) private {
//      bidCount++;
//      bidders[bidCount] = Bidder(id, 0);
//  }    // Bidder[] public bidders;
//     // mapping(uint => Bidder) public bidders;

 
    function random () private view returns(uint){
        return uint(keccak256(block.difficulty, now, players));
    }
 
    function buyTicket() public payable {
        require(msg.value > 0 wei);
        require(players.length < 5);
        players.push(msg.sender);
    }
 
    function pickWinner() public {
        require(players.length == 5);
        players[random() % 5].transfer(address(this).balance);
        players = new address[](0);
    }
 
}