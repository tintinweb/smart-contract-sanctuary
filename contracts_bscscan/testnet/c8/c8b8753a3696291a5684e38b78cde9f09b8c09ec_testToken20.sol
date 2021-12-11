/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
/**
 * @dev ERC20 Token abstract constract.
 */
 abstract contract ERC20Token {
      function transferFrom(address, address, uint256)  virtual public returns (bool);
   
}

contract testToken20{
     /**
    * @dev calls the ERC20 token's transferFrom function
    * @param _token address The address of ERC20 token.
    * @param _dsts address The addresses which be air dropped.
    * @param _values uint256 The token values that each address will receive.
    * array, struct or mapping类型的参数不需要加 memory _token
    */
    function transfer(address _token, address[] calldata _dsts, uint256[] calldata _values)     public    payable 
    {
        ERC20Token token = ERC20Token(_token);
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transferFrom(msg.sender, _dsts[i], _values[i]);
        }
    }
    
    //接受币
    receive() external payable { }
}