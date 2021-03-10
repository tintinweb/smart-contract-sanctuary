/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

contract InternalOne {

    uint256 public myValue;

    function addOddSome(uint256 sum) external {
        require (sum % 2 == 1, "PLEASE_ADD_ODD_SUM_ONLY");
        myValue += sum;
    }

}

contract ExternalOne {
    address internalContract;
    constructor(address _internalContract) public {
        internalContract = _internalContract;
    }

    function addCallFailing(uint256 sum) external {
        InternalOne(internalContract).addOddSome(sum);
    }

    function addDelagateCallFailing(uint256 sum) external {
        internalContract.delegatecall(
            abi.encodeWithSelector(InternalOne(internalContract).addOddSome.selector, sum));
    }

    function addCallquiet(uint256 sum) external {
        (bool success, bytes memory returndata) = internalContract.call(
            abi.encodeWithSelector(InternalOne(internalContract).addOddSome.selector, sum));
    }

    function addDelagateCallquiet(uint256 sum) external {
        (bool success, bytes memory returndata) = internalContract.delegatecall(
            abi.encodeWithSelector(InternalOne(internalContract).addOddSome.selector, sum));
    }
}