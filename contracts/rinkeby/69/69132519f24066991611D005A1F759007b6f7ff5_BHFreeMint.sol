// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract BH {
    function mintButt(uint256 _numberOfButts) external payable virtual;

    function buttsOfOwner(address _owner)
        external
        view
        virtual
        returns (uint256[] memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}

contract BHFreeMint is ERC721Holder, Ownable {
    BH private butts;
    address wallet = 0x8a8320ceb5D99b6BB5B3967f40f422E471BeD72B;

    uint256 public _mintPrice = 0.06 ether;
    uint256 public startTimeSale = 0;
    bool public _freeMintActive = false;

    mapping(address => bool) private _freeMintList;
    mapping(address => uint256) private _freeMintListClaimed;
    mapping(address => uint256) private _freeMintAllowed;

    constructor(address dependedContract) {
        butts = BH(dependedContract);
    }

    //modifiers
    modifier onlyFreeMinters() {
        require(
            _freeMintList[_msgSender()],
            "You are not on the free mint list"
        );
        _;
    }

    function addToFreeList(
        address[] calldata addresses,
        uint256[] calldata allowed
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");

            _freeMintList[addresses[i]] = true;

            _freeMintListClaimed[addresses[i]] > 0
                ? _freeMintListClaimed[addresses[i]]
                : 0;

            _freeMintAllowed[addresses[i]] = allowed[i];
        }
    }

    function setStartTimeSale(uint256 _startSale) external onlyOwner {
        startTimeSale = _startSale;
    }

    function setPrice(uint256 _price) external onlyOwner {
        _mintPrice = _price;
    }

    function onFreeMintList(address addr) external view returns (bool) {
        return _freeMintList[addr];
    }

    function freeMintsLeft(address addr) external view returns (uint256) {
        return
            _freeMintList[addr]
                ? _freeMintAllowed[addr] - _freeMintListClaimed[addr]
                : 0;
    }

    function setFreeMintState(bool val) external onlyOwner {
        _freeMintActive = val;
    }

    function removeFromFreeMintList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");
            _freeMintList[addresses[i]] = false;
        }
    }

    function _mint(address _to, uint256 _butts) internal {
        require(
            address(this).balance >= _mintPrice * _butts,
            "Not enough money in the contract"
        );
        butts.mintButt{value: _mintPrice * _butts}(_butts);
        uint256[] memory booties = butts.buttsOfOwner(address(this));
        for (uint256 i = 0; i < _butts; i++) {
            butts.transferFrom(address(this), _to, booties[i]);
        }
    }

    function gift(address _to, uint256 _butts) external onlyOwner {
        _mint(_to, _butts);
    }

    function giftMany(address[] calldata _to, uint256[] calldata _butts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _butts.length; i++) {
            _mint(_to[i], _butts[i]);
        }
    }

    function freeMint(uint256 _numberOfButts) external onlyFreeMinters {
        require(_freeMintActive, "Free Mint is not active");
        require(block.timestamp >= startTimeSale, "Free Mint did not start yet");
        require(
            _freeMintListClaimed[_msgSender()] + _numberOfButts <=
                _freeMintAllowed[_msgSender()],
            "Purchase exceeds max allowed"
        );

        _freeMintListClaimed[_msgSender()] += _numberOfButts;
        _mint(_msgSender(), _numberOfButts);
    }

    function withdraw() public onlyOwner {
        uint256 _amount = address(this).balance;
        require(payable(wallet).send(_amount));
    }

    fallback() external payable {}

    receive() external payable {}
}

