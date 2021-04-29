/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ICErc20 } from "../../../interfaces/external/ICErc20.sol";
import { Compound } from "../lib/Compound.sol";

/**
 * @title CompoundWrapAdapter
 * @author Set Protocol, Ember Fund
 *
 * Wrap adapter for Compound that returns data for wraps/unwraps of tokens
 */
contract CompoundWrapAdapter {
  using Compound for ICErc20;


  /* ============ Constants ============ */

    // Compound Mock address to indicate ETH. ETH is used directly in Compound protocol (instead of an abstraction such as WETH)
    address public constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ External Getter Functions ============ */

    /**
     * Generates the calldata to wrap an underlying asset into a wrappedToken.
     *
     * @param _underlyingToken      Address of the component to be wrapped
     * @param _wrappedToken         Address of the desired wrapped token
     * @param _underlyingUnits      Total quantity of underlying units to wrap
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of underlying units (if underlying is ETH)
     * @return bytes                Wrap calldata
     */
    function getWrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        uint256 value;
        bytes memory callData;
        if (_underlyingToken == ETH_TOKEN_ADDRESS) {
            value = _underlyingUnits;
            ( , , callData) = ICErc20(_wrappedToken).getMintCEtherCalldata(_underlyingUnits);
        } else {
            value = 0;
            ( , , callData) = ICErc20(_wrappedToken).getMintCTokenCalldata(_underlyingUnits);
        }

        return (_wrappedToken, value, callData);
    }

    /**
     * Generates the calldata to unwrap a wrapped asset into its underlying.
     *
     * @param _underlyingToken      Address of the underlying asset
     * @param _wrappedToken         Address of the component to be unwrapped
     * @param _wrappedTokenUnits    Total quantity of wrapped token units to unwrap
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of wrapped token units to unwrap. This will always be 0 for unwrapping
     * @return bytes                Unwrap calldata
     */
    function getUnwrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedTokenUnits
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        ( , , bytes memory callData) = ICErc20(_wrappedToken).getRedeemCalldata(_wrappedTokenUnits);
        return (_wrappedToken, 0, callData);
    }

    /**
     * Returns the address to approve source tokens for wrapping.
     * @param _wrappedToken         Address of the wrapped token
     * @return address              Address of the contract to approve tokens to
     */
     function getSpenderAddress(address /* _underlyingToken */, address _wrappedToken) external view returns(address) {
         return address(_wrappedToken);
     }

}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ICErc20
 * @author Set Protocol
 *
 * Interface for interacting with Compound cErc20 tokens (e.g. Dai, USDC)
 */
interface ICErc20 is IERC20 {

    function borrowBalanceCurrent(address _account) external returns (uint256);

    function borrowBalanceStored(address _account) external view returns (uint256);

    /**
     * Calculates the exchange rate from the underlying to the CToken
     *
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external returns (address);

    /**
     * Sender supplies assets into the market and receives cTokens in exchange
     *
     * @notice Accrues interest whether or not the operation succeeds, unless reverted
     * @param _mintAmount The amount of the underlying asset to supply
     * @return uint256 0=success, otherwise a failure
     */
    function mint(uint256 _mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemTokens The number of cTokens to redeem into underlying
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 _redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param _redeemAmount The amount of underlying to redeem
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256);

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param _borrowAmount The amount of the underlying asset to borrow
      * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint256 _borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @param _repayAmount The amount to repay
     * @return uint256 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint256 _repayAmount) external returns (uint256);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { ISetToken } from "../../../interfaces/ISetToken.sol";
import { ICErc20 } from "../../../interfaces/external/ICErc20.sol";
import { IComptroller } from "../../../interfaces/external/IComptroller.sol";

/**
 * @title Compound
 * @author Set Protocol
 *
 * Collection of helper functions for interacting with Compound integrations
 */
