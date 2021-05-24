/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ElixyrsaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}