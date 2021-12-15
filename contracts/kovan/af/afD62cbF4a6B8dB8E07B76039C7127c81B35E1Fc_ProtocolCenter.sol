// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function owner() external view returns (address);
}


contract ProtocolCenter {

    address public accountCenter;

    mapping(string => address) public protocols;

    modifier onlyOwner() {
        require(accountCenter != address(0), "CHFRY: accountCenter not set");
        require(
            msg.sender == AccountCenterInterface(accountCenter).owner(),
            "CHFRY: only AccountCenter Owner"
        );
        _;
    }

    function setAccountCenter(address _accountCenter) external {
        require(accountCenter == address(0), "CHFRY: accountCenter already set");
        accountCenter = _accountCenter;
    }

    function addProtocol(string calldata protocolName, address protocol)
        external
        onlyOwner
    {
        // require(
        //     protocols[protocolName] == address(0),
        //     "addConnectors: protocol  already added"
        // );
        require(
            protocol != address(0),
            "CHFRY addConnectors: protocol address not vaild"
        );
        protocols[protocolName] = protocol;
    }

    function updateProtocol(string calldata protocolName, address protocol)
        external
        onlyOwner
    {
        require(
            protocols[protocolName] != address(0),
            "addConnectors: protocol not exist"
        );
        require(
            protocol != address(0),
            "CHFRY addConnectors: protocol address not vaild"
        );

        protocols[protocolName] = protocol;
    }

    function removeProtocol(string calldata protocolName )
        external
        onlyOwner
    {
        require(
            protocols[protocolName] != address(0),
            "addConnectors: protocol not exist"
        );

        protocols[protocolName] = address(0);
    }

    function getProtocol(string memory protocolName)
        external
        view
        returns (address protocol)
    {
        protocol = protocols[protocolName];
        require(protocol != address(0),"CHFRY: protocol not exist");
    }
}