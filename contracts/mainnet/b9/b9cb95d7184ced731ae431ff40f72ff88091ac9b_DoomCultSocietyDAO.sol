/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev ERC20 Contract Implementation
 */
contract ERC20 {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string public constant name = 'Doom Cult Society DAO';
    string public constant symbol = 'CUL';
    uint256 public constant decimals = 18;
    uint256 public constant CURRENCY_MULTIPLIER = 1000000000000000000;
    uint256 internal constant ERROR_SIG = 0x08c379a000000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant TRANSFER_SIG = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    bytes32 internal constant APPROVAL_SIG = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {}

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 result) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _allowances.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            result := sload(keccak256(0x00, 0x40))
        }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance;
        assembly {
            // currentAllowance = _allowances[sender][msg.sender]
            mstore(0x00, sender)
            mstore(0x20, _allowances.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, caller())
            let currentAllowanceSlot := keccak256(0x00, 0x40)
            currentAllowance := sload(currentAllowanceSlot)
            if gt(amount, currentAllowance) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 23)
                mstore(0x44, 'ERC20: amount>allowance')
                revert(0x00, 0x64)
            }
        }
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        assembly {
            mstore(0x00, sender)
            mstore(0x20, _balances.slot)
            let balancesSlot := keccak256(0x00, 0x40)
            let senderBalance := sload(balancesSlot)

            if or(or(iszero(sender), iszero(recipient)), gt(amount, senderBalance)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 32)
                mstore(0x44, 'ERC20: amount>balance or from==0')
                revert(0x00, 0x64)
            }

            sstore(balancesSlot, sub(senderBalance, amount))

            mstore(0x00, recipient)
            balancesSlot := keccak256(0x00, 0x40)
            // skip overflow check as we only have 30,000 tokens
            sstore(balancesSlot, add(sload(balancesSlot), amount))
            mstore(0x00, amount)
            log3(0x00, 0x20, TRANSFER_SIG, sender, recipient)
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        assembly {
            if or(iszero(owner), iszero(spender)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 29)
                mstore(0x44, 'ERC20: approve from 0 address')
                revert(0x00, 0x64)
            }

            // _allowances[owner][spender] = amount
            mstore(0x00, owner)
            mstore(0x20, _allowances.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            sstore(keccak256(0x00, 0x40), amount)

            // emit Approval(owner, spender, amount)
            mstore(0x00, amount)
            log3(0x00, 0x20, APPROVAL_SIG, owner, spender)
        }
    }
}

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension but not the Enumerable extension
 */
contract ERC721 is IERC165, IERC721, IERC721Metadata {
    // Token name
    string public constant override name = 'Doom Cult Society';

    // Token symbol
    string public constant override symbol = 'DCS';

    uint256 internal constant ERROR_SIG = 0x08c379a000000000000000000000000000000000000000000000000000000000;
    // event signatures
    uint256 private constant APPROVAL_FOR_ALL_SIG = 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;
    bytes32 internal constant TRANSFER_SIG = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    bytes32 internal constant APPROVAL_SIG = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256 res) {
        assembly {
            if iszero(owner) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 42)
                mstore(0x44, 'ERC721: balance query for the ze')
                mstore(0x64, 'ro address')
                revert(0x00, 0x84)
            }

            mstore(0x00, owner)
            mstore(0x20, _balances.slot)
            res := sload(keccak256(0x00, 0x40))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _owners.slot)
            // no need to mask address if we ensure everything written into _owners is an address
            owner := sload(keccak256(0x00, 0x40))

            if iszero(owner) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 41)
                mstore(0x44, 'ERC721: owner query for nonexist')
                mstore(0x64, 'ent token')
                revert(0x00, 0x84)
            }
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256) public view virtual override returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        bool approvedForAll = isApprovedForAll(owner, msg.sender);
        /**
         * Failure cases
         * 1. to == owner (if ya wanna approve yourself go stare in a mirror!)
         * 2. !(msg.sender == owner OR approvedForAll == 1)
         */
        assembly {
            if or(eq(to, owner), iszero(or(eq(caller(), owner), approvedForAll))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 19)
                mstore(0x44, 'ERC721: bad approve')
                revert(0x00, 0x64)
            }

            mstore(0x00, tokenId)
            mstore(0x20, _tokenApprovals.slot)
            sstore(keccak256(0x00, 0x40), to)
            log3(0x00, 0x20, APPROVAL_SIG, owner, to)
        }
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address res) {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _owners.slot)
            if iszero(sload(keccak256(0x00, 0x40))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 19)
                mstore(0x44, 'ERC721: bad approve')
                revert(0x00, 0x64)
            }

            mstore(0x00, tokenId)
            mstore(0x20, _tokenApprovals.slot)
            res := sload(keccak256(0x00, 0x40))
        }
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        assembly {
            if eq(operator, caller()) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 25)
                mstore(0x44, 'ERC721: approve to caller')
                revert(0x00, 0x64)
            }

            // _operatorApprovals[_msgSender()][operator] = approved
            mstore(0x00, caller())
            mstore(0x20, _operatorApprovals.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            sstore(keccak256(0x00, 0x40), approved)

            log4(0, 0, APPROVAL_FOR_ALL_SIG, caller(), operator, approved)
        }
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool res) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _operatorApprovals.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, operator)
            res := sload(keccak256(0x00, 0x40))
        }
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _isApprovedOrOwner(msg.sender, tokenId);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _isApprovedOrOwner(msg.sender, tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        bool isContract;
        assembly {
            isContract := gt(extcodesize(to), 0)
        }
        if (isContract) {
            _checkOnERC721ReceivedContract(from, to, tokenId, _data);
        }
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual {
        address owner;
        bool approvedForAll = isApprovedForAll(owner, spender);
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _owners.slot)
            owner := sload(keccak256(0x00, 0x40))

            mstore(0x20, _tokenApprovals.slot)
            let approved := sload(keccak256(0x00, 0x40))

            /**
             * Success Conditions
             * 1. spender = owner
             * 2. spender = approved
             * 3. approvedForAll = true
             * Also owner must NOT be 0
             */
            if or(iszero(or(or(eq(spender, owner), eq(approved, spender)), approvedForAll)), iszero(owner)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 44)
                mstore(0x44, 'ERC721: operator query for nonex')
                mstore(0x64, 'istent token')
                revert(0x00, 0x84)
            }
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // address owner = ownerOf(tokenId);
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _owners.slot)
            let owner := sload(keccak256(0x00, 0x40))

            // Clear approvals from the previous owner
            mstore(0x00, tokenId)
            mstore(0x20, _tokenApprovals.slot)
            sstore(keccak256(0x00, 0x40), 0)
            log3(0x00, 0x20, APPROVAL_SIG, owner, 0)
            log3(0x00, 0x20, TRANSFER_SIG, from, to)

            // _owners[tokenId] = to
            mstore(0x20, _owners.slot)
            sstore(keccak256(0x00, 0x40), to)

            // _balances[from] -= 1
            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let slot := keccak256(0x00, 0x40)
            let fromBalance := sload(slot)
            sstore(slot, sub(fromBalance, 0x01))

            // _balances[to] += 1
            mstore(0x00, to)
            slot := keccak256(0x00, 0x40)
            sstore(slot, add(sload(slot), 1))

            /**
             * Failure cases...
             * 1. owner != from
             * 2. to == 0
             * 3. owner == 0
             * 4. balances[from] == 0
             */
            if or(or(iszero(owner), iszero(fromBalance)), or(iszero(to), sub(owner, from))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 20)
                mstore(0x44, 'ERC721: bad transfer')
                revert(0x00, 0x64)
            }
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     */
    function _checkOnERC721ReceivedContract(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            require(
                retval == IERC721Receiver(to).onERC721Received.selector,
                'ERC721: transfer to non ERC721Receiver implementer'
            );
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert('ERC721: transfer to non ERC721Receiver implementer');
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}

/**
 * @dev DoomCultSocietyDAO
 * Decentralized Autonomous Doom! Doooooooooooooooooooooooom!
 *
 * The DAO controls cultist tokens: CUL
 * Cultist tokens are sacrificed in order to mint DoomCultSociety NFTs
 */
