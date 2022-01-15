/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

contract GuessingGame {
    uint256 public balance;
    uint256 private secret;

    constructor(uint256 amount) {
        balance = amount;
        secret = block.timestamp;
    } 

    function guess(uint256 guess) public {
        if ((guess + secret) % 2 == 0) {
            balance += 1;
        } else{
            balance -= 1;
        }
        secret = block.timestamp;
    }
    
}