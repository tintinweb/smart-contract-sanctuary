/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Escrow {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    // @openzeppelin/contracts/security/ReentrancyGuard.sol
    modifier nonReentrant() {
        require(_status != _ENTERED, "Cannot execute reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    struct EscrowState {
        address beneficiary;
        uint256 amount;
        address governor;
    }
    mapping(address => EscrowState) outstanding;

    event Deposit(address indexed arbiter, address indexed beneficiary, address indexed governor, uint256 amount);
    event Release(address indexed arbiter, address indexed beneficiary, address indexed governor, uint256 amount);
    event Cancellation(address indexed arbiter, address indexed beneficiary, address indexed governor, uint256 amount);

    function currentDeposit(address _arbiter) public view returns (address, uint256) {
        return (outstanding[_arbiter].beneficiary, outstanding[_arbiter].amount);
    }

    function deposit(address _beneficiary) public payable nonReentrant {
        require(outstanding[msg.sender].beneficiary == address(0), "Cannot have more than one outstanding deposit");
        require(_beneficiary != address(0) && _beneficiary != msg.sender, "Beneficiary cannot be the zero or your own address");
        require(msg.value > 0, "Deposit value must be greater than zero");

        outstanding[msg.sender].beneficiary = _beneficiary;
        outstanding[msg.sender].amount = msg.value;

        emit Deposit(msg.sender, _beneficiary, address(0), msg.value);
    }

    function depositWithGovernor(address _beneficiary, address _governor) public payable nonReentrant {
        require(outstanding[msg.sender].beneficiary == address(0), "Cannot have more than one outstanding deposit");
        require(_beneficiary != address(0) && _beneficiary != msg.sender, "Beneficiary cannot be the zero or your own address");
        require(msg.value > 0, "Deposit value must be greater than zero");

        outstanding[msg.sender].beneficiary = _beneficiary;
        outstanding[msg.sender].governor = _governor;
        outstanding[msg.sender].amount = msg.value;

        emit Deposit(msg.sender, _beneficiary, _governor, msg.value);
    }

	function release(address _arbiter) public nonReentrant {
		require(outstanding[_arbiter].beneficiary != address(0), "No outstanding deposit");
        require((outstanding[_arbiter].governor == address(0) && msg.sender == _arbiter) || msg.sender == outstanding[_arbiter].governor, "You are not the arbiter or the governor");

        address beneficiary = outstanding[_arbiter].beneficiary;
        address governor = outstanding[_arbiter].governor;
        uint256 amount = outstanding[_arbiter].amount;

		(bool success, ) = payable(beneficiary).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[_arbiter];
        emit Release(_arbiter, beneficiary, governor, amount);
	}

    function cancel(address _arbiter) public nonReentrant {
        require(outstanding[_arbiter].beneficiary == msg.sender || outstanding[_arbiter].governor == msg.sender, "You are not the beneficiary or governor, or no outstanding deposit");

        address beneficiary = outstanding[_arbiter].beneficiary;
        address governor = outstanding[_arbiter].governor;
        uint256 amount = outstanding[_arbiter].amount;
        
		(bool success, ) = payable(_arbiter).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[_arbiter];
        emit Cancellation(_arbiter, beneficiary, governor, amount);
    }
}