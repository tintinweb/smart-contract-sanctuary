// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./lib/CloneLibrary.sol";

/// @author Conjure Finance Team
/// @title ConjureFactory
/// @notice Factory contract to create new instances of Conjure
contract ConjureFactory {
    using CloneLibrary for address;

    event NewConjure(address conjure, address etherCollateral);
    event FactoryOwnerChanged(address newowner);

    address payable public factoryOwner;
    address public conjureImplementation;
    address public etherCollateralImplementation;
    address payable public conjureRouter;

    constructor(
        address _conjureImplementation,
        address _etherCollateralImplementation,
        address payable _conjureRouter
    )
    {
        factoryOwner = msg.sender;
        conjureImplementation = _conjureImplementation;
        etherCollateralImplementation = _etherCollateralImplementation;
        conjureRouter = _conjureRouter;
    }

    /**
     * @dev lets anyone mint a new Conjure contract
     *
     *  @param oracleTypesValuesWeightsDecimals array containing the oracle type, oracle value, oracle weight,
     *         oracle decimals array
     *  @param calldataarray thr calldata array for the oracle setup
     *  @param signatures_ the array containing the signatures if the oracles
     *  @param oracleAddresses_ the addresses array of the oracles containing 2 addresses: 1. address to call,
     *         2. address of the token for supply if needed can be empty
     *  @param divisorAssetTypeMintingFeeRatio array containing 2 arrays: 1. divisor + assetType, 2. mintingFee + cratio
     *  @param conjureAddresses containing the 3 conjure needed addresses: owner, indexedFinanceUniswapv2oracle_,
               ethusdchainlinkoracle_
     *  @param namesymbol array containing the name and the symbol of the asset
     *  @param inverse indicator if this an inverse asset
     *  @return conjure the conjure contract address
     *  @return etherCollateral the ethercollateral address
    */
    function ConjureMint(
        // oracle type, oracle value, oracle weight, oracle decimals array
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        bytes[] memory calldataarray,
        string[] memory signatures_,
        // oracle address to call, token address for supply
        address[][2] memory oracleAddresses_,
        // divisor, asset type // mintingFee_, cratio_
        uint256[2][2] memory divisorAssetTypeMintingFeeRatio,
        // owner, indexedFinanceUniswapv2oracle_, ethusdchainlinkoracle_
        address[] memory conjureAddresses,
        // name, symbol
        string[2] memory namesymbol,
        // inverse asset indicator
        bool inverse
    )
    public
    returns(address conjure, address etherCollateral)
    {
        conjure = conjureImplementation.createClone();
        etherCollateral = etherCollateralImplementation.createClone();

        IConjure(conjure).initialize(
            namesymbol,
            conjureAddresses,
            address(this),
            etherCollateral
        );

        IEtherCollateral(etherCollateral).initialize(
            payable(conjure),
            conjureAddresses[0],
            address(this),
            divisorAssetTypeMintingFeeRatio[1]
        );

        IConjure(conjure).init(
            inverse,
            divisorAssetTypeMintingFeeRatio[0],
            oracleAddresses_,
            oracleTypesValuesWeightsDecimals,
            signatures_,
            calldataarray
        );

        emit NewConjure(conjure, etherCollateral);
    }

    /**
    * receive function to receive funds
    */
    receive() external payable {}

    /**
     * @dev gets the address of the current factory owner
     *
     * @return the address of the conjure router
    */
    function getConjureRouter() public view returns (address payable) {
        return conjureRouter;
    }

    /**
     * @dev lets the owner change the current conjure implementation
     *
     * @param conjureImplementation_ the address of the new implementation
    */
    function newConjureImplementation(address conjureImplementation_) public {
        require(msg.sender == factoryOwner, "Only factory owner");
        conjureImplementation = conjureImplementation_;
    }

    /**
     * @dev lets the owner change the current ethercollateral implementation
     *
     * @param etherCollateralImplementation_ the address of the new implementation
    */
    function newEtherCollateralImplementation(address etherCollateralImplementation_) public {
        require(msg.sender == factoryOwner, "Only factory owner");
        etherCollateralImplementation = etherCollateralImplementation_;
    }

    /**
     * @dev lets the owner change the current conjure router
     *
     * @param conjureRouter_ the address of the new router
    */
    function newConjureRouter(address payable conjureRouter_) public {
        require(msg.sender == factoryOwner, "Only factory owner");
        conjureRouter = conjureRouter_;
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) public {
        require(msg.sender == factoryOwner, "Only factory owner");
        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }
}

interface IConjure {
    function initialize(
        string[2] memory namesymbol,
        address[] memory conjureAddresses,
        address factoryaddress_,
        address collateralContract
    ) external;

    function init(
        bool inverse_,
        uint256[2] memory divisorAssetType,
        address[][2] memory oracleAddresses_,
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        string[] memory signatures_,
        bytes[] memory calldata_
    ) external;
}

interface IEtherCollateral {
    function initialize(
        address payable _asset,
        address _owner,
        address _factoryaddress,
        uint256[2] memory _mintingFeeRatio
    )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


/**
 * EIP 1167 Proxy Deployment
 * Originally from https://github.com/optionality/clone-factory/
 */
library CloneLibrary {

    function createClone(address target) internal returns (address result) {
        // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
        // other memory in the final mstore
        bytes memory cloneBuffer = new bytes(72);
        assembly {
            let clone := add(cloneBuffer, 32)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), shl(96, target))
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }


    function isClone(address target, address query) internal view returns (bool result) {
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), shl(96, target))
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

