/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract vault {
    event BuyEggsDB(uint beggs, address account);
    event SellEggsDB(uint seggs, address account);
    address public token = 0x3a642391357c2b2d6B9765fabF1f11DA7E4d35d0;
    address public devaddress = 0x79ae5d3FE295d81342A49aECE586716D60b37C6b;  //AdminContract Address where the token holds
   

   function recover(bytes32 hash, bytes memory signature)
    public
    pure
    returns (address)
    {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (signature.length != 65) {
      return (address(0));
    }

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

  function GetHash(uint message) private pure returns (bytes32) {
    bytes32 prefixedHash = keccak256(abi.encodePacked(message));
    return prefixedHash;
  }
   
    function BuyEggs(uint amount, uint _fees) external {
        IERC20(token).transferFrom(msg.sender, address(this) , amount);
        IERC20(token).transferFrom(msg.sender, devaddress , _fees);
        uint beggs = amount;
        emit BuyEggsDB(beggs, msg.sender);
        
    }
    
    function SellEggs(uint _eggs, bytes32 hash, bytes memory signature) external {
        (address temp) = recover(hash, signature);
        (bytes32 temp2) = GetHash(_eggs);
        require(temp2 == hash, 'Egg value is invalid');
        require(temp == msg.sender, 'This is not Auth User');
        uint seggs = _eggs;
        IERC20(token).transfer(msg.sender, _eggs);
        emit SellEggsDB(seggs, msg.sender);
        
    }

}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}