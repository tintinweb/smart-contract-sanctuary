// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function owner() external view returns (address);
}

contract OperationCenter {

    address public defaultOpCodeAddress;
    address public accountCenter;
    address public eventCenterAddress;
    address public connectorCenterAddress;
    address public tokenCenterAddress;
    address public protocolCenterAddress;

    mapping(bytes4 => address) internal opCodeSigToAddress;
    mapping(address => bytes4[]) internal opCodeAddressToSigs;

    event SetAccountCenter(address indexed accountCenter);
    event SetDefaultOpCodeAddress(address indexed defaultOp);
    event AddOpCode(address indexed opCodeAddress, bytes4[] sigs);
    event RemoveOpCode(address indexed opCodeAddress, bytes4[] sigs);
    event SetEventCenter(address indexed eventCenterAddress);
    event SetConnectorCenter(address indexed connectorCenterAddress);
    event SetTokenCenter(address indexed tokenCenterAddress);
    event SetProtocolCenter(address indexed protocolCenterAddress);

    modifier onlyOwner() {
        require(accountCenter != address(0), "CHFRY: accountCenter not setup");
        require(
            msg.sender == AccountCenterInterface(accountCenter).owner(),
            "CHFRY: only AccountCenter Owner"
        );
        _;
    }

    function setAccountCenter(address _accountCenter) external {
        require(accountCenter == address(0), "CHFRY: accountCenter already set");
        accountCenter = _accountCenter;
        emit SetAccountCenter(_accountCenter);
    }

    function setDefaultOpCodeAddress(address _defaultOpCodeAddress)
        external
        onlyOwner
    {
        require(
            _defaultOpCodeAddress != address(0),
            "CHFRY Account: OpCode address should not be 0"
        );
        defaultOpCodeAddress = _defaultOpCodeAddress;
        emit SetDefaultOpCodeAddress(defaultOpCodeAddress);
    }

    function addOpcode(address _opCodeAddress, bytes4[] calldata _sigs)
        external
        onlyOwner
    {
        require(
            _opCodeAddress != address(0),
            "CHFRY Account: OpCode address should not be 0"
        );
        require(
            opCodeAddressToSigs[_opCodeAddress].length == 0,
            "CHFRY Account: OpCode exist"
        );

        for (uint256 i = 0; i < _sigs.length; i++) {
            bytes4 _sig = _sigs[i];
            require(
                opCodeSigToAddress[_sig] == address(0),
                "CHFRY Account: OpCode Sig exist"
            );
            opCodeSigToAddress[_sig] = _opCodeAddress;
        }

        opCodeAddressToSigs[_opCodeAddress] = _sigs;
        emit AddOpCode(_opCodeAddress, _sigs);
    }

    function removeOpcode(address _opCodeAddress) external onlyOwner {
        require(
            _opCodeAddress != address(0),
            "CHFRY Account: OpCode address should not be 0"
        );
        require(
            opCodeAddressToSigs[_opCodeAddress].length != 0,
            "CHFRY Account: OpCode not exist"
        );
        bytes4[] memory sigs = opCodeAddressToSigs[_opCodeAddress];
        for (uint256 i = 0; i < sigs.length; i++) {
            bytes4 sig = sigs[i];
            delete opCodeSigToAddress[sig];
        }
        delete opCodeAddressToSigs[_opCodeAddress];
        emit RemoveOpCode(_opCodeAddress, sigs);
    }

    function getOpCodeAddress(bytes4 _sig) external view returns (address) {
        address _opCodeAddress = opCodeSigToAddress[_sig];
        return
            _opCodeAddress == address(0)
                ? defaultOpCodeAddress
                : _opCodeAddress;
    }

    function setEventCenterAddress(address _eventCenterAddress)
        external
        onlyOwner
    {
        require(_eventCenterAddress != address(0),"CHFRY: address should not be 0");
        eventCenterAddress = _eventCenterAddress;
        emit SetEventCenter(eventCenterAddress);
    }

    function setTokenCenterAddress(address _tokenCenterAddress)
        external
        onlyOwner
    {
        require(_tokenCenterAddress != address(0),"CHFRY: address should not be 0");
        tokenCenterAddress = _tokenCenterAddress;
        emit SetTokenCenter(tokenCenterAddress);
    }

    function setConnectorCenterAddress(address _connectorCenterAddress)
        external
        onlyOwner
    {
        require(_connectorCenterAddress != address(0),"CHFRY: address should not be 0");
        connectorCenterAddress = _connectorCenterAddress;
        emit SetConnectorCenter(connectorCenterAddress);
    }

    function setProtocolCenterAddress(address _protocolCenterAddress)
        external
        onlyOwner
    {
        require(_protocolCenterAddress != address(0),"CHFRY: address should not be 0");
        protocolCenterAddress = _protocolCenterAddress;
        emit SetProtocolCenter(protocolCenterAddress);
    }
}