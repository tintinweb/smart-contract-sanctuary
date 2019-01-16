pragma solidity ^0.4.25;

contract Roll{
    address public admin;
    address[] public players;
    uint8[] public luckynumbers;
    uint256 sizebet;
    uint256 win;
    uint256 luck;
    event Won(
    address from,
    uint256 value,
    uint256 number
    );
    event Luckynumber(
    uint8 luckynumber
    );
    event Luckyplayer(
    bytes32 congratulation
    );
    
    constructor() public{
        admin = msg.sender;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty, luckynumbers))%100); // random 0-99
    }

    function bet(uint8 under) public payable{
        require(msg.value > .01 ether);
        require(under > 0 && under < 96);
        players.push(msg.sender);
        sizebet = msg.value;
        win = uint256 (sizebet*98/under);
        luck = .001 ether;
        uint8 _random = random();
        emit Luckynumber(_random);
        luckynumbers.push(_random);
        
        if (_random < under) {
            if(msg.value*98/under < address(this).balance) {
                msg.sender.transfer(win);
                emit Won(msg.sender, msg.value, under);
            }
        } else if (_random + 3 >= 100) {
          msg.sender.transfer(luck);
          emit Luckyplayer("You are lucky!");
        }
    }
    


    modifier onlyAdmin() {
        // Ensure the participant awarding the ether is the manager
        require(msg.sender == admin);
        _;
    }
    
    function withdrawEth(address to, uint256 balance) internal onlyAdmin {
        if (balance == uint256(0x0)) {
            to.transfer(address(this).balance);
        } else {
        to.transfer(balance);
    }
  }

    function getPlayers() public view returns(address[]) {
        // Return list of players
        return players;
    }
    function getLuckynumber() public view returns(uint8[]) {
        // Return list of luckynumbers
        return luckynumbers;
    }
}