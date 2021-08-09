/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity 0.8.6;

contract LilPix {
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

    uint256 public price = 0.0003 ether;

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

    function create(uint256[] calldata tokenIds, address[] calldata recipients)
        external
        payable
    {
        uint256 mintCount = 0; // Only pay for what you mint
        uint256 _price = price;

        // 1. Mint
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address to = i < recipients.length ? recipients[i] : msg.sender;
            if (_owners[tokenId] == address(0)) {
                _balances[to] += 1;
                _owners[tokenId] = to;
                if (to != msg.sender) {
                    // record the sender as the creator, before transfering
                    emit Transfer(address(0), msg.sender, tokenId);
                    emit Transfer(msg.sender, to, tokenId);
                } else {
                    emit Transfer(address(0), to, tokenId);
                }
                mintCount += 1;
            }
        }

        // 2. Paymint
        uint256 expected = _price * mintCount;
        if (msg.value < expected) {
            revert("Not enough ETH");
        } else if (msg.value > expected) {
            // Return any unused eth.
            // This may fail silently and not transfer
            // if reciever tries to use too much gas,
            // or is a non-payable contract.
            // Too bad, I tried. Not my problem any more.
            payable(msg.sender).send(msg.value - expected);
        }
    }

    function collect() external {
        require(msg.sender == _owner, "NO");
        payable(_owner).call{value: address(this).balance}("");
    }

    function setPrice(uint256 _price) external {
        require(msg.sender == _owner, "NO");
        price = _price;
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