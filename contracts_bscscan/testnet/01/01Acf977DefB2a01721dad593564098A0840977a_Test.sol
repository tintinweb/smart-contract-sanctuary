/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

contract Test {
    struct DATA {
        address account;
        uint256 amount;
    }
    function getData(address[] memory _addrs) public view returns(DATA[] memory data_)
    {
        data_ = new DATA[](_addrs.length);   
        for (uint256 idx = 0; idx < _addrs.length; idx++) {
            data_[idx].account = _addrs[idx];
            data_[idx].amount = address(_addrs[idx]).balance;
        }
    }
}