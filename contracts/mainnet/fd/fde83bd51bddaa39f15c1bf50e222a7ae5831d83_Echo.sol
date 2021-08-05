/**
 *Submitted for verification at Etherscan.io on 2020-04-15
*/

pragma solidity 0.6.2;

contract Echo {
    event Echoed(int indexed value);

    mapping (int => bool) public emitted;

    function echo(int value) public {
      emitted[value] = true;
      emit Echoed(value);
    }

    receive() external payable {
      require(1 == 2, "Always fails");
    }
}