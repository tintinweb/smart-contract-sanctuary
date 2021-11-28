/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Strings.sol


// pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// Root file: contracts/bsc/PlayerOneRoleBlindBox.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

interface IPlayerOneRoleParts {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data
    ) external;
}

contract PlayerOneRoleBlindBox is Ownable, ReentrancyGuard {
    using Strings for uint256;

    // X1 X3 X6 X9 X1 X3 X6 X9
    uint256[8] public priceList = [
        1e18 / 10000,
        2e18 / 1000,
        3e18 / 1000,
        4e18 / 1000,
        5e18 / 1000,
        6e18 / 1000,
        7e18 / 1000,
        8e18 / 1000
    ];

    uint256[8] public partNums = [1, 3, 6, 9, 1, 3, 6, 9];

    IPlayerOneRoleParts public playerOneRoleParts;

    constructor() {
        playerOneRoleParts = IPlayerOneRoleParts(
            0x3e0e4ca537755912401391bf46606E4754c44A24
        );
    }

    function buyBlindBox(uint256 x) public payable nonReentrant {
        require(msg.value >= priceList[x], "Give short weight");

        uint256 randomDigit = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );

        uint256 p0 = 1;
        uint256 p1 = uint256((randomDigit >> 4) % 12) + 1;
        uint256 p2 = uint256((randomDigit >> 8) % 10) + 1;
        uint256 p3 = uint256((randomDigit >> 12) % 11) + 1;
        uint256 p4 = uint256((randomDigit >> 16) % 33) + 1;
        p4 = p4 > 10 ? p4 + 1 : p4;
        uint256 p5 = uint256((randomDigit >> 20) % 10) + 1;
        uint256 p6 = uint256((randomDigit >> 24) % 20) + 1;
        uint256 p7 = uint256((randomDigit >> 28) % 20) + 1;
        uint256 p8 = uint256((randomDigit >> 32) % 20) + 1;
        uint256 p9 = uint256((randomDigit >> 36) % 9) + 1;
        uint256 p10 = uint256((randomDigit >> 40) % 20) + 1;

        uint256[11] memory p = [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10];

        uint256 partNum = partNums[x];
        uint256 tmpRandomDigit = randomDigit;

        for (uint256 i = 0; i < partNum; i++) {
            uint256 ranOffset = 44 + i * 4;
            uint256 ran = uint256((tmpRandomDigit >> ranOffset) % 11);
            if (ran == 0) {
                uint256 _tokenid = p[ran];
                playerOneRoleParts.mint(_msgSender(), _tokenid, 1, "0x");
            } else {
                uint256 _tokenid = parseInt(
                    string(abi.encodePacked(ran.toString(), p[ran].toString()))
                );
                playerOneRoleParts.mint(_msgSender(), _tokenid, 1, "0x");
            }
        }
    }

    function buyBlindBoxAriseBody(uint256 x) public payable nonReentrant {
        require(msg.value >= priceList[x], "Give short weight");

        uint256 randomDigit = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );

        uint256 p0 = 1;
        uint256 p1 = uint256((randomDigit >> 4) % 12) + 1;
        uint256 p2 = uint256((randomDigit >> 8) % 10) + 1;
        uint256 p3 = uint256((randomDigit >> 12) % 11) + 1;
        uint256 p4 = uint256((randomDigit >> 16) % 33) + 1;
        p4 = p4 > 10 ? p4 + 1 : p4;
        uint256 p5 = uint256((randomDigit >> 20) % 10) + 1;
        uint256 p6 = uint256((randomDigit >> 24) % 20) + 1;
        uint256 p7 = uint256((randomDigit >> 28) % 20) + 1;
        uint256 p8 = uint256((randomDigit >> 32) % 20) + 1;
        uint256 p9 = uint256((randomDigit >> 36) % 9) + 1;
        uint256 p10 = uint256((randomDigit >> 40) % 20) + 1;

        uint256[11] memory p = [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10];

        uint256 partNum = partNums[x];
        partNum = partNum - 1;

        playerOneRoleParts.mint(_msgSender(), p0, 1, "0x");

        uint256 tmpRandomDigit = randomDigit;

        for (uint256 i = 0; i < partNum; i++) {
            uint256 ranOffset = 44 + i * 4;
            uint256 ran = uint256((tmpRandomDigit >> ranOffset) % 10) + 1;
            uint256 _tokenid = parseInt(
                string(abi.encodePacked(ran.toString(), p[ran].toString()))
            );
            playerOneRoleParts.mint(_msgSender(), _tokenid, 1, "0x");
        }
    }

    function parseInt(string memory _a) public pure returns (uint256) {
        bytes memory bresult = bytes(_a);

        uint256 tmp = 0;

        for (uint256 i = 0; i < bresult.length; i++) {
            uint256 b = uint256(uint8(bresult[i])) - 48;
            tmp *= 10;
            tmp += b;
        }

        return tmp;
    }

    function setPlayerOneRoleParts(IPlayerOneRoleParts addr) public onlyOwner {
        playerOneRoleParts = addr;
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}