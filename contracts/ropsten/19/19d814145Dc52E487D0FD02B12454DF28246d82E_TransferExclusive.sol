/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

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


contract TransferExclusive is Ownable {
    IERC20 public _tokenContract;
    address public _tokenAddress;
    address public _ownerAddress;
    
    mapping (address => uint256) claims;
    
    bytes32 _merkleRoot;
    
    struct inputModel {
        address addr;
        uint64 val;
    }

    constructor (address contractAddress, address ownerAddress) {
        _tokenContract = IERC20(contractAddress);
        _ownerAddress = ownerAddress;
        _tokenAddress = contractAddress;
    }
    
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) private pure returns (bool)
    {
        bytes32 computedHash = leaf;
    
        for (uint256 i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
    
          if (computedHash < proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
    
        return computedHash == root;
    }
  
    function getMerkleRoot() public view returns(bytes32) {
        return _merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner  {
        _merkleRoot = merkleRoot;
    }

    function setPrimaryContract(address contractAddress, address ownerAddress) public onlyOwner returns (uint256){
        _tokenContract = IERC20(contractAddress);
        _ownerAddress = ownerAddress;
        _tokenAddress = contractAddress;
        
        return 1;
    }
    
    function getPrimaryAllowance() public onlyOwner view returns (uint256){
        return _tokenContract.allowance(_ownerAddress, address(this));
    }
    
    function getClaimedValue(address _address) public view returns (uint256){
        return claims[_address];
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
        
    function transferExclusive(uint256 amount, uint256 max, bytes32[] memory proof) public returns (uint256){
        require(_tokenContract.allowance(_ownerAddress, address(this)) >= amount, "Allowance too low");
        
        bytes32 leaf=keccak256(abi.encode(msg.sender, uint2str(max)));
        
        require(verify(_merkleRoot, leaf, proof), "Verify failed");
        
        require(claims[msg.sender]+amount <= max, "Amount not allowed");
        
       _internalTransferFrom(_tokenContract, _ownerAddress, msg.sender, amount);
       
       return 1;
    }

    function _internalTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        
        require(sent, "Token transfer failed");
        
        claims[recipient]+=amount;
    }
}