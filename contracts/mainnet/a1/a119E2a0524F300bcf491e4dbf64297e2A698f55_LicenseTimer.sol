/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

contract LicenseTimer {
    uint256 internal _licenseDeadline;

    address public immutable ADMIN;

    event LicenseDeadlineChanged(uint256 licenseDeadline);

    /**
     * @param licenseDeadline The UNIX timestamp where occurs the change of the License
     * @param admin The admin of the LicenseTimer contract
     **/
    constructor(uint256 licenseDeadline, address admin) {
        _licenseDeadline = licenseDeadline;
        ADMIN = admin;
    }

    /**
     * @dev Modifier to allow certain methods to only be callable by admin
     **/
    modifier onlyAdmin() {
        require(msg.sender == ADMIN, "ONLY_ADMIN");
        _;
    }

    /**
     * @return The UNIX timestamp of the License Deadline
     **/
    function getLicenseDeadline() external view returns (uint256) {
        return _licenseDeadline;
    }

    /**
     * @param licenseDeadline The UNIX timestamp of the License Deadline
     **/
    function setLicenseDeadline(uint256 licenseDeadline) external onlyAdmin {
        _licenseDeadline = licenseDeadline;
        emit LicenseDeadlineChanged(_licenseDeadline);
    }
}