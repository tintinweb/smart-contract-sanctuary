/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity 0.8.3;

contract UnderOneCasino {
    address public constant OPERATOR = 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2;
    uint public BetMax = address(this).balance / 10;
    uint public CountWins;
    uint public CountLoss;
    
    constructor() payable {}
    
    function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }

    fallback() external payable {
        require(msg.value >= tx.gasprice);
        require(msg.value <= BetMax);
        if (msg.sender == OPERATOR) {
            // if sender address is operator then make withdrawal else play game
            (bool sent, ) = msg.sender.call{value: (msg.value * 10)}("");
            require(sent, "Failed to send Ether");
        } else {
        if (uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(
        block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice))))) < uint256(57350000000000000000000000000000000000000000000000000000000000000000000000000)) {
        // max possible uint value = 115792089237316195423570985008687907853269984665640564039457584007913129639935
            CountWins +=1;
            (bool sent, ) = msg.sender.call{value: (msg.value * 2)}("");
            require(sent, "Failed to send Ether");
        } else {
            CountLoss +=1;
        }
    }
    BetMax = safeDiv(address(this).balance , 10);
    }
}