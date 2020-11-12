pragma solidity ^0.5.0; // solidity 0.5.2

import "./SafeMath.sol";

/**
 * @title MultiOwnable
 * dev
 */
contract MultiOwnable {
    using SafeMath for uint256;

    address public root; // 혹시 몰라 준비해둔 superOwner 의 백업. 하드웨어 월렛 주소로 세팅할 예정.
    address public superOwner;
    mapping (address => bool) public owners;
    address[] public ownerList;

    // for changeSuperOwnerByDAO
    // mapping(address => mapping (address => bool)) public preSuperOwnerMap;
    mapping(address => address) public candidateSuperOwnerMap;


    event ChangedRoot(address newRoot);
    event ChangedSuperOwner(address newSuperOwner);
    event AddedNewOwner(address newOwner);
    event DeletedOwner(address deletedOwner);

    constructor() public {
        root = msg.sender;
        superOwner = msg.sender;
        owners[root] = true;

        ownerList.push(msg.sender);

    }

    modifier onlyRoot() {
        require(msg.sender == root, "Root privilege is required.");
        _;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwner, "SuperOwner priviledge is required.");
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender], "Owner priviledge is required.");
        _;
    }

    /**
     * dev root 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * dev 기존 루트가 관리자에서 지워지지 않고, 새 루트가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeRoot(address newRoot) onlyRoot public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");

        root = newRoot;

        emit ChangedRoot(newRoot);
        return true;
    }

    /**
     * dev superOwner 교체 (root 는 root 와 superOwner 를 교체할 수 있는 권리가 있다.)
     * dev 기존 superOwner 가 관리자에서 지워지지 않고, 새 superOwner 가 자동으로 관리자에 등록되지 않음을 유의!
     */
    function changeSuperOwner(address newSuperOwner) onlyRoot public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");

        superOwner = newSuperOwner;

        emit ChangedSuperOwner(newSuperOwner);
        return true;
    }

    /**
     * dev owner 들의 1/2 초과가 합의하면 superOwner 를 교체할 수 있다.
     */
    function changeSuperOwnerByDAO(address newSuperOwner) onlyOwner public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(newSuperOwner != candidateSuperOwnerMap[msg.sender], "You have already voted for this account.");

        candidateSuperOwnerMap[msg.sender] = newSuperOwner;

        uint8 votingNumForSuperOwner = 0;
        uint8 i = 0;

        for (i = 0; i < ownerList.length; i++) {
            if (candidateSuperOwnerMap[ownerList[i]] == newSuperOwner)
                votingNumForSuperOwner++;
        }

        if (votingNumForSuperOwner > ownerList.length / 2) { // 과반수 이상이면 DAO 성립 => superOwner 교체
            superOwner = newSuperOwner;

            // 초기화
            for (i = 0; i < ownerList.length; i++) {
                delete candidateSuperOwnerMap[ownerList[i]];
            }

            emit ChangedSuperOwner(newSuperOwner);
        }

        return true;
    }

    function newOwner(address owner) onlySuperOwner public returns (bool) {
        require(owner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(!owners[owner], "This address is already registered.");

        owners[owner] = true;
        ownerList.push(owner);

        emit AddedNewOwner(owner);
        return true;
    }

    function deleteOwner(address owner) onlySuperOwner public returns (bool) {
        require(owners[owner], "This input address is not a super owner.");
        delete owners[owner];

        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length.sub(1)];
                ownerList.length = ownerList.length.sub(1);
                break;
            }
        }

        emit DeletedOwner(owner);
        return true;
    }
}