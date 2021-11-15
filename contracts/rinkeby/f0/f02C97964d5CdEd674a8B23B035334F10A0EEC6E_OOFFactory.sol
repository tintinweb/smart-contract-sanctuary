// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./lib/CloneLibrary.sol";

/// @author Conjure Finance Team
/// @title ConjureFactory
contract OOFFactory {
    using CloneLibrary for address;

    event NewOOF(address oof);
    event FactoryOwnerChanged(address newowner);
    event NewConjureRouter(address newConjureRouter);
    event NewOOFImplementation(address newOOFImplementation);

    address payable public factoryOwner;
    address public oofImplementation;
    address payable public conjureRouter;

    constructor(
        address _oofImplementation,
        address payable _conjureRouter
    )
    {
        require(_oofImplementation != address(0), "No zero address for _oofImplementation");
        require(_conjureRouter != address(0), "No zero address for conjureRouter");

        factoryOwner = msg.sender;
        oofImplementation = _oofImplementation;
        conjureRouter = _conjureRouter;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewOOFImplementation(oofImplementation);
        emit NewConjureRouter(conjureRouter);
    }

    function oofMint(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_
    )
    external
    returns(address oof)
    {
        oof = oofImplementation.createClone();

        emit NewOOF(oof);

        IOOF(oof).initialize(
            signers_,
            signerThreshold_,
            payoutAddress_,
            subscriptionPassPrice_,
            address(this)
        );
    }

    /**
     * @dev gets the address of the current factory owner
     *
     * @return the address of the conjure router
    */
    function getConjureRouter() external view returns (address payable) {
        return conjureRouter;
    }

    /**
     * @dev lets the owner change the current conjure implementation
     *
     * @param oofImplementation_ the address of the new implementation
    */
    function newOOFImplementation(address oofImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(oofImplementation_ != address(0), "No zero address for oofImplementation_");

        oofImplementation = oofImplementation_;
        emit NewOOFImplementation(oofImplementation);
    }

    /**
     * @dev lets the owner change the current conjure router
     *
     * @param conjureRouter_ the address of the new router
    */
    function newConjureRouter(address payable conjureRouter_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(conjureRouter_ != address(0), "No zero address for conjureRouter_");

        conjureRouter = conjureRouter_;
        emit NewConjureRouter(conjureRouter);
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");

        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IOOF {
    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

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

