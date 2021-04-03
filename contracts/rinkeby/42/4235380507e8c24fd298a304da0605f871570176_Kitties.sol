/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity 0.5.16;

contract Kitties {
    
    uint256 public mua = 123;

    function setMua(uint256 _newMua) public {
        mua = _newMua;
    }
}