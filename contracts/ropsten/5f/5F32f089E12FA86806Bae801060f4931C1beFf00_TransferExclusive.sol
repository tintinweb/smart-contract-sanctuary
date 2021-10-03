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
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    bytes32 merkleRoot;
    
    struct inputModel {
        address addr;
        uint64 val;
    }

    constructor (address contractAddress, address ownerAddress) {
        _tokenContract = IERC20(contractAddress);
        _ownerAddress = ownerAddress;
        _tokenAddress = contractAddress;
    }
    
    function verify(
    bytes32 leaf,
    bytes32[] memory proof
  )
    public
    view
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == merkleRoot;
  }
  
  function getMerkleRoot() public view returns(bytes32 ) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner  {
        merkleRoot = _merkleRoot;
    }

    function setPrimaryContract(address contractAddress, address ownerAddress) public onlyOwner returns (uint256){
        _tokenContract = IERC20(contractAddress);
        _ownerAddress = ownerAddress;
        _tokenAddress = contractAddress;
        
        return 1;
    }
    
    function addAllowAddress(address allowAddress, uint256 value) public onlyOwner returns (uint256){
        allowed[_tokenAddress][allowAddress]=value;
        
        return 1;
    }
    
    function addAllowAddresses(inputModel[] memory allowAddresses) public onlyOwner returns (uint256){
        for(uint i=0; i<allowAddresses.length; i++) {
            allowed[_tokenAddress][allowAddresses[i].addr]=allowAddresses[i].val;
        }
        
        return 1;
    }
    
    function getAllowance(address addr) public view returns (uint256){
        return allowed[_tokenAddress][addr];
    }

    function getPrimaryAllowance() public onlyOwner view returns (uint256){
        return _tokenContract.allowance(_ownerAddress, address(this));
    }
    
    function transferExclusive(uint256 amount) public returns (uint256){
        require(_tokenContract.allowance(_ownerAddress, address(this)) >= amount, "Allowance too low");
        
        require(allowed[_tokenAddress][msg.sender] >= amount, "Not allowed");
        
       _internalTransferFrom(_tokenContract, _ownerAddress, msg.sender, amount);
       
       return 1;
    }

   
        
    function _internalTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
        allowed[_tokenAddress][recipient]-=amount;
    }
}