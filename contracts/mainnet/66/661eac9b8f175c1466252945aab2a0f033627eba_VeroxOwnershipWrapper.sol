/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AnyToken {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface IVEROX_MAKER {
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) external;
}

contract VeroxOwnershipWrapper {
    
    address public owner;
    AnyToken veroxToken = AnyToken(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    IVEROX_MAKER maker = IVEROX_MAKER(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
  constructor() {
    owner = msg.sender;
  }
  
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
    function transferAnyTokensFromMaker(address _tokenAddr, address _to, uint _amount) public {
        require(msg.sender == owner);
        require(_tokenAddr != address(veroxToken), "Not allowed for Verox token");
        maker.transferAnyERC20Tokens(_tokenAddr, _to, _amount);
    }

    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyTokensFromThis(address _tokenAddr, address _to, uint _amount) public {
        require(msg.sender == owner);
        AnyToken(_tokenAddr).transfer(_to, _amount);
    }
}