// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import './WalletSimple.sol';
import './CloneFactory.sol';

contract WalletFactory is CloneFactory {
    address public implementationAddress;
    event WalletCreated(address newWalletAddress, address[] allowedSigners);
    mapping(address => address)changeOwnerAllowance;
    mapping(address => string)ownername;
    mapping(string => address)ownerAddress;
    mapping(address => bool)changeColdWalletAddressAlowance;
    mapping(address => bool)isOwner;
    
    address walletFactoryAddress = address(this);
    
    address[] allowedSigners;
    address coldWalletAddress;
  constructor(address _implementationAddress,address _coldWalletAddress, address _owner1, address _owner2, address _owner3) {
    implementationAddress = _implementationAddress;
    ownername[_owner1]='owner1';
    ownerAddress['owner1'] = _owner1;
    isOwner[_owner1] = true;
    
    ownername[_owner2]='owner2';
    ownerAddress['owner2'] = _owner2;
    isOwner[_owner2] = true;
    
    ownername[_owner3]='owner3';
    ownerAddress['owner3'] = _owner3;
    isOwner[_owner3] = true;
    
    coldWalletAddress = _coldWalletAddress;
    allowedSigners=[_owner1, _owner2, _owner3];
  }
    
    function showColdWalletAddress()public  view returns(address){
        return(coldWalletAddress);
    }
    
    
    function allowTochangeColdWalletAddress()public {
        require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']);
        changeColdWalletAddressAlowance[msg.sender] = true;
    }

    function changeColdWalletAddress(address _newColdWalletAddress)public  {
        
        if(msg.sender == ownerAddress['owner1']){
            require(changeColdWalletAddressAlowance[ownerAddress['owner3']] == true ||
            changeColdWalletAddressAlowance[ownerAddress['owner2']] == true);
            
            changeColdWalletAddressAlowance[msg.sender] = false;
            changeColdWalletAddressAlowance[ownerAddress['owner3']] == false;
            changeColdWalletAddressAlowance[ownerAddress['owner2']] == false;
            coldWalletAddress = _newColdWalletAddress;
            
        }else if(msg.sender == ownerAddress['owner2']){
            require(changeColdWalletAddressAlowance[ownerAddress['owner3']] == true || changeColdWalletAddressAlowance[ownerAddress['owner1']] == true);
            
            changeColdWalletAddressAlowance[msg.sender] = false;
            changeColdWalletAddressAlowance[ownerAddress['owner3']] == false;
            changeColdWalletAddressAlowance[ownerAddress['owner1']] == false;
            coldWalletAddress = _newColdWalletAddress;
            
        }else if(msg.sender == ownerAddress['owner3']){
            require(changeColdWalletAddressAlowance[ownerAddress['owner2']] == true || changeColdWalletAddressAlowance[ownerAddress['owner1']] == true);
            
            changeColdWalletAddressAlowance[msg.sender] = false;
            changeColdWalletAddressAlowance[ownerAddress['owner2']] == false;
            changeColdWalletAddressAlowance[ownerAddress['owner1']] == false;
            coldWalletAddress = _newColdWalletAddress;
        }
    }

   
    function allowToChangeOwner(address _targetedAddress)public {
         require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']  );
         changeOwnerAllowance[msg.sender] = _targetedAddress;
    }
    
    

    function createWallet(bytes32 salt) 
        external
    {
   
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    
    bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    WalletSimple(clone).init(allowedSigners, walletFactoryAddress);
    emit WalletCreated(clone, allowedSigners);
  }
  
  function changeOwner(address _owner, address _changeOwnerTo)public {
      require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']  );
      
      if(msg.sender == _owner){
          string memory ownerName = ownername[_owner];
          ownerAddress[ownerName] = _changeOwnerTo;
          ownername[_changeOwnerTo] = ownerName;
          isOwner[_owner] = false;
          isOwner[_changeOwnerTo] = true;
          
      }else{
          string memory name = ownername[msg.sender];
          string memory currentOwnerName = ownername[_owner];
          if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner1'))){
              require(changeOwnerAllowance[ownerAddress['owner2']] == _owner
              || changeOwnerAllowance[ownerAddress['owner3']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
              isOwner[_owner] = false;
              isOwner[_changeOwnerTo] = true;
              
          }else if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner2'))){
              require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
              || changeOwnerAllowance[ownerAddress['owner3']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
              isOwner[_owner] = false;
              isOwner[_changeOwnerTo] = true;
              
          }else if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner3'))){
              require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
              || changeOwnerAllowance[ownerAddress['owner2']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
              isOwner[_owner] = false;
              isOwner[_changeOwnerTo] = true;
          }
      }
      
  }
  
  function isOwnerOrNot(address _isOwner)public view returns(bool){
      return(isOwner[_isOwner]);
  }
  
}