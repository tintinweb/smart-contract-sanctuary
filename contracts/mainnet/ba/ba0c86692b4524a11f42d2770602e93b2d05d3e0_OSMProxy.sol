/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity 0.6.12;

interface OracleSecurityModule {
    function peek() external view returns (bytes32, bool);

    function peep() external view returns (bytes32, bool);

    function bud(address) external view returns (uint256);
}

contract OSMProxy {
    mapping(address => bool) consumers;
    address public osm;
    address public owner;

    constructor(address _osm) public {
        consumers[msg.sender] = true;
        osm = _osm;
        owner = msg.sender;
    }

    function addConsumer(address _target) external {
        require(owner == msg.sender);
        consumers[_target] = true;
    }

    function removeConsumer(address _target) external {
        require(owner == msg.sender);
        consumers[_target] = false;
    }

    function peek() external view returns (bytes32, bool) {
        if (_isAccessible()) return OracleSecurityModule(osm).peek();

        return (0, false);
    }

    function peep() external view returns (bytes32, bool) {
        if (_isAccessible()) return OracleSecurityModule(osm).peep();

        return (0, false);
    }

    function _isAccessible() internal view returns (bool) {
        return
            consumers[msg.sender] &&
            (OracleSecurityModule(osm).bud(address(this)) == 1);
    }
}