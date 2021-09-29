/**
 *Submitted for verification at Etherscan.io on 2021-09-29
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

    // potential max cultists
    uint256 internal constant MAX_CULTISTS = 30000;
    // how many do we actually start with? (phase 2 starts after 4 weeks regardless)
    uint256 public numStartingCultists;
    // If currentEpochTotalSacrificed <= lastEpocTotalSacrificed when epoch ends...kaboom!
    uint256 public currentEpochTotalSacrificed;
    uint256 public lastEpochTotalSacrificed;

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
        // Mmmmmmmmmmm slightly corrupt cheeky premine...
        _balances[address(0x24065d97424687EB9c83c87729fc1b916266F637)] = 400; // some extra for givaways
        _balances[address(0x1E11a16335E410EB5f4e7A781C6f069609E5946A)] = 200; // om
        _balances[address(0x9436630F6475D04E1d396a255f1321e00171aBFE)] = 200; // nom
        _balances[address(0x001aBc8196c60C2De9f9a2EdBdf8Db00C1Fa35ef)] = 200; // nom
        _balances[address(0x53DF4Fc15BdAfd4c01ca289797A85D00cC791810)] = 200; // *burp*
        _totalSupply = 1200;

        emit Transfer(address(0), address(0x24065d97424687EB9c83c87729fc1b916266F637), 400);
        emit Transfer(address(0), address(0x1E11a16335E410EB5f4e7A781C6f069609E5946A), 200);
        emit Transfer(address(0), address(0x9436630F6475D04E1d396a255f1321e00171aBFE), 200);
        emit Transfer(address(0), address(0x001aBc8196c60C2De9f9a2EdBdf8Db00C1Fa35ef), 200);
        emit Transfer(address(0), address(0x53DF4Fc15BdAfd4c01ca289797A85D00cC791810), 200);
    }

    function attractCultists() public onlyAsleep {
        assembly {
            if lt(MAX_CULTISTS, add(1, sload(_totalSupply.slot))) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 22)
                mstore(0x44, 'No remaining cultists!')
                revert(0x00, 0x64)
            }
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let balanceSlot := keccak256(0x00, 0x40)
            // _balances[msg.sender] += 3
            sstore(balanceSlot, add(sload(balanceSlot), 3))
            // _totalSupply += 3
            sstore(_totalSupply.slot, add(sload(_totalSupply.slot), 3))
            // emit Transfer(0, msg.sender, 3)
            mstore(0x00, 3)
            log3(0x00, 0x20, TRANSFER_SIG, 0, caller())
        }
    }

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
            sstore(numStartingCultists.slot, total)

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
            selfdestruct(0x00) // so long and thanks for all the fish
        }
    }

    /**
     * N.B. This function will only generate ONE NFT regardless of how many you sacrifice!!!!!
     *      If you want lots of NFTs call `sacrifice()` multiple times
     *      This function is for those who just want to run those numbers up for maximum chaos
     */
    function sacrificeManyButOnlyMintOneNFT(uint256 num) public onlyAwake {
        uint256 remainingCultists;
        uint256 sacrificedCultists;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let slot := keccak256(0x00, 0x40)
            let userBal := sload(slot)
            if or(lt(userBal, num), iszero(num)) {
                mstore(0x00, ERROR_SIG)
                mstore(0x04, 0x20)
                mstore(0x24, 21)
                mstore(0x44, 'Insufficient Cultists')
                revert(0x00, 0x64)
            }
            sstore(slot, sub(userBal, num))
            sstore(currentEpochTotalSacrificed.slot, add(sload(currentEpochTotalSacrificed.slot), num))
            remainingCultists := sub(sload(_totalSupply.slot), num)
            sstore(_totalSupply.slot, remainingCultists)
            sacrificedCultists := sub(sload(numStartingCultists.slot), remainingCultists)
        }
        doomCultSociety.mint(doomCounter, remainingCultists, sacrificedCultists, msg.sender);
        assembly {
            // emit Transfer(msg.sender, 0, num)
            mstore(0x00, num)
            log3(0x00, 0x20, TRANSFER_SIG, caller(), 0)
        }
    }

    function sacrifice() public onlyAwake {
        sacrificeManyButOnlyMintOneNFT(1);
    }

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

        if (lastEpochTotalSacrificed >= currentEpochTotalSacrificed) {
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

    constructor() ERC721() {
        assembly {
            sstore(doomCultSocietyDAO.slot, caller())
        }
    }

    // Not enumerable but hey we have enough info for this method...so why not
    // (until the DAO blows up that is!)
    function totalSupply() public view returns (uint256) {
        DoomCultSocietyDAO dao = DoomCultSocietyDAO(doomCultSocietyDAO);
        return dao.numStartingCultists() - dao.totalSupply();
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
                mstore(512, '<?xml version="1.0" encoding="UT')
                mstore(544, 'F-8"?><svg viewBox="0 0 700 800"')
                mstore(576, ' xmlns')
                mstore(582, t15)
                mstore(602, '2000/svg" xmlns:xlink')
                mstore(623, t15)
                mstore(643, '1999/xlink"><style>.heavy,.super')
                mstore(675, 'heavy{font:700 30px sans-serif;f')
                mstore(707, 'ill:#fff}</style><path d="M0 0h7')
                mstore(739, '00v0800H0z"/><g')
                mstore(754, t1)
                mstore(766, 'matrix(.1 0 0 -.1 -350 650)"><de')
                mstore(798, 'fs><g id="g">')
                mstore(811, t11)
                mstore(823, '-20" cy="210" r="100')
                mstore(843, t13)
                mstore(851, t10)
                mstore(864, 'd')
                mstore(865, t13)
                mstore(873, 'transform="')
                mstore(884, t2)
                mstore(890, '(45 30.71 267.28)" ')
                mstore(909, t10)
                mstore(922, 'd')
                mstore(923, t13)
                mstore(931, 'transform="')
                mstore(942, t2)
                mstore(948, '(90 -20 240)" ')
                mstore(962, t10)
                mstore(975, 'd"/></g><g id="f')
                mstore(991, t14)
                mstore(998, t10)
                mstore(1011, 'c')
                mstore(1012, t13)
                mstore(1020, 'transform="')
                mstore(1031, t2)
                mstore(1037, '(45 -19.645 218.14)" ')
                mstore(1058, t10)
                mstore(1071, 'c')
                mstore(1072, t13)
                mstore(1080, 'transform="')
                mstore(1091, t2)
                mstore(1097, '(90 -30 230)" ')
                mstore(1111, t10)
                mstore(1124, 'c')
                mstore(1125, t13)
                mstore(1133, 'transform="')
                mstore(1144, t2)
                mstore(1150, '(-48 -37.302 218.45)" ')
                mstore(1172, t10)
                mstore(1185, 'c"/></g><g id="1')
                mstore(1201, t14)
                mstore(1208, 'fill="#f57914" ')
                mstore(1223, t10)
                mstore(1236, 'l')
                mstore(1237, t13)
                mstore(1245, 'transform="matrix(.44463 1.2216 ')
                mstore(1277, '-1.0337 .37622 7471.6 -2470.6)" ')
                mstore(1309, 'x="-2000"')
                mstore(1318, t8)
                mstore(1333, ' ')
                mstore(1334, t10)
                mstore(1347, 'e"/></g><g id="2"')
                mstore(1364, t1)
                mstore(1376, 'translate(5150 4100)')
                mstore(1396, t14)
                mstore(1403, 'fill="#ed1c24" ')
                mstore(1418, t10)
                mstore(1431, 'g')
                mstore(1432, t13)
                mstore(1440, 'fill="#8c1b85" ')
                mstore(1455, t10)
                mstore(1468, 'f"/></g><g id="3')
                mstore(1484, t14)
                mstore(1491, 'transform="scale(.9 -.7)" x="960')
                mstore(1523, '" y="-4400"')
                mstore(1534, t6)
                mstore(1549, ' ')
                mstore(1550, t10)
                mstore(1563, 'a')
                mstore(1564, t13)
                mstore(1572, 'transform="scale(.7 -.7) ')
                mstore(1597, t2)
                mstore(1603, '(40 14283 5801)"')
                mstore(1619, t4)
                mstore(1634, ' ')
                mstore(1635, t10)
                mstore(1648, 'a"/></g><g id="4"')
                mstore(1665, t1)
                mstore(1677, t2)
                mstore(1683, '(125 3495.9 1947) scale(.6)')
                mstore(1710, t14)
                mstore(1717, 'fill="#f57914" ')
                mstore(1732, t10)
                mstore(1745, 'g')
                mstore(1746, t13)
                mstore(1754, 'fill="#8c1b85" ')
                mstore(1769, t10)
                mstore(1782, 'f"/></g><g id="5')
                mstore(1798, t14)
                mstore(1805, 'transform="matrix(-1.4095 .51303')
                mstore(1837, ' .0684 -1.4083 12071 6071.6)" x=')
                mstore(1869, '"-2100" y="1650"')
                mstore(1885, t9)
                mstore(1898, t10)
                mstore(1911, 'e"/>')
                mstore(1915, t11)
                mstore(1927, '6470" cy="1780" r="130"')
                mstore(1950, t6)
                mstore(1965, '/>')
                mstore(1967, t11)
                mstore(1979, '5770" cy="1350" r="70"')
                mstore(2001, t4)
                mstore(2016, '/>')
                mstore(2018, t11)
                mstore(2030, '5820" cy="1150" r="70"')
                mstore(2052, t4)
                mstore(2067, '/>')
                mstore(2069, t11)
                mstore(2081, '5720" cy="1550" r="70"')
                mstore(2103, t4)
                mstore(2118, '/>')
                mstore(2120, t11)
                mstore(2132, '6190" cy="1700" r="80"')
                mstore(2154, t4)
                mstore(2169, '/></g><g id="6">')
                mstore(2185, t11)
                mstore(2197, '6e3" cy="1650" r="80"')
                mstore(2218, t6)
                mstore(2233, '/>')
                mstore(2235, t11)
                mstore(2247, '6370" cy="200" r="80"')
                mstore(2268, t3)
                mstore(2283, '/><path d="m6300 1710c-7-13-6-26')
                mstore(2315, '-4-41s9-26 17-37c6-11 22-17 41-2')
                mstore(2347, '4 17-4 44 9 79 41 35 33 63 131 8')
                mstore(2379, '5 299-92-124-153-194-183-207-4-2')
                mstore(2411, '-9-4-13-6-10-4-17-13-22-24m-470-')
                mstore(2443, '161c-26 2-50-6-72-26-19-17-33-39')
                mstore(2475, '-39-65-4-13 20-164 72-452 50-286')
                mstore(2507, ' 181-530 393-731-201 421-292 709')
                mstore(2539, '-277 860 15 150 20 247 13 284-6 ')
                mstore(2571, '37-17 68-28 90-15 24-37 39-61 41')
                mstore(2603, '"')
                mstore(2604, t4)
                mstore(2619, '/></g><g id="7')
                mstore(2633, t14)
                mstore(2640, 'transform="scale(.9 1.6)" x="960')
                mstore(2672, '" y="-840"')
                mstore(2682, t6)
                mstore(2697, ' ')
                mstore(2698, t10)
                mstore(2711, 'a')
                mstore(2712, t13)
                mstore(2720, 'transform="')
                mstore(2731, t2)
                mstore(2737, '(-50 6340 4600)"')
                mstore(2753, t9)
                mstore(2766, t10)
                mstore(2779, 'h')
                mstore(2780, t13)
                mstore(2788, 'transform="scale(.9 1.3) ')
                mstore(2813, t2)
                mstore(2819, '(30 6740 4300)" x="400" y="-530"')
                mstore(2851, t4)
                mstore(2866, ' ')
                mstore(2867, t10)
                mstore(2880, 'a"/></g><g id="8"')
                mstore(2897, t1)
                mstore(2909, 'translate(7100 5100)')
                mstore(2929, t14)
                mstore(2936, 'transform="')
                mstore(2947, t2)
                mstore(2953, '(260 -158.56 64.887) scale(.6)"')
                mstore(2984, t4)
                mstore(2999, ' ')
                mstore(3000, t10)
                mstore(3013, 'd')
                mstore(3014, t13)
                mstore(3022, 'transform="')
                mstore(3033, t2)
                mstore(3039, '(125) scale(.6)" ')
                mstore(3056, t10)
                mstore(3069, 'j')
                mstore(3070, t13)
                mstore(3078, 'transform="scale(-.6 .6) ')
                mstore(3103, t2)
                mstore(3109, '(-55 -272.14 -141.67)" ')
                mstore(3132, t10)
                mstore(3145, 'j"/></g><g id="j')
                mstore(3161, t14)
                mstore(3168, 'fill="#0994d3" ')
                mstore(3183, t10)
                mstore(3196, 'g')
                mstore(3197, t13)
                mstore(3205, 'fill="#8c1b85" ')
                mstore(3220, t10)
                mstore(3233, 'f"/></g><g id="l">')
                mstore(3251, t11)
                mstore(3263, '5630" cy="4060" r="140"/>')
                mstore(3288, t11)
                mstore(3300, '5400" cy="3850" r="110"/>')
                mstore(3325, t11)
                mstore(3337, '5270" cy="3600" r="90"/>')
                mstore(3361, t11)
                mstore(3373, '5180" cy="3350" r="70"/>')
                mstore(3397, t11)
                mstore(3409, '5150" cy="3150" r="60"/></g><g i')
                mstore(3441, 'd="q">')
                mstore(3447, t11)
                mstore(3459, '6840" cy="3060" r="165" style="f')
                mstore(3491, 'ill:#ed1344"/>')
                mstore(3505, t11)
                mstore(3517, '6770" cy="3335" r="165" style="f')
                mstore(3549, 'ill:#ed1344"/>')
                mstore(3563, t11)
                mstore(3575, '6640" cy="3535" r="165" style="f')
                mstore(3607, 'ill:#ed1344"/>')
                mstore(3621, t11)
                mstore(3633, '6395" cy="3690" r="165" style="f')
                mstore(3665, 'ill:#ed1344"/>')
                mstore(3679, t11)
                mstore(3691, '6840" cy="3060" r="80" style="fi')
                mstore(3723, 'll:#0994d3"/>')
                mstore(3736, t11)
                mstore(3748, '6770" cy="3335" r="80" style="fi')
                mstore(3780, 'll:#0994d3"/>')
                mstore(3793, t11)
                mstore(3805, '6640" cy="3535" r="80" style="fi')
                mstore(3837, 'll:#0994d3"/>')
                mstore(3850, t11)
                mstore(3862, '6395" cy="3690" r="80" style="fi')
                mstore(3894, 'll:#0994d3"/></g><g id="p')
                mstore(3919, t14)
                mstore(3926, t10)
                mstore(3939, 'q')
                mstore(3940, t13)
                mstore(3948, t10)
                mstore(3961, 'q"')
                mstore(3963, t1)
                mstore(3975, t2)
                mstore(3981, '(180 6150 3060)')
                mstore(3996, t13)
                mstore(4004, t10)
                mstore(4017, 'q"')
                mstore(4019, t1)
                mstore(4031, t2)
                mstore(4037, '(270 6150 3060)')
                mstore(4052, t13)
                mstore(4060, t10)
                mstore(4073, 'q"')
                mstore(4075, t1)
                mstore(4087, t2)
                mstore(4093, '(90 6150 3060)"/></g>')
                mstore(4114, t12)
                mstore(4124, 'n" d="m7507 5582c-168 33-340 50-')
                mstore(4156, '517 52-177-2-349-20-517-52-345-6')
                mstore(4188, '8-659-244-941-530-284-286-469-55')
                mstore(4220, '6-556-814-20-57-35-116-50-175-33')
                mstore(4252, '-138-48-284-46-436 0-452 74-803 ')
                mstore(4284, '220-1056 98-168 133-334 102-495-')
                mstore(4316, '30-159 20-308 148-441 68-68 122-')
                mstore(4348, '127 166-177 41-46 74-85 96-116 4')
                mstore(4380, '4-255 120-526 229-807 109-282 30')
                mstore(4412, '1-443 576-489 39-6 76-11 111-18 ')
                mstore(4444, '308-37 613-37 921 0 35 7 72 11 1')
                mstore(4476, '13 17 273 46 465 207 574 489 109')
                mstore(4508, ' 281 185 552 229 807 46 63 133 1')
                mstore(4540, '59 262 292s179 282 148 441c-30 1')
                mstore(4572, '61 4 327 103 495 146 253 220 605')
                mstore(4604, ' 223 1056-2 218-35 421-98 611-89')
                mstore(4636, ' 258-275 528-556 814-283 286-598')
                mstore(4668, ' 463-941 530" fill="#fcca07"/>')
                mstore(4698, t12)
                mstore(4708, 'm" d="M7243 1429c-2 24-10 43-26 ')
                mstore(4740, '61-15 17-34 26-54 26h-67c-21 0-4')
                mstore(4772, '1-9-57-26-15-17-24-37-22-61v-260')
                mstore(4804, 'c-2-24 6-44 22-61 15-17 35-26 57')
                mstore(4836, '-26h68c20 0 39 9 54 26s24 37 26 ')
                mstore(4868, '61v260m-9-487c-2 22-9 41-24 57-1')
                mstore(4900, '5 17-33 26-52 26h-65c-20 0-37-9-')
                mstore(4932, '52-26-15-15-22-35-22-57V695c0-22')
                mstore(4964, ' 6-41 22-57 15-15 33-24 52-24h65')
                mstore(4996, 'c20 0 37 8 52 24 15 15 22 35 24 ')
                mstore(5028, '57v246m82 86c-15-20-22-39-22-63l')
                mstore(5060, '.01-260c0-24 6-41 22-57 15-13 30')
                mstore(5092, '-17 50-13l59 13c20 4 35 15 50 35')
                mstore(5124, ' 6 11 13 24 15.34 37 2 9 4 17 4 ')
                mstore(5156, '24v242c0 24-6 41-20 57-15 15-30 ')
                mstore(5188, '22-50 19m263 60h-59c-20 0-37-9-5')
                mstore(5220, '4-24-15-15-22-33-22-52V816c0-17 ')
                mstore(5252, '6-35 22-48 15-11 31-15 46-13h9l5')
                mstore(5284, '8 15c17 4 32 13 46 28 13 17 20 3')
                mstore(5316, '5 20 52v204c0 20-6 35-20 48-13 1')
                mstore(5348, '3-28 20-46 20m294 373c-11 11-24 ')
                mstore(5380, '17-39 17h-50c-17 0-33-6-48-20-13')
                mstore(5412, '-13-20-28-20-48v-201c0-15 6-28 2')
                mstore(5444, '0-39 11-9 24-13 39-13h9l50 13c15')
                mstore(5476, ' 2 28 11 39 26s17 31 17 46v177c0')
                mstore(5508, ' 15-6 31-17 41m-480-65c0 22-7 41')
                mstore(5540, '-20 57-15 18-30 26-48 26h-58c-20')
                mstore(5572, ' 0-37-9-52-26s-22-37-22-61v-260c')
                mstore(5604, '0-24 6-43 22-59 15-15 33-20 52-1')
                mstore(5636, '7l59 6c17 2 33 13 48 33 13 17 20')
                mstore(5668, ' 37 20 59v242m381-262c-17-2-33-9')
                mstore(5700, '-48-24-13-15-20-30-17-50V892c-2-')
                mstore(5732, '15 4-28 17-37s26-13 41-11c2 2 4 ')
                mstore(5764, '2 6 2l52 17c15 7 28 15 39 31 11 ')
                mstore(5796, '15 17 33 17 48v178c0 15-6 28-17 ')
                mstore(5828, '39s-24 15-39 13l-52-4M7584 1488c')
                mstore(5860, '-15-15-22-33-22-52v-229c0-20 6-3')
                mstore(5892, '5 22-48 13-11 28-15 44-13h11l57 ')
                mstore(5924, '15c17 4 33 13 48 28 13 17 20 35 ')
                mstore(5956, '20 52v203c0 19-6 35-20 48-15 13-')
                mstore(5988, '30 20-48 20h-57c-20 0-39-9-55-24')
                mstore(6020, '"/>')
                mstore(6023, t12)
                mstore(6033, 'd" d="M0 0c4-54-1-112-17-177-9-4')
                mstore(6065, '0-18-73-31-103 7-32 21-61 36-83 ')
                mstore(6097, '28-48 53-71 78-73 22 4 39 31 54 ')
                mstore(6129, '81 8 34 12 75 11 115-19 22-36 47')
                mstore(6161, '-51 74C43-107 14-51 0 0"/>')
                mstore(6187, t12)
                mstore(6197, 'c" d="m250-340c41-36 75-48 96-40')
                mstore(6229, ' 21 12 25 46 14 95-5 30-15 59-28')
                mstore(6261, ' 88-8 17-14 37-25 56-8 17-20 34-')
                mstore(6293, '30 54-44 68-91 124-140 163-20 16')
                mstore(6325, '-40 28-55 36-15 4-27 7-37 4l-2-2')
                mstore(6357, 'c-4 0-7-5-9-7-7-9-10-21-12-38 0-')
                mstore(6389, '14 1-30 6-52 12-58 40-124 83-194')
                mstore(6421, ' 5-7 12-13 17-20 10-19 23-40 39-')
                mstore(6453, '57 28-33 56-63 85-86"/>')
                mstore(6476, t12)
                mstore(6486, 'o" d="m5960 3720c-33 9-76 20-127')
                mstore(6518, ' 33-94 28-150 35-166 24-17-11-28')
                mstore(6550, '-65-33-159-4-59-9-109-11-148-33-')
                mstore(6582, '11-72-26-122-46-92-33-142-61-150')
                mstore(6614, '-81-7-17 17-68 68-148 33-50 59-9')
                mstore(6646, '2 78-124-20-28-44-65-72-111-55-8')
                mstore(6678, '1-78-131-72-150 4-20 50-46 140-7')
                mstore(6710, '8 55-22 100-41 138-57 2-26 4-59 ')
                mstore(6742, '7-96v-35c4-98 15-153 31-164 15-1')
                mstore(6774, '1 68-6 161 17 57 15 105 26 142 3')
                mstore(6806, '5 22-26 50-61 83-103 61-76 102-1')
                mstore(6838, '13 122-116 20 0 59 37 120 109 37')
                mstore(6870, ' 46 68 85 94 113 33-7 76-20 129-')
                mstore(6902, '35 94-24 148-33 166-22 15 11 26 ')
                mstore(6934, '65 33 159 0 15 0 28 2 39 2 41 4 ')
                mstore(6966, '79 6 107 33 13 74 28 124 48 92 3')
                mstore(6998, '5 140 61 146 79 6 20-17 68-68 14')
                mstore(7030, '8-33 50-57 92-76 124 18 30 41 68')
                mstore(7062, ' 72 111 52 81 76 131 72 150-6 20')
                mstore(7094, '-52 48-142 81-54 22-100 39-135 5')
                mstore(7126, '4-2 35-4 78-6 133-4 98-15 153-30')
                mstore(7158, ' 164-15 13-70 6-161-17-59-15-107')
                mstore(7190, '-26-144-35-22 26-50 61-83 103-61')
                mstore(7222, ' 76-100 116-120 116s-61-37-120-1')
                mstore(7254, '11c-37-46-70-83-96-111"/>')
                mstore(7279, t12)
                mstore(7289, 'e" d="m6500 4100c-25 8-53 6-79-3')
                mstore(7321, '-31-8-53-28-62-53-11-25-8-53 5-7')
                mstore(7353, '8 11-22 31-39 56-53 11-6 25-11 3')
                mstore(7385, '9-17 87-31 182-90 289-177-53 213')
                mstore(7417, '-120 336-205 367-14 6-31 11-45 1')
                mstore(7449, '4"/>')
                mstore(7453, t12)
                mstore(7463, 'h" d="m5769 4876c274 21 415 85 6')
                mstore(7495, '92-127-115 159-241 266-379 326-8')
                mstore(7527, '9 36-218 80-316 63-70-13-117-37-')
                mstore(7559, '136-65-25-33-34-68-26-103s29-62 ')
                mstore(7591, '66-80c28-16 62-22 100-14"/>')
                mstore(7618, t12)
                mstore(7628, 'a" d="m6740 4300c-17-22-25-48-28')
                mstore(7660, '-78v-50c-3-98 34-230 109-401 62 ')
                mstore(7692, '168 93 303 92 400v50c-3 31-14 56')
                mstore(7724, '-31 78-20 25-45 39-70 39-28 0-53')
                mstore(7756, '-14-73-39"/><g id="i')
                mstore(7776, t14)
                mstore(7783, 'transform="')
                mstore(7794, t2)
                mstore(7800, '(130 6130 3100)"')
                mstore(7816, t7)
                mstore(7831, ' ')
                mstore(7832, t10)
                mstore(7845, 'l"/>')
                mstore(7849, t11)
                mstore(7861, '6665" cy="4440" r="80"')
                mstore(7883, t6)
                mstore(7898, '/>')
                mstore(7900, t11)
                mstore(7912, '6370" cy="4510" r="80"')
                mstore(7934, t6)
                mstore(7949, '/>')
                mstore(7951, t11)
                mstore(7963, '6480" cy="4360" r="60"')
                mstore(7985, t6)
                mstore(8000, '/><use')
                mstore(8006, t6)
                mstore(8021, ' ')
                mstore(8022, t10)
                mstore(8035, 'a"/>')
                mstore(8039, t11)
                mstore(8051, '7e3" cy="3900" r="50"')
                mstore(8072, t6)
                mstore(8087, '/>')
                mstore(8089, t0)
                mstore(8105, t2)
                mstore(8111, '(-20 6500 4100)" x="110" y="50"')
                mstore(8142, t4)
                mstore(8157, ' ')
                mstore(8158, t10)
                mstore(8171, 'e')
                mstore(8172, t13)
                mstore(8180, 'fill="#ed1c24" ')
                mstore(8195, t10)
                mstore(8208, 'h"/>')
                mstore(8212, t11)
                mstore(8224, '5350" cy="2550" r="80"')
                mstore(8246, t4)
                mstore(8261, '/>')
                mstore(8263, t11)
                mstore(8275, '5420" cy="2280" r="130"')
                mstore(8298, t4)
                mstore(8313, '/>')
                mstore(8315, t11)
                mstore(8327, '5950" cy="4500" r="50"')
                mstore(8349, t4)
                mstore(8364, '/><path d="m5844 4593c36 36 81 5')
                mstore(8396, '3 134 56 53 3 90-17 109-53 20-36')
                mstore(8428, ' 14-73-17-104-31-31-39-62-25-90 ')
                mstore(8460, '11-25 42-34 92-20 50 14 79 53 81')
                mstore(8492, ' 118 3 68-20 118-73 151-53 34-10')
                mstore(8524, '9 50-174 50-65 0-120-22-168-70-4')
                mstore(8556, '8-48-70-104-70-168 0-64 22-120 7')
                mstore(8588, '0-168 48-48 140-90 280-132 126-4')
                mstore(8620, '2 252-115 379-221-126 208-235 32')
                mstore(8652, '2-325 348-93 25-171 48-241 67-70')
                mstore(8684, ' 19-106 56-106 106 0 50 17 93 53')
                mstore(8716, ' 129"')
                mstore(8721, t6)
                mstore(8736, '/>')
                mstore(8738, t11)
                mstore(8750, '6160" cy="3050" r="600"')
                mstore(8773, t8)
                mstore(8788, '/><path d="m7145 1722c59 0 109 2')
                mstore(8820, '6 151 76 41 50 61 113 61 185s-19')
                mstore(8852, ' 135-61 185c-41 50-120 144-236 2')
                mstore(8884, '79-22 26-41 46-59 59-17-13-37-33')
                mstore(8916, '-59-59-116-135-194-229-236-279-4')
                mstore(8948, '1-50-63-113-61-185-2-72 20-135 6')
                mstore(8980, '1-186 41-50 92-76 151-76 55 0 10')
                mstore(9012, '3 24 144 70"')
                mstore(9024, t8)
                mstore(9039, '/><use')
                mstore(9045, t9)
                mstore(9058, t10)
                mstore(9071, 'm')
                mstore(9072, t13)
                mstore(9080, t10)
            }
            let p := 9093
            res := 480
            mstore(0x40, 30000)
            // Token information
            // tokenId % 1,000,000 = index of token (i.e. how many were minted before this token)
            // (tokenId / 1,000,000) % 100 = week in which sacrificed occured (from game start)
            // (tokenId / 100,000,000) = number of cultists remaining after sacrifice
            let countdown := mod(div(tokenId, 1000000), 100)
            mstore(0x00, tokenId)
            mstore(0x20, 5148293888310004) // some salt for your token
            let seed := keccak256(0x00, 0x40)
            let table1 := mload(0x40)
            let table2 := add(0x340, table1)
            mstore8(p, 0x30) // "0"
            if mod(seed, 3) {
                mstore8(p, add(0x30, mod(seed, 3))) // "1" or "2"
            }
            p := add(p, 0x01)
            seed := shr(8, seed)

            let temp := '"/><use xlink:href="#'
            mstore(p, temp)
            p := add(p, 21)

            mstore8(p, 0x30) // "0"
            if mod(seed, 3) {
                mstore8(p, add(0x32, mod(seed, 3))) // "3" or "4"
            }
            p := add(p, 0x01)
            seed := shr(8, seed)

            mstore(p, temp)
            p := add(p, 21)

            mstore8(p, 0x30) // "0"
            if mod(seed, 3) {
                mstore8(p, add(0x34, mod(seed, 3))) // "5" or "6"
            }
            p := add(p, 0x01)
            seed := shr(8, seed)

            mstore(p, temp)
            p := add(p, 21)
            mstore8(p, 0x30) // "0"
            if mod(seed, 3) {
                mstore8(p, add(0x36, mod(seed, 3))) // "7" or "8"
            }
            p := add(p, 1)
            seed := shr(8, seed)

            mstore(p, '"/></g></defs><g filter="invert(')
            p := add(p, 32)
            {
                // 1% change of inverting colours
                // increases to 50% iff week counter is 10 or greater
                let isWeekTenYet := gt(countdown, 9)
                let invertProbInv := add(mul(isWeekTenYet, 2), mul(iszero(isWeekTenYet), 100))
                let inverted := eq(mod(seed, invertProbInv), 0)
                mstore8(p, add(0x30, inverted)) // "0" or "1"
                mstore(add(p, 1), ') hue-rotate(')
                seed := shr(8, seed)
                let hue := mul(30, mod(seed, 12)) // 0 to 360 in steps of 12
                mstore8(add(p, 0xe), add(0x30, mod(div(hue, 100), 10)))
                mstore8(add(p, 0xf), add(0x30, mod(div(hue, 10), 10)))
                mstore8(add(p, 0x10), add(0x30, mod(hue, 10)))
            }
            p := add(p, 17)

            let eye1 := add(0x6f, and(seed, 1)) // "o" or "p"
            let hasMixedEyes := eq(mod(shr(1, seed), 10), 0)
            let eye2
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
            seed := shr(16, seed)

            mstore(p, 'deg)"><use xlink:href="#n')
            mstore(add(p, 25), temp)

            p := add(p, 46)

            mstore8(p, eye1) // "o" or "p"
            mstore(add(p, 1), '" style="fill:#')
            mstore(0x00, 'ed1c24')
            mstore(0x20, '9addf0')
            mstore(add(p, 16), mload(shl(5, and(seed, 1))))
            seed := shr(1, seed)

            p := add(p, 22)

            mstore(p, temp)
            mstore(add(p, 21), 'i"/><g transform="matrix(-1 0 0 ')
            mstore(add(p, 53), '1 14000 0)"><use xlink:href="#')

            p := add(p, 83)
            mstore8(p, eye2) // "1" or "2"
            mstore(add(p, 1), '" style="fill:#')
            mstore(add(p, 16), mload(shl(5, and(seed, 1))))
            seed := shr(16, seed)

            p := add(p, 22)

            mstore(p, temp)
            mstore(add(p, 21), 'i"/></g></g></g><text x="30" ')
            mstore(add(p, 50), 'y="55" class="heavy">')
            p := add(p, 71)

            mstore(p, 'Week: ')
            p := add(p, 6)

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
            mstore(p, '</text><text x="670" y="55" clas')
            mstore(add(p, 32), 's="heavy" text-anchor="end">')
            p := add(p, 60)

            {
                let livingCultists := div(tokenId, 100000000) // 100 million
                let oneCultist := eq(livingCultists, 1)
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

                mstore(p, ' Cultist')
                mstore(add(p, 8), mul(iszero(oneCultist), 's'))
                p := add(p, iszero(oneCultist))
                mstore(add(p, 8), ' Remaining')
                p := add(p, 18)
            }
            mstore(p, '</text><text x="350" y="730" cla')
            mstore(add(p, 32), 'ss="superheavy" text-anchor="mid')
            mstore(add(p, 64), 'dle">')
            p := add(p, 69)

            mstore(table1, 0)
            mstore(add(table1, 0x20), 'Willingly ')
            mstore(add(table1, 0x40), 'Enthusiastically ')
            mstore(add(table1, 0x60), 'Cravenly ')
            mstore(add(table1, 0x80), 'Gratefully ')
            mstore(add(table1, 0xa0), 'Vicariously ')
            mstore(add(table1, 0xc0), 'Shockingly ')
            mstore(add(table1, 0xe0), 'Gruesomly ')
            mstore(add(table1, 0x100), 'Confusingly ')
            mstore(add(table1, 0x120), 'Angrily ')
            mstore(add(table1, 0x140), 'Carelessly ')
            mstore(add(table1, 0x160), 'Mysteriously ')
            mstore(add(table1, 0x180), 'Shamefully ')

            mstore(table2, 0)
            mstore(add(table2, 0x20), 10)
            mstore(add(table2, 0x40), 17)
            mstore(add(table2, 0x60), 9)
            mstore(add(table2, 0x80), 11)
            mstore(add(table2, 0xa0), 12)
            mstore(add(table2, 0xc0), 11)
            mstore(add(table2, 0xe0), 11)
            mstore(add(table2, 0x100), 12)
            mstore(add(table2, 0x120), 8)
            mstore(add(table2, 0x140), 11)
            mstore(add(table2, 0x160), 13)
            mstore(add(table2, 0x180), 11)

            let idx := mul(iszero(mod(seed, 10)), add(0x20, shl(5, mod(shr(8, seed), 12))))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))
            seed := shr(16, seed)

            mstore(add(table1, 0x20), 'Banished To The Void Using')
            mstore(add(table1, 0x40), 'Crushed Under The Weight Of')
            mstore(add(table1, 0x60), 'Devoured By')
            mstore(add(table1, 0x80), 'Erased From Existence By')
            mstore(add(table1, 0xa0), 'Extinguished By')
            mstore(add(table1, 0xc0), 'Hugged To Death By')
            mstore(add(table1, 0xe0), 'Obliterated By')
            mstore(add(table1, 0x100), 'Ripped Apart By')
            mstore(add(table1, 0x120), 'Sacrificed In The Service Of')
            mstore(add(table1, 0x140), 'Slaughtered Defending')
            mstore(add(table1, 0x160), 'Succumbed To Burns From')
            mstore(add(table1, 0x180), 'Torn To Shreds By')
            mstore(add(table1, 0x1a0), 'Vanished At A Party Hosted By')
            mstore(add(table1, 0x1c0), 'Vivisected Via')

            mstore(add(table2, 0x20), 26)
            mstore(add(table2, 0x40), 27)
            mstore(add(table2, 0x60), 11)
            mstore(add(table2, 0x80), 24)
            mstore(add(table2, 0xa0), 15)
            mstore(add(table2, 0xc0), 18)
            mstore(add(table2, 0xe0), 14)
            mstore(add(table2, 0x100), 15)
            mstore(add(table2, 0x120), 28)
            mstore(add(table2, 0x140), 21)
            mstore(add(table2, 0x160), 23)
            mstore(add(table2, 0x180), 17)
            mstore(add(table2, 0x1a0), 29)
            mstore(add(table2, 0x1c0), 14)

            idx := add(0x20, shl(5, mod(seed, 14)))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))
            seed := shr(8, seed)

            mstore(p, '</text><text x="350" y="780" cla')
            mstore(add(p, 32), 'ss="superheavy" text-anchor="mid')
            mstore(add(p, 64), 'dle">')
            p := add(p, 69)

            mstore(add(table1, 0x20), 'Anarcho-Capitalist ')
            mstore(add(table1, 0x40), 'Artificial ')
            mstore(add(table1, 0x60), 'Energetic ')
            mstore(add(table1, 0x80), 'Extreme ')
            mstore(add(table1, 0xa0), 'Ferocious ')
            mstore(add(table1, 0xc0), 'French ')
            mstore(add(table1, 0xe0), 'Funkadelic ')
            mstore(add(table1, 0x100), 'Grossly Incompetent ')
            mstore(add(table1, 0x120), 'Hysterical ')
            mstore(add(table1, 0x140), 'Irrepressible ')
            mstore(add(table1, 0x160), 'Morally Bankrupt ')
            mstore(add(table1, 0x180), 'Overcollateralized ')
            mstore(add(table1, 0x1a0), 'Politically Indiscreet ')
            mstore(add(table1, 0x1c0), 'Punch-Drunk ')
            mstore(add(table1, 0x1e0), 'Punk ')
            mstore(add(table1, 0x200), 'Time-Travelling ')
            mstore(add(table1, 0x220), 'Unsophisticated ')
            mstore(add(table1, 0x240), 'Volcanic ')
            mstore(add(table1, 0x260), 'Voracious ')
            mstore(add(table1, 0x280), "Grandmother's Leftover ")
            mstore(add(table1, 0x2a0), "M. Night Shyamalan's ")
            mstore(add(table1, 0x2c0), 'Emergency British ')
            mstore(add(table1, 0x2e0), 'Oecumenical ')

            mstore(add(table2, 0x20), 19)
            mstore(add(table2, 0x40), 11)
            mstore(add(table2, 0x60), 10)
            mstore(add(table2, 0x80), 8)
            mstore(add(table2, 0xa0), 10)
            mstore(add(table2, 0xc0), 7)
            mstore(add(table2, 0xe0), 11)
            mstore(add(table2, 0x100), 20)
            mstore(add(table2, 0x120), 11)
            mstore(add(table2, 0x140), 14)
            mstore(add(table2, 0x160), 17)
            mstore(add(table2, 0x180), 19)
            mstore(add(table2, 0x1a0), 23)
            mstore(add(table2, 0x1c0), 12)
            mstore(add(table2, 0x1e0), 5)
            mstore(add(table2, 0x200), 16)
            mstore(add(table2, 0x220), 16)
            mstore(add(table2, 0x240), 9)
            mstore(add(table2, 0x260), 10)
            mstore(add(table2, 0x280), 23)
            mstore(add(table2, 0x2a0), 21)
            mstore(add(table2, 0x2c0), 18)
            mstore(add(table2, 0x2e0), 12)

            let rare := eq(mod(seed, 100), 0) // mmmm rare communism...

            idx := mul(iszero(rare), add(0x20, shl(5, mod(seed, 23))))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))
            seed := shr(16, seed)

            mstore(table1, 'The Communist Manifesto')

            mstore(add(table1, 0x20), '4D Buckaroo')
            mstore(add(table1, 0x40), 'Ballroom Dancing Fever')
            mstore(add(table1, 0x60), 'Bees')
            mstore(add(table1, 0x80), 'Canadians')
            mstore(add(table1, 0xa0), 'Electric Jazz')
            mstore(add(table1, 0xc0), 'Explosions')
            mstore(add(table1, 0xe0), 'FOMO')
            mstore(add(table1, 0x100), 'Giant Gummy Bears')
            mstore(add(table1, 0x120), 'Gigawatt Lasers')
            mstore(add(table1, 0x140), 'Heavy Metal')
            mstore(add(table1, 0x160), 'Lifestyle Vloggers')
            mstore(add(table1, 0x180), 'Memes')
            mstore(add(table1, 0x1a0), 'Physics')
            mstore(add(table1, 0x1c0), 'Rum Runners')
            mstore(add(table1, 0x1e0), 'Swine Flu')
            mstore(add(table1, 0x200), 'Theatre Critics')
            mstore(add(table1, 0x220), 'Trainee Lawyers')
            mstore(add(table1, 0x240), 'Twitterati')
            mstore(add(table1, 0x260), 'Velociraptors')
            mstore(add(table1, 0x280), 'Witches')
            mstore(add(table1, 0x2a0), 'Wizards')
            mstore(add(table1, 0x2c0), 'Z-List Celebrities')
            mstore(add(table1, 0x2e0), 'High-Stakes Knitting')
            mstore(add(table1, 0x300), 'Hardtack And Whiskey')
            mstore(add(table1, 0x320), 'Melodramatic Bullshit')

            mstore(table2, 23)
            mstore(add(table2, 0x20), 11)
            mstore(add(table2, 0x40), 22)
            mstore(add(table2, 0x60), 4)
            mstore(add(table2, 0x80), 9)
            mstore(add(table2, 0xa0), 13)
            mstore(add(table2, 0xc0), 10)
            mstore(add(table2, 0xe0), 4)
            mstore(add(table2, 0x100), 17)
            mstore(add(table2, 0x120), 15)
            mstore(add(table2, 0x140), 11)
            mstore(add(table2, 0x160), 18)
            mstore(add(table2, 0x180), 5)
            mstore(add(table2, 0x1a0), 7)
            mstore(add(table2, 0x1c0), 11)
            mstore(add(table2, 0x1e0), 9)
            mstore(add(table2, 0x200), 15)
            mstore(add(table2, 0x220), 15)
            mstore(add(table2, 0x240), 10)
            mstore(add(table2, 0x260), 13)
            mstore(add(table2, 0x280), 7)
            mstore(add(table2, 0x2a0), 7)
            mstore(add(table2, 0x2c0), 18)
            mstore(add(table2, 0x2e0), 20)
            mstore(add(table2, 0x300), 20)
            mstore(add(table2, 0x320), 21)

            idx := mul(iszero(rare), add(0x20, shl(5, mod(seed, 25))))
            mstore(p, mload(add(table1, idx)))
            p := add(p, mload(add(table2, idx)))

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
            id := mod(tokenId, 1000000)
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
        return Base64.encode(innerData, 0, 0);
    }

    function imageURI(uint256 tokenId) public pure returns (string memory) {
        string memory result = Base64.encode(getImgData(tokenId), 62, 3);
        assembly {
            let ptr := add(result, 0x20)
            mstore(ptr, 'data:image/svg+xml;base64,')
            mstore(add(ptr, 26), '<img src="data:image/svg+xml;bas')
            mstore(add(ptr, 58), or('e64,', and(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff, mload(add(ptr, 56)))))
            mstore(result, add(mload(result), 62))
            ptr := add(result, add(0x20, mload(result)))
            mstore(ptr, '"\\>')
            mstore(result, add(mload(result), 3))
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