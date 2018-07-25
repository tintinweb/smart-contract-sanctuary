contract SimpleGame {
    address[] players;
    uint public counter = 0;
    uint public totalCounter = 0;
    uint[] ttint;
    
    event join(address indexed _from, uint indexed value);
    event joinFailed(address indexed _from);
    event victory(address indexed _from);

    function () external payable {
        address player = msg.sender;
        uint256 etherValue = msg.value;
        
        if(etherValue >= 1e-5 ether) {
            join(player, etherValue);
            if(counter == players.length) {
                players.length += 1;
            }
            totalCounter++;
            players[counter++] =player;
            if(counter == 10) {
                transfer();
            }
        }
        else {
            joinFailed(msg.sender);
        }
    }

    function getCounter() public view returns (uint) {
        return counter;
    }
    function getTotalCounter() public view returns (uint) {
        return totalCounter;
    }
    
    function getBalance() public view returns (uint) {
        return this.balance;
    } 

    function getPlayers() public view returns(address[]) {
        return players;
    }
    function reset() private {
        counter = 0;
    }
    function transfer() private returns (uint256) {
        reset();
        uint randNonce = 0;
        uint random = uint(keccak256(now, msg.sender, randNonce)) % 10;
        uint256 refund = getBalance() - 1e-5 ether;
        players[random].transfer(refund);
        victory(players[random]);
        return random;
    }
}