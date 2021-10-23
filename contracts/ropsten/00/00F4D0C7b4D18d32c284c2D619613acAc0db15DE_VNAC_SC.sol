/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity >=0.4.16 <0.7.0;
pragma experimental ABIEncoderV2;
contract VNAC_SC
{
    string right;
    string vn;
    function addRight(string memory action,string memory virtualnetwrok) public
    {
        right=action;
        vn=virtualnetwrok;
    }
    function getRight() public view returns (string memory, string memory)
    {
      return (right,vn);
    }
}