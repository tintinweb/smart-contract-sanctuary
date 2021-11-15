// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// contracts/Wedding.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Wedding {

    address public lowbAddress;
    address public owner;
    uint private _randomSeed = 5201314;
    uint public balance;
    bool public isStart = true;
    uint public totalWY;

    struct Pool {
        address luckyLoser;
        uint luckyNumber;
        uint totalLoser;
        uint amount;
    }

    Pool[8] public poolOf;
    mapping (address => uint[8]) public luckyNumberOf;
    mapping (address => uint) public wyAmoutOf;

    
    event BlessNewlyweds(address indexed loser, uint indexed n, uint luckyNumber);
    event NewLuckyLoser(address indexed loser, uint indexed n, uint luckyNumber);

    constructor(address lowb_) {
        lowbAddress = lowb_;
        owner = msg.sender;
        poolOf[0].amount = 20000e18;
        poolOf[1].amount = 30000e18;
        poolOf[2].amount = 50000e18;
        poolOf[3].amount = 100000e18;
        poolOf[4].amount = 200000e18;
        poolOf[5].amount = 500000e18;
        poolOf[6].amount = 2000000e18;
        poolOf[7].amount = 10000000e18;
    }

    function getWyAmout(address player) public view returns(uint) {
        return wyAmoutOf[player];
    }
    
    function getPoolInfo(uint n) public view returns (Pool memory) {
      require(n < 8, "Index overflowed.");
      return poolOf[n];
    }

    function getPoolInfoV2(uint n) public view returns (address luckyLoser, uint luckyNumber, uint totalLoser, uint amount) {
      require(n < 8, "Index overflowed.");
      return (poolOf[n].luckyLoser, poolOf[n].luckyNumber, poolOf[n].totalLoser, poolOf[n].amount);
    }

    function setStart(bool _start) public {
        require(msg.sender == owner, "Only owner can start wedding!");
        isStart = _start;
    }
    
    function pullFunds() public {
        require(msg.sender == owner, "Only owner can pull the funds!");
        IERC20 lowb = IERC20(lowbAddress);
        lowb.transfer(msg.sender, balance);
        balance = 0;
    }

    function blessNewlyweds(uint n) public {
        require(isStart, "The weddig is not start.");
        require(n < 8, "Index overflowed.");
        IERC20 lowb = IERC20(lowbAddress);
        require(lowb.transferFrom(msg.sender, address(this), poolOf[n].amount), "Lowb transfer failed");
        _randomSeed = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randomSeed)));
        uint luckyNumber = _randomSeed % 5201314;
        luckyNumberOf[msg.sender][n] = luckyNumber;
        balance += poolOf[n].amount;
        poolOf[n].totalLoser ++;
        wyAmoutOf[msg.sender] += poolOf[n].amount / 100;
        totalWY += poolOf[n].amount / 100;
        emit BlessNewlyweds(msg.sender, n, luckyNumber);
        if (poolOf[n].luckyLoser == address(0) || luckyNumber < poolOf[n].luckyNumber) {
            poolOf[n].luckyNumber = luckyNumber;
            poolOf[n].luckyLoser = msg.sender;
            emit NewLuckyLoser(msg.sender, n, luckyNumber);
        }
    }

}

// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wedding.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract WeddingGift {

    address public weddingAddress;
    address public punkAddress;
    address public owner;
    uint public punkId;
    mapping (address => bool[8]) public claimed;

    struct Info {
        uint luckyNumber;
        bool isClaimed;
        bool isLucky;
    }

    constructor(address weddingAddress_, address punkAddress_) {
        weddingAddress = weddingAddress_;
        punkAddress = punkAddress_;
        owner = msg.sender;
        punkId = 402;
    }

    function isLucky(address loser, uint poolId) public view returns (bool) {
        Wedding wedding = Wedding(weddingAddress);
        uint luckyNumber = wedding.luckyNumberOf(loser, poolId);
        if (luckyNumber == 0 || claimed[msg.sender][poolId]) return false;
        if (poolId == 5 && luckyNumber % 5 != 0) return false;
        if (poolId == 4 && luckyNumber % 20 != 0) return false;
        if (poolId == 3 && luckyNumber % 60 != 0) return false;
        if (poolId == 2 && luckyNumber % 120 != 0) return false;
        if (poolId == 1 && luckyNumber % 240 != 0) return false;
        if (poolId == 0 && luckyNumber % 500 != 0) return false;
        return true;
    }

    function returnNFT(uint start, uint end, address to) public {
        require(msg.sender == owner, "You are not admin");
        IERC721 nft = IERC721(punkAddress);
        for (uint i=start; i<=end; i++) {
            nft.transferFrom(address(this), to, i);
        }
    }

    function claimPunk(uint poolId) public {
        require(isLucky(msg.sender, poolId), "You are not lucky");
        claimed[msg.sender][poolId] = true;
        IERC721 nft = IERC721(punkAddress);
        if (poolId == 7) {
            for (uint i=0; i<5; i++) {
                nft.transferFrom(address(this), msg.sender, punkId);
                punkId ++;
            }
        }
        else {
            nft.transferFrom(address(this), msg.sender, punkId);
            punkId ++;
        }
    }

    function getInfo(address loser) public view returns (Info[8] memory) {
        Wedding wedding = Wedding(weddingAddress);
        Info[8] memory infos;
        for (uint i=0; i<8; i++) {
            infos[i].luckyNumber = wedding.luckyNumberOf(loser, i);
            infos[i].isLucky = isLucky(loser, i);
            infos[i].isClaimed = claimed[loser][i];
        }
        return infos;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

