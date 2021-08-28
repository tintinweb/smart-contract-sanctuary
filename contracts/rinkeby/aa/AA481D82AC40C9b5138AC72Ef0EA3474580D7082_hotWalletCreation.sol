// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
import './SourceHotWallet.sol';
import './CloneFactory.sol';

contract hotWalletCreation is CloneFactory {
    address public implementationAddress;
    event WalletCreationDone(address newWalletAddress);
    event depositeDone(address from, uint256 value, address to, bytes data);
    
    address owner1;  
    address owner2;
    address admin;
    bool pausable=false;
    
    mapping(address => bool)isWalletOrNot;
    
    address[] walletAddresses;
    
    address walletCreationAddress = address(this);
    address[] allowedSigners;
    
    constructor(address _implementationAddress, address _owner1, address _owner2, address _admin) {
    implementationAddress = _implementationAddress;
    owner1 = _owner1;
    owner2 = _owner2;
    admin = _admin;
    allowedSigners.push(_owner1);
    allowedSigners.push(_owner2);
    allowedSigners.push(_admin);
  }
    
    
    function DepositDoneEvent(address _from, uint256 _value, address _to, bytes memory _data)external {
        require(isWalletOrNot[msg.sender] == true);
        emit depositeDone(_from, _value, _to, _data);
    }


    function owner1ChangesOwner2(address _newOwner2Address)public {
         require(msg.sender == owner1);
         owner2 = _newOwner2Address;
    }
    
    function owner1ChangesOwner1(address _newOwner1Address)public {
         require(msg.sender == owner1);
         owner1 = _newOwner1Address;
    }
    
    function changeAdminAddress (address _newAdminAddress)public {
        require (msg.sender == owner1 || msg.sender == owner2);
        admin = _newAdminAddress;
    }
    
    function showOwner1Address()public view returns(address){
        return(owner1);
    }
    
    function showOwner2Address()public view returns(address){
        return(owner2);
    }
    
    function showAdminAddress()public view returns(address){
        return(admin);
    }
    
    function togglePause()public returns(bool success){
        require(msg.sender == owner1 || msg.sender == owner2);
        if(pausable == true){
         pausable = false;   
        }else{
            pausable = true;
        }
        return(success);
    }
    
    function showPauseSituation()public view returns(bool){
        return(pausable);
    }
    
    function showAllWalletAddresses()public view returns(address[] memory){
        return(walletAddresses);
    }
    
    function showLastWalletAddress()public view returns(address){
        address tempAddress = walletAddresses[walletAddresses.length-1];
        return(tempAddress);
    }

    function createWallet(bytes32 salt)  
        external
    {
    
    bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    SourceHotWallet(clone).init(allowedSigners, walletCreationAddress);
    emit WalletCreationDone(clone);
    isWalletOrNot[clone] = true;
    walletAddresses.push(clone);
  }
}