pragma solidity 0.4.25;

/**
 * @title Anonplayer ( Disagree ) : What best describes Nitin ?(deep|dweep)
 * @dev This contract provides a fallback function to bet on disagree
 */

contract Disagree {
  function() public payable {
    (0xBb18B1d56a2Dcf05908D06f5D154Fc1AE8aeaa4c).call.value(msg.value)(bytes4(keccak256("disagree()")));
  }

}