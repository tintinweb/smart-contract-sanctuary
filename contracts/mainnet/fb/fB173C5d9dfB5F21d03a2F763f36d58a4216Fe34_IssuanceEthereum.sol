/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// File: contracts/tokens-base/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/tokens-base/IERC20Metadata.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/utils/Context.sol

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/tokens-base/ERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        // TODO: remove before hook unless needed
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/core/YoloEthereumUtilityTokens.sol

pragma solidity 0.8.4;

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *  From OpenZep
 * _Available since v3.4._
 */
contract YoloEthereumUtilityTokens is ERC20 {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        address owner
    ) ERC20(name, symbol) {
        require(bytes(name).length != 0, "token name must be specified");
        require(bytes(symbol).length != 0, "token symbol must be specified");
        uint256 amount = 10**9 * 10**(decimals()); // 1 Billion Tokens
        _mint(owner, amount);
    }
}

// File: contracts/fx-portal/IRootChainManager.sol

pragma solidity ^0.8.0;

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

// File: contracts/fx-portal/lib/RLPReader.sol

pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
        require(item.length > 0, "RLPReader: INVALID_BYTES_LENGTH");
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory)
    {
        require(isList(item), "RLPReader: ITEM_NOT_LIST");

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);
        uint256 listLength = _itemLength(item.memPtr);
        require(
            listLength == item.len,
            "RLPReader: LIST_DECODED_LENGTH_MISMATCH"
        );

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(item.len);

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        require(!isList(item), "RLPReader: DECODING_LIST_AS_ADDRESS");
        // 1 byte for the length prefix
        require(item.len == 21, "RLPReader: INVALID_ADDRESS_LENGTH");

        return address(bytes20(uint160(toUint(item))));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(!isList(item), "RLPReader: DECODING_LIST_AS_UINT");
        require(item.len <= 33, "RLPReader: INVALID_UINT_LENGTH");

        uint256 itemLength = _itemLength(item.memPtr);
        require(
            itemLength == item.len,
            "RLPReader: UINT_DECODED_LENGTH_MISMATCH"
        );

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        uint256 itemLength = _itemLength(item.memPtr);
        require(
            itemLength == item.len,
            "RLPReader: UINT_STRICT_DECODED_LENGTH_MISMATCH"
        );
        // one byte prefix
        require(item.len == 33, "RLPReader: INVALID_UINT_STRICT_LENGTH");

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 listLength = _itemLength(item.memPtr);
        require(
            listLength == item.len,
            "RLPReader: BYTES_DECODED_LENGTH_MISMATCH"
        );
        uint256 offset = _payloadOffset(item.memPtr);

        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        // add `isList` check if `item` is expected to be passsed without a check from calling function
        // require(isList(item), "RLPReader: NUM_ITEMS_NOT_LIST");

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            require(
                currPtr <= endPtr,
                "RLPReader: NUM_ITEMS_DECODED_LENGTH_MISMATCH"
            );
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        unchecked {
            // copy as many word sizes as possible
            for (; len >= WORD_SIZE; len -= WORD_SIZE) {
                assembly {
                    mstore(dest, mload(src))
                }

                src += WORD_SIZE;
                dest += WORD_SIZE;
            }

            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// File: contracts/fx-portal/lib/MerklePatriciaProof.sol

pragma solidity ^0.8.0;

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[16])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(
                    RLPReader.toUintStrict(currentNodeList[nextPathNibble])
                );
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(
                    RLPReader.toBytes(currentNodeList[0]),
                    path,
                    pathPtr
                );
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[1])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str)
        private
        pure
        returns (bytes1)
    {
        return
            bytes1(
                n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10
            );
    }
}

// File: contracts/fx-portal/lib/Merkle.sol

pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// File: contracts/access/Ownable.sol

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;

    // Sets the original owner of
    // contract when it is deployed
    constructor() {
        owner = msg.sender;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier restricted() {
        require(msg.sender == owner, "Must have admin role to invoke");
        _;
    }

    function transferOwner(address newOwner)
        external
        restricted
        returns (bool)
    {
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);

        return true;
    }
}

// File: contracts/fx-portal/tunnel/FxBaseRootTunnel.sol

