/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT



pragma solidity >=0.7.0 <0.9.0;


contract address_checker{

    
    address[] public EOA_List;
 /*   
    function Are_You_Contract(address account) public view returns(bool) {
        

        return ;
    }
*/

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // extcodesize関数で該当のアドレスのコードの長さを調べられる
        // EOAまたはまだ割り当てられていない、もしくはなんらかの理由でコードが存在しない場合０になる
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}