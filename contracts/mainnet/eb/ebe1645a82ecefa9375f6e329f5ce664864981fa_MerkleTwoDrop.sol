/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MerkleTwoDrop {

    struct Airdrop {
      bytes32 root;
      mapping(address => bool) awarded;
    }

    /// Events
    event Start(uint id);
    event Award(uint id, address recipient, uint amount0, uint amount1);

    /// State
    mapping(uint => Airdrop) public airdrops;
    ITokenManager public tokenManager0;
    ITokenManager public tokenManager1;
    uint public airdropsCount;
    address public startAuth;

    bool private initialized;

    function initialize(address _tokenManager0, address _tokenManager1, address _startAuth) public {
        require(!initialized, "Already initialized");
        initialized = true;

        require(_tokenManager0 != address(0), "Needs token0 manager");
        require(_tokenManager1 != address(0), "Needs token1 manager");
        require(_startAuth != address(0), "Needs startAuth");

        tokenManager0 = ITokenManager(_tokenManager0);
        tokenManager1 = ITokenManager(_tokenManager1);
        startAuth = _startAuth;
    }

    /**
     * @notice Start a new airdrop `_root`
     * @param _root New airdrop merkle root
     */
    function start(bytes32 _root) public {
        require(msg.sender == startAuth, "Not authorized");
        _start(_root);
    }

    function _start(bytes32 _root) internal returns(uint id){
        id = ++airdropsCount;    // start at 1
        Airdrop storage newAirdrop = airdrops[id];
        newAirdrop.root = _root;
        emit Start(id);
    }

    /**
     * @notice Award from airdrop
     * @param _id Airdrop id
     * @param _recipient Recepient of award
     * @param _amount0 The token0 amount
     * @param _amount1 The token1 amount
     * @param _proof Merkle proof to correspond to data supplied
     */
    function award(uint _id, address _recipient, uint256 _amount0, uint256 _amount1, bytes32[] calldata _proof) public {
        Airdrop storage airdrop = airdrops[_id];

        bytes32 hash = keccak256(abi.encodePacked(_recipient, _amount0, _amount1));
        require( validate(airdrop.root, _proof, hash), "Invalid proof" );

        require( !airdrops[_id].awarded[_recipient], "Already awarded" );

        airdrops[_id].awarded[_recipient] = true;

        tokenManager0.mint(_recipient, _amount0);
        tokenManager1.mint(_recipient, _amount1);

        emit Award(_id, _recipient, _amount0, _amount1);
    }

    /**
     * @notice Award from multiple airdrops to single recipient
     * @param _ids Airdrop ids
     * @param _recipient Recepient of award
     * @param _amount0s The token0 amounts
     * @param _amount1s The token1 amounts
     * @param _proofs Merkle proofs
     */
    function awardFromMany(uint[] calldata _ids, address _recipient, uint[] calldata _amount0s, uint[] calldata _amount1s, bytes32[][] calldata _proofs) public {

        uint totalAmount0;
        uint totalAmount1;

        for (uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];

            bytes32 hash = keccak256(abi.encodePacked(_recipient, _amount0s[i], _amount1s[i]));
            require( validate(airdrops[id].root, _proofs[i], hash), "Invalid proof" );

            require( !airdrops[id].awarded[_recipient], "Already awarded" );

            airdrops[id].awarded[_recipient] = true;

            totalAmount0 += _amount0s[i];
            totalAmount1 += _amount1s[i];

            emit Award(id, _recipient, _amount0s[i], _amount1s[i]);
        }

        tokenManager0.mint(_recipient, totalAmount0);
        tokenManager1.mint(_recipient, totalAmount1);

    }

    /**
     * @notice Award from airdrop to multiple recipients
     * @param _id Airdrop ids
     * @param _recipients Recepients of award
     * @param _amount0s The karma amount
     * @param _amount1s The currency amount
     * @param _proofs Merkle proofs
     */
    function awardToMany(uint _id, address[] calldata _recipients, uint[] calldata _amount0s, uint[] calldata _amount1s, bytes32[][] calldata _proofs) public {

        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];

            if( airdrops[_id].awarded[recipient] )
                continue;

            bytes32 hash = keccak256(abi.encodePacked(recipient, _amount0s[i], _amount1s[i]));
            if( !validate(airdrops[_id].root, _proofs[i], hash) )
                continue;

            airdrops[_id].awarded[recipient] = true;

            tokenManager0.mint(recipient, _amount0s[i]);
            tokenManager1.mint(recipient, _amount1s[i]);

            emit Award(_id, recipient, _amount0s[i], _amount1s[i]);
        }

    }

    function validate(bytes32 root, bytes32[] memory proof, bytes32 hash) public pure returns (bool) {

        for (uint i = 0; i < proof.length; i++) {
            if (hash < proof[i]) {
                hash = keccak256(abi.encodePacked(hash, proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(proof[i], hash));
            }
        }

        return hash == root;
    }

    /**
     * @notice Check if address:`_recipient` awarded in airdrop:`_id`
     * @param _id Airdrop id
     * @param _recipient Recipient to check
     */
    function awarded(uint _id, address _recipient) public view returns(bool) {
        return airdrops[_id].awarded[_recipient];
    }
}

abstract contract ITokenManager {
    function mint(address _receiver, uint256 _amount) virtual external;
}