pragma solidity ^0.8.0;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data)
        external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel is Ownable {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address fxChildTunnel_
    ) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
        fxChildTunnel = fxChildTunnel_;
    }

    // just in case
    function setFxChildTunnel(address _fxChildTunnel) public restricted {
        require(
            _fxChildTunnel != address(0),
            "fx child tunnel aka child issuance contract address must be specified"
        );
        fxChildTunnel = _fxChildTunnel;
    }

    // just in case
    function setFxRoot(address _fxRoot) public restricted {
        require(
            _fxRoot != address(0),
            "fxRoot contract address must be specified"
        );
        fxRoot = IFxStateSender(_fxRoot);
    }

    // just in case
    function setCheckpointManager(address _checkpointManager)
        public
        restricted
    {
        require(
            _checkpointManager != address(0),
            "checkpoint manager contract address must be specified"
        );
        checkpointManager = ICheckpointManager(_checkpointManager);
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData)
        internal
        returns (bytes memory)
    {
        RLPReader.RLPItem[] memory inputDataRLPList = inputData
        .toRlpItem()
        .toList();

        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                inputDataRLPList[2].toUint(), // blockNumber
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(
                    inputDataRLPList[8].toBytes()
                ), // branchMask
                inputDataRLPList[9].toUint() // receiptLogIndex
            )
        );
        require(
            processedExits[exitHash] == false,
            "FxRootTunnel: EXIT_ALREADY_PROCESSED"
        );
        processedExits[exitHash] = true;

        RLPReader.RLPItem[] memory receiptRLPList = inputDataRLPList[6]
        .toBytes()
        .toRlpItem()
        .toList();
        RLPReader.RLPItem memory logRLP = receiptRLPList[3].toList()[
            inputDataRLPList[9].toUint() // receiptLogIndex
        ];

        RLPReader.RLPItem[] memory logRLPList = logRLP.toList();

        // check child tunnel
        require(
            fxChildTunnel == RLPReader.toAddress(logRLPList[0]),
            "FxRootTunnel: INVALID_FX_CHILD_TUNNEL"
        );

        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(
                inputDataRLPList[6].toBytes(), // receipt
                inputDataRLPList[8].toBytes(), // branchMask
                inputDataRLPList[7].toBytes(), // receiptProof
                bytes32(inputDataRLPList[5].toUint()) // receiptRoot
            ),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            inputDataRLPList[2].toUint(), // blockNumber
            inputDataRLPList[3].toUint(), // blockTime
            bytes32(inputDataRLPList[4].toUint()), // txRoot
            bytes32(inputDataRLPList[5].toUint()), // receiptRoot
            inputDataRLPList[0].toUint(), // headerNumber
            inputDataRLPList[1].toBytes() // blockProof
        );

        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory receivedData = logRLPList[2].toBytes();
        bytes memory message = abi.decode(receivedData, (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (
            bytes32 headerRoot,
            uint256 startBlock,
            ,
            uint256 createdAt,

        ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            ).checkMembership(blockNumber - startBlock, headerRoot, blockProof),
            "FxRootTunnel: INVALID_HEADER"
        );
        return createdAt;
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

// File: contracts/issuance/IssuanceCommon.sol

pragma solidity 0.8.4;

abstract contract IssuanceCommon is Ownable {
    uint256 public immutable deploymentTimestamp;

    address public fundRecipient;
    bool public isContributionWindowOpen;
    bool public isContributionWindowClosed;
    bool public isRedemptionRegimeOpen;
    uint256 public contributionStartTimestamp;

    // Mapping contributors address to amount
    mapping(address => uint256) public contributorAmounts;

    mapping(address => bool) public claimsCheck;

    event ContributionWindowOpened(address indexed authorizer);
    event ContributionMade(address indexed contributor, uint256 value);
    event ContributionWindowClosed(address indexed authorizer, uint256 value);
    event RedemptionWindowOpened(
        address indexed authorizer,
        uint256 contributionValue,
        uint256 allocatedTokens
    );
    event TokensRedeemed(address indexed redeemer, uint256 value);
    event InvestmentFundTransferred(address indexed recipient, uint256 value);

    modifier validateRecipient(address _recipient) {
        require(_recipient != address(0), "recipient cannot be zero address");
        require(
            _recipient == fundRecipient,
            "recipient must match registered fund receiver!"
        );
        _;
    }

    constructor() {
        deploymentTimestamp = block.timestamp;
    }

    function openContributionWindow() external virtual returns (bool);

    function closeContributionWindow() external virtual returns (bool);

    function openRedemptionRegime() external virtual returns (bool);

    function registerFundRecipient(address _fundRecipient)
        external
        restricted
        returns (bool)
    {
        fundRecipient = _fundRecipient;

        return true;
    }

    function redeemTokens() external virtual returns (bool);
}

// File: contracts/issuance/IssuanceEthereum.sol

/**

YOLOrekt Token Issuance - 

YOLOrekt is issuing 5% of the 1 Billion total supply to raise capital to provide in-game liquidity. 
This contracts accepts ETH contributions for acquiring early YOLO tokens at a price that 
is determined at close by calculating proportion of funds raised on the ethereum root chain 
with respect to the polygon child chain and sending the appropriate share of YOLO tokens to the 
child issuance contract, while encumbering the appropriate amount (the remainder) for 
redemption by the contributors within the Ethereum (root) chain.

https://yolorekt.com 

Authors :
Garen Vartanian
Yogesh Srihari 

**/

pragma solidity 0.8.4;

contract IssuanceEthereum is IssuanceCommon, FxBaseRootTunnel {
    uint256 public constant TOTAL_ISSUANCE_CONTRACT_TOKENS =
        50 * 10**6 * 10**18; // 5% of 1B tokens

    // YOLOrekt's ERC20 Contracts
    YoloEthereumUtilityTokens public immutable yoloEthereumTokenContract;

    // Sum of contribution on Ethereum side
    uint256 public rootSum;

    // Remaining proportion after distribution Polygon side's contribution
    uint256 public rootIssuanceAllocatedTokens;

    // Polygon's Total Contribution Sum in Wei (mEth)
    uint256 public childSum;

    // Polygon sum received from child tunnel and processed
    bool public hasProcessedMessageFromChild;

    // Polygon side token proportion requested to be sent
    bool public hasRootToChildTransferRequest;

    // Predicate contract for ERC20 token lock and transfer across root to child
    address public predicateContractAddress;

    // Polygon root contracts watched by Heimdall nodes
    IRootChainManager public rootChainManagerContract;

    constructor(
        address yoloEthereumTokenAddress_,
        address checkpointManager_,
        address fxRoot_,
        address fxChildTunnel_,
        address rootChainManager_,
        address predicateContractAddress_
    ) FxBaseRootTunnel(checkpointManager_, fxRoot_, fxChildTunnel_) {
        require(
            yoloEthereumTokenAddress_ != address(0),
            "YOLO ethereum token contract address must be specified"
        );
        require(
            checkpointManager_ != address(0),
            "checkpointManager contract address must be specified"
        );
        require(
            fxRoot_ != address(0),
            "fxRoot contract address must be specified"
        );
        require(
            fxChildTunnel_ != address(0),
            "fx child tunnel aka child issuance contract address must be specified"
        );
        require(
            rootChainManager_ != address(0),
            "root chain manager contract address must be specified"
        );
        require(
            predicateContractAddress_ != address(0),
            "erc20 predicate contract address must be specified"
        );

        // Use ChainId to compare and stop contract instantiaion if its the wrong address

        yoloEthereumTokenContract = YoloEthereumUtilityTokens(
            yoloEthereumTokenAddress_
        );
        rootChainManagerContract = IRootChainManager(rootChainManager_);
        predicateContractAddress = predicateContractAddress_;
    }

    // just in case
    function setPredicateContractAddress(address contractAddress)
        external
        restricted
        returns (bool)
    {
        require(
            contractAddress != address(0),
            "erc20 predicate contract address must be specified"
        );
        predicateContractAddress = contractAddress;

        return true;
    }

    // just in case
    function setRootManagerContract(address contractAddress)
        external
        restricted
        returns (bool)
    {
        require(
            contractAddress != address(0),
            "root chain manager contract address must be specified"
        );
        rootChainManagerContract = IRootChainManager(contractAddress);

        return true;
    }

    // escape hatch - for unlikely scenario where incorrect amount of tokens transferred into
    // issaunce contract, e.g. value other than TOTAL_ISSUANCE_CONTRACT_TOKENS (50 Million)
    // transferred into IssuanceEthereum
    function returnYoloTokens(address ownerAddress, uint256 amount)
        external
        restricted
        returns (bool)
    {
        require(
            isContributionWindowOpen == false,
            "contribution window already opened"
        );

        yoloEthereumTokenContract.transfer(ownerAddress, amount);

        return true;
    }

    function openContributionWindow()
        external
        override
        restricted
        returns (bool)
    {
        require(
            yoloEthereumTokenContract.balanceOf(address(this)) ==
                TOTAL_ISSUANCE_CONTRACT_TOKENS,
            "50 million tokens must be transferred to issuance contract before issuance is started"
        );
        require(
            isContributionWindowOpen == false,
            "contribution window already opened"
        );

        isContributionWindowOpen = true;
        contributionStartTimestamp = block.timestamp;
        emit ContributionWindowOpened(msg.sender);

        return true;
    }

    function contribute() public payable returns (bool) {
        require(
            isContributionWindowOpen == true,
            "contribution window has not opened"
        );
        require(
            isContributionWindowClosed == false,
            "contribution window has closed"
        );
        require(msg.value >= 0.01 ether, "minimum contribution is 0.01 ether");

        uint256 contributorTotal = contributorAmounts[msg.sender] + msg.value;

        contributorAmounts[msg.sender] = contributorTotal;
        rootSum += msg.value;
        emit ContributionMade(msg.sender, msg.value);

        return true;
    }

    function closeContributionWindow()
        external
        override
        restricted
        returns (bool)
    {
        require(
            isContributionWindowOpen == true,
            "contribution window must be open before closing"
        );

        isContributionWindowClosed = true;

        emit ContributionWindowClosed(msg.sender, rootSum);

        return true;
    }

    function _processMessageFromChild(bytes memory data) internal override {
        childSum = abi.decode(data, (uint256));
        hasProcessedMessageFromChild = true;
    }

    // !!! remove virtual after testing
    function depositOnChildIssuanceContract()
        external
        virtual
        restricted
        returns (bool)
    {
        require(
            isContributionWindowClosed == true,
            "contribution window must be closed"
        );
        require(
            hasProcessedMessageFromChild == true,
            "childSum must be processed from child first"
        );
        require(
            hasRootToChildTransferRequest == false,
            "root to child transfer already requested"
        );
        require(
            predicateContractAddress != address(0),
            "predicate contract address must be set"
        );

        // expressions can overflow, assign sum first
        uint256 totalCrossChainSum = rootSum + childSum;
        uint256 childTokenAmount = (TOTAL_ISSUANCE_CONTRACT_TOKENS * childSum) /
            totalCrossChainSum;

        rootIssuanceAllocatedTokens =
            TOTAL_ISSUANCE_CONTRACT_TOKENS -
            childTokenAmount;

        yoloEthereumTokenContract.approve(
            predicateContractAddress,
            childTokenAmount
        );

        bytes memory encodedChildAmount = abi.encode(childTokenAmount);

        rootChainManagerContract.depositFor(
            fxChildTunnel,
            address(yoloEthereumTokenContract),
            encodedChildAmount
        );

        hasRootToChildTransferRequest = true;

        return true;
    }

    function openRedemptionRegime() external override returns (bool) {
        // check repeateadly - this means isContributionWindowClosed is also true
        require(
            hasRootToChildTransferRequest == true,
            "requires token transfer request to child and updated root token pool amount"
        );

        require(
            msg.sender == owner ||
                block.timestamp > contributionStartTimestamp + 60 days,
            "cannot open redemption window unless owner or 60 days since deployment"
        );
        require(
            isRedemptionRegimeOpen == false,
            "redemption regime already open"
        );

        isRedemptionRegimeOpen = true;

        emit RedemptionWindowOpened(
            msg.sender,
            rootSum,
            rootIssuanceAllocatedTokens
        );

        return true;
    }

    function migrateInvestmentFund(address payable recipient)
        external
        restricted
        validateRecipient(recipient)
        returns (bool)
    {
        require(
            isContributionWindowClosed == true,
            "contribution window must be closed"
        );

        uint256 contractBalance = address(this).balance;
        recipient.transfer(contractBalance);
        emit InvestmentFundTransferred(recipient, contractBalance);

        return true;
    }

    function redeemTokens() external override returns (bool) {
        // Which will unlock once the product goes live.
        require(
            isRedemptionRegimeOpen == true,
            "redemption window is not open yet"
        );
        require(claimsCheck[msg.sender] == false, "prior claim executed");

        claimsCheck[msg.sender] = true;

        uint256 claimAmount = (contributorAmounts[msg.sender] *
            rootIssuanceAllocatedTokens) / rootSum;

        contributorAmounts[msg.sender] = 0;

        yoloEthereumTokenContract.transfer(msg.sender, claimAmount);
        emit TokensRedeemed(msg.sender, claimAmount);

        return true;
    }
}