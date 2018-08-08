pragma solidity ^0.4.24;

contract wordbot { function getWords(uint _wordcount) public view returns (bytes6[]) {} }

contract test {
    wordbot wordbot_contract = wordbot(0xA95E23ac202ad91204DA8C1A24B55684CDcC19B3);
    
    uint wordcount = 12;
    string[12] public human_readable_blockhash;
    
    modifier one_time_use {
        require(keccak256(human_readable_blockhash[0]) == keccak256(""));
        _;
    }
    
    function record_human_readable_blockhash() 
        one_time_use public
    {
        bytes6[] memory word_sequence = new bytes6[](wordcount);
        word_sequence = wordbot_contract.getWords(wordcount);
        
        for(uint i = 0; i<wordcount; i++) {
            bytes6 word = word_sequence[i];
            bytes memory toBytes = new bytes(6);
            assembly {
                toBytes := mload(word)
            }
            human_readable_blockhash[i] = string(toBytes);
        }
        
    }
    
}