contract DoomCultSocietyDAO is ERC20 {
    uint256 internal constant WEEKS_UNTIL_OBLIVION = 52;
    uint256 internal constant SECONDS_PER_WEEK = 604800;

    uint256 public sleepTimer; // can wake up once block.timestamp > sleepTimer
    uint256 public doomCounter; // number of weeks until contract is destroyed
    uint256 public timestampUntilNextEpoch; // countdown timer can decrease once block.timestamp > timestampUntilNextEpoch

    // potential max cultists (incl. currency multiplier. This is 30,000 CUL)
    uint256 internal constant MAX_CULTISTS = 30000000000000000000000;
    // how many do we actually start with? (phase 2 starts after 4 weeks regardless)
    uint256 public numStartingCultists;
    // If currentEpochTotalSacrificed <= lastEpocTotalSacrificed when epoch ends...kaboom!
    uint256 public currentEpochTotalSacrificed;
    uint256 public lastEpochTotalSacrificed;

    // How many times this week has the DAO been placated
    uint256 public placationCount;
    // How much does the cost increase by each time we placate?
    uint256 private constant PLACATE_INTERVAL = 100000000000000000; // 0.1 eth in wei
    // What is the current cost to placate?
    uint256 public placateThreshold = PLACATE_INTERVAL;

    uint256 private constant IT_HAS_AWOKEN_SIG = 0x21807e0b842b099372e0a04f56a3c00df1f88de6af9d3e3ebb06d4d6fac76a8d;
    event ItHasAwoken(uint256 startNumCultists);

    uint256 private constant COUNTDOWN_SIG = 0x11d2d22584d0bb23681c07ce6959f34dfc15469ad3546712ab96e3a945c6f603;
    event Countdown(uint256 weeksRemaining);

    uint256 private constant OBLITERATE_SIG = 0x03d6576f6c77df8600e2667de4d5c1fbc7cb69b42d5eaa80345d8174d80af46b;
    event Obliterate(uint256 endNumCultists);
    bool public isAwake;
    DoomCultSociety public doomCultSociety;

    modifier onlyAwake() {
        assembly {
            if iszero(and(sload(isAwake.slot), 1)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 14)
                mstore(0x44, 'It Is Sleeping')
                revert(0x00, 0x64)
            }
        }
        _;
    }
    modifier onlyAsleep() {
        assembly {
            if and(sload(isAwake.slot), 1) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 12)
                mstore(0x44, 'It Has Woken')
                revert(0x00, 0x64)
            }
        }
        _;
    }

    constructor() ERC20() {
        doomCultSociety = new DoomCultSociety();
        assembly {
            sstore(sleepTimer.slot, add(timestamp(), mul(4, SECONDS_PER_WEEK)))
        }
        // Mmmmmmmmmmm slightly corrupt cheeky premine aka 6.66% founder reward
        _balances[address(0x24065d97424687EB9c83c87729fc1b916266F637)] = 898 * CURRENCY_MULTIPLIER; // some extra for givaways
        _balances[address(0x1E11a16335E410EB5f4e7A781C6f069609E5946A)] = 100 * CURRENCY_MULTIPLIER; // om
        _balances[address(0x9436630F6475D04E1d396a255f1321e00171aBFE)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x001aBc8196c60C2De9f9a2EdBdf8Db00C1Fa35ef)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x53DF4Fc15BdAfd4c01ca289797A85D00cC791810)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x10715Db3d70bBB01f39B6A6CA817cbcf2F6e9B5f)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x4a4866086D4b74521624Dbaec9478C9973Ff2C8e)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0xB658bF75C8968e8C9a577D5c8814803A1dDD0939)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x99A94D55417aaCC993889d5C574B07F01Ad35920)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0xE71f18D8F2e874AD3284C1A432A38fD158e35D70)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x31102499a64BEc6dC5Cc22FFDCBDc0551b2687Ab)] = 100 * CURRENCY_MULTIPLIER; // nom
        _balances[address(0x934a19c7f2cD41D330d00C02884504fb59a33F36)] = 100 * CURRENCY_MULTIPLIER; // *burp*
        _totalSupply = 1998 * CURRENCY_MULTIPLIER;

        emit Transfer(address(0), address(0x24065d97424687EB9c83c87729fc1b916266F637), 898 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x1E11a16335E410EB5f4e7A781C6f069609E5946A), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x9436630F6475D04E1d396a255f1321e00171aBFE), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x001aBc8196c60C2De9f9a2EdBdf8Db00C1Fa35ef), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x53DF4Fc15BdAfd4c01ca289797A85D00cC791810), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x10715Db3d70bBB01f39B6A6CA817cbcf2F6e9B5f), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x4a4866086D4b74521624Dbaec9478C9973Ff2C8e), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0xB658bF75C8968e8C9a577D5c8814803A1dDD0939), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x99A94D55417aaCC993889d5C574B07F01Ad35920), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0xE71f18D8F2e874AD3284C1A432A38fD158e35D70), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x31102499a64BEc6dC5Cc22FFDCBDc0551b2687Ab), 100 * CURRENCY_MULTIPLIER);
        emit Transfer(address(0), address(0x934a19c7f2cD41D330d00C02884504fb59a33F36), 100 * CURRENCY_MULTIPLIER);
    }

    /**
     * @dev Acquire cultists!
     */
    function attractCultists() public onlyAsleep {
        assembly {
            if lt(MAX_CULTISTS, add(1, sload(_totalSupply.slot))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 22)
                mstore(0x44, 'No remaining cultists!')
                revert(0x00, 0x64)
            }
            let numTokens := mul(3, CURRENCY_MULTIPLIER)
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let balanceSlot := keccak256(0x00, 0x40)
            // _balances[msg.sender] += 3
            sstore(balanceSlot, add(sload(balanceSlot), numTokens))
            // _totalSupply += 3
            sstore(_totalSupply.slot, add(sload(_totalSupply.slot), numTokens))
            // emit Transfer(0, msg.sender, 3)
            mstore(0x00, numTokens)
            log3(0x00, 0x20, TRANSFER_SIG, 0, caller())
        }
    }

    /**
     * @dev Awaken the wrath of the Doom Cult Society DAO!
     */
    function wakeUp() public onlyAsleep {
        assembly {
            if iszero(
                or(gt(add(sload(_totalSupply.slot), 1), MAX_CULTISTS), gt(add(timestamp(), 1), sload(sleepTimer.slot)))
            ) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 17)
                mstore(0x44, 'Still Sleeping...')
                revert(0x00, 0x64)
            }
            sstore(isAwake.slot, or(sload(isAwake.slot), 1))
            sstore(timestampUntilNextEpoch.slot, add(timestamp(), SECONDS_PER_WEEK))
            sstore(doomCounter.slot, 1)
            let total := sload(_totalSupply.slot)
            sstore(numStartingCultists.slot, div(total, CURRENCY_MULTIPLIER))

            // emit ItHasAwoken(_totalSupply)
            mstore(0x00, total)
            log1(0x00, 0x20, IT_HAS_AWOKEN_SIG)
        }
    }

    function obliterate() internal onlyAwake {
        assembly {
            if iszero(eq(sload(doomCounter.slot), add(WEEKS_UNTIL_OBLIVION, 1))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 22)
                mstore(0x44, 'Too Soon To Obliterate')
                revert(0x00, 0x64)
            }

            // emit Obliterate(_totalSupply)
            mstore(0x00, sload(_totalSupply.slot))
            log1(0x00, 0x20, OBLITERATE_SIG)
            selfdestruct(0x00) // so long and thanks for all the fish!
        }
    }

    /**
     * @dev This function will only generate ONE NFT regardless of how many you sacrifice!!!!!
     *      If you want lots of NFTs call `sacrifice()` multiple times
     *      This function is for those who just want to run those numbers up for maximum chaos
     * @param num number of cultists to sacrifice!
     */
    function sacrificeManyButOnlyMintOneNFT(
        uint256 num,
        string memory /*message*/
    ) public onlyAwake {
        uint256 totalRemainingCultists;
        uint256 totalSacrificedCultists;
        uint256 requiredTokens;
        assembly {
            requiredTokens := mul(CURRENCY_MULTIPLIER, num)
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let slot := keccak256(0x00, 0x40)
            let userBal := sload(slot)
            if or(lt(userBal, requiredTokens), iszero(num)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 21)
                mstore(0x44, 'Insufficient Cultists')
                revert(0x00, 0x64)
            }
            sstore(slot, sub(userBal, requiredTokens))
            sstore(currentEpochTotalSacrificed.slot, add(sload(currentEpochTotalSacrificed.slot), num))
            let remainingTokens := sub(sload(_totalSupply.slot), requiredTokens)
            totalRemainingCultists := div(remainingTokens, CURRENCY_MULTIPLIER)
            sstore(_totalSupply.slot, remainingTokens)
            totalSacrificedCultists := sub(sload(numStartingCultists.slot), totalRemainingCultists)
        }
        doomCultSociety.mint(doomCounter, totalRemainingCultists, totalSacrificedCultists, msg.sender);
        assembly {
            // emit Transfer(msg.sender, 0, num)
            mstore(0x00, requiredTokens)
            log3(0x00, 0x20, TRANSFER_SIG, caller(), 0)
        }
    }

    /**
     * @dev BLOOD FOR THE BLOOD GOD!
     *
     * @param message commemorate your sacrifice with a message to be recorded for all eternity
     */
    function sacrifice(string memory message) public onlyAwake {
        sacrificeManyButOnlyMintOneNFT(1, message);
    }

    /**
     *  @dev Stuff the DAO with gold to soothe its wrath! When money talks, there are few interruptions.
     *
     *  HOW IT WORKS
     *  Users can push the required sacrifices down by 1 with some RAW ULTRA SOUND MONEY
     *  Placate starts at 0.1 Eth, cost increases by 0.1 Eth per placation.
     *  Yes, this gets stupid expensive very quickly!
     *
     *  What do we do with these funds? Well, we could fairly redistribute them
     *  to the DAO's stakeholders...but who has time to bother with writing that code? Certainly not me!
     *  Instead send it to charity lol. Cults are supposed to take money from their supporters, not give it back!
     */
    function placate() public payable onlyAwake {
        require(msg.value >= placateThreshold, 'TOO POOR');

        uint256 numPlacations = msg.value / placateThreshold;

        placationCount += numPlacations;

        placateThreshold += (numPlacations * PLACATE_INTERVAL);

        // GiveDirectly Eth address
        (bool sent, ) = payable(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C).call{value: msg.value}('');
        require(sent, 'Failed to send Ether');
    }

    /**
     * @dev KNEEL PEON! KNEEL BEFORE YOUR MASTER!
     */
    function worship() public payable onlyAwake {
        assembly {
            if gt(sload(timestampUntilNextEpoch.slot), add(timestamp(), 1)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 8)
                mstore(0x44, 'Too Soon')
                revert(0x00, 0x64)
            }
        }

        uint256 score = currentEpochTotalSacrificed + placationCount;
        if (lastEpochTotalSacrificed >= score) {
            assembly {
                // emit Obliterate(_totalSupply)
                mstore(0x00, sload(_totalSupply.slot))
                log1(0x00, 0x20, OBLITERATE_SIG)
                selfdestruct(0x00) // womp womp
            }
        }
        assembly {
            sstore(lastEpochTotalSacrificed.slot, sload(currentEpochTotalSacrificed.slot))
            sstore(currentEpochTotalSacrificed.slot, 0)
            sstore(timestampUntilNextEpoch.slot, add(timestamp(), SECONDS_PER_WEEK))
            sstore(doomCounter.slot, add(sload(doomCounter.slot), 1))
            sstore(placationCount.slot, 0)
        }
        if (doomCounter == (WEEKS_UNTIL_OBLIVION + 1)) {
            obliterate();
        }
        // emit Countdown(doomCounter)
        assembly {
            mstore(0x00, sload(doomCounter.slot))
            log1(0x00, 0x20, COUNTDOWN_SIG)
        }
    }
}

