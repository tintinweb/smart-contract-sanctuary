pragma solidity 0.8.0;
import "./child.sol";

contract factory {
    address[] public childs;

    function createChild(uint256 number) public {
        children child = new children(number);
        childs.push(address(child));
    }
}