pragma solidity ^0.4.25;
// Guess the number, win a prize!

contract GuessMe {
    uint256 private current;
    uint256 public last;
    address public owner;
    uint256 public min_bet = 0.001 ether;

    struct Guess {
        uint256 playerNo;
        uint256 number;
    }
    
    Guess[] public guesses;
    mapping( address => bool ) public winners;
    
    constructor() public {
        owner = msg.sender;
        every_day_im_shufflin();
    }
    
    function every_day_im_shufflin() internal {
        // EVERY DAY IM SHUFFLIN
        current = uint8(keccak256(blockhash(block.number-2))) % 64;
    }
    
    function isWinner(address addr) public view returns (bool) {
        return winners[addr];
    }
    
    function do_guess(uint256 number) payable public {
        require(msg.value >= min_bet && number <= 10);
        require(!winners[msg.sender]);
        
        Guess guess;
        guess.playerNo = uint16(uint256(msg.sender)&0xffff);
        guess.number = number;
        guesses.push(guess);
        
        if (number == current) {
            msg.sender.transfer(100000000000000000);
            winners[msg.sender] = true;
        }
        
        every_day_im_shufflin();
        
        last = now;
    }
    
    function kill() public {
        if (msg.sender == owner) {
            selfdestruct(msg.sender);
        }
    }
    
    function() public payable { }
}