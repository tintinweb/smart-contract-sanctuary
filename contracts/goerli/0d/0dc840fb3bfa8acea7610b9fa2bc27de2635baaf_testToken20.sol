/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.4.24;
/**
 * @dev ERC20 Token abstract constract.
 */
contract ERC20Token {
    function transferFrom(address, address, uint256) public returns (bool);
   
}

contract testToken20{
     /**
    * @dev calls the ERC20 token's transferFrom function
    * @param _token address The address of ERC20 token.
    * @param _dsts address The addresses which be air dropped.
    * @param _values uint256 The token values that each address will receive.
    */
    function transfer(address _token, address[] _dsts, uint256[] _values)   public    payable
    {
        ERC20Token token = ERC20Token(_token);
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transferFrom(msg.sender, _dsts[i], _values[i]);
        }
    }
}