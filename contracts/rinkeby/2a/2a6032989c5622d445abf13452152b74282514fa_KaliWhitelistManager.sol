/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

/// @notice Kali DAO whitelist manager.
/// @author Modified from SushiSwap 
/// (https://github.com/sushiswap/trident/blob/master/contracts/pool/franchised/WhiteListManager.sol)
contract KaliWhitelistManager {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event WhitelistCreated(uint256 indexed listId, address indexed operator);

    event AccountWhitelisted(uint256 indexed listId, address indexed account, bool approved);
    
    event MerkleRootSet(uint256 indexed listId, bytes32 merkleRoot);
    
    event WhitelistJoined(uint256 indexed listId, uint256 indexed index, address indexed account);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NullId();

    error IdExists();

    error NotOperator();

    error SignatureExpired();

    error InvalidSignature();

    error WhitelistClaimed();

    error NotRooted();

    /*///////////////////////////////////////////////////////////////
                            EIP-712 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 internal constant WHITELIST_TYPEHASH = 
        keccak256('Whitelist(address account,bool approved,uint256 deadline)');

    /*///////////////////////////////////////////////////////////////
                            WHITELIST STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public operatorOf;
    
    mapping(uint256 => bytes32) public merkleRoots;

    mapping(uint256 => mapping(address => bool)) public whitelistedAccounts;

    mapping(uint256 => mapping(uint256 => uint256)) internal whitelistedBitmaps;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-712 LOGIC
    //////////////////////////////////////////////////////////////*/

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes('KaliWhitelistManager')),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }
 
    /*///////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function createWhitelist(
        uint256 listId, 
        address[] calldata accounts,
        bytes32 merkleRoot
    ) public virtual {
        if (listId == 0) revert NullId();

        if (operatorOf[listId] != address(0)) revert IdExists();

        operatorOf[listId] = msg.sender;

        if (accounts.length != 0) {
            // cannot realistically overflow on human timescales
            unchecked {
                for (uint256 i; i < accounts.length; i++) {
                    _whitelistAccount(listId, accounts[i], true);
                }
            }

            emit WhitelistCreated(listId, msg.sender);
        }

        if (merkleRoot != '')
            merkleRoots[listId] = merkleRoot;

            emit MerkleRootSet(listId, merkleRoot);
    }
    
    function isWhitelisted(uint256 listId, uint256 index) public view virtual returns (bool) {
        uint256 whitelistedWordIndex = index / 256;

        uint256 whitelistedBitIndex = index % 256;

        uint256 claimedWord = whitelistedBitmaps[listId][whitelistedWordIndex];

        uint256 mask = 1 << whitelistedBitIndex;

        return claimedWord & mask == mask;
    }

    function whitelistAccounts(
        uint256 listId, 
        address[] calldata accounts, 
        bool[] calldata approvals
    ) public virtual {
        if (msg.sender != operatorOf[listId]) revert NotOperator();

        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                _whitelistAccount(listId, accounts[i], approvals[i]);
            }
        }
    }

    function whitelistAccountBySig(
        uint256 listId,
        address account,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(WHITELIST_TYPEHASH, account, approved, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        if (recoveredAddress != operatorOf[listId]) revert InvalidSignature();

        _whitelistAccount(listId, account, approved);
    }

    function _whitelistAccount(
        uint256 listId,
        address account,
        bool approved
    ) internal virtual {
        whitelistedAccounts[listId][account] = approved;

        emit AccountWhitelisted(listId, account, approved);
    }

    /*///////////////////////////////////////////////////////////////
                            MERKLE LOGIC
    //////////////////////////////////////////////////////////////*/

    function setMerkleRoot(uint256 listId, bytes32 merkleRoot) public virtual {
        if (msg.sender != operatorOf[listId]) revert NotOperator();
        
        merkleRoots[listId] = merkleRoot;

        emit MerkleRootSet(listId, merkleRoot);
    }

    function joinWhitelist(
        uint256 listId,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public virtual {
        if (isWhitelisted(listId, index)) revert WhitelistClaimed();

        bytes32 computedHash = keccak256(abi.encodePacked(index, account));

        for (uint256 i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];

            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        // check if the computed hash (root) is equal to the provided root
        if (computedHash != merkleRoots[listId]) revert NotRooted();

        uint256 whitelistedWordIndex = index / 256;

        uint256 whitelistedBitIndex = index % 256;

        whitelistedBitmaps[listId][whitelistedWordIndex] = whitelistedBitmaps[listId][whitelistedWordIndex] 
            | (1 << whitelistedBitIndex);

        _whitelistAccount(listId, account, true);

        emit WhitelistJoined(listId, index, account);
    }

    function _efficientHash(bytes32 a, bytes32 b) internal pure virtual returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}