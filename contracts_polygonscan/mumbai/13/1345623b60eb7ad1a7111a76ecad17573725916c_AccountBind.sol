// SPDX-License-Identifier: MIT

import "Ownable.sol";

pragma solidity ^0.8.0;

contract AccountBind is Ownable {

    struct Account {
        uint mid;
        bool bound;
    }
    uint256 private _transferAmount;
    mapping(address => Account) accounts;
    mapping(uint => address) mids;

    event AccountBoundMid(address indexed addr, uint indexed mid);

    /**
     * Initializes the contract setting default transfer amount.
     */
    constructor() {
        _transferAmount = 20000000000000000;
    }

    /**
     *
     * Check address already bound.
     * Can be called by anyone.
     */
    function isAddressBound(address addr) private view returns(bool) {
        return accounts[addr].bound;
    }

    // Check mid already bound
    function isMidBound(uint mid) private view returns(bool) {
        return mids[mid] != address(0);
    }

    /**
     *
     * Get adddress bound mid.
     * Can be called by anyone.
     */
    function getMid(address addr) public view returns(uint) {
        require(isAddressBound(addr), "Address not bound");
        return accounts[addr].mid;
    }

    /**
     *
     * Check contract balance.
     * Can be called by anyone.
     */
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /**
     *
     * Get transfer amount setting.
     * Can be called by anyone.
     */
    function getTransferAmount() public view returns(uint256) {
        return _transferAmount;
    }

    /**
     *
     * Change transfer amount setting.
     * Can only be called by the current owner.
     */
    function changeTransferAmount(uint256 transferAmount) public onlyOwner {
        _transferAmount = transferAmount;
    }

    /**
     *
     * Send a little matic to compensate for gas fee.
     * Can only be called by the current owner.
     */
    function sendGasFee(address payable addr) public payable onlyOwner {
        require(isAddressBound(addr), "Address not bound");
        require(addr.balance < _transferAmount, "Enough balance found");
        addr.transfer(_transferAmount);
    }

    /**
     *
     * Bind address and mid.
     * Send a little matic to compensate for gas fee.
     * Can only be called by the current owner.
     */
    function bind(address payable addr, uint mid) public payable onlyOwner {
        require(!isAddressBound(addr), "Address already bound");
        require(!isMidBound(mid), "Mid already bound");
        accounts[addr] = Account({mid: mid, bound: true});
        mids[mid] = addr;
        addr.transfer(_transferAmount);
        emit AccountBoundMid(addr, mid);
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