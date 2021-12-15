// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMetaCoin.sol";

contract MetaCoin is IMetaCoin {
    address _owner;
    uint256 _totalBalance;
    constructor (
        address owner,
        uint256 balance
    )  {
        _owner = owner;
        _totalBalance = balance;
    }


    function changeBalance(uint256 balance) external override {
        _totalBalance = balance;
    }

    function getBalance() external override view returns (uint256) {
        return _totalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaCoin {
    function changeBalance(uint256) external;
    function getBalance() external view returns (uint256);
}