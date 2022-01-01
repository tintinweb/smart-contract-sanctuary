//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';
import './interfaces/ICollectionMint.sol';

contract CryptoKombatClaim is Context {
    address public owner;

    ICollectionMint public collection;

    uint256 public CLAIM_START;
    uint256 public CLAIM_END;
    uint256 public HERO_ID;

    mapping(address => bool) public isClaimed;

    // EVENTS
    event Claimed(address indexed account);

    // CONSTRUCTOR
    constructor(
        address _collection,
        uint256 _heroId,
        uint256 _start,
        uint256 _end
    ) {
        require(_collection != address(0), '!zero');
        require(_heroId != 0, '!zero');
        require(_start != 0, '!zero');
        require(_end != 0, '!zero');
        require(_start < _end, '!time');

        owner = _msgSender();
        collection = ICollectionMint(_collection);
        CLAIM_START = _start;
        CLAIM_END = _end;
        HERO_ID = _heroId;
    }

    // Modifiers
    modifier onlyOwner() {
        require(owner == _msgSender(), '!owner');
        _;
    }

    // PUBLIC FUNCTIONS

    function claim() external {
        require(!isClaimed[_msgSender()], '!claimed');
        require(block.timestamp >= CLAIM_START, '!start');
        require(block.timestamp <= CLAIM_END, '!end');
        require(tx.origin == _msgSender(), '!eoa');

        isClaimed[_msgSender()] = true;

        collection.mint(_msgSender(), HERO_ID, 1, bytes('0x0'));

        emit Claimed(_msgSender());
    }

    // Admin functions

    function setStartEnd(uint256 _start, uint256 _end) external onlyOwner {
        require(_start != 0, '!zero');
        require(_end != 0, '!zero');
        require(_start < _end, '!time');

        CLAIM_START = _start;
        CLAIM_END = _end;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollectionMint {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}