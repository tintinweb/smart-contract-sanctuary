/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

pragma solidity "0.8.7";


contract A {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 amount);
    function mint(address _to, uint256 _amount)  public returns (bool) {
        emit Transfer(0x0000000000000000000000000000000000000001,0x0000000000000000000000000000000000000002,50);
        emit Mint(0x0000000000000000000000000000000000000001,50);
        return true;
    }
}