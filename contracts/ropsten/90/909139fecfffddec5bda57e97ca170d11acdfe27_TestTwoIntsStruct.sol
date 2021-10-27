/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library TUSLib {
    struct TwoUintStruct {
        uint256 ua;
        uint256 aa;
    }
}

contract TestTwoIntsStruct  {

    TUSLib.TwoUintStruct tus;

    function setFromStruct(TUSLib.TwoUintStruct calldata passedAsStruct) external {
        tus.ua = passedAsStruct.ua;
        tus.aa = passedAsStruct.aa;
    }

    function setFromTwo(uint256 ua_, uint256 aa_) external {
        tus.ua = ua_;
        tus.aa = aa_;
    }

    function getTusUints() external view returns(uint256, uint256) {
        return (tus.ua, tus.aa);
    }

    function getTus() external view returns(TUSLib.TwoUintStruct memory) {
        return tus;
    }

}