// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.4 <0.7.0;

/**
 * @title IFeature
 * @notice Interface for a Feature.
 * @author Julien Niset - <julien@argent.xyz>, Olivier VDB - <olivier@argent.xyz>
 */
interface IFeature {

    enum OwnerSignature {
        Anyone,             // Anyone
        Required,           // Owner required
        Optional,           // Owner and/or guardians
        Disallowed          // guardians only
    }

    /**
    * @notice Utility method to recover any ERC20 token that was sent to the Feature by mistake.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external;

    /**
     * @notice Inits a Feature for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(address _wallet) external;

    /**
     * @notice Helper method to check if an address is an authorised feature of a target wallet.
     * @param _wallet The target wallet.
     * @param _feature The address.
     */
    function isFeatureAuthorisedInVersionManager(address _wallet, address _feature) external view returns (bool);

    /**
    * @notice Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures and the wallet owner signature requirement.
    */
    function getRequiredSignatures(address _wallet, bytes calldata _data) external view returns (uint256, OwnerSignature);

    /**
    * @notice Gets the list of static call signatures that this feature responds to on behalf of wallets
    */
    function getStaticCallSignatures() external view returns (bytes4[] memory);
}