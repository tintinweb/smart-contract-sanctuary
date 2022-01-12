// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Clones.sol";
import "ICollabFactory.sol";
import "ICollab.sol";

contract MetaCollabFactory is ICollabFactory {
    uint256 public collabCount = 0;
    mapping(uint256 => address) internal _collabs;
    mapping(address => uint256) public flatFees;

    event LogNewCollab(uint256 indexed index, address collab);
    event UpdateFlatFee(
        address indexed resolver,
        uint256 indexed flatFee,
        bytes32 details
    );

    address public immutable implementation;

    constructor(address _implementation) {
        require(_implementation != address(0), "invalid implementation");
        implementation = _implementation;
    }

    function _newCollab(
        address _collabAddress,
        address _funder,
        address _doer
    ) internal {
        ICollab(_collabAddress).init(_funder, _doer, address(this));

        _collabs[collabCount] = _collabAddress;
        emit LogNewCollab(collabCount, _collabAddress);

        collabCount++;
    }

    function create(address _funder, address _doer)
        external
        override
        returns (address)
    {
        address collabAddress = Clones.clone(implementation);

        _newCollab(collabAddress, _funder, _doer);

        return collabAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, _salt);
    }

    function createDeterministic(
        address _funder,
        address _doer,
        bytes32 _salt
    ) external override returns (address) {
        address collabAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        _newCollab(collabAddress, _funder, _doer);

        return collabAddress;
    }

    function getCollabAddress(uint256 _index) public view returns (address) {
        return _collabs[_index];
    }

    function updateFlatFee(uint256 _flatFee, bytes32 _hash) external {
        flatFees[msg.sender] = _flatFee;
        emit UpdateFlatFee(msg.sender, _flatFee, _hash);
    }
}