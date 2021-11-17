// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import './SourceWallet.sol';
import './CloneFactory.sol';

contract WalletCreation is CloneFactory {
    address public implementationAddress;

    event WalletCreationDone(address newWalletAddress);
    event depositeDone(uint256 value, address to);

    mapping(address => address)changeOwnerAllowance;
    mapping(address => string)ownerName;
    mapping(string => address)ownerAddress;
    mapping(address => bool)changeAdminWalletAddressAlowance;
    mapping(address => bool)isOwner;
    mapping(address => bool)isWalletOrNot;

    address[] walletAddresses;

    address walletCreationAddress = address(this);
    address[] allowedSigners;
    address adminWalletAddress;
    constructor(address _implementationAddress, address _adminWalletAddress, address _owner1, address _owner2, address _owner3) {
        implementationAddress = _implementationAddress;
        ownerName[_owner1] = 'owner1';
        ownerAddress['owner1'] = _owner1;
        isOwner[_owner1] = true;

        ownerName[_owner2] = 'owner2';
        ownerAddress['owner2'] = _owner2;
        isOwner[_owner2] = true;

        ownerName[_owner3] = 'owner3';
        ownerAddress['owner3'] = _owner3;
        isOwner[_owner3] = true;

        adminWalletAddress = _adminWalletAddress;
        allowedSigners = [_owner1, _owner2, _owner3];
    }

    function showAdminWalletAddress() public view returns (address){
        return (adminWalletAddress);
    }

    function DepositDoneEvent(uint256 _value, address _to) external {
        require(isWalletOrNot[msg.sender] == true);
        emit depositeDone(_value, _to);
    }

    function allowTochangeAdminWalletAddress() public {
        require(msg.sender == ownerAddress['owner1']
        || msg.sender == ownerAddress['owner2']
            || msg.sender == ownerAddress['owner3']);
        changeAdminWalletAddressAlowance[msg.sender] = true;
    }

    function changeAdminWalletAddress(address _newColdWalletAddress) public {

        if (msg.sender == ownerAddress['owner1']) {
            require(changeAdminWalletAddressAlowance[ownerAddress['owner3']] == true ||
                changeAdminWalletAddressAlowance[ownerAddress['owner2']] == true);

            changeAdminWalletAddressAlowance[msg.sender] = false;
            changeAdminWalletAddressAlowance[ownerAddress['owner3']] == false;
            changeAdminWalletAddressAlowance[ownerAddress['owner2']] == false;
            adminWalletAddress = _newColdWalletAddress;

        } else if (msg.sender == ownerAddress['owner2']) {
            require(changeAdminWalletAddressAlowance[ownerAddress['owner3']] == true || changeAdminWalletAddressAlowance[ownerAddress['owner1']] == true);

            changeAdminWalletAddressAlowance[msg.sender] = false;
            changeAdminWalletAddressAlowance[ownerAddress['owner3']] == false;
            changeAdminWalletAddressAlowance[ownerAddress['owner1']] == false;
            adminWalletAddress = _newColdWalletAddress;

        } else if (msg.sender == ownerAddress['owner3']) {
            require(changeAdminWalletAddressAlowance[ownerAddress['owner2']] == true || changeAdminWalletAddressAlowance[ownerAddress['owner1']] == true);

            changeAdminWalletAddressAlowance[msg.sender] = false;
            changeAdminWalletAddressAlowance[ownerAddress['owner2']] == false;
            changeAdminWalletAddressAlowance[ownerAddress['owner1']] == false;
            adminWalletAddress = _newColdWalletAddress;
        }
    }


    function allowToChangeOwner(address _targetedAddress) public {
        require(msg.sender == ownerAddress['owner1']
        || msg.sender == ownerAddress['owner2']
            || msg.sender == ownerAddress['owner3']);
        changeOwnerAllowance[msg.sender] = _targetedAddress;
    }

    function showAllWalletAddresses() public view returns (address[] memory){
        return (walletAddresses);
    }

    function showLastWalletAddress() public view returns (address){
        address tempAddress = walletAddresses[walletAddresses.length - 1];
        return (tempAddress);
    }

    function createWallet(bytes32 salt)
    external
    {
        bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

        address payable clone = createClone(implementationAddress, finalSalt);
        SourceWallet(clone).init(allowedSigners, walletCreationAddress);
        emit WalletCreationDone(clone);
        isWalletOrNot[clone] = true;
        walletAddresses.push(clone);
    }

    function changeOwner(address _owner, address _changeOwnerTo) public {
        require(msg.sender == ownerAddress['owner1']
        || msg.sender == ownerAddress['owner2']
            || msg.sender == ownerAddress['owner3']);

        if (msg.sender == _owner) {
            string memory OwnerName = ownerName[_owner];
            ownerAddress[OwnerName] = _changeOwnerTo;
            ownerName[_changeOwnerTo] = OwnerName;
            isOwner[_owner] = false;
            isOwner[_changeOwnerTo] = true;

        } else {
            string memory name = ownerName[msg.sender];
            string memory currentOwnerName = ownerName[_owner];
            if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked('owner1'))) {
                require(changeOwnerAllowance[ownerAddress['owner2']] == _owner
                    || changeOwnerAllowance[ownerAddress['owner3']] == _owner);
                ownerAddress[currentOwnerName] = _changeOwnerTo;
                ownerName[_changeOwnerTo] = currentOwnerName;
                isOwner[_owner] = false;
                isOwner[_changeOwnerTo] = true;

            } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked('owner2'))) {
                require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
                    || changeOwnerAllowance[ownerAddress['owner3']] == _owner);
                ownerAddress[currentOwnerName] = _changeOwnerTo;
                ownerName[_changeOwnerTo] = currentOwnerName;
                isOwner[_owner] = false;
                isOwner[_changeOwnerTo] = true;

            } else if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked('owner3'))) {
                require(changeOwnerAllowance[ownerAddress['owner1']] == _owner
                    || changeOwnerAllowance[ownerAddress['owner2']] == _owner);
                ownerAddress[currentOwnerName] = _changeOwnerTo;
                ownerName[_changeOwnerTo] = currentOwnerName;
                isOwner[_owner] = false;
                isOwner[_changeOwnerTo] = true;
            }
        }

    }

    function isOwnerOrNot(address _isOwner) public view returns (bool){
        return (isOwner[_isOwner]);
    }

}