/**
 * @dev DoomCultSociety
 * It's more than a cult, it's a society!
 * We have culture, economic theories and heaps of dead cultists
 */
contract DoomCultSociety is ERC721 {
    address public doomCultSocietyDAO;
    uint256 private constant SPLIT_PHRASE_ACROSS_LINES = 31;

    constructor() ERC721() {
        assembly {
            sstore(doomCultSocietyDAO.slot, caller())
        }
        mint(0, 30000, 0, address(this));
    }

    // Not enumerable but hey we have enough info for this method...so why not
    // (until the DAO blows up that is!)
    function totalSupply() public view returns (uint256) {
        DoomCultSocietyDAO dao = DoomCultSocietyDAO(doomCultSocietyDAO);
        return dao.numStartingCultists() - (dao.totalSupply() / 1000000000000000000);
    }

    function mint(
        uint256 countdown,
        uint256 remainingCultists,
        uint256 sacrificedCultists,
        address owner
    ) public {
        uint256 tokenId;
        assembly {
            if iszero(eq(caller(), sload(doomCultSocietyDAO.slot))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 10)
                mstore(0x44, 'Bad Caller')
                revert(0x00, 0x64)
            }

            tokenId := add(add(mul(remainingCultists, 100000000), mul(countdown, 1000000)), sacrificedCultists)

            mstore(0x00, owner)
            mstore(0x20, _balances.slot)
            let slot := keccak256(0x00, 0x40)
            // no need to check overflow, there are only 30,000 tokens!
            sstore(slot, add(sload(slot), 1))

            mstore(0x00, tokenId)
            mstore(0x20, _owners.slot)
            sstore(keccak256(0x00, 0x40), owner)

            mstore(0x00, tokenId)
            log3(0x00, 0x20, TRANSFER_SIG, 0, owner)
        }
    }

    function getImgData(uint256 tokenId) internal pure returns (string memory res) {
        // we make some assumptions when this function is called...
        // 1: a max of 480 bytes of RAM have been used so far (i.e. `getImgData` is called at start of call context!)
        // 2: setting the free memory pointer to 20000 won't cause any problems!
        assembly {
            {
                let t0 := '<use transform="'
                let t1 := ' transform="'
                let t2 := 'rotate'
                let t3 := ' fill="#f57914"'
                let t4 := ' fill="#ed1c24"'
                let t5 := ' fill="#8c1b85"'
                let t6 := ' fill="#0994d3"'
                let t7 := ' fill="#9addf0"'
                let t8 := ' fill="#312b5d"'
                let t9 := ' fill="#fff" '
                let t10 := 'xlink:href="#'
                let t11 := '<circle cx="'
                let t12 := '<path id="'
                let t13 := '"/><use '
                let t14 := '"><use '
                let t15 := '="http://www.w3.org/'
                mstore(512, '<svg viewBox="0 0 700 800" xmlns')
                mstore(544, t15)
                mstore(564, '2000/svg" xmlns:xlink')
                mstore(585, t15)
                mstore(605, '1999/xlink"><style>.soft{font:70')
                mstore(637, '0 20px sans-serif;fill:#ffffff88')
                mstore(669, '}.heavy{font:700 29px sans-serif')
                mstore(701, ';fill:#fff}.superheavy{font:700 ')
                mstore(733, '40px sans-serif;fill:#fff}@-webk')
                mstore(765, 'it-keyframes shine {from {-webki')
                mstore(797, 't-filter: hue-')
                mstore(811, t2)
                mstore(817, '(0deg);}to { -webkit-filter: hue')
                mstore(849, '-')
                mstore(850, t2)
                mstore(856, '(360deg); } }g { -webkit-animati')
                mstore(888, 'on: shine 5s ease-in-out infinit')
                mstore(920, 'e; }</style><path d="M0 0h700v08')
                mstore(952, '00H0z"/><g')
                mstore(962, t1)
                mstore(974, 'matrix(.1 0 0 -.1 -350 660)"><de')
                mstore(1006, 'fs><g id="g">')
                mstore(1019, t11)
                mstore(1031, '-20" cy="210" r="100')
                mstore(1051, t13)
                mstore(1059, t10)
                mstore(1072, 'd')
                mstore(1073, t13)
                mstore(1081, 'transform="')
                mstore(1092, t2)
                mstore(1098, '(45 30.71 267.28)" ')
                mstore(1117, t10)
                mstore(1130, 'd')
                mstore(1131, t13)
                mstore(1139, 'transform="')
                mstore(1150, t2)
                mstore(1156, '(90 -20 240)" ')
                mstore(1170, t10)
                mstore(1183, 'd"/></g><g id="f')
                mstore(1199, t14)
                mstore(1206, t10)
                mstore(1219, 'c')
                mstore(1220, t13)
                mstore(1228, 'transform="')
                mstore(1239, t2)
                mstore(1245, '(45 -19.645 218.14)" ')
                mstore(1266, t10)
                mstore(1279, 'c')
                mstore(1280, t13)
                mstore(1288, 'transform="')
                mstore(1299, t2)
                mstore(1305, '(90 -30 230)" ')
                mstore(1319, t10)
                mstore(1332, 'c')
                mstore(1333, t13)
                mstore(1341, 'transform="')
                mstore(1352, t2)
                mstore(1358, '(-48 -37.302 218.45)" ')
                mstore(1380, t10)
                mstore(1393, 'c"/></g><g id="1')
                mstore(1409, t14)
                mstore(1416, 'fill="#f57914" ')
                mstore(1431, t10)
                mstore(1444, 'l')
                mstore(1445, t13)
                mstore(1453, 'transform="matrix(.44463 1.2216 ')
                mstore(1485, '-1.0337 .37622 7471.6 -2470.6)" ')
                mstore(1517, 'x="-2000"')
                mstore(1526, t8)
                mstore(1541, ' ')
                mstore(1542, t10)
                mstore(1555, 'e"/></g><g id="2"')
                mstore(1572, t1)
                mstore(1584, 'translate(5150 4100)')
                mstore(1604, t14)
                mstore(1611, 'fill="#ed1c24" ')
                mstore(1626, t10)
                mstore(1639, 'g')
                mstore(1640, t13)
                mstore(1648, 'fill="#8c1b85" ')
                mstore(1663, t10)
                mstore(1676, 'f"/></g><g id="3')
                mstore(1692, t14)
                mstore(1699, 'transform="scale(.9 -.7)" x="960')
                mstore(1731, '" y="-4400"')
                mstore(1742, t6)
                mstore(1757, ' ')
                mstore(1758, t10)
                mstore(1771, 'a')
                mstore(1772, t13)
                mstore(1780, 'transform="scale(.7 -.7) ')
                mstore(1805, t2)
                mstore(1811, '(40 14283 5801)"')
                mstore(1827, t4)
                mstore(1842, ' ')
                mstore(1843, t10)
                mstore(1856, 'a"/></g><g id="4"')
                mstore(1873, t1)
                mstore(1885, t2)
                mstore(1891, '(125 3495.9 1947) scale(.6)')
                mstore(1918, t14)
                mstore(1925, 'fill="#f57914" ')
                mstore(1940, t10)
                mstore(1953, 'g')
                mstore(1954, t13)
                mstore(1962, 'fill="#8c1b85" ')
                mstore(1977, t10)
                mstore(1990, 'f"/></g><g id="5')
                mstore(2006, t14)
                mstore(2013, 'transform="matrix(-1.4095 .51303')
                mstore(2045, ' .0684 -1.4083 12071 6071.6)" x=')
                mstore(2077, '"-2100" y="1650"')
                mstore(2093, t9)
                mstore(2106, t10)
                mstore(2119, 'e"/>')
                mstore(2123, t11)
                mstore(2135, '6470" cy="1780" r="130"')
                mstore(2158, t6)
                mstore(2173, '/>')
                mstore(2175, t11)
                mstore(2187, '5770" cy="1350" r="70"')
                mstore(2209, t4)
                mstore(2224, '/>')
                mstore(2226, t11)
                mstore(2238, '5820" cy="1150" r="70"')
                mstore(2260, t4)
                mstore(2275, '/>')
                mstore(2277, t11)
                mstore(2289, '5720" cy="1550" r="70"')
                mstore(2311, t4)
                mstore(2326, '/>')
                mstore(2328, t11)
                mstore(2340, '6190" cy="1700" r="80"')
                mstore(2362, t4)
                mstore(2377, '/></g><g id="6">')
                mstore(2393, t11)
                mstore(2405, '6000" cy="1650" r="80"')
                mstore(2427, t6)
                mstore(2442, '/>')
                mstore(2444, t11)
                mstore(2456, '6370" cy="200" r="80"')
                mstore(2477, t3)
                mstore(2492, '/><path d="M6300 1710c-7-13-6-26')
                mstore(2524, '-4-41s9-26 17-37c6-11 22-17 41-2')
                mstore(2556, '4 17-4 44 9 79 41 35 33 63 131 8')
                mstore(2588, '5 299-92-124-153-194-183-207-4-2')
                mstore(2620, '-9-4-13-6-10-4-17-13-22-24m-470-')
                mstore(2652, '161c-26 2-50-6-72-26-19-17-33-39')
                mstore(2684, '-39-65-4-13 20-164 72-452 50-286')
                mstore(2716, ' 181-530 393-731-201 421-292 709')
                mstore(2748, '-277 860 15 150 20 247 13 284-6 ')
                mstore(2780, '37-17 68-28 90-15 24-37 39-61 41')
                mstore(2812, '"')
                mstore(2813, t4)
                mstore(2828, '/></g><g id="7')
                mstore(2842, t14)
                mstore(2849, 'transform="scale(.9 1.6)" x="960')
                mstore(2881, '" y="-840"')
                mstore(2891, t6)
                mstore(2906, ' ')
                mstore(2907, t10)
                mstore(2920, 'a')
                mstore(2921, t13)
                mstore(2929, 'transform="')
                mstore(2940, t2)
                mstore(2946, '(-50 6340 4600)"')
                mstore(2962, t9)
                mstore(2975, t10)
                mstore(2988, 'h')
                mstore(2989, t13)
                mstore(2997, 'transform="scale(.9 1.3) ')
                mstore(3022, t2)
                mstore(3028, '(30 6740 4300)" x="400" y="-530"')
                mstore(3060, t4)
                mstore(3075, ' ')
                mstore(3076, t10)
                mstore(3089, 'a"/></g><g id="8"')
                mstore(3106, t1)
                mstore(3118, 'translate(7100 5100)')
                mstore(3138, t14)
                mstore(3145, 'transform="')
                mstore(3156, t2)
                mstore(3162, '(-100 -158.56 64.887) scale(.6)"')
                mstore(3194, t4)
                mstore(3209, ' ')
                mstore(3210, t10)
                mstore(3223, 'd')
                mstore(3224, t13)
                mstore(3232, 'transform="')
                mstore(3243, t2)
                mstore(3249, '(125) scale(.6)" ')
                mstore(3266, t10)
                mstore(3279, 'j')
                mstore(3280, t13)
                mstore(3288, 'transform="scale(-.6 .6) ')
                mstore(3313, t2)
                mstore(3319, '(-55 -272.14 -141.67)" ')
                mstore(3342, t10)
                mstore(3355, 'j"/></g><g id="j')
                mstore(3371, t14)
                mstore(3378, 'fill="#0994d3" ')
                mstore(3393, t10)
                mstore(3406, 'g')
                mstore(3407, t13)
                mstore(3415, 'fill="#8c1b85" ')
                mstore(3430, t10)
                mstore(3443, 'f"/></g><g id="l">')
                mstore(3461, t11)
                mstore(3473, '5630" cy="4060" r="140"/>')
                mstore(3498, t11)
                mstore(3510, '5400" cy="3850" r="110"/>')
                mstore(3535, t11)
                mstore(3547, '5270" cy="3600" r="90"/>')
                mstore(3571, t11)
                mstore(3583, '5180" cy="3350" r="70"/>')
                mstore(3607, t11)
                mstore(3619, '5150" cy="3150" r="60"/></g><g i')
                mstore(3651, 'd="q">')
                mstore(3657, t11)
                mstore(3669, '6840" cy="3060" r="165" style="f')
                mstore(3701, 'ill:#ed1344"/>')
                mstore(3715, t11)
                mstore(3727, '6770" cy="3335" r="165" style="f')
                mstore(3759, 'ill:#ed1344"/>')
                mstore(3773, t11)
                mstore(3785, '6640" cy="3535" r="165" style="f')
                mstore(3817, 'ill:#ed1344"/>')
                mstore(3831, t11)
                mstore(3843, '6395" cy="3690" r="165" style="f')
                mstore(3875, 'ill:#ed1344"/>')
                mstore(3889, t11)
                mstore(3901, '6840" cy="3060" r="80" style="fi')
                mstore(3933, 'll:#0994d3"/>')
                mstore(3946, t11)
                mstore(3958, '6770" cy="3335" r="80" style="fi')
                mstore(3990, 'll:#0994d3"/>')
                mstore(4003, t11)
                mstore(4015, '6640" cy="3535" r="80" style="fi')
                mstore(4047, 'll:#0994d3"/>')
                mstore(4060, t11)
                mstore(4072, '6395" cy="3690" r="80" style="fi')
                mstore(4104, 'll:#0994d3"/></g><g id="p')
                mstore(4129, t14)
                mstore(4136, t10)
                mstore(4149, 'q')
                mstore(4150, t13)
                mstore(4158, t10)
                mstore(4171, 'q"')
                mstore(4173, t1)
                mstore(4185, t2)
                mstore(4191, '(180 6150 3060)')
                mstore(4206, t13)
                mstore(4214, t10)
                mstore(4227, 'q"')
                mstore(4229, t1)
                mstore(4241, t2)
                mstore(4247, '(270 6150 3060)')
                mstore(4262, t13)
                mstore(4270, t10)
                mstore(4283, 'q"')
                mstore(4285, t1)
                mstore(4297, t2)
                mstore(4303, '(90 6150 3060)"/></g>')
                mstore(4324, t12)
                mstore(4334, 'n" d="M7507 5582c-168 33-340 50-')
                mstore(4366, '517 52-177-2-349-20-517-52-345-6')
                mstore(4398, '8-659-244-941-530-284-286-469-55')
                mstore(4430, '6-556-814-20-57-35-116-50-175-33')
                mstore(4462, '-138-48-284-46-436 0-452 74-803 ')
                mstore(4494, '220-1056 98-168 133-334 102-495-')
                mstore(4526, '30-159 20-308 148-441 68-68 122-')
                mstore(4558, '127 166-177 41-46 74-85 96-116 4')
                mstore(4590, '4-255 120-526 229-807 109-282 30')
                mstore(4622, '1-443 576-489 39-6 76-11 111-18 ')
                mstore(4654, '308-37 613-37 921 0 35 7 72 11 1')
                mstore(4686, '13 17 273 46 465 207 574 489 109')
                mstore(4718, ' 281 185 552 229 807 46 63 133 1')
                mstore(4750, '59 262 292s179 282 148 441c-30 1')
                mstore(4782, '61 4 327 103 495 146 253 220 605')
                mstore(4814, ' 223 1056-2 218-35 421-98 611-89')
                mstore(4846, ' 258-275 528-556 814-283 286-598')
                mstore(4878, ' 463-941 530" fill="#fcca07"/>')
                mstore(4908, t12)
                mstore(4918, 'm" d="M7243 1429c-2 24-10 43-26 ')
                mstore(4950, '61-15 17-34 26-54 26h-67c-21 0-4')
                mstore(4982, '1-9-57-26-15-17-24-37-22-61v-260')
                mstore(5014, 'c-2-24 6-44 22-61 15-17 35-26 57')
                mstore(5046, '-26h68c20 0 39 9 54 26s24 37 26 ')
                mstore(5078, '61v260m-9-487c-2 22-9 41-24 57-1')
                mstore(5110, '5 17-33 26-52 26h-65c-20 0-37-9-')
                mstore(5142, '52-26-15-15-22-35-22-57V695c0-22')
                mstore(5174, ' 6-41 22-57 15-15 33-24 52-24h65')
                mstore(5206, 'c20 0 37 8 52 24 15 15 22 35 24 ')
                mstore(5238, '57v246m82 86c-15-20-22-39-22-63l')
                mstore(5270, '.01-260c0-24 6-41 22-57 15-13 30')
                mstore(5302, '-17 50-13l59 13c20 4 35 15 50 35')
                mstore(5334, ' 6 11 13 24 15.34 37 2 9 4 17 4 ')
                mstore(5366, '24v242c0 24-6 41-20 57-15 15-30 ')
                mstore(5398, '22-50 19m263 60h-59c-20 0-37-9-5')
                mstore(5430, '4-24-15-15-22-33-22-52V816c0-17 ')
                mstore(5462, '6-35 22-48 15-11 31-15 46-13h9l5')
                mstore(5494, '8 15c17 4 32 13 46 28 13 17 20 3')
                mstore(5526, '5 20 52v204c0 20-6 35-20 48-13 1')
                mstore(5558, '3-28 20-46 20m294 373c-11 11-24 ')
                mstore(5590, '17-39 17h-50c-17 0-33-6-48-20-13')
                mstore(5622, '-13-20-28-20-48v-201c0-15 6-28 2')
                mstore(5654, '0-39 11-9 24-13 39-13h9l50 13c15')
                mstore(5686, ' 2 28 11 39 26s17 31 17 46v177c0')
                mstore(5718, ' 15-6 31-17 41m-480-65c0 22-7 41')
                mstore(5750, '-20 57-15 18-30 26-48 26h-58c-20')
                mstore(5782, ' 0-37-9-52-26s-22-37-22-61v-260c')
                mstore(5814, '0-24 6-43 22-59 15-15 33-20 52-1')
                mstore(5846, '7l59 6c17 2 33 13 48 33 13 17 20')
                mstore(5878, ' 37 20 59v242m381-262c-17-2-33-9')
                mstore(5910, '-48-24-13-15-20-30-17-50V892c-2-')
                mstore(5942, '15 4-28 17-37s26-13 41-11c2 2 4 ')
                mstore(5974, '2 6 2l52 17c15 7 28 15 39 31 11 ')
                mstore(6006, '15 17 33 17 48v178c0 15-6 28-17 ')
                mstore(6038, '39s-24 15-39 13l-52-4M7584 1488c')
                mstore(6070, '-15-15-22-33-22-52v-229c0-20 6-3')
                mstore(6102, '5 22-48 13-11 28-15 44-13h11l57 ')
                mstore(6134, '15c17 4 33 13 48 28 13 17 20 35 ')
                mstore(6166, '20 52v203c0 19-6 35-20 48-15 13-')
                mstore(6198, '30 20-48 20h-57c-20 0-39-9-55-24')
                mstore(6230, '"/>')
                mstore(6233, t12)
                mstore(6243, 'd" d="M0 0c4-54-1-112-17-177-9-4')
                mstore(6275, '0-18-73-31-103 7-32 21-61 36-83 ')
                mstore(6307, '28-48 53-71 78-73 22 4 39 31 54 ')
                mstore(6339, '81 8 34 12 75 11 115-19 22-36 47')
                mstore(6371, '-51 74C43-107 14-51 0 0"/>')
                mstore(6397, t12)
                mstore(6407, 'c" d="M250-340c41-36 75-48 96-40')
                mstore(6439, ' 21 12 25 46 14 95-5 30-15 59-28')
                mstore(6471, ' 88-8 17-14 37-25 56-8 17-20 34-')
                mstore(6503, '30 54-44 68-91 124-140 163-20 16')
                mstore(6535, '-40 28-55 36-15 4-27 7-37 4l-2-2')
                mstore(6567, 'c-4 0-7-5-9-7-7-9-10-21-12-38 0-')
                mstore(6599, '14 1-30 6-52 12-58 40-124 83-194')
                mstore(6631, ' 5-7 12-13 17-20 10-19 23-40 39-')
                mstore(6663, '57 28-33 56-63 85-86"/>')
                mstore(6686, t12)
                mstore(6696, 'o" d="M5960 3720c-33 9-76 20-127')
                mstore(6728, ' 33-94 28-150 35-166 24-17-11-28')
                mstore(6760, '-65-33-159-4-59-9-109-11-148-33-')
                mstore(6792, '11-72-26-122-46-92-33-142-61-150')
                mstore(6824, '-81-7-17 17-68 68-148 33-50 59-9')
                mstore(6856, '2 78-124-20-28-44-65-72-111-55-8')
                mstore(6888, '1-78-131-72-150 4-20 50-46 140-7')
                mstore(6920, '8 55-22 100-41 138-57 2-26 4-59 ')
                mstore(6952, '7-96v-35c4-98 15-153 31-164 15-1')
                mstore(6984, '1 68-6 161 17 57 15 105 26 142 3')
                mstore(7016, '5 22-26 50-61 83-103 61-76 102-1')
                mstore(7048, '13 122-116 20 0 59 37 120 109 37')
                mstore(7080, ' 46 68 85 94 113 33-7 76-20 129-')
                mstore(7112, '35 94-24 148-33 166-22 15 11 26 ')
                mstore(7144, '65 33 159 0 15 0 28 2 39 2 41 4 ')
                mstore(7176, '79 6 107 33 13 74 28 124 48 92 3')
                mstore(7208, '5 140 61 146 79 6 20-17 68-68 14')
                mstore(7240, '8-33 50-57 92-76 124 18 30 41 68')
                mstore(7272, ' 72 111 52 81 76 131 72 150-6 20')
                mstore(7304, '-52 48-142 81-54 22-100 39-135 5')
                mstore(7336, '4-2 35-4 78-6 133-4 98-15 153-30')
                mstore(7368, ' 164-15 13-70 6-161-17-59-15-107')
                mstore(7400, '-26-144-35-22 26-50 61-83 103-61')
                mstore(7432, ' 76-100 116-120 116s-61-37-120-1')
                mstore(7464, '11c-37-46-70-83-96-111"/>')
                mstore(7489, t12)
                mstore(7499, 'e" d="M6500 4100c-25 8-53 6-79-3')
                mstore(7531, '-31-8-53-28-62-53-11-25-8-53 5-7')
                mstore(7563, '8 11-22 31-39 56-53 11-6 25-11 3')
                mstore(7595, '9-17 87-31 182-90 289-177-53 213')
                mstore(7627, '-120 336-205 367-14 6-31 11-45 1')
                mstore(7659, '4"/>')
                mstore(7663, t12)
                mstore(7673, 'h" d="M5769 4876c274 21 415 85 6')
                mstore(7705, '92-127-115 159-241 266-379 326-8')
                mstore(7737, '9 36-218 80-316 63-70-13-117-37-')
                mstore(7769, '136-65-25-33-34-68-26-103s29-62 ')
                mstore(7801, '66-80c28-16 62-22 100-14"/>')
                mstore(7828, t12)
                mstore(7838, 'a" d="M6740 4300c-17-22-25-48-28')
                mstore(7870, '-78v-50c-3-98 34-230 109-401 62 ')
                mstore(7902, '168 93 303 92 400v50c-3 31-14 56')
                mstore(7934, '-31 78-20 25-45 39-70 39-28 0-53')
                mstore(7966, '-14-73-39"/><g id="z')
                mstore(7986, t14)
                mstore(7993, 'transform="')
                mstore(8004, t2)
                mstore(8010, '(130 6130 3100)"')
                mstore(8026, t7)
                mstore(8041, ' ')
                mstore(8042, t10)
                mstore(8055, 'l"/>')
                mstore(8059, t11)
                mstore(8071, '6665" cy="4440" r="80"')
                mstore(8093, t6)
                mstore(8108, '/>')
                mstore(8110, t11)
                mstore(8122, '6370" cy="4510" r="80"')
                mstore(8144, t6)
                mstore(8159, '/>')
                mstore(8161, t11)
                mstore(8173, '6480" cy="4360" r="60"')
                mstore(8195, t6)
                mstore(8210, '/><use')
                mstore(8216, t6)
                mstore(8231, ' ')
                mstore(8232, t10)
                mstore(8245, 'a"/>')
                mstore(8249, t11)
                mstore(8261, '7000" cy="3900" r="50"')
                mstore(8283, t6)
                mstore(8298, '/>')
                mstore(8300, t0)
                mstore(8316, t2)
                mstore(8322, '(-20 6500 4100)" x="110" y="50"')
                mstore(8353, t4)
                mstore(8368, ' ')
                mstore(8369, t10)
                mstore(8382, 'e')
                mstore(8383, t13)
                mstore(8391, 'fill="#ed1c24" ')
                mstore(8406, t10)
                mstore(8419, 'h"/>')
                mstore(8423, t11)
                mstore(8435, '5350" cy="2550" r="80"')
                mstore(8457, t4)
                mstore(8472, '/>')
                mstore(8474, t11)
                mstore(8486, '5420" cy="2280" r="130"')
                mstore(8509, t4)
                mstore(8524, '/>')
                mstore(8526, t11)
                mstore(8538, '5950" cy="4500" r="50"')
                mstore(8560, t4)
                mstore(8575, '/><path d="M5844 4593c36 36 81 5')
                mstore(8607, '3 134 56s90-17 109-53c20-36 14-7')
                mstore(8639, '3-17-104s-39-62-25-90c11-25 42-3')
                mstore(8671, '4 92-20s79 53 81 118c3 68-20 118')
                mstore(8703, '-73 151-53 34-109 50-174 50s-120')
                mstore(8735, '-22-168-70-70-104-70-168 22-120 ')
                mstore(8767, '70-168 140-90 280-132c126-42 252')
                mstore(8799, '-115 379-221-126 208-235 322-325')
                mstore(8831, ' 348-93 25-171 48-241 67s-106 56')
                mstore(8863, '-106 106 17 93 53 129"')
                mstore(8885, t6)
                mstore(8900, '/>')
                mstore(8902, t11)
                mstore(8914, '6160" cy="3050" r="600"')
                mstore(8937, t8)
                mstore(8952, '/><path d="M7145 1722c59 0 109 2')
                mstore(8984, '6 151 76 41 50 61 113 61 185s-19')
                mstore(9016, ' 135-61 185c-41 50-120 144-236 2')
                mstore(9048, '79-22 26-41 46-59 59-17-13-37-33')
                mstore(9080, '-59-59-116-135-194-229-236-279-4')
                mstore(9112, '1-50-63-113-61-185-2-72 20-135 6')
                mstore(9144, '1-186 41-50 92-76 151-76 55 0 10')
                mstore(9176, '3 24 144 70"')
                mstore(9188, t8)
                mstore(9203, '/><use')
                mstore(9209, t9)
                mstore(9222, t10)
                mstore(9235, 'm')
                mstore(9236, t13)
                mstore(9244, t10)
            }
            res := 480
            mstore(0x40, 30000)
            // Token information
            // tokenId % 1,000,000 = index of token (i.e. how many were minted before this token)
            // (tokenId / 1,000,000) % 100 = week in which sacrificed occured (from game start)
            // (tokenId / 100,000,000) = number of cultists remaining after sacrifice
            let countdown := mod(div(tokenId, 1000000), 100)

            // SHINY???
            if lt(countdown, 52) {
                // NO SHINY FOR YOU
                mstore8(898, 0x30)
            }
            mstore(0x00, tokenId)
            mstore(0x20, 5148293888310004) // some salt for your token
            let seed := keccak256(0x00, 0x40)
            // Store num living cultists at 0x00, not enough vars
            mstore(0x00, div(tokenId, 100000000))

            let table1 := mload(0x40)
            let table2 := add(0x500, table1)

            let phrase1Seed := seed
            let phrase2Seed := shr(16, seed)
            let phrase3Seed := shr(32, seed)
            let phrase4Seed := shr(48, seed)
            let descSeed := shr(64, seed)
            let eyeSeed := shr(128, seed)
            let rare1Seed := shr(144, seed)
            let hueSeed := shr(160, seed)

            let p := 9257

            mstore8(p, 0x30) // "0"
            if mod(descSeed, 3) {
                mstore8(p, add(0x30, mod(descSeed, 3))) // "1" or "2"
            }
            p := add(p, 0x01)

            let temp := '"/><use xlink:href="#'
            mstore(p, temp)
            p := add(p, 21)

            mstore8(p, 0x30) // "0"
            if mod(shr(16, descSeed), 3) {
                mstore8(p, add(0x32, mod(shr(16, descSeed), 3))) // "3" or "4"
            }
            p := add(p, 0x01)

            mstore(p, temp)
            p := add(p, 21)

            mstore8(p, 0x30) // "0"
            if mod(shr(32, descSeed), 3) {
                mstore8(p, add(0x34, mod(shr(32, descSeed), 3))) // "5" or "6"
            }
            p := add(p, 0x01)

            mstore(p, temp)
            p := add(p, 21)
            mstore8(p, 0x30) // "0"
            if mod(shr(48, descSeed), 3) {
                mstore8(p, add(0x36, mod(shr(48, descSeed), 3))) // "7" or "8"
            }
            p := add(p, 1)

            mstore(p, '"/></g></defs><g>')

            p := add(p, 17)

            // ARE WE BOUNCY???!!
            {
                /**
                    IF LIVINGCULTISTS > 20000 ROLL 1%
                    IF LIVINGCULTISTS < 20000 ROLL 2%
                    IF LIVINGCULTISTS < 10000 ROLL 4%
                    IF LIVINGCULTISTS <  2500 ROLL 8%
                    IF LIVINGCULTISTS <  1250 ROLL 16%
                    IF LIVINGCULTISTS <   625 ROLL 33%
                    IF LIVINGCULTISTS <   200 ROLL 100%
                 */

                let isBouncy := eq(mod(shr(176, seed), 100), 0)
                if lt(mload(0x00), 20000) {
                    isBouncy := eq(mod(shr(176, seed), 50), 0)
                }
                if lt(mload(0x00), 10000) {
                    isBouncy := eq(mod(shr(176, seed), 25), 0)
                }
                if lt(mload(0x00), 2500) {
                    isBouncy := eq(mod(shr(176, seed), 12), 0)
                }
                if lt(mload(0x00), 1250) {
                    isBouncy := eq(mod(shr(176, seed), 6), 0)
                }
                if lt(mload(0x00), 625) {
                    isBouncy := eq(mod(shr(176, seed), 3), 0)
                }
                if lt(mload(0x00), 200) {
                    isBouncy := 1
                }
                if isBouncy {
                    // YESSSS WE BOUNCY

                    let anim1 := '<animateTransform id="anim1" att'
                    let anim2 := 'ributeName="transform" attribute'
                    let anim3 := 'Type="XML" type="rotate"  from="'
                    let anim5 := ' repeatCount="repeat" dur="1s" b'
                    let anim6 := 'egin="0s;anim2.end"/>'
                    mstore(p, anim1)
                    mstore(add(p, 32), anim2)
                    mstore(add(p, 64), anim3)
                    mstore(add(p, 96), '-20 6000 5000" to="20 8000 5000"')
                    mstore(add(p, 128), anim5)

                    mstore(add(p, 160), anim6)
                    mstore(add(p, 181), anim1)
                    mstore8(add(p, 207), 0x32)
                    mstore(add(p, 213), anim2)
                    mstore(add(p, 245), anim3)
                    mstore(add(p, 277), '20 8000 5000" to="-20 6000 5000"')

                    mstore(add(p, 309), anim5)
                    mstore(add(p, 341), 'egin="anim1.end"/>')
                    p := add(p, 359)
                }
                mstore(p, '<g filter="invert(')
                p := add(p, 18)
            }
            {
                // 1% change of inverting colours
                // increases to 50% iff week counter is 10 or greater
                let isWeekTenYet := gt(countdown, 9)
                let invertProbInv := add(mul(isWeekTenYet, 2), mul(iszero(isWeekTenYet), 100))
                let inverted := eq(mod(rare1Seed, invertProbInv), 0)
                mstore8(p, add(0x30, inverted)) // "0" or "1"
                mstore(add(p, 1), ') hue-rotate(')
                let hue := mul(30, mod(hueSeed, 12)) // 0 to 360 in steps of 12
                mstore8(add(p, 0xe), add(0x30, mod(div(hue, 100), 10)))
                mstore8(add(p, 0xf), add(0x30, mod(div(hue, 10), 10)))
                mstore8(add(p, 0x10), add(0x30, mod(hue, 10)))
            }
            p := add(p, 17)
            let eye2
            {
                let eye1 := add(0x6f, and(eyeSeed, 1)) // "o" or "p"
                {
                    let hasMixedEyes := eq(mod(shr(1, eyeSeed), 10), 0)
                    switch hasMixedEyes
                    case 1 {
                        switch eq(eye1, 0x6f)
                        case 1 {
                            eye2 := 0x70
                        }
                        case 0 {
                            eye2 := 0x6f
                        }
                    }
                    case 0 {
                        eye2 := eye1
                    }
                }
                mstore(p, 'deg)"><use xlink:href="#n')
                mstore(add(p, 25), temp)

                p := add(p, 46)

                mstore8(p, eye1) // "o" or "p"
                mstore(add(p, 1), '" style="fill:#')
                mstore(0x00, 'ed1c24')
                mstore(0x20, '9addf0')
                mstore(add(p, 16), mload(shl(5, and(shr(2, eyeSeed), 1))))

                p := add(p, 22)
            }
            /**
            Eye1 Animation
             */
            {
                /**
                 * ARE THE EYES SPINNY OR NOT?
                 * IF NOT YET WEEK 12 ROLL AT 0.5%
                 * IF AT LEAST WEEK 12 ROLL AT 2%
                 * IF AT LEAST WEEK 24 ROLL AT 5%
                 * IF AT LEAST WEEK 36 ROLL AT 20%
                 * IF AT LEAST WEEK 48 ROLL AT 33%
                 * IF WEEK 52 100% CONGRATULATIONS YOU ARE VERY SPINNY
                 */
                let rotatingEyes := mul(lt(countdown, 13), eq(mod(shr(3, eyeSeed), 200), 0))
                rotatingEyes := add(rotatingEyes, mul(gt(countdown, 11), eq(0, mod(shr(3, eyeSeed), 50))))
                rotatingEyes := add(rotatingEyes, mul(gt(countdown, 23), eq(0, mod(shr(3, eyeSeed), 20))))
                rotatingEyes := add(rotatingEyes, mul(gt(countdown, 35), eq(0, mod(shr(3, eyeSeed), 5))))
                rotatingEyes := add(rotatingEyes, mul(gt(countdown, 47), eq(0, mod(shr(3, eyeSeed), 3))))
                rotatingEyes := add(rotatingEyes, gt(countdown, 51))
                rotatingEyes := mul(5, gt(rotatingEyes, 0)) // set to 5s duration if any of the above triggers are hit

                let anim1 := '"><animateTransform attributeNam'
                let anim2 := 'e="transform" attributeType="XML'
                let anim3 := '" type="rotate" from="360 6160 3'
                let anim4 := '050" to="0 6160 3050" repeatCoun'
                let anim5 := 't="indefinite" dur="'

                mstore(p, anim1)
                mstore(add(p, 32), anim2)
                mstore(add(p, 64), anim3)
                mstore(add(p, 96), anim4)
                mstore(add(p, 128), anim5)

                mstore8(add(p, 148), add(0x30, rotatingEyes))
                mstore(add(p, 149), 's" /></use><use xlink:href="#')
                // 179
                p := add(p, 157)
                mstore(add(p, 21), 'z"/><g transform="matrix(-1 0 0 ')
                mstore(add(p, 53), '1 14000 0)"><use xlink:href="#')

                p := add(p, 83)
                mstore8(p, eye2) // "1" or "2"
                mstore(add(p, 1), '" style="fill:#')
                mstore(add(p, 16), mload(shl(5, and(shr(11, eyeSeed), 1))))

                p := add(p, 22)

                mstore(p, anim1)
                mstore(add(p, 32), anim2)
                mstore(add(p, 64), anim3)
                mstore(add(p, 96), anim4)
                mstore(add(p, 128), anim5)
                mstore8(add(p, 148), add(0x30, rotatingEyes))
                mstore(add(p, 149), 's"/></use><use xlink:href="#')
            }
            p := add(p, 156)
            mstore(add(p, 21), 'z"/></g></g></g></g><text x="10"')
            mstore(add(p, 53), ' y="25" class="soft">')
            p := add(p, 74)

            mstore(p, 'Week ')
            p := add(p, 5)

            switch gt(countdown, 9)
            case 1 {
                mstore8(p, add(0x30, mod(div(countdown, 10), 10))) // 0 or 1
                mstore8(add(p, 1), add(0x30, mod(countdown, 10))) // 0 or 1
                p := add(p, 2)
            }
            case 0 {
                mstore8(p, add(0x30, mod(countdown, 10))) // 0 or 1
                p := add(p, 1)
            }
            mstore(p, '</text><text x="690" y="25" clas')
            mstore(add(p, 32), 's="soft" text-anchor="end">')
            p := add(p, 59)

            {
                let livingCultists := div(tokenId, 100000000) // 100 million
                switch eq(livingCultists, 0)
                case 1 {
                    mstore8(p, 0x30)
                    p := add(p, 1)
                }
                default {
                    let t := livingCultists
                    let len := 0
                    for {

                    } t {

                    } {
                        t := div(t, 10)
                        len := add(len, 1)
                    }
                    for {
                        let i := 0
                    } lt(i, len) {
                        i := add(i, 1)
                    } {
                        mstore8(add(p, sub(sub(len, 1), i)), add(mod(livingCultists, 10), 0x30))
                        livingCultists := div(livingCultists, 10)
                    }
                    p := add(p, len)
                }

                // mstore(p, ' Cultist')
                //   mstore(add(p, 8), mul(iszero(oneCultist), 's'))
                //  p := add(p, iszero(oneCultist))
                //  mstore(add(p, 8), ' Remaining')
                //  p := add(p, 18)
            }
            mstore(p, '</text><text x="350" y="70" clas')
            mstore(add(p, 32), 's="heavy" text-anchor="middle">')
            p := add(p, 63)

            mstore(table1, 0)
            mstore(add(table1, 32), 'Willingly ')
            mstore(add(table1, 64), 'Enthusiastically ')
            mstore(add(table1, 96), 'Cravenly ')
            mstore(add(table1, 128), 'Gratefully ')
            mstore(add(table1, 160), 'Vicariously ')
            mstore(add(table1, 192), 'Shockingly ')
            mstore(add(table1, 224), 'Gruesomly ')
            mstore(add(table1, 256), 'Confusingly ')
            mstore(add(table1, 288), 'Angrily ')
            mstore(add(table1, 320), 'Mysteriously ')
            mstore(add(table1, 352), 'Shamefully ')
            mstore(add(table1, 384), 'Allegedly ')

            mstore(table2, 0)
            mstore(add(table2, 32), 10)
            mstore(add(table2, 64), 17)
            mstore(add(table2, 96), 9)
            mstore(add(table2, 128), 11)
            mstore(add(table2, 160), 12)
            mstore(add(table2, 192), 11)
            mstore(add(table2, 224), 10)
            mstore(add(table2, 256), 12)
            mstore(add(table2, 288), 8)
            mstore(add(table2, 320), 13)
            mstore(add(table2, 352), 11)
            mstore(add(table2, 384), 10)

            let idx := mul(iszero(mod(phrase1Seed, 10)), add(0x20, shl(5, mod(shr(8, phrase1Seed), 12))))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))

            mstore(add(table1, 32), 'Banished To The Void Using')
            mstore(add(table1, 64), 'Crushed Under The Weight Of')
            mstore(add(table1, 96), 'Devoured By')
            mstore(add(table1, 128), 'Erased From Existence By')
            mstore(add(table1, 160), 'Extinguished By')
            mstore(add(table1, 192), 'Squished Into Nothingness By')
            mstore(add(table1, 224), 'Obliterated By')
            mstore(add(table1, 256), 'Ripped Apart By')
            mstore(add(table1, 288), 'Sacrificed In The Service Of')
            mstore(add(table1, 320), 'Slaughtered Defending')
            mstore(add(table1, 352), 'Suffered 3rd Degree Burns From')
            mstore(add(table1, 384), 'Torn To Shreds By')
            mstore(add(table1, 416), 'Vanished At A Party Hosted By')
            mstore(add(table1, 448), 'Vivisected Via')
            mstore(add(table1, 480), 'Lost Everything To')
            mstore(add(table1, 512), "Just Couldn't Cope With")
            mstore(add(table1, 544), 'Tried To Mess With')
            mstore(add(table1, 576), 'Scared To Death By')
            mstore(add(table1, 608), '"Dissapeared" For Sharing')
            mstore(add(table1, 640), 'Caught Red-Handed With')
            mstore(add(table1, 672), 'Caught Stealing')
            mstore(add(table1, 704), 'Lost A Fatal Game Of')

            mstore(add(table2, 32), 26)
            mstore(add(table2, 64), 27)
            mstore(add(table2, 96), 11)
            mstore(add(table2, 128), 24)
            mstore(add(table2, 160), 15)
            mstore(add(table2, 192), 28)
            mstore(add(table2, 224), 14)
            mstore(add(table2, 256), 15)
            mstore(add(table2, 288), 28)
            mstore(add(table2, 320), 21)
            mstore(add(table2, 352), 30)
            mstore(add(table2, 384), 17)
            mstore(add(table2, 416), 29)
            mstore(add(table2, 448), 14)
            mstore(add(table2, 480), 18)
            mstore(add(table2, 512), 23)
            mstore(add(table2, 544), 18)
            mstore(add(table2, 576), 18)
            mstore(add(table2, 608), 25)
            mstore(add(table2, 640), 22)
            mstore(add(table2, 672), 15)
            mstore(add(table2, 704), 20)

            idx := add(0x20, shl(5, mod(phrase2Seed, 22)))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))
            let lengthByte := add(p, 25)
            mstore(p, '</text><text x="350" y="720" cla')
            mstore(add(p, 32), 'ss="superheavy" text-anchor="mid')
            mstore(add(p, 64), 'dle">')
            p := add(p, 69)
            mstore(add(table1, 32), 'Anarcho-Capitalist ')
            mstore(add(table1, 64), 'Artificial ')
            mstore(add(table1, 96), 'Another Round Of ')
            mstore(add(table1, 128), 'Extreme ')
            mstore(add(table1, 160), 'Ferocious ')
            mstore(add(table1, 192), 'French ')
            mstore(add(table1, 224), 'Funkadelic ')
            mstore(add(table1, 256), 'Grossly Incompetent ')
            mstore(add(table1, 288), 'Hysterical ')
            mstore(add(table1, 320), 'Award-Winning ')
            mstore(add(table1, 352), 'Morally Bankrupt ')
            mstore(add(table1, 384), 'Overcollateralized ')
            mstore(add(table1, 416), 'Politically Indiscreet ')
            mstore(add(table1, 448), 'Punch-Drunk ')
            mstore(add(table1, 480), 'Punk ')
            mstore(add(table1, 512), 'Time-Travelling ')
            mstore(add(table1, 544), 'Unsophisticated ')
            mstore(add(table1, 576), 'Volcanic ')
            mstore(add(table1, 608), 'Voracious ')
            mstore(add(table1, 640), "Grandmother's Leftover ")
            mstore(add(table1, 672), "M. Night Shyamalan's ")
            mstore(add(table1, 704), 'Emergency British ')
            mstore(add(table1, 736), 'Oecumenical ')
            mstore(add(table1, 768), 'Another Round Of ')
            mstore(add(table1, 800), 'Self-Obsessed ')
            mstore(add(table1, 832), 'Number-Theoretic ')
            mstore(add(table1, 864), 'Award-Winning ')
            mstore(add(table1, 896), 'Chemically Enriched ')
            mstore(add(table1, 928), 'Winnie-The-Pooh Themed ')
            mstore(add(table1, 960), 'Gratuitously Violent ')
            mstore(add(table1, 992), 'Extremely Aggressive ')
            mstore(add(table1, 1024), 'Enraged ')

            mstore(add(table2, 32), 19)
            mstore(add(table2, 64), 11)
            mstore(add(table2, 96), 17)
            mstore(add(table2, 128), 8)
            mstore(add(table2, 160), 10)
            mstore(add(table2, 192), 7)
            mstore(add(table2, 224), 11)
            mstore(add(table2, 256), 20)
            mstore(add(table2, 288), 11)
            mstore(add(table2, 320), 14)
            mstore(add(table2, 352), 17)
            mstore(add(table2, 384), 19)
            mstore(add(table2, 416), 23)
            mstore(add(table2, 448), 12)
            mstore(add(table2, 480), 5)
            mstore(add(table2, 512), 16)
            mstore(add(table2, 544), 16)
            mstore(add(table2, 576), 9)
            mstore(add(table2, 608), 10)
            mstore(add(table2, 640), 23)
            mstore(add(table2, 672), 21)
            mstore(add(table2, 704), 18)
            mstore(add(table2, 736), 12)
            mstore(add(table2, 768), 17)
            mstore(add(table2, 800), 14)
            mstore(add(table2, 832), 17)
            mstore(add(table2, 864), 14)
            mstore(add(table2, 896), 20)
            mstore(add(table2, 928), 23)
            mstore(add(table2, 960), 21)
            mstore(add(table2, 992), 21)
            mstore(add(table2, 1024), 8)

            let rare := eq(mod(rare1Seed, 100), 0) // mmmm rare communism...

            idx := mul(iszero(rare), add(0x20, shl(5, mod(phrase3Seed, 32))))
            let phrase3 := mload(add(table1, idx))
            let phrase3Len := mload(add(table2, idx))

            mstore(table1, 'The Communist Manifesto')
            mstore(add(table1, 32), 'Ballroom Dancing Fever')
            mstore(add(table1, 64), 'Canadians')
            mstore(add(table1, 96), 'Electric Jazz')
            mstore(add(table1, 128), 'Explosions')
            mstore(add(table1, 160), 'Insurance Fraud')
            mstore(add(table1, 192), 'Giant Gummy Bears')
            mstore(add(table1, 224), 'Gigawatt Lasers')
            mstore(add(table1, 256), 'Heavy Metal')
            mstore(add(table1, 288), 'Lifestyle Vloggers')
            mstore(add(table1, 320), 'Memes')
            mstore(add(table1, 352), 'Mathematicians')
            mstore(add(table1, 384), 'Rum Runners')
            mstore(add(table1, 416), 'Swine Flu')
            mstore(add(table1, 448), 'Theatre Critics')
            mstore(add(table1, 480), 'Trainee Lawyers')
            mstore(add(table1, 512), 'Twitterati')
            mstore(add(table1, 544), 'Velociraptors')
            mstore(add(table1, 576), 'Witches')
            mstore(add(table1, 608), 'Wizards')
            mstore(add(table1, 640), 'Z-List Celebrities')
            mstore(add(table1, 672), 'High-Stakes Knitting')
            mstore(add(table1, 704), 'Hardtack And Whiskey')
            mstore(add(table1, 736), 'Melodramatic Bullshit')
            mstore(add(table1, 768), '"Kidney Surprise"')
            mstore(add(table1, 800), 'Budget Cuts')
            mstore(add(table1, 832), 'Scurvy')
            mstore(add(table1, 864), 'Knife-Wielding Geese')
            mstore(add(table1, 896), 'Venture Capitalists')

            mstore(table2, 23)
            mstore(add(table2, 32), 22)
            mstore(add(table2, 64), 9)
            mstore(add(table2, 96), 13)
            mstore(add(table2, 128), 10)
            mstore(add(table2, 160), 15)
            mstore(add(table2, 192), 17)
            mstore(add(table2, 224), 15)
            mstore(add(table2, 256), 11)
            mstore(add(table2, 288), 18)
            mstore(add(table2, 320), 5)
            mstore(add(table2, 352), 14)
            mstore(add(table2, 384), 11)
            mstore(add(table2, 416), 9)
            mstore(add(table2, 448), 15)
            mstore(add(table2, 480), 15)
            mstore(add(table2, 512), 10)
            mstore(add(table2, 544), 13)
            mstore(add(table2, 576), 7)
            mstore(add(table2, 608), 7)
            mstore(add(table2, 640), 18)
            mstore(add(table2, 672), 20)
            mstore(add(table2, 704), 20)
            mstore(add(table2, 736), 21)
            mstore(add(table2, 768), 17)
            mstore(add(table2, 800), 11)
            mstore(add(table2, 832), 6)
            mstore(add(table2, 864), 20)
            mstore(add(table2, 896), 19)

            idx := mul(iszero(rare), add(0x20, shl(5, mod(phrase4Seed, 28))))
            let phrase4 := mload(add(table1, idx))
            let phrase4Len := mload(add(table2, idx))

            switch gt(add(phrase3Len, phrase4Len), SPLIT_PHRASE_ACROSS_LINES)
            case 1 {
                mstore(p, '<tspan>')
                mstore(add(p, 7), phrase3)
                p := add(add(p, 7), phrase3Len)
                mstore(p, '</tspan><tspan x="350" dy="1.2em')
                mstore(add(p, 32), '">')
                mstore(add(p, 34), phrase4)
                p := add(p, add(34, phrase4Len))
                mstore(p, '</tspan>')
                p := add(p, 8)
            }
            default {
                mstore(p, phrase3)
                mstore(add(p, phrase3Len), phrase4)
                p := add(p, add(phrase3Len, phrase4Len))
                mstore8(lengthByte, 0x35)
            }
            //   mstore(p, )
            //   p := add(p, )

            mstore(p, '</text></svg>')
            p := add(p, 13)

            mstore(res, sub(sub(p, res), 0x20))
        }
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        // 191 + length of tokenId
        uint256 strLen;
        uint256 tokenLen;
        uint256 id;
        assembly {
            id := mod(div(tokenId, 100000000), 1000000)
            let x := id
            for {

            } x {

            } {
                tokenLen := add(tokenLen, 1)
                x := div(x, 10)
            }
            tokenLen := add(tokenLen, iszero(id))
            strLen := add(tokenLen, 191)
        }
        string memory innerData = Base64.encode(getImgData(tokenId), strLen, 2);
        assembly {
            let ptr := add(innerData, 0x20)
            mstore(ptr, '{"name": "Cultist #')
            ptr := add(ptr, 19)
            switch iszero(id)
            case 1 {
                mstore8(ptr, 0x30)
                ptr := add(ptr, 1)
            }
            case 0 {
                let i := tokenLen
                for {

                } id {

                } {
                    i := sub(i, 1)
                    mstore8(add(ptr, i), add(mod(id, 10), 0x30))
                    id := div(id, 10)
                }
                ptr := add(ptr, tokenLen)
            }
            mstore(ptr, '", "description": "Doom Cult Soc')
            mstore(add(ptr, 0x20), 'iety is an interactive cult simu')
            mstore(add(ptr, 0x40), 'lator. Acquire and sacrifice cul')
            mstore(add(ptr, 0x60), 'tists to hasten the end of the w')
            mstore(add(ptr, 0x80), 'orld.", "image": "data:image/svg')
            mstore(
                add(ptr, 0xa0),
                or('+xml;base64,', and(0xffffffffffffffffffffffffffffffffffffffff, mload(add(ptr, 0xa0))))
            )

            mstore(innerData, add(mload(innerData), strLen))

            ptr := add(innerData, add(0x20, mload(innerData)))
            mstore(ptr, '"}')
            mstore(innerData, add(mload(innerData), 2))
        }
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(innerData, 0, 0)));
    }

    function imageURI(uint256 tokenId) public pure returns (string memory) {
        string memory result = Base64.encode(getImgData(tokenId), 26, 0);
        assembly {
            let ptr := add(result, 0x20)
            mstore(ptr, or('data:image/svg+xml;base64,', and(0xffffffffffff, mload(ptr))))
            mstore(result, add(mload(result), 26))
        }
        return result;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Original author Brecht Devos <[email protected]>
/// @notice alterations have been made to this code
library Base64 {
    /// @notice Encodes some bytes to the base64 representation
    // bytesBefore = prepend this many bytes to the output string
    // bytesAfter = append this many bytes to the output string
    function encode(
        string memory data,
        uint256 bytesBefore,
        uint256 bytesAfter
    ) internal pure returns (string memory result) {
        assembly {
            // ignore case where len = 0, shoudln't' happen with this contract
            let len := mload(data)
            // multiply by 4/3 rounded up
            let encodedLen := shl(2, div(add(len, 2), 3))

            // Add some extra buffer at the end
            result := mload(0x40)
            mstore(0x40, add(add(result, encodedLen), add(0x20, add(bytesBefore, bytesAfter))))

            let tablePtr := mload(0x40)
            mstore(add(tablePtr, 0x1f), 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef')
            mstore(add(tablePtr, 0x3f), 'ghijklmnopqrstuvwxyz0123456789+/')
            let resultPtr := add(result, add(32, bytesBefore))
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
    }
}