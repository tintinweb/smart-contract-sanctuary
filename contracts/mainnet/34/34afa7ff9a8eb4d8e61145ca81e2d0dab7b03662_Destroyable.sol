pragma solidity ^0.4.0;

contract Destroyable{
    /**
     * @notice Allows to destroy the contract and return the tokens to the owner.
     */
    function destroy() public{
        selfdestruct(address(this));
    }
}