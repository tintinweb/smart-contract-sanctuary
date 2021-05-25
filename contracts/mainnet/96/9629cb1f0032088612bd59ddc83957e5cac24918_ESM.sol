/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract ESMThresholdSetter {
    function recomputeThreshold() virtual public;
}

abstract contract TokenLike {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
    function transferFrom(address, address, uint256) virtual public returns (bool);
}

abstract contract GlobalSettlementLike {
    function shutdownSystem() virtual public;
}

contract ESM {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) public isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "esm/account-not-authorized");
        _;
    }

    TokenLike            public protocolToken;      // collateral
    GlobalSettlementLike public globalSettlement;   // shutdown module
    ESMThresholdSetter   public thresholdSetter;    // threshold setter

    address              public tokenBurner;        // burner
    uint256              public triggerThreshold;   // threshold
    uint256              public settled;            // flag that indicates whether the shutdown module has been called/triggered

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 wad);
    event ModifyParameters(bytes32 parameter, address account);
    event Shutdown();
    event FailRecomputeThreshold(bytes revertReason);

    constructor(
      address protocolToken_,
      address globalSettlement_,
      address tokenBurner_,
      address thresholdSetter_,
      uint256 triggerThreshold_
    ) public {
        require(both(triggerThreshold_ > 0, triggerThreshold_ < TokenLike(protocolToken_).totalSupply()), "esm/threshold-not-within-bounds");

        authorizedAccounts[msg.sender] = 1;

        protocolToken    = TokenLike(protocolToken_);
        globalSettlement = GlobalSettlementLike(globalSettlement_);
        thresholdSetter  = ESMThresholdSetter(thresholdSetter_);
        tokenBurner      = tokenBurner_;
        triggerThreshold = triggerThreshold_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters(bytes32("triggerThreshold"), triggerThreshold_);
        emit ModifyParameters(bytes32("thresholdSetter"), thresholdSetter_);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    // --- Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Modify a uint256 parameter
    * @param parameter The name of the parameter to change the value for
    * @param wad The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 wad) external {
        require(settled == 0, "esm/already-settled");
        require(either(address(thresholdSetter) == msg.sender, authorizedAccounts[msg.sender] == 1), "esm/account-not-authorized");
        if (parameter == "triggerThreshold") {
          require(both(wad > 0, wad < protocolToken.totalSupply()), "esm/threshold-not-within-bounds");
          triggerThreshold = wad;
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, wad);
    }
    /*
    * @notice Modify an address parameter
    * @param parameter The parameter name whose value will be changed
    * @param account The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address account) external isAuthorized {
        require(settled == 0, "esm/already-settled");
        if (parameter == "thresholdSetter") {
          thresholdSetter = ESMThresholdSetter(account);
          // Make sure the update works
          thresholdSetter.recomputeThreshold();
        }
        else revert("esm/modify-unrecognized-param");
        emit ModifyParameters(parameter, account);
    }

    /*
    * @notify Recompute the triggerThreshold using the thresholdSetter
    */
    function recomputeThreshold() internal {
        if (address(thresholdSetter) != address(0)) {
          try thresholdSetter.recomputeThreshold() {}
          catch(bytes memory revertReason) {
            emit FailRecomputeThreshold(revertReason);
          }
        }
    }
    /*
    * @notice Sacrifice tokens and trigger settlement
    * @dev This can only be done once
    */
    function shutdown() external {
        require(settled == 0, "esm/already-settled");
        recomputeThreshold();
        settled = 1;
        require(protocolToken.transferFrom(msg.sender, tokenBurner, triggerThreshold), "esm/transfer-failed");
        emit Shutdown();
        globalSettlement.shutdownSystem();
    }
}