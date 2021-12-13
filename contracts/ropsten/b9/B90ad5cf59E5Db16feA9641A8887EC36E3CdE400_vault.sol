/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract vault {
    address veri;
    event BuyEggsDB(uint beggs, address account);
    event SellEggsDB(uint seggs, address account);
    address public token = 0x3a642391357c2b2d6B9765fabF1f11DA7E4d35d0;
    address public devaddress = 0x79ae5d3FE295d81342A49aECE586716D60b37C6b;  //AdminContract Address where the token holds


    constructor(address _veri){
      veri = _veri;
    }

  function recoverAddress (bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    return ecrecover(prefixedHash, v, r, s);
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
    
    function SellEggs(uint _eggs, bytes32 hash, uint8 v, bytes32 r, bytes32 s) external {
        (address recover) = recoverAddress(hash, v, r, s);
        (bytes32 hashcheck) = GetHash(_eggs);
        require(hashcheck == hash, 'Egg value is invalid');
        require(recover == veri, 'This is not Auth User');
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