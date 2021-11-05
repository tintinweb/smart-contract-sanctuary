/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// File: @onchain-id/solidity/contracts/interface/IImplementationAuthority.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IImplementationAuthority {
    function getImplementation() external view returns(address);
}

// File: @onchain-id/solidity/contracts/proxy/IdentityProxy.sol


contract IdentityProxy {
    address public implementationAuthority;

    constructor(address _implementationAuthority, address initialManagementKey) {
        implementationAuthority = _implementationAuthority;

        address logic = IImplementationAuthority(implementationAuthority).getImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = logic.delegatecall(abi.encodeWithSignature("initialize(address)", initialManagementKey));
        require(success, "Initialization failed.");
    }

    fallback() external payable {
        address logic = IImplementationAuthority(implementationAuthority).getImplementation();

        assembly { // solium-disable-line
        calldatacopy(0x0, 0x0, calldatasize())
        let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
        let retSz := returndatasize()
        returndatacopy(0, 0, retSz)
        switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}


interface IIdFactory {
    function createIdentity(address _wallet, string memory _salt) external returns (address);

    function linkWallet(address _newWallet) external;

    function unlinkWallet(address _oldWallet) external;

    function getIdentity(address _wallet) external view returns (address);
}

// File: contracts/factory/IdFactory.sol




contract IdFactory is IIdFactory {

    /// event emitted whenever a single contract is deployed by the factory
    event Deployed(address _addr);

    event WalletLinked(address wallet, address identity);
    event WalletUnlinked(address wallet, address identity);

    // address of the implementationAuthority contract making the link to the implementation contract
    address implementationAuthority;

    // as it is not possible to deploy 2 times the same contract address, this mapping allows us to check which
    // salt is taken and which is not
    mapping(string => bool) saltTaken;

    mapping(address => address) userIdentity;


    /// setting
    constructor (address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;
    }

    /// deploy function with create2 opcode call
    /// returns the address of the contract created
    function deploy(string memory salt, bytes memory bytecode) internal returns (address) {
        bytes memory implInitCode = bytecode;
        address addr;
        assembly {
            let encoded_data := add(0x20, implInitCode) // load initialization code.
            let encoded_size := mload(implInitCode)     // load init code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr);
        return addr;
    }

    /// function used to deploy an identity using CREATE2
    function deployIdentity
    (
        string memory _salt,
        address _implementationAuthority,
        address _wallet
    ) internal returns (address){
        bytes memory _code = type(IdentityProxy).creationCode;
        bytes memory _constructData = abi.encode(_implementationAuthority, _wallet);
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }



    /// function used to create a new identity contract
    /// the function is deploying a proxy contract linked to the implementation contract
    /// previously deployed and is taking a string as salt to deploy the ID
    function createIdentity(address _wallet, string memory _salt) public override returns (address) {
        require (!saltTaken[_salt], "salt already taken");
        require (userIdentity[_wallet] == address(0), "wallet already linked to an identity");
        address identity = deployIdentity(_salt, implementationAuthority, _wallet);
        saltTaken[_salt] = true;
        userIdentity[_wallet] = identity;
        emit WalletLinked(_wallet, identity);
        return identity;
    }

    function linkWallet(address _newWallet) public override {
        require(userIdentity[msg.sender] != address(0), "wallet not linked to an identity contract");
        address identity = userIdentity[msg.sender];
        userIdentity[_newWallet] = identity;
        emit WalletLinked(_newWallet, identity);
    }

    function unlinkWallet(address _oldWallet) public override {
        require(userIdentity[msg.sender] == userIdentity[_oldWallet], "only a linked wallet can unlink");
        address _identity = userIdentity[_oldWallet];
        delete userIdentity[_oldWallet];
        emit WalletUnlinked(_oldWallet, _identity);
    }

    function getIdentity(address _wallet) public override view returns (address) {
        return userIdentity[_wallet];
    }
}