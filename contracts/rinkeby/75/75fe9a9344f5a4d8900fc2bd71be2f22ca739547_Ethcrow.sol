/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Ethcrow {
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

    struct EscrowDeposit {
        address beneficiary;
        address arbiter;
        uint256 amount;
    }
    mapping(address => EscrowDeposit) outstanding;

    event Deposit(address indexed depositor, address indexed beneficiary, address indexed arbiter, uint256 amount);
    event Release(address indexed depositor, address indexed beneficiary, address indexed arbiter, uint256 amount);
    event Cancellation(address indexed depositor, address indexed beneficiary, address indexed arbiter, uint256 amount);

    function currentDeposit(address _depositor) public view returns (address beneficiary, address arbiter, uint256 amount) {
        return (outstanding[_depositor].beneficiary, outstanding[_depositor].arbiter, outstanding[_depositor].amount);
    }

    function deposit(address _beneficiary) public payable nonReentrant {
        require(outstanding[msg.sender].amount == 0, "Cannot have more than one outstanding deposit");
        require(_beneficiary != address(0) && _beneficiary != msg.sender, "Beneficiary cannot be the zero or your own address");
        require(msg.value > 0, "Deposit value must be greater than zero");

        outstanding[msg.sender].beneficiary = _beneficiary;
        outstanding[msg.sender].amount = msg.value;

        emit Deposit(msg.sender, _beneficiary, address(0), msg.value);
    }

    function deposit(address _beneficiary, address _arbiter) public payable nonReentrant {
        require(outstanding[msg.sender].amount == 0, "Cannot have more than one outstanding deposit");
        require(_beneficiary != address(0) && _beneficiary != msg.sender, "Beneficiary cannot be the zero or your own address");
        require(_arbiter != address(0) && _arbiter != msg.sender, "Arbiter cannot be the zero or your own address");
        require(msg.value > 0, "Deposit value must be greater than zero");

        outstanding[msg.sender].beneficiary = _beneficiary;
        outstanding[msg.sender].arbiter = _arbiter;
        outstanding[msg.sender].amount = msg.value;

        emit Deposit(msg.sender, _beneficiary, _arbiter, msg.value);
    }

	function release(address _depositor) public nonReentrant {
		require(outstanding[_depositor].amount != 0, "No outstanding deposit");
        require(msg.sender == _depositor || msg.sender == outstanding[_depositor].arbiter, "You are not the depositor or the arbiter");

        address beneficiary = outstanding[_depositor].beneficiary;
        address arbiter = outstanding[_depositor].arbiter;
        uint256 amount = outstanding[_depositor].amount;

		(bool success, ) = payable(beneficiary).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[_depositor];
        emit Release(_depositor, beneficiary, arbiter, amount);
	}

    function cancel(address _depositor) public nonReentrant {
        require(outstanding[_depositor].amount != 0, "No outstanding deposit");
        require(outstanding[_depositor].beneficiary == msg.sender || outstanding[_depositor].arbiter == msg.sender, "You are not the beneficiary or arbiter");

        address beneficiary = outstanding[_depositor].beneficiary;
        address arbiter = outstanding[_depositor].arbiter;
        uint256 amount = outstanding[_depositor].amount;
        
		(bool success, ) = payable(_depositor).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[_depositor];
        emit Cancellation(_depositor, beneficiary, arbiter, amount);
    }
}