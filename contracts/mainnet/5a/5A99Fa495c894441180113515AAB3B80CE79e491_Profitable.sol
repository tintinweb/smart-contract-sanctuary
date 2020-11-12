// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Timelocked.sol";

contract Profitable is Timelocked {
    mapping(address => bool) private verifiedIntegrators;
    uint256 private numIntegrators = 0;
    uint256[] private mintFees = [0, 0, 0];
    uint256[] private burnFees = [0, 0, 0];
    uint256[] private dualFees = [0, 0, 0];
    uint256[] private supplierBounty = [(5 * 10**17), 10];

    event MintFeesSet(uint256[] mintFees);
    event BurnFeesSet(uint256[] burnFees);
    event DualFeesSet(uint256[] dualFees);
    event SupplierBountySet(uint256[] supplierBounty);
    event IntegratorSet(address account, bool isVerified);
    event Withdrawal(address to, uint256 amount);

    function getMintFees() public view returns (uint256[] memory) {
        return mintFees;
    }

    function getBurnFees() public view returns (uint256[] memory) {
        return burnFees;
    }

    function getDualFees() public view returns (uint256[] memory) {
        return dualFees;
    }

    function getSupplierBounty() public view returns (uint256[] memory) {
        return supplierBounty;
    }

    function _getMintFees() internal view returns (uint256[] storage) {
        return mintFees;
    }

    function _getBurnFees() internal view returns (uint256[] storage) {
        return burnFees;
    }

    function _getDualFees() internal view returns (uint256[] storage) {
        return dualFees;
    }

    function setMintFees(uint256[] memory newMintFees)
        public
        onlyOwner
        whenNotLockedM
    {
        require(newMintFees.length == 3, "Wrong length");
        mintFees = newMintFees;
        emit MintFeesSet(newMintFees);
    }

    function setBurnFees(uint256[] memory newBurnFees)
        public
        onlyOwner
        whenNotLockedL
    {
        require(newBurnFees.length == 3, "Wrong length");
        burnFees = newBurnFees;
        emit BurnFeesSet(newBurnFees);
    }

    function setDualFees(uint256[] memory newDualFees)
        public
        onlyOwner
        whenNotLockedM
    {
        require(newDualFees.length == 3, "Wrong length");
        dualFees = newDualFees;
        emit DualFeesSet(newDualFees);
    }

    function setSupplierBounty(uint256[] memory newSupplierBounty)
        public
        onlyOwner
        whenNotLockedL
    {
        require(newSupplierBounty.length == 2, "Wrong length");
        supplierBounty = newSupplierBounty;
        emit SupplierBountySet(newSupplierBounty);
    }

    function isIntegrator(address account) public view returns (bool) {
        return verifiedIntegrators[account];
    }

    function getNumIntegrators() public view returns (uint256) {
        return numIntegrators;
    }

    function setIntegrator(address account, bool isVerified)
        public
        onlyOwner
        whenNotLockedM
    {
        require(isVerified != verifiedIntegrators[account], "Already set");
        if (isVerified) {
            numIntegrators = numIntegrators.add(1);
        } else {
            numIntegrators = numIntegrators.sub(1);
        }
        verifiedIntegrators[account] = isVerified;
        emit IntegratorSet(account, isVerified);
    }

    function getFee(address account, uint256 numTokens, uint256[] storage fees)
        internal
        view
        returns (uint256)
    {
        uint256 fee = 0;
        if (verifiedIntegrators[account]) {
            return 0;
        } else if (numTokens == 1) {
            fee = fees[0];
        } else {
            fee = fees[1] + numTokens * fees[2];
        }
        return fee;
    }

    function getBurnBounty(uint256 numTokens) public view returns (uint256) {
        uint256 bounty = 0;
        uint256 reservesLength = getReserves().length();
        uint256 padding = supplierBounty[1];
        if (reservesLength - numTokens <= padding) {
            uint256 addedAmount = 0;
            for (uint256 i = 0; i < numTokens; i++) {
                if (reservesLength - i <= padding && reservesLength - i > 0) {
                    addedAmount += (supplierBounty[0] *
                        (padding - (reservesLength - i) + 1));
                }
            }
            bounty += addedAmount;
        }
        return bounty;
    }

    function getMintBounty(uint256 numTokens) public view returns (uint256) {
        uint256 bounty = 0;
        uint256 reservesLength = getReserves().length();
        uint256 padding = supplierBounty[1];
        if (reservesLength <= padding) {
            uint256 addedAmount = 0;
            for (uint256 i = 0; i < numTokens; i++) {
                if (reservesLength + i <= padding) {
                    addedAmount += (supplierBounty[0] *
                        (padding - (reservesLength + i)));
                }
            }
            bounty += addedAmount;
        }
        return bounty;
    }

    function withdraw(address payable to) public onlyOwner whenNotLockedM {
        uint256 balance = address(this).balance;
        to.transfer(balance);
        emit Withdrawal(to, balance);
    }
}
