/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity >=0.7.0 <0.9.0;
//pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only for owner");
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract TotoGame is Ownable {
    
    mapping (uint256 => mt[]) matches;
    
    struct mt {
        string t1;
        string t2;
        uint8 t1s;
        uint8 t2s;
        bool a;
    }
    
    constructor () {
       
    }
    
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
    
    function setMatchs(uint256 chId, mt[] memory mts) external onlyOwner {
        for(uint8 i=0;i<mts.length;i++)
        {
            matches[chId][i]=mts[i];
        }
    }
    
    function getMatchs(uint256 chId) external view returns(mt[] memory) {
        return matches[chId];
    }
    
    function getMatch(uint256 chId, uint8 matchId) external view returns(string memory, string memory, uint8, uint8, bool) {
        return (
            matches[chId][matchId].t1, 
            matches[chId][matchId].t2,
            matches[chId][matchId].t1s,
            matches[chId][matchId].t2s,
            matches[chId][matchId].a
        );
    }
}