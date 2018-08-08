// ECE 398 SC - Smart Contracts and Blockchain Security
// http://soc1024.ece.illinois.edu/teaching/ece398sc/spring2018/
// March 28, 2018

// This is an extra credit smart contract Pinata. It contains a puzzle 
// involving hash functions (you should be able to solve it pretty easily)

pragma solidity ^0.4.21;
contract TestContract {
    function SHA256(string s) public pure returns(bytes32) {
        return(sha256(s));
    }

    mapping ( bytes32 => uint ) public amount;
    
    // Pay for a preimage
    function commitTo(bytes32 hash) public payable {
        amount[hash] = msg.value;
    }
    
    // Claim a hash preimage
    
    // On mainnet, for the class Spring 2018,
    // The contract&#39;s address is 0x9faf31f1546ec47e99321045bbfda8ab5ef60b74
    //
    // A value has already been committed to ($10 of ETH)
    // The is the hash of a string, of the form "word1 word2 word3", where
    // word1,2,3 are randomly chosen words from the BIP39 word list.
    // Call the view
    // "amount(0xee67868e1463033b8cf103066b1d476b1698ca9a3e60c068430c520d2725b246)"
    // to check whether it has been taken or not!
    // 
    // The first person to solve it wins the prize! The game is not too fun
    // for anyone else unfortunately :(
    
    event BountyClaimed(string note, uint);
    function claim(string s) public payable {
        emit BountyClaimed("bounty claimed for eth amount:", amount[sha256(s)]);
        msg.sender.transfer( amount[sha256(s)] );
    }

}