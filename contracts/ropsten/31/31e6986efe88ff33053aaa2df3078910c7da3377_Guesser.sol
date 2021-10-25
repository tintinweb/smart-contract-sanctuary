/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.8.9;

contract Guesser {
    event LockInGuess(bool success, uint8 number);
    event Receive(uint256 value);
    event NumberGenerated(uint8 number);
    event Settled(bool success);
    
    address constant ME = 0x4301BEd7A2327D175E4842563E044b73a089D199;
    address constant CHALLENGE = 0xb70b627782105AfbA66011533595D81f06fB1a5f;
    uint8 constant GUESSED_NUMBER = 0;
    uint256 public settlementBlockNumber;
    
    receive() external payable {
        emit Receive(msg.value);
    }
    

    function lockInGuess() public payable {
        require(msg.sender == ME);
        require(msg.value == 1 ether);
        
        (bool success, ) = CHALLENGE.call{value: 1 ether}(
            abi.encodeWithSignature("lockInGuess(uint8)", GUESSED_NUMBER)
        );
        settlementBlockNumber = block.number + 1;
        emit LockInGuess(success, GUESSED_NUMBER);
    }

    function settle() public {
        require(msg.sender == ME);
        require(settlementBlockNumber != 0);
        require(block.number > settlementBlockNumber);

        bytes memory encodePacked = abi.encodePacked(blockhash(block.number - 1), block.timestamp);
        uint256 hash = uint256(keccak256(encodePacked));
        uint8 answer = uint8(hash) % 10;

        emit NumberGenerated(answer);

        if (answer == GUESSED_NUMBER){
            (bool success, ) = CHALLENGE.call{value: 1 ether}(
                abi.encodeWithSignature("settle()")
            );
            
            emit Settled(success);
            
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}