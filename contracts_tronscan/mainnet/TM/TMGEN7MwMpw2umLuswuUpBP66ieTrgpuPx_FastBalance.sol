//SourceUnit: FastBalance.sol

pragma solidity ^0.5.10;

contract FastBalance {
    function balanceOf(address _user) external view returns (uint256) {
        return address(_user).balance;
    }
}