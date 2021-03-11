/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity >=0.7.0 <0.8.0;

contract Owner {

    address private owner;
    uint256 private sellingPrice;

    constructor(uint256 _sellingPrice) {
        owner = msg.sender;
        sellingPrice = _sellingPrice;
    }

    function changeOwner(address newOwner) payable public {
        require(msg.sender == owner || msg.value == sellingPrice, "Caller is not owner");
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}