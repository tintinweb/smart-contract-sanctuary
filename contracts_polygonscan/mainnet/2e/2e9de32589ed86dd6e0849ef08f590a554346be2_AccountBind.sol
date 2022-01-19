// SPDX-License-Identifier: MIT

import "Ownable.sol";

pragma solidity ^0.8.0;

contract AccountBind is Ownable {

    struct Account {
        uint mid;
        bool bound;
    }

    mapping(address => Account) accounts;
    mapping(uint => address) mids;

    // Donat us by crypto
    function donate() public payable {
        (bool sent,) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to donate");
    }

    // Check address is bound
    function isAddressBound(address addr) view internal returns(bool) {
        return accounts[addr].bound;
    }

    // Check mid is bound
    function isMidBound(uint mid) view internal returns(bool) {
        return mids[mid] != address(0);
    }

    // Get adddress bound mid
    function getMid(address addr) view external returns(uint) {
        require(
            isAddressBound(addr) == true,
            "Address not bound"
        );
        return accounts[addr].mid;
    }

    // Check contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     *
     * Write address and mid to data the contract.
     * Can only be called by the current owner.
     */
    function bind(address payable addr, uint mid) public payable onlyOwner {
        require(
            isAddressBound(addr) != true,
            "Address already bound"
        );
        require(
            isMidBound(mid) != true,
            "Mid already bound"
        );
        accounts[addr] = Account({mid: mid, bound: true});
        mids[mid] = addr;
        addr.transfer(10000000000000000);
    }

    /**
     *
     * Can only be called by the current owner.
     */
    function withdraw() public payable onlyOwner {
        payable(Ownable.owner()).transfer(getBalance());
    }

    receive() external payable {}

    fallback() external payable {}

}