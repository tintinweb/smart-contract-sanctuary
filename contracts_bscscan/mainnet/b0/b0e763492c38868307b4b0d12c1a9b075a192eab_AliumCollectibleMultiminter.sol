/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File contracts/IAliumCollectible.sol

pragma solidity =0.6.2;

interface IAliumCollectible {
    function mint(address to, uint256 _type) external returns (uint256);

    function setMinterOnly(address _minter, uint256 _type) external;

    function addMinter(address _minter) external;

    function transfer(address _to, uint256 _tokenId) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address _to, uint256 _tokenId) external returns (bool);

    function owner() external view returns (address);

    function getTypeInfo(uint256 _type)
        external
        view
        returns (
            uint256 nominalPrice,
            uint256 totalSupply,
            uint256 maxSupply,
            string memory info,
            address minterOnly
        );

    function getTokenType(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;
}


// File contracts/extended/AliumCollectibleMultiminter.sol

// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;
/**
 * @title AliumCollectibleMultiminter - tokens issuer
 * @author Pavel Bolhar <[email protected]>
 */
contract AliumCollectibleMultiminter is IERC721Receiver, Ownable {

    /**
     * @dev Multi mint.
     *
     * Permission: Contract must have minter privilege.
     */
    function mintBatch(
        address token,
        address to,
        uint256 amount,
        uint256 _type
    )
        external
        onlyOwner
        returns (uint256[] memory items)
    {
        items = new uint256[](amount);
        uint tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = IAliumCollectible(token).mint(address(this), _type);
            IAliumCollectible(token).safeTransferFrom(address(this), to, tokenId);
            items[i] = tokenId;
        }
    }

    /**
     * @dev See {ERC721TokenReceiver-onERC721Received}
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