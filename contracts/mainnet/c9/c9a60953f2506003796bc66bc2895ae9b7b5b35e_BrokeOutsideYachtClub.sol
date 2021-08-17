/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity 0.8.6;

// Art
// 
// By
// Daniel Von Fange


contract BrokeOutsideYachtClub {
    // Mapping from owner to list of owned token IDs

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    address private _owner;

    string private _base;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) {
        _name = name;
        _symbol = symbol;
        _base = baseURI;
        _owner = msg.sender;
    }

    fallback() external {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                // BIT IT AGAIN!
                0x9B5D407F144dA142A0A5E3Ad9c53eE936fbBb3dd,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}