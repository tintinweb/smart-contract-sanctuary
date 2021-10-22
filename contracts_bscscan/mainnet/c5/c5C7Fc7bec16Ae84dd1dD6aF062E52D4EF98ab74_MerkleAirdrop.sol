// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract MerkleAirdrop is Ownable, ReentrancyGuard {
    /* STATE VARIABLES */

    bytes32[] public merkleRoots;

    IERC20 public tokenContract;

    mapping(uint256 => mapping(address => bool)) public isSpent;

    /* MODIFIERS */
    /* EVENTS */

    event AirdropTransfer(address addr, uint256 num, uint256 rootInd);

    event RootAdded(uint rootIndex);

    /* FUNCTIONS */

    constructor(IERC20 _tokenContract) {
        tokenContract = _tokenContract;
    }

    /* EXTERNAL FUNCTIONS */

    function addRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoots.push(_merkleRoot);
        emit RootAdded(merkleRoots.length - 1);
    }

    function getLastRootIndex() external view returns(uint) {
        return merkleRoots.length;
    }

    function claimTokens(IERC20 _token, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(address(_token) != address(0), "MerkleAirdrop: Wrong token");
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(tokenBalance > 0, "MerkleAirdrop: Token balane equals zero");
        require(amount < tokenBalance, "MerkleAirdrop: Wrong amount");
        if (amount == 0) amount = tokenBalance;
        require(
            _token.transfer(owner(), amount),
            "MerkleAirdrop: Transfer failed"
        );
    }

    function getTokensByMerkleProof(
        bytes32[] calldata _proof,
        address _who,
        uint256 _amount,
        uint256 rootInd
    ) external nonReentrant returns (bool) {
        require(
            isSpent[rootInd][_who] != true,
            "MerkleAirdrop: This user has already been used"
        );
        require(_amount > 0, "MerkleAirdrop: Wrong amount");

        require(
            _checkProof(
                _proof,
                _leafFromAddressAndNumTokens(_who, _amount),
                rootInd
            ),
            "MerkleAirdrop: Wrong proof"
        );

        isSpent[rootInd][_who] = true;

        emit AirdropTransfer(_who, _amount, rootInd);

        require(
            tokenContract.transfer(_who, _amount),
            "MerkleAirdrop: Transfer failed"
        );

        return true;
    }

    /* EXTERNAL VIEW FUNCTIONS */

    function contractTokenBalance() external view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function numOfRoots() external view returns (uint256) {
        return merkleRoots.length;
    }

    /* PUBLIC FUNCTIONS */
    /* INTERNAL FUNCTIONS */
    /* PRIVATE FUNCTIONS */
    /* PRIVATE PURE FUNCTIONS */

    function _leafFromAddressAndNumTokens(address _a, uint256 _n)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_a, _n));
    }

    /* PRIVATE VIEW FUNCTIONS */

    function _checkProof(
        bytes32[] calldata proof,
        bytes32 _hash,
        uint256 rootInd
    ) private view returns (bool) {
        bytes32 el;
        bytes32 h = _hash;

        for (uint256 i = 0; i < proof.length; i += 1) {
            el = proof[i];

            if (h < el) {
                h = keccak256(abi.encodePacked(h, el));
            } else {
                h = keccak256(abi.encodePacked(el, h));
            }
        }

        return h == merkleRoots[rootInd];
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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