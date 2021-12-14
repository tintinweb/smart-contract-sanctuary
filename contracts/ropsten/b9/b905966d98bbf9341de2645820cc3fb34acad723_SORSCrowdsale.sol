// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract SORSCrowdsale {
    IERC20 public token;
    address public _owner;

    event TransferSent(address _from, address _destAddr, uint _amount);

    constructor (IERC20 _token) public {
        _owner = msg.sender;
        token = _token;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transfer(address _recipient, uint256 _amount) public onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(_amount <= erc20balance, "balance is low");
        token.transfer(_recipient, _amount);
        emit TransferSent(msg.sender, _recipient, _amount);
    }
}