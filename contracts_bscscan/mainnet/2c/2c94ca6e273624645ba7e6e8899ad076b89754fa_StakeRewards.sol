/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function mint(address to, uint32 _assetType, uint256 _value, uint32 _customDetails) external returns (bool success);
}

interface StorageContract {
    function checkClaim (address _wallet, uint256 _calcBase, uint32 _assetType, uint32 _monthStep) external view returns (bool _paid);
    function storeClaim (address _wallet, uint256 _calcBase, uint32 _assetType, uint32 _monthStep) external returns (bool success);
}

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StakeRewards is Ownable {
  StorageContract storageContract;
  IERC721 nft3dToken;
  mapping (uint256 => uint256) public assetPrice;
  uint256 assetsCount;
  address signerAddress;

  constructor() {
    storageContract =  StorageContract(0x5a0d173F492ACB0E5A088596F8c1A3563F26EfA3);
    nft3dToken = IERC721(0xd6EB2D21a6267ae654eF5dbeD49D93F8b9FEEad9);
    signerAddress = 0xa28e63539573540c4Cf8f31D276eE15e50211e05;
    assetPrice[40] = 1210 ether;
    assetPrice[42] = 9680 ether;

  }

  function checkClaim(address _wallet, uint256 _calcBase, uint32 _assetType, uint32 _monthStep) public view returns (bool _paid) {
    return(storageContract.checkClaim(_wallet, _calcBase, _assetType,  _monthStep));
  }

  function changeSigner(address _newSigner) onlyOwner public {
    signerAddress = _newSigner;
  }
  
  function changeStorage(address _newStorage) onlyOwner public {
    storageContract =  StorageContract(_newStorage);
  }

  function claimReward(uint256 _calcBase, uint256 _assetType, uint256 _monthStep, uint32 _customDetails, bytes memory sig) public {
    bytes32 message = createHash(msg.sender, _calcBase, _assetType, _monthStep);
    require(recoverSigner(message, sig) == signerAddress, "Invalid signature");
    require(storageContract.storeClaim(msg.sender, _calcBase, uint32(_assetType), uint32(_monthStep)) == true, "Already claimed");
    require(nft3dToken.mint(msg.sender, uint32(_assetType), assetPrice[_assetType], _customDetails), "Not possible to mint this type of asset");
  }
  
  function verifySignature(uint256 _calcBase, uint256 _assetType, uint256 _monthStep, bytes memory sig) public view returns (bool) {
    bytes32 message = createHash(msg.sender, _calcBase, _assetType, _monthStep);
    return(recoverSigner(message, sig) == signerAddress);
  }

  function verifySignatureFrom(address _from, uint256 _calcBase, uint256 _assetType, uint256 _monthStep, bytes memory sig) public view returns (bool) {
    bytes32 message = createHash(_from, _calcBase, _assetType, _monthStep);
    return(recoverSigner(message, sig) == signerAddress);
  }
  
  function createHash(address _address, uint256 _calcBase, uint256 _assetType, uint256 _step) private pure returns (bytes32) {
    return(keccak256(abi.encode(_address, _calcBase, _assetType, _step)));
  }
  
  function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }

  function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = splitSignature(sig);
    return ecrecover(message, v, r, s);
  }

  function incrementPrice(uint256 _start, uint256 _end, uint256 percentage) public onlyOwner {
    for (uint256 i=_start; i<=_end;i++) {
        assetPrice[i] += ((assetPrice[i]*percentage)/100);
    }
  }
  
  function setPrice(uint256 _assetId, uint256 _price) public onlyOwner {
    assetPrice[_assetId] = _price;
      
  }

}