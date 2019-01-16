pragma solidity ^0.4.25;

contract Roll{
    address public manager;
    address[] public players;
    uint8[] public luckynumbers;
    uint256 sizebet;
    uint256 win;
    uint256 luck;
    event Bet (
    address from,
    uint256 value,
    uint256 number
    );
    event Luckynumber(
    uint8 luckynumber
    );
    
    constructor() public{
        manager = msg.sender;
    }

    function random() private view returns (uint8) {
    return uint8(uint256(keccak256(block.timestamp, block.difficulty))%100); // random 0-99
    }

    function bet(uint8 under) public payable{
        require(msg.value > .01 ether, "sender value not enough");
        require(under > 0 && under < 99, "no 100% win");
        players.push(msg.sender);
        sizebet = msg.value;

        uint8 _random = random();
        luckynumbers.push(_random);
        emit Luckynumber(_random);

        if (_random + under >= 100) {
          luck = .001 ether;
          win = uint256 (sizebet*(98 - under)/100);
          if (address(this).balance > win){
            msg.sender.transfer(win);
          emit Bet(msg.sender, msg.value, under);
          }
          
          
        } else if (_random + 3 >= 100) {
          msg.sender.transfer(luck);
        }
    }
    


    modifier restricted() {
        // Ensure the participant awarding the ether is the manager
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[]) {
        // Return list of players
        return players;
    }
    function getLuckynumber() public view returns(uint8[]) {
        // Return list of players
        return luckynumbers;
    }
}