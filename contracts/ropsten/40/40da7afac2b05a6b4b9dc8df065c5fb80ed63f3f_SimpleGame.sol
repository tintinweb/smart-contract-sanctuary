contract SimpleGame {
    address[] players = [this];
    uint public counter = 0;
    uint[] ttint;
    
    event join(address indexed _from, uint indexed value);
    event joinFailed(address indexed _from);

    function () external payable {
        address player = msg.sender;
        uint256 etherValue=msg.value;
        
        if(etherValue >= 1e7) {
            join(player, etherValue);
            if(counter == players.length) {
                players.length += 1;
            }
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
    
    function getBalance() returns (uint) {
        return this.balance;//0
    } 
    function getPlayers() returns(address[]) {
        return players;
    }
    function reset() private {
        counter = 0;
    }
    function transfer() private returns (uint256) {
        reset();
        uint randNonce = 0;
        uint random = uint(keccak256(now, msg.sender, randNonce)) % 10;
        uint256 refund = getBalance() - 1e7;
        players[random].transfer(refund);
        return random;
    }
}