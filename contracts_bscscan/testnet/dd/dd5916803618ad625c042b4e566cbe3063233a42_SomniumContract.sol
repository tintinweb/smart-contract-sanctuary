/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

pragma solidity ^0.8.10;

contract SomniumContract {
    struct Balance {
        uint256 amountDue;
        uint256 amountPaid;
    }

    mapping(address => Balance) private _balances;
    uint256 private _totalPaid;
    uint256 private _totalDue;
    address payable private _destination;

    constructor(
        address[] memory adressesInput,
        uint256[] memory amountsInput,
        uint256 totalDue,
        address payable destination
    ) {
        _totalDue = totalDue;
        _destination = destination;

        for (uint256 i = 0; i < amountsInput.length; i++) {
            _balances[adressesInput[i]] = Balance(amountsInput[i], 0);
        }
    }

    fallback() external payable {
        _totalPaid = _totalPaid + msg.value;
        if (_totalPaid >= _totalDue) {
            _destination.transfer(_totalPaid);
        } else {
            _balances[msg.sender] = Balance(
                _balances[msg.sender].amountDue,
                _balances[msg.sender].amountPaid + msg.value
            );
        }
    }
}