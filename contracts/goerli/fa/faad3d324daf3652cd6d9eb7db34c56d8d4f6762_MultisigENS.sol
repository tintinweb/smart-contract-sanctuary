// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MultisigDeployer.sol";
import "./IMultisigENS.sol";

/// @title Multisignature wallet ENS- Allows to set a ENS over a multisig and over a user.
/// @author Santiago Del Valle - <[email protected]>
contract MultisigENS is IMultisigENS, Ownable {

    MultisigDeployer private _msigDeployer;

    mapping (address => string) private _msigNames;
    mapping (address => string) private _userNames;
 
    modifier onlyMultisig {
        require(_msigDeployer.isMultisigAdded(msg.sender), "Multisig is not added");
        _;
    }

    constructor(address _msigDeployerAddress) {
        require(_msigDeployerAddress != address(0), "Contract address cannot be 0"); 
        _msigDeployer = MultisigDeployer(_msigDeployerAddress);
        emit SetMultisigDeployerAddress(_msigDeployerAddress);
    }

    function setMultisigName(string memory _name) external virtual override onlyMultisig {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Contract name cannot be empty");
        _msigNames[msg.sender] = _name;
        emit SetContractName(msg.sender, _name);
    }

    function setUserName(string memory _name) external virtual override {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "User name cannot be empty");
        _userNames[msg.sender] = _name;
        emit SetUserName(msg.sender, _name);
    }

    function setMultisigDeployerAddress(address _msigDeployerAddress) external virtual override onlyOwner {
        require(_msigDeployerAddress != address(0), "Contract address cannot be 0");
        _msigDeployer = MultisigDeployer(_msigDeployerAddress);
        emit SetMultisigDeployerAddress(_msigDeployerAddress);
    }

    function getMultisigDeployerAddress() external virtual override view returns(address) {
        return address(_msigDeployer);
    }

    function getMultisigName(address _msig) external virtual override view returns(string memory) {
        return _msigNames[_msig];
    }

    function getUserName(address _user) external virtual override view returns(string memory) {
        return _userNames[_user];
    }
}