library Compound {
    /* ============ External ============ */

    /**
     * Get enter markets calldata from SetToken
     */
    function getEnterMarketsCalldata(
        ICErc20 _cToken,
        IComptroller _comptroller
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        address[] memory marketsToEnter = new address[](1);
        marketsToEnter[0] = address(_cToken);

        // Compound's enter market function signature is: enterMarkets(address[] _cTokens)
        bytes memory callData = abi.encodeWithSignature("enterMarkets(address[])", marketsToEnter);

        return (address(_comptroller), 0, callData);
    }

    /**
     * Invoke enter markets from SetToken
     */
    function invokeEnterMarkets(ISetToken _setToken, ICErc20 _cToken, IComptroller _comptroller) external {
        ( , , bytes memory enterMarketsCalldata) = getEnterMarketsCalldata(_cToken, _comptroller);

        uint256[] memory returnValues = abi.decode(_setToken.invoke(address(_comptroller), 0, enterMarketsCalldata), (uint256[]));
        require(returnValues[0] == 0, "Entering failed");
    }

    /**
     * Get exit market calldata from SetToken
     */
    function getExitMarketCalldata(
        ICErc20 _cToken,
        IComptroller _comptroller
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's exit market function signature is: exitMarket(address _cToken)
        bytes memory callData = abi.encodeWithSignature("exitMarket(address)", address(_cToken));

        return (address(_comptroller), 0, callData);
    }

    /**
     * Invoke exit market from SetToken
     */
    function invokeExitMarket(ISetToken _setToken, ICErc20 _cToken, IComptroller _comptroller) external {
        ( , , bytes memory exitMarketCalldata) = getExitMarketCalldata(_cToken, _comptroller);
        require(
            abi.decode(_setToken.invoke(address(_comptroller), 0, exitMarketCalldata), (uint256)) == 0,
            "Exiting failed"
        );
    }

    /**
     * Get mint cEther calldata from SetToken
     */
    function getMintCEtherCalldata(
       ICErc20 _cEther,
       uint256 _mintNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's mint cEther function signature is: mint(). No return, reverts on error.
        bytes memory callData = abi.encodeWithSignature("mint()");

        return (address(_cEther), _mintNotional, callData);
    }

    /**
     * Invoke mint cEther from the SetToken
     */
    function invokeMintCEther(ISetToken _setToken, ICErc20 _cEther, uint256 _mintNotional) external {
        ( , , bytes memory mintCEtherCalldata) = getMintCEtherCalldata(_cEther, _mintNotional);

        _setToken.invoke(address(_cEther), _mintNotional, mintCEtherCalldata);
    }

    /**
     * Get mint cToken calldata from SetToken
     */
    function getMintCTokenCalldata(
       ICErc20 _cToken,
       uint256 _mintNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's mint cToken function signature is: mint(uint256 _mintAmount). Returns 0 if success
        bytes memory callData = abi.encodeWithSignature("mint(uint256)", _mintNotional);

        return (address(_cToken), _mintNotional, callData);
    }

    /**
     * Invoke mint from the SetToken. Mints the specified cToken from the underlying of the specified notional quantity
     */
    function invokeMintCToken(ISetToken _setToken, ICErc20 _cToken, uint256 _mintNotional) external {
        ( , , bytes memory mintCTokenCalldata) = getMintCTokenCalldata(_cToken, _mintNotional);

        require(
            abi.decode(_setToken.invoke(address(_cToken), 0, mintCTokenCalldata), (uint256)) == 0,
            "Mint failed"
        );
    }

    /**
     * Get redeem underlying calldata
     */
    function getRedeemUnderlyingCalldata(
       ICErc20 _cToken,
       uint256 _redeemNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's redeem function signature is: redeemUnderlying(uint256 _underlyingAmount)
        bytes memory callData = abi.encodeWithSignature("redeemUnderlying(uint256)", _redeemNotional);

        return (address(_cToken), _redeemNotional, callData);
    }

    /**
     * Invoke redeem underlying from the SetToken
     */
    function invokeRedeemUnderlying(ISetToken _setToken, ICErc20 _cToken, uint256 _redeemNotional) external {
        ( , , bytes memory redeemUnderlyingCalldata) = getRedeemUnderlyingCalldata(_cToken, _redeemNotional);

        require(
            abi.decode(_setToken.invoke(address(_cToken), 0, redeemUnderlyingCalldata), (uint256)) == 0,
            "Redeem underlying failed"
        );
    }

    /**
     * Get redeem calldata
     */
    function getRedeemCalldata(
       ICErc20 _cToken,
       uint256 _redeemNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature("redeem(uint256)", _redeemNotional);

        return (address(_cToken), _redeemNotional, callData);
    }


    /**
     * Invoke redeem from the SetToken
     */
    function invokeRedeem(ISetToken _setToken, ICErc20 _cToken, uint256 _redeemNotional) external {
        ( , , bytes memory redeemCalldata) = getRedeemCalldata(_cToken, _redeemNotional);

        require(
            abi.decode(_setToken.invoke(address(_cToken), 0, redeemCalldata), (uint256)) == 0,
            "Redeem failed"
        );
    }

    /**
     * Get repay borrow calldata
     */
    function getRepayBorrowCEtherCalldata(
       ICErc20 _cToken,
       uint256 _repayNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's repay ETH function signature is: repayBorrow(). No return, revert on fail
        bytes memory callData = abi.encodeWithSignature("repayBorrow()");

        return (address(_cToken), _repayNotional, callData);
    }

    /**
     * Invoke repay cEther from the SetToken
     */
    function invokeRepayBorrowCEther(ISetToken _setToken, ICErc20 _cEther, uint256 _repayNotional) external {
        ( , , bytes memory repayBorrowCalldata) = getRepayBorrowCEtherCalldata(_cEther, _repayNotional);
        _setToken.invoke(address(_cEther), _repayNotional, repayBorrowCalldata);
    }

    /**
     * Get repay borrow calldata
     */
    function getRepayBorrowCTokenCalldata(
       ICErc20 _cToken,
       uint256 _repayNotional
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's repay asset function signature is: repayBorrow(uint256 _repayAmount)
        bytes memory callData = abi.encodeWithSignature("repayBorrow(uint256)", _repayNotional);

        return (address(_cToken), _repayNotional, callData);
    }

    /**
     * Invoke repay cToken from the SetToken
     */
    function invokeRepayBorrowCToken(ISetToken _setToken, ICErc20 _cToken, uint256 _repayNotional) external {
        ( , , bytes memory repayBorrowCalldata) = getRepayBorrowCTokenCalldata(_cToken, _repayNotional);
        require(
            abi.decode(_setToken.invoke(address(_cToken), 0, repayBorrowCalldata), (uint256)) == 0,
            "Repay failed"
        );
    }

    /**
     * Get borrow calldata
     */
    function getBorrowCalldata(
       ICErc20 _cToken,
       uint256 _notionalBorrowQuantity
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        // Compound's borrow function signature is: borrow(uint256 _borrowAmount). Note: Notional borrow quantity is in units of underlying asset
        bytes memory callData = abi.encodeWithSignature("borrow(uint256)", _notionalBorrowQuantity);

        return (address(_cToken), 0, callData);
    }

    /**
     * Invoke the SetToken to interact with the specified cToken to borrow the cToken's underlying of the specified borrowQuantity.
     */
    function invokeBorrow(ISetToken _setToken, ICErc20 _cToken, uint256 _notionalBorrowQuantity) external {
        ( , , bytes memory borrowCalldata) = getBorrowCalldata(_cToken, _notionalBorrowQuantity);
        require(
            abi.decode(_setToken.invoke(address(_cToken), 0, borrowCalldata), (uint256)) == 0,
            "Borrow failed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

import { ICErc20 } from "./ICErc20.sol";


/**
 * @title IComptroller
 * @author Set Protocol
 *
 * Interface for interacting with Compound Comptroller
 */
interface IComptroller {

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param cTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory cTokens) external returns (uint[] memory);

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param cTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address cTokenAddress) external returns (uint);

    function getAllMarkets() external view returns (ICErc20[] memory);

    function claimComp(address holder) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "contracts/protocol/integration/lib/Compound.sol": {
      "Compound": "0x4972d98602aaf0ccd678e59827200b86dfae65f9"
    }
  }
}