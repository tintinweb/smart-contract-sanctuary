contract Gamble {
    address owner;
    Bet[] bets;
    address[] winners;

    struct Bet {
        address sender;
        int8 range;
    }

    function Gamble() {
        owner = msg.sender;
    }

    function place (int8 range) public payable {
        if (msg.value >= 50 finney && range <= 100) {
            bets[bets.length++] = Bet({sender: msg.sender, range: range});
        }
    }

    function solve (int8 range) public {
        if (msg.sender == owner && range <= 100) {
            for (uint i = 0; i < bets.length; ++i) {
                if (bets[i].range == range) {
                    winners[winners.length++] = bets[i].sender;
                }
            }

            for (uint j = 0; j < winners.length; ++j) {
                winners[j].send(winners.length / this.balance);
            }

            selfdestruct(owner);
        }
    }
}