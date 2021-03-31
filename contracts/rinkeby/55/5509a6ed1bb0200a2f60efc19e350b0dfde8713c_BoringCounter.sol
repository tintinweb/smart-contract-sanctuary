/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.8.3;

contract BoringCounter {
    uint256 public counter;
    
    event Increment(address who, uint256 preValue, uint256 increment, uint256 postValue);

    function increment() public {
        uint256 preValue = counter;
        counter += 1;
        emit Increment(msg.sender, preValue, 1, counter);
    }
    
    function increment(uint256 amount) public {
        uint256 preValue = counter;
        counter += amount;
        emit Increment(msg.sender, preValue, amount, counter);
    }

}