// SPDX-License-Identifier: -- ICE --

pragma solidity ^0.8.9;

import "MerkleProof.sol";
import "SafeTransfer.sol";

/**
  * @title Smart Ice Keeper
  * @author Vitally Marinchenko
  */

contract IceKeeper is SafeTransfer {

    address public immutable distributionToken;

    uint256 public maximumDrop;
    uint256 public icedropCount;
    uint256 public totalRequired;
    uint256 public totalCollected;

    address public masterAccount;
    address public workerAccount;

    struct Keeper {
        bytes32 root;
        uint256 total;
        uint256 claimed;
    }

    mapping(uint256 => string) public ipfsData;
    mapping(bytes32 => Keeper) public icedrops;

    mapping(bytes32 => mapping(address => bool)) public hasClaimed;

    modifier onlyMaster() {
        require(
            msg.sender == masterAccount,
            'IceKeeper: invalid master'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == workerAccount,
            'IceKeeper: invalid worker'
        );
        _;
    }

    event Withdraw(
        address indexed account,
        uint256 amount
    );

    event NewIcedrop(
        bytes32 indexed hash,
        address indexed master,
        string indexed ipfsAddress,
        uint256 total
    );

    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(
        address _masterAccount,
        address _workerAccount,
        address _iceTokenAddress,
        uint256 _maximumDrop
    ) {
        masterAccount = _masterAccount;
        workerAccount = _workerAccount;
        distributionToken = _iceTokenAddress;
        maximumDrop = _maximumDrop;
    }

    function changeMaximumDrop(
        uint256 _newMaximumDrop
    )
        external
        onlyMaster
    {
        maximumDrop = _newMaximumDrop;
    }


    function createIceDrop(
        bytes32 _root,
        uint256 _total,
        string calldata _ipfsAddress
    )
        external
        onlyWorker
    {
        require(
            _total > 0,
            'IceKeeper: invalid total'
        );

        bytes32 hash = getHash(
            _ipfsAddress
        );

        require(
            icedrops[hash].total == 0,
            'IceKeeper: already created'
        );

        icedrops[hash] = Keeper({
            root: _root,
            total: _total,
            claimed: 0
        });

        icedropCount =
        icedropCount + 1;

        ipfsData[icedropCount] = _ipfsAddress;

        totalRequired =
        totalRequired + _total;

        emit NewIcedrop(
            _root,
            masterAccount,
            _ipfsAddress,
            _total
        );
    }

    function getHash(
        string calldata _ipfsAddress
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _ipfsAddress
            )
        );
    }

    function isClaimed(
        bytes32 _hash,
        address _account
    )
        public
        view
        returns (bool)
    {
        return hasClaimed[_hash][_account];
    }

    function getClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            msg.sender,
            _merkleProof
        );
    }

    function getClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        bytes32[][] calldata _merkleProof
    )
        external
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                msg.sender,
                _merkleProof[i]
            );
        }
    }

    function giveClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        external
        onlyWorker
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            _account,
            _merkleProof
        );
    }

    function giveClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        address[] calldata _account,
        bytes32[][] calldata _merkleProof
    )
        external
        onlyWorker
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                _account[i],
                _merkleProof[i]
            );
        }
    }

    function _doClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        private
    {
        require(
            isClaimed(_hash, _account) == false,
            'IceKeeper: already claimed'
        );

        require(
            _amount <= maximumDrop,
            'IceKeeper: invalid amount'
        );

        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _account,
                _amount
            )
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                icedrops[_hash].root,
                node
            ),
            'IceKeeper: invalid proof'
        );

        icedrops[_hash].claimed =
        icedrops[_hash].claimed + _amount;

        totalCollected =
        totalCollected + _amount;

        require(
            icedrops[_hash].total >=
            icedrops[_hash].claimed,
            'IceKeeper: claim excess'
        );

        _setClaimed(
            _hash,
            _account
        );

        safeTransfer(
            distributionToken,
            _account,
            _amount
        );

        emit Claimed(
            _index,
            _account,
            _amount
        );
    }

    function _setClaimed(
        bytes32 _hash,
        address _account
    )
        private
    {
        hasClaimed[_hash][_account] = true;
    }

    function withdrawFunds(
        uint256 _amount
    )
        external
        onlyMaster
    {
        safeTransfer(
            distributionToken,
            masterAccount,
            _amount
        );

        emit Withdraw(
            masterAccount,
            _amount
        );
    }

    function changeMaster(
        address _newMaster
    )
        external
        onlyMaster
    {
        masterAccount = _newMaster;
    }

    function changeWorker(
        address _newWorker
    )
        external
        onlyMaster
    {
        workerAccount = _newWorker;
    }

    function getBalance()
        public
        returns (uint256)
    {
        return safeBalanceOf(
            distributionToken,
            address(this)
        );
    }

    function showRemaining(
        bytes32 _hash
    )
        public
        view
        returns (uint256)
    {
        return icedrops[_hash].total - icedrops[_hash].claimed;
    }

    function showExcess(
        bytes32 _hash
    )
        external
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining(_hash));
    }

    function showRemaining()
        public
        view
        returns (uint256)
    {
        return totalRequired - totalCollected;
    }

    function showExcess()
        external
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining());
    }
}