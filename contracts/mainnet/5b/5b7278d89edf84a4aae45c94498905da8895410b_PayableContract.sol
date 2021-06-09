/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @author [@DreWhyte](Telegram)
/// @title Payable Contract
contract PayableContract {

    address public owner;

    address public admin;

    event Transfer(address indexed _to, uint256 _value);

    event Receive(address indexed _from, uint256 _value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin privilege only");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner privilege only");
        _;
    }

    /**
    * @notice Set the default admin and owner
    * as address that deploys contract
    */
    constructor() {
        admin = msg.sender;
        owner = admin;
    }

    /**
    * @param _newOwner payable address of new owner
    * @return status
    * @dev previous owner cannot be made new owner
    */
    function transferOwnership(address _newOwner) public onlyAdmin returns(bool status){
        require(_newOwner != address(0));

        address previousOwner = owner;

        require(previousOwner != _newOwner);

        owner = _newOwner;

        return true;
    }

    /**
    * @dev Withdraw all funds
    */
    function withdrawAll() public onlyOwner {
        uint amount = address(this).balance;

        (bool success,) = msg.sender.call{value: amount}("");

        require(success, "withdrawAll: Transfer failed");

        emit Transfer(msg.sender, amount);
    }

    /**
    * @param amount Amount to withdraw in wei
    */
    function withdrawPartial(uint amount) public onlyOwner {
        (bool success,) = msg.sender.call{value: amount}("");

        require(success, "withdrawPartial: Transfer failed");

        emit Transfer(msg.sender, amount);
    }


    /**
    * @dev This can only reply on 2300 gas been available
    * @dev We can't do beyond simple ven logging
    */
    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    /**
    * @dev Retrieve all funds & destroy contract
    * in case of emergency
    */
    function killSwitch() public onlyAdmin() {
      address payable _owner = payable(owner);

      selfdestruct(_owner);
    }
}