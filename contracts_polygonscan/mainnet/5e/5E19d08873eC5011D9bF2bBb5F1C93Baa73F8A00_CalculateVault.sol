// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVaultChef.sol";

contract CalculateVault {
    
    address public constant fishAddress = 0x3a3Df212b7AA91Aa0402B9035b098891d276572B;
    address public immutable vaultChef;
    uint256 public immutable vaultPid;
    
    constructor(
        address _vaultChef,
        uint256 _vaultPid
    ) public {
        vaultChef = _vaultChef;
        vaultPid = _vaultPid;
    }

    function balanceOf(address _user) external view returns (uint256) {
        return calculateVault(_user, vaultChef, vaultPid);
    }
    
    function calculateVault(address _user, address _vault, uint256 _pid) public view returns (uint256) {
        return IVaultChef(_vault).stakedWantTokens(_pid, _user);
    }
}