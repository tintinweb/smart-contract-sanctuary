/**
 *Submitted for verification at Etherscan.io on 2021-08-17
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
    
    struct inputModel {
        address addr;
        uint256 val;
    }
  
    constructor (address contractAddress, address ownerAddress, inputModel[] memory allowAddresses) {
        _tokenContract = IERC20(contractAddress);
        _ownerAddress = ownerAddress;
        _tokenAddress = contractAddress;
        
        for(uint i=0; i<allowAddresses.length; i++) {
            allowed[_tokenAddress][allowAddresses[i].addr]=allowAddresses[i].val;
        }
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
    
    function getAllowance() public view returns (uint256){
        return allowed[_tokenAddress][msg.sender];
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
    }
}