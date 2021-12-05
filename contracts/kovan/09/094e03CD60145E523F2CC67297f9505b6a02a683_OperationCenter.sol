// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface AccountIndexInterface {
    function owner() external view returns (address);
}

contract OperationCenter {

    address public   accountIndex;
    address internal defaultOpCodeAddress;

    mapping(bytes4 => address) internal opCodeSigToAddress;
    mapping(address => bytes4[]) internal opCodeAddressToSigs;

    event SetDefaultOpCodeAddress(address indexed defaultOp);
    event AddOpCode(address indexed opCodeAddress, bytes4[] sigs);
    event RemoveOpCode(address indexed opCodeAddress, bytes4[] sigs);

    modifier onlyOwner {
        require(accountIndex != address(0),"CHFRY: accountIndex not setup");
        require(msg.sender == AccountIndexInterface(accountIndex).owner(), "CHFRY: only AccountIndex Owner");
        _;
    }

    function setAccountIndex(address _accountIndex) external {
        require(accountIndex == address(0),"CHFRY: accountIndex already set");
        accountIndex = _accountIndex;
    }

    function setDefaultOpCodeAddress(address _defaultOpCodeAddress) external onlyOwner {
        require(_defaultOpCodeAddress != address(0),"CHFRY Account: OpCode address should not be 0");
        defaultOpCodeAddress = _defaultOpCodeAddress;
        emit SetDefaultOpCodeAddress(defaultOpCodeAddress);
    }

    function addOpcode(address _opCodeAddress, bytes4[] calldata _sigs) external onlyOwner{
        require(_opCodeAddress != address(0),"CHFRY Account: OpCode address should not be 0");
        require(opCodeAddressToSigs[_opCodeAddress].length == 0 ,"CHFRY Account: OpCode exist");

        for (uint256 i = 0; i < _sigs.length; i++){
            bytes4 _sig = _sigs[i];
            require(opCodeSigToAddress[_sig] == address(0), "CHFRY Account: OpCode Sig exist");
            opCodeSigToAddress[_sig] = _opCodeAddress;
        }

        opCodeAddressToSigs[_opCodeAddress] = _sigs;
        emit AddOpCode(_opCodeAddress,_sigs);
    }

    function removeOpcode(address _opCodeAddress) external onlyOwner{
        require(_opCodeAddress != address(0),"CHFRY Account: OpCode address should not be 0");
        require(opCodeAddressToSigs[_opCodeAddress].length != 0 ,"CHFRY Account: OpCode not exist");
        bytes4[] memory sigs = opCodeAddressToSigs[_opCodeAddress];
        for (uint256 i = 0; i < sigs.length; i++) {
                bytes4 sig = sigs[i];
                delete opCodeSigToAddress[sig];
        }
        delete opCodeAddressToSigs[_opCodeAddress];
        emit RemoveOpCode(_opCodeAddress,sigs);
    }

    function getOpCodeAddress(bytes4 _sig) external view returns (address){
        address _opCodeAddress = opCodeSigToAddress[_sig];
        return _opCodeAddress == address(0) ? defaultOpCodeAddress : _opCodeAddress;
    }
}