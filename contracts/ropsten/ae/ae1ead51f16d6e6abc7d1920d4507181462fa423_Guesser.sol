/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.8.9;

contract Guesser {
    event LockInGuess(uint8 number);
    event Receive(uint256 value);
    event NumberGenerated(uint8 number);
    event Settled(bool success);
    
    address constant ME = 0x4301BEd7A2327D175E4842563E044b73a089D199;
    address constant CHALLENGE = 0xb3e9f2E511f0cAE94Db0838Da37130F7c43d19E8;
    uint8 constant GUESSED_NUMBER = 0;
    uint256 public settlementBlockNumber;
    
    receive() external payable {
        emit Receive(msg.value);
    }
    

    function lockInGuess() public payable {
        require(msg.sender == ME, 'Must be called by ME');
        require(msg.value == 1 ether, 'Must send 1 ether');
        require(settlementBlockNumber == 0, 'Already locked');
        
        (bool success, ) = CHALLENGE.call{value: 1 ether}(
            abi.encodeWithSignature("lockInGuess(uint8)", GUESSED_NUMBER)
        );
        require(success, "Can't lock in guess");
        
        settlementBlockNumber = block.number + 1;
        emit LockInGuess(GUESSED_NUMBER);
    }

    function settle() public {
        require(msg.sender == ME, 'Must be called by ME');
        require(settlementBlockNumber != 0, 'Must call lockInGuess first');
        require(block.number > settlementBlockNumber);

        bytes memory encodePacked = abi.encodePacked(blockhash(block.number - 1), block.timestamp);
        uint256 hash = uint256(keccak256(encodePacked));
        uint8 answer = uint8(hash) % 10;

        emit NumberGenerated(answer);

        if (answer == GUESSED_NUMBER){
            (bool success, ) = CHALLENGE.call(
                abi.encodeWithSignature("settle()")
            );
            
            emit Settled(success);
            
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}