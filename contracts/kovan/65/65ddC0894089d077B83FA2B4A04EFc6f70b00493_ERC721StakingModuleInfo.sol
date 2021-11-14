/*
ERC721StakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IStakingModule.sol";

/**
 * @title ERC721 staking module
 *
 * @notice this staking module allows users to deposit one or more ERC721
 * tokens in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC721StakingModule is IStakingModule {
    // constant
    uint256 public constant SHARES_PER_TOKEN = 10**18;

    // members
    IERC721 private immutable _token;
    address private immutable _factory;

    mapping(address => uint256) public counts;
    mapping(uint256 => address) public owners;
    mapping(address => mapping(uint256 => uint256)) public tokenByOwner;
    mapping(uint256 => uint256) public tokenIndex;

    /**
     * @param token_ the token that will be rewarded
     */
    constructor(address token_, address factory_) {
        require(IERC165(token_).supportsInterface(0x80ac58cd), "smn1");
        _token = IERC721(token_);
        _factory = factory_;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function balances(address user)
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        balances_[0] = counts[user];
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](1);
        totals_[0] = _token.balanceOf(address(this));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (address, uint256) {
        // validate
        require(amount > 0, "smn2");
        require(amount <= _token.balanceOf(user), "smn3");
        require(data.length == 32 * amount, "smn4");

        uint256 sz = counts[user];

        // stake
        for (uint256 i = 0; i < amount; i++) {
            // get token id
            uint256 id;
            uint256 pos = 132 + 32 * i;
            assembly {
                id := calldataload(pos)
            }

            // ownership mappings
            owners[id] = user;
            uint256 len = sz + i;
            tokenByOwner[user][len] = id;
            tokenIndex[id] = len;

            // transfer to module
            _token.transferFrom(user, address(this), id);
        }

        // update position
        counts[user] = sz + amount;

        // emit
        uint256 s = amount * SHARES_PER_TOKEN;
        emit Staked(user, address(_token), amount, s);

        return (user, s);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (address, uint256) {
        // validate
        require(amount > 0, "smn5");
        uint256 sz = counts[user];
        require(amount <= sz, "smn6");
        require(data.length == 32 * amount, "smn7");

        // unstake
        for (uint256 i = 0; i < amount; i++) {
            // get token id
            uint256 id;
            uint256 pos = 132 + 32 * i;
            assembly {
                id := calldataload(pos)
            }

            // ownership
            require(owners[id] == user, "smn8");
            delete owners[id];

            // clean up ownership mappings
            uint256 lastIndex = sz - 1 - i;
            if (amount != sz) {
                // reindex on partial unstake
                uint256 index = tokenIndex[id];
                if (index != lastIndex) {
                    uint256 lastId = tokenByOwner[user][lastIndex];
                    tokenByOwner[user][index] = lastId;
                    tokenIndex[lastId] = index;
                }
            }
            delete tokenByOwner[user][lastIndex];
            delete tokenIndex[id];

            // transfer to user
            _token.safeTransferFrom(address(this), user, id);
        }

        // update position
        counts[user] = sz - amount;

        // emit
        uint256 s = amount * SHARES_PER_TOKEN;
        emit Unstaked(user, address(_token), amount, s);

        return (user, s);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address user,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (address, uint256) {
        // validate
        require(amount > 0, "smn9");
        require(amount <= counts[user], "smn10");

        uint256 s = amount * SHARES_PER_TOKEN;
        emit Claimed(user, address(_token), amount, s);
        return (user, s);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(address) external override {}

    /**
     * @inheritdoc IStakingModule
     */
    function clean() external override {}
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

/*
ERC721StakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "../interfaces/IStakingModule.sol";
import "../ERC721StakingModule.sol";

/**
 * @title ERC721 staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC721StakingModule contract.
 */
library ERC721StakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        )
    {
        IStakingModule m = IStakingModule(module);
        IERC721Metadata tkn = IERC721Metadata(m.tokens()[0]);
        if (!tkn.supportsInterface(0x5b5e139f)) {
            return (address(tkn), "", "", 0);
        }
        return (address(tkn), tkn.name(), tkn.symbol(), 0);
    }

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) public view returns (uint256) {
        ERC721StakingModule m = ERC721StakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.counts(addr) * m.SHARES_PER_TOKEN();
        }

        require(amount <= m.counts(addr), "smni1");
        return amount * m.SHARES_PER_TOKEN();
    }

    /**
     * @notice get shares per token
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        ERC721StakingModule m = ERC721StakingModule(module);
        return m.SHARES_PER_TOKEN() * 1e18;
    }

    /**
     * @notice get staked token ids for user
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens to enumerate
     * @param start token index to start at
     * @return ids array of token ids
     */
    function tokenIds(
        address module,
        address addr,
        uint256 amount,
        uint256 start
    ) public view returns (uint256[] memory ids) {
        ERC721StakingModule m = ERC721StakingModule(module);
        uint256 sz = m.counts(addr);
        require(start + amount <= sz, "smni2");

        if (amount == 0) {
            amount = sz - start;
        }

        ids = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = m.tokenByOwner(addr, i + start);
        }
    }
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IStakingModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of staking tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user)
        external
        view
        virtual
        returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view virtual returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to stake
     * @param data additional data
     * @return address of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return address of staking account
     * @return number of shares burned for unstake
     */
    function unstake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param user address of user
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return address of staking account
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */
    function clean() external virtual;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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