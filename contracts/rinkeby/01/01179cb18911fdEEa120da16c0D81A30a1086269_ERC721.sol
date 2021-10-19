// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./libraries/Counters.sol";

/**
 * @dev Implementation of dummy ERC721.
 */
contract ERC721 is IERC721 {
    using Counters for Counters.Counter;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Token id
    uint256 public tokenId;

    bool public paused;

    // counter for token id
    Counters.Counter private _counter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public owners;

    // Mapping owner address to token count
    mapping(address => uint256) public balances;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    event Paused(address account);
    event Unpaused(address account);

    /**
     * @dev Initializes the contract
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        paused = false;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Mints and transfers tokenId to `to`.
     */
    function mint(address to) public virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(owners[tokenId] == address(0), "ERC721: token already minted");

        balances[to] += 1;
        owners[tokenId] = to;

        _counter.increment();
        tokenId = _counter.current();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     */
    function burn(uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);

        balances[owner] -= 1;
        delete owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() public virtual whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() public virtual whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address to) external;
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Counters library
 */
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}