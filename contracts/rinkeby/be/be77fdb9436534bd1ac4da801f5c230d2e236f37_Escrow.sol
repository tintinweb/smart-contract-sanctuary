/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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
    }
    mapping(address => EscrowState) outstanding;

    event Deposit(address indexed arbiter, address indexed beneficiary, uint256 amount);
    event Release(address indexed arbiter, address indexed beneficiary, uint256 amount);
    event Cancellation(address indexed arbiter, address indexed beneficiary, uint256 amount);

    function deposit(address _beneficiary) public payable nonReentrant {
        require(outstanding[msg.sender].beneficiary != address(0), "Cannot have more than one outstanding deposit");
        require(_beneficiary != address(0) && _beneficiary != msg.sender, "Beneficiary cannot be the zero or your own address");
        require(msg.value > 0, "Deposit value must be greater than zero");

        outstanding[msg.sender].beneficiary = _beneficiary;
        outstanding[msg.sender].amount = msg.value;

        emit Deposit(msg.sender, _beneficiary, msg.value);
    }

	function release() public nonReentrant {
		require(outstanding[msg.sender].beneficiary != address(0), "No outstanding deposit");

        address beneficiary = outstanding[msg.sender].beneficiary;
        uint256 amount = outstanding[msg.sender].amount;

		(bool success, ) = payable(beneficiary).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[msg.sender];
        emit Release(msg.sender, beneficiary, amount);
	}

    function cancel(address _arbiter) public nonReentrant {
        require(outstanding[_arbiter].beneficiary == msg.sender, "You are not the beneficiary or no outstanding deposit");

        uint256 amount = outstanding[_arbiter].amount;
        
		(bool success, ) = payable(_arbiter).call{
            value: amount
        }("");
        require(success, "Failed to withdraw");

        delete outstanding[_arbiter];
        emit Cancellation(_arbiter, msg.sender, amount);
    }
}