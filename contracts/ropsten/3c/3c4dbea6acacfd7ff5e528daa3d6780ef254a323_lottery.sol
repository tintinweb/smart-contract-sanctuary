pragma solidity ^0.4.0;
contract lottery {
    
    /*
        ●  The two input fields for the smart contract are the address and amount of Ether to wager. 
            The default is everyone has an equal chance of winning no matter how much Ether you wager but if you want to make the project more interesting, 
            you can design the contract so that the more Ether you wager the more likely you are to win as long as you document that in the submission file.
        ●  Once 5 people enter the contract, the contract will randomly generate a number using the random function provided below.
        ●  After generating a random number, the smart contract will then initiate a transaction that sends the Ether to the winning address and then restarts the lottery.
    */
    
    address owner;
    bool state; //true = Accepting, false = processing, not accepting new entries
    address[] players;
    uint pot;
    
    uint numElements = 0;
    
    function Lottery() public {
        owner = msg.sender;
        state = true;
        pot = 0;
    }
    
    /// Create a new lottery with $(amt) as the prize, and host&#39;s address
    function addEntry(uint8 amt) public returns(address) {
        require(state == true);
        require(amt > 0);
        pot += amt;

        if(numElements == players.length) {
            players.length += 1;
        }
        players[numElements++] = msg.sender;
        
        if(players.length == 5) {
            state = false;
            address temp = findWinner();
            clear();
            state = true;
            return temp;
        }
        return;
    }
    
    function getPot() public returns(uint) {
        return pot;
    }
    
    function clear() private {
        numElements = 0;
    }
    
    function findWinner() private returns(address){
        uint index = random() % players.length;    
        payOut(players[index]);
        return(players[index]);
    }
    
    function payOut(address winner) private {
        winner.transfer(pot);
    }
    
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

}