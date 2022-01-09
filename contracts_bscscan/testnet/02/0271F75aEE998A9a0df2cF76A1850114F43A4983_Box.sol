pragma solidity 0.8.10;

contract Box {

    uint256 private value;

    event ValueChanged(uint256 newValue);

    function mystore (uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns(uint256) {
        return value;
    }
}