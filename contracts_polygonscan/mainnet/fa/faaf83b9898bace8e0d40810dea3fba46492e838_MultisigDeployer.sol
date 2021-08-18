// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableCustom.sol"; 
import "./ERC20MultisigWallet.sol";  
import "./Create2.sol";
 
contract MultisigDeployer is OwnableCustom  {

    using Create2 for uint256;

    event NewMultisig(address indexed _creator, address indexed _multisigAddress);
    event NewMultisigPrecomputed(address indexed _creator, address indexed _multisigAddress, uint _salt);
    event SetFeeCollector(address indexed feeCollector);

    address[] private _multisigs;
    address public feeCollector;
    mapping(address => bool) private _isMultisigAdded;
    mapping(address => uint256) private _addressToSalt;

    //upgradability
    bool internal _initialized; 
 
    function initialize(address _owner, address _feeCollector) public {
        require(!_initialized, "Contract already initialized");
        require(_feeCollector != address(0), "Fee collector address cannot be 0");
        require(_owner != address(0), "Contract owner cannot be 0");
        feeCollector = _feeCollector;
        _setOwner(_owner); 
        _initialized = true;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Fee collector address cannot be 0");
        feeCollector = _feeCollector;
        emit SetFeeCollector(_feeCollector);
    }

    function getAll() external virtual view returns(address[] memory) {
        return _multisigs;
    }

    function isMultisigAdded(address _multisig) external virtual view returns(bool) {
        return _isMultisigAdded[_multisig];
    }

    function getBytecode(address[] calldata _owners, uint256 _required) public view returns (bytes memory) {
        bytes memory bytecode = type(ERC20MultisigWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owners, _required, feeCollector));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        return _salt.getAddress(bytecode, address(this));
    }

    function getContractSalt(address contractAddress) public view returns (uint256) {
        return _addressToSalt[contractAddress];
    } 

    function deployMultisig(address[] calldata _owners, uint256 _required) external virtual {
        ERC20MultisigWallet multisigWallet = new ERC20MultisigWallet(_owners, _required, feeCollector);
        address multisigAddress = address(multisigWallet);
        _multisigs.push(multisigAddress);
        _isMultisigAdded[multisigAddress] = true;
        emit NewMultisig(msg.sender, multisigAddress);
    }

    function deployMultisigPrecomputed(bytes memory bytecode, uint _salt) public payable {
        address multisigAddress = _salt.deployContract(bytecode);
        _multisigs.push(multisigAddress);
        _isMultisigAdded[multisigAddress] = true;
        _addressToSalt[multisigAddress] = _salt;
        emit NewMultisigPrecomputed(msg.sender, multisigAddress, _salt);
    }

}