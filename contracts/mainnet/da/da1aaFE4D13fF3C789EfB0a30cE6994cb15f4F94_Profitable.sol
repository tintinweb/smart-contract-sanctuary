// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Timelocked.sol";

contract Profitable is Timelocked {
    mapping(address => bool) private verifiedIntegrators;
    uint256[] private mintFees = [0, 0, 0];
    uint256[] private burnFees = [0, 0, 0];
    uint256[] private dualFees = [0, 0, 0];

    event MintFeesSet(uint256[] mintFees);
    event BurnFeesSet(uint256[] burnFees);
    event DualFeesSet(uint256[] dualFees);
    event IntegratorSet(address account, bool isVerified);
    event Withdrawal(address to, uint256 amount);

    function getMintFees() internal view returns (uint256[] storage) {
        return mintFees;
    }

    function getBurnFees() internal view returns (uint256[] storage) {
        return burnFees;
    }

    function getDualFees() internal view returns (uint256[] storage) {
        return dualFees;
    }

    function setMintFees(uint256[] memory newMintFees)
        public
        onlyOwner
        whenNotLockedM
    {
        mintFees = newMintFees;
        emit MintFeesSet(newMintFees);
    }

    function setBurnFees(uint256[] memory newBurnFees)
        public
        onlyOwner
        whenNotLockedL
    {
        burnFees = newBurnFees;
        emit BurnFeesSet(newBurnFees);
    }

    function setDualFees(uint256[] memory newDualFees)
        public
        onlyOwner
        whenNotLockedM
    {
        dualFees = newDualFees;
        emit DualFeesSet(newDualFees);
    }

    function setIntegrator(address account, bool isVerified)
        public
        onlyOwner
        whenNotLockedM
    {
        verifiedIntegrators[account] = isVerified;
        emit IntegratorSet(account, isVerified);
    }

    function getFee(
        address account,
        uint256 numTokens,
        uint256[] storage fees
    ) internal view returns (uint256) {
        if (verifiedIntegrators[account]) {
            return 0;
        }
        if (numTokens == 1) {
            return fees[0];
        }
        return fees[1] + numTokens * fees[2];
    }

    function withdraw(address payable to) public onlyOwner whenNotLockedM {
        uint256 balance = address(this).balance;
        to.transfer(balance);
        emit Withdrawal(to, balance);
    }
}
