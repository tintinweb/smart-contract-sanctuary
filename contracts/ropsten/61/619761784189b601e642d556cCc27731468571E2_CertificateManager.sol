/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File smart-contract/contracts/CertificateManager.sol

pragma solidity ^0.8.6;

contract CertificateManager is Ownable {
    struct Certificate {
        // User provided data
        string name;
        uint256 expiredAt;
        bytes32[] participants;
        // System provided data
        uint256 createdAt;
        State state;
        bytes32 metadataHash;
        bytes32 participantsHash;
    }

    enum State {
        None,
        Created,
        Updated,
        Revoked
    }

    enum Validity {
        Valid,
        Revoked,
        Expired,
        Invalid
    }

    mapping(uint256 => Certificate) certificates;

    event CertificateState(
        uint256 id,
        State state,
        bytes32 metadataHash,
        bytes32 participantsHash
    );

    function create(
        uint256 _id,
        string memory _name,
        uint256 _expiredAt,
        bytes32[] memory _participants
    ) public onlyOwner {
        require(certificates[_id].state == State.None, "ID already used");

        require(
            _expiredAt == 0 || _expiredAt > block.timestamp,
            "Expired Time invalid"
        );

        bytes32 metadataHash = keccak256(abi.encodePacked(_name, _expiredAt));
        bytes32 participantsHash = keccak256(abi.encodePacked(_participants));

        Certificate memory certificate = Certificate(
            _name,
            _expiredAt,
            _participants,
            block.timestamp,
            State.Created,
            metadataHash,
            participantsHash
        );
        certificates[_id] = certificate;

        emit CertificateState(
            _id,
            State.Created,
            metadataHash,
            participantsHash
        );
    }

    modifier onlyActiveState(uint256 _id) {
        require(
            certificates[_id].state == State.Created ||
                certificates[_id].state == State.Updated,
            "Unavailable or revoked certificate "
        );
        _;
    }

    function updateMetadata(
        uint256 _id,
        string memory _name,
        uint256 _expiredAt
    ) public onlyOwner onlyActiveState(_id) {
        require(
            _expiredAt == 0 || _expiredAt > certificates[_id].createdAt,
            "Expired Time invalid"
        );

        bytes32 metadataHash = keccak256(abi.encodePacked(_name, _expiredAt));

        certificates[_id].state = State.Updated;
        certificates[_id].name = _name;
        certificates[_id].expiredAt = _expiredAt;
        certificates[_id].metadataHash = metadataHash;

        emit CertificateState(
            _id,
            State.Updated,
            metadataHash,
            certificates[_id].participantsHash
        );
    }

    function updateParticipants(uint256 _id, bytes32[] memory _participants)
        public
        onlyOwner
        onlyActiveState(_id)
    {
        bytes32 participantsHash = keccak256(abi.encodePacked(_participants));

        certificates[_id].state = State.Updated;
        certificates[_id].participants = _participants;
        certificates[_id].participantsHash = participantsHash;

        emit CertificateState(
            _id,
            State.Updated,
            certificates[_id].metadataHash,
            participantsHash
        );
    }

    function update(
        uint256 _id,
        string memory _name,
        uint256 _expiredAt,
        bytes32[] memory _participants
    ) public onlyOwner onlyActiveState(_id) {
        require(
            _expiredAt == 0 || _expiredAt > certificates[_id].createdAt,
            "Expired Time invalid"
        );

        bytes32 metadataHash = keccak256(abi.encodePacked(_name, _expiredAt));
        bytes32 participantsHash = keccak256(abi.encodePacked(_participants));

        certificates[_id].state = State.Updated;
        certificates[_id].name = _name;
        certificates[_id].expiredAt = _expiredAt;
        certificates[_id].metadataHash = metadataHash;
        certificates[_id].participants = _participants;
        certificates[_id].participantsHash = participantsHash;

        emit CertificateState(
            _id,
            State.Updated,
            metadataHash,
            participantsHash
        );
    }

    function revoke(uint256 _id) public onlyOwner onlyActiveState(_id) {
        certificates[_id].state = State.Revoked;

        emit CertificateState(
            _id,
            State.Revoked,
            certificates[_id].metadataHash,
            certificates[_id].participantsHash
        );
    }

    modifier onlyAvailable(uint256 _id) {
        require(
            certificates[_id].state != State.None,
            "Unavailable certificate"
        );
        _;
    }

    function remove(uint256 _id) public onlyOwner onlyAvailable(_id) {
        delete certificates[_id];
    }

    function getCertificate(uint256 _id)
        public
        view
        onlyAvailable(_id)
        returns (
            string memory,
            uint256,
            uint256,
            State,
            bytes32,
            bytes32
        )
    {
        Certificate memory certificate = certificates[_id];
        return (
            certificate.name,
            certificate.expiredAt,
            certificate.createdAt,
            certificate.state,
            certificate.metadataHash,
            certificate.participantsHash
        );
    }

    function getParticipants(uint256 _id)
        public
        view
        onlyAvailable(_id)
        returns (bytes32[] memory)
    {
        return certificates[_id].participants;
    }

    function checkValidity(uint256 _id, string memory _name)
        public
        view
        onlyAvailable(_id)
        returns (Validity)
    {
        Certificate memory certificate = certificates[_id];

        bytes32 nameHash = keccak256(abi.encodePacked(_name));

        bool exist = false;
        for (uint256 i = 0; i < certificate.participants.length; i++) {
            if (nameHash == certificate.participants[i]) {
                exist = true;
                break;
            }
        }

        if (!exist) return Validity.Invalid;

        if (certificate.state == State.Revoked) return Validity.Revoked;

        if (
            certificate.expiredAt > 0 && block.timestamp > certificate.expiredAt
        ) return Validity.Expired;

        return Validity.Valid;
    }
}