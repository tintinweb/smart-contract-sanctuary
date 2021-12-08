/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity >=0.6.0;

contract MatchingPennies {
   

    address public playerA;
    bytes32 public playerAhash;
    uint256 public betAmount;
    address public playerB;
    bool public playerBChoice;
    uint256 public expiration = 2*256-1;


    // we want to let A enter the game and make a choice and type a sentence of words. Then we use sha256 to get a unique hash value which
// can't be guessed by player B.
    function AEnter(bool choose, string memory password) public payable {
        playerA = msg.sender;
        playerAhash = sha256(abi.encodePacked(choose, password));
        betAmount = msg.value;
    }

    // To make the game to be fair, we let A can cancel the game at any time if B don't enter the game, the money A paid to the contract
// will return back to A's account.
    function PlayerAcancel() public {
        require(msg.sender == playerA);
        require(playerB == address(0));
        betAmount = 0;
        payable(msg.sender).transfer(address(this).balance);
    }

    // B can enter the game as long as there is no other player in the game, and player B should pay as much amount as player A's,
// after the player B take the bet, the timer will start to make sure that player A will reveal the answer in time.
    function BBet(bool choice) public payable {
        require(playerB == address(0));
        require(msg.value == betAmount);
        playerB = msg.sender;
        playerBChoice = choice;
        expiration = block.timestamp + 3 hours;
    }

    // We need A to enter two inputs in this function and to match with the choose and words that A set before.
    function Answer(bool choose, string memory password) public {
        require(playerB != address(0));
        require(block.timestamp < expiration);
        require(sha256(abi.encodePacked(choose, password)) == playerAhash);
        if (playerBChoice == choose) {
            payable(playerA).transfer(address(this).balance);
        } else {
            payable(playerB).transfer(address(this).balance);
        }
    }

    // B can cancel at any time, also, B will get the bet back.
    function PlayerBcancel() public {
        require(block.timestamp >= expiration);
        payable(playerB).transfer(address(this).balance);
    }
}