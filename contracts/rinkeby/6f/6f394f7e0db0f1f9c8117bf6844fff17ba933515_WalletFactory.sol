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
    mapping(address => bool)changeDeployerAllowance;
    mapping(address => bool)changeColdWalletAddressAlowance;
    
    address[] allowedSigners;
    address deployer;
    address coldWalletAddress;
  constructor(address _implementationAddress,address _coldWalletAddress, address _owner1, address _owner2, address _owner3) {
    implementationAddress = _implementationAddress;
    ownername[_owner1]='owner1';
    ownerAddress['owner1'] = _owner1;
    
    ownername[_owner2]='owner2';
    ownerAddress['owner2'] = _owner2;
    
    ownername[_owner3]='owner3';
    ownerAddress['owner3'] = _owner3;
    
    coldWalletAddress = _coldWalletAddress;
    deployer = msg.sender;
    allowedSigners=[_owner1, _owner2, _owner3];
  }
    
    function showColdWalletAddress2() public view returns(address){
        return(coldWalletAddress);
    }
    
    function showColdWalletAddress() external view returns(address){
        return(coldWalletAddress);
    }
    
    function showDeployerAddress2()public view returns(address){
        return(deployer);
    }
    
    function showDeployerAddress()external view returns(address){
        return(deployer);
    }
    
    function isOwnerOrNot()external view returns(address, address, address){
        return(ownerAddress['owner1'], ownerAddress['owner2'], ownerAddress['owner3']);
    }
    
    function allowTochangeColdWalletAddress()public{
        require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']);
        changeColdWalletAddressAlowance[msg.sender] = true;
    }

    function changeColdWalletAddress(address _coldWalletAddress)public {
        
        if(msg.sender == ownerAddress['owner1']){
            require(changeColdWalletAddressAlowance[ownerAddress['owner3']] == true ||
            changeColdWalletAddressAlowance[ownerAddress['owner2']] == true);
            
            changeColdWalletAddressAlowance[msg.sender] = false;
            changeColdWalletAddressAlowance[ownerAddress['owner3']] == false;
            changeColdWalletAddressAlowance[ownerAddress['owner2']] == false;
            coldWalletAddress = _coldWalletAddress;
            
        }else if(msg.sender == ownerAddress['owner2']){
            require(changeDeployerAllowance[ownerAddress['owner3']] == true || changeDeployerAllowance[ownerAddress['owner1']] == true);
            
            changeDeployerAllowance[msg.sender] = false;
            changeDeployerAllowance[ownerAddress['owner3']] == false;
            changeDeployerAllowance[ownerAddress['owner1']] == false;
            coldWalletAddress = _coldWalletAddress;
            
        }else if(msg.sender == ownerAddress['owner3']){
            require(changeDeployerAllowance[ownerAddress['owner2']] == true || changeDeployerAllowance[ownerAddress['owner1']] == true);
            
            changeDeployerAllowance[msg.sender] = false;
            changeDeployerAllowance[ownerAddress['owner2']] == false;
            changeDeployerAllowance[ownerAddress['owner1']] == false;
            coldWalletAddress = _coldWalletAddress;
        }
    }

    function allowToChangeDeployer()public{
        require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']);
         
         changeDeployerAllowance[msg.sender] = true;
    }

    function changeDeployer(address _deployer)public{
        
        if(msg.sender == ownerAddress['owner1']){
            require(changeDeployerAllowance[ownerAddress['owner3']] == true ||
            changeDeployerAllowance[ownerAddress['owner2']] == true);
            
            changeDeployerAllowance[msg.sender] = false;
            changeDeployerAllowance[ownerAddress['owner3']] == false;
            changeDeployerAllowance[ownerAddress['owner2']] == false;
            deployer = _deployer;
            
        }else if(msg.sender == ownerAddress['owner2']){
            require(changeDeployerAllowance[ownerAddress['owner3']] == true ||
            changeDeployerAllowance[ownerAddress['owner1']] == true);
            
            changeDeployerAllowance[msg.sender] = false;
            changeDeployerAllowance[ownerAddress['owner3']] == false;
            changeDeployerAllowance[ownerAddress['owner1']] == false;
            deployer = _deployer;
            
        }else if(msg.sender == ownerAddress['owner3']){
            require(changeDeployerAllowance[ownerAddress['owner2']] == true ||
            changeDeployerAllowance[ownerAddress['owner1']] == true);
            
            changeDeployerAllowance[msg.sender] = false;
            changeDeployerAllowance[ownerAddress['owner2']] == false;
            changeDeployerAllowance[ownerAddress['owner1']] == false;
            deployer = _deployer;
        }
    }
    
    function allowToChangeOwner(address _targetedAddress)public{
         require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']  );
         changeOwnerAllowance[msg.sender] = _targetedAddress;
    }
    
    function notAllowToChangeOwner()public{
        require(msg.sender == ownerAddress['owner1']
         || msg.sender == ownerAddress['owner2']
         || msg.sender == ownerAddress['owner3']  );
         changeOwnerAllowance[msg.sender] = address(0);
    }

    function createWallet(bytes32 salt)
        external
    {
     require(msg.sender == deployer);
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    
    bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    WalletSimple(clone).init(allowedSigners, address(this));
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
      }else{
          string memory name = ownername[msg.sender];
          string memory currentOwnerName = ownername[_owner];
          if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner1'))){
              require(changeOwnerAllowance[ownerAddress['owner2']] == _owner
              || changeOwnerAllowance[ownerAddress['owner3']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
              
          }else if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner2'))){
              require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
              || changeOwnerAllowance[ownerAddress['owner3']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
          }else if(keccak256(abi.encodePacked(name)) ==keccak256(abi.encodePacked('owner3'))){
              require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
              || changeOwnerAllowance[ownerAddress['owner2']]== _owner);
              ownerAddress[currentOwnerName] = _changeOwnerTo;
              ownername[_changeOwnerTo] = currentOwnerName;
          }
      }
      
  }
  
}