pragma solidity ^0.8.0;

import "./zombieattack.sol";
import "./safemath.sol";



contract ZombieOwnership is ZombieAttack {

using SafeMath for uint256;

    

    mapping (uint => address) zombieApprovals;

     event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
     event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    


     function balanceOf(address _owner) external view returns (uint256) {
    return ownerZombieCount[_owner];
      }
  
    function ownerOf(uint256 _tokenId) external view returns (address) {
    return zombieToOwner[_tokenId];
      }
  
  
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        
        ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
        ownerZombieCount[_from] = ownerZombieCount[_from].sub(1);
        zombieToOwner[_tokenId] = _to;
        
        emit Transfer(_from,_to,_tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(zombieApprovals[_tokenId] == msg.sender || zombieToOwner[_tokenId] == msg.sender, "Keine Berechtigung");
        _transfer(_from, _to, _tokenId);
    }
    
     function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
         zombieApprovals[_tokenId] = _approved;
         
         emit Approval(msg.sender, _approved, _tokenId); 
    }
      
  
}