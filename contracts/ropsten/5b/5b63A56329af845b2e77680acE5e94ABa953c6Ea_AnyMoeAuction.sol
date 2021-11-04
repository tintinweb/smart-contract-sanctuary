/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


interface AnyMoeNFTAuctionInterface {
    event TransferIn(address owner, uint256 tokenId, uint256 amount);
    event TransferOut(address destination, uint256 tokenId, uint256 amount);
    event CreateAuction(uint256 auctionId, address owner, uint256 tokenId, uint256 amount, uint baseBid, uint bidIncrement, uint duration);
    event CancelAuction(uint256 auctionId);
    event PlaceBid(uint256 auctionId, address bidder, uint bidAmount);
    event WithdrawBid(uint256 auctionId, address bidder);
    event DelayAuction(uint256 auctionId);
    event SettleAuction(uint256 auctionId, address destination, uint256 amount);
    event WithdrawAuction(uint256 auctionId, address destination, uint amount);

    function withdrawToken(uint256 id, uint256 amount) external;
    function createAuction(uint256 tokenId, uint256 amount, uint baseBid, uint bidIncrement, uint duration) external returns (uint256);
    function placeBid(uint256 auctionId) payable external;
    function settleAuction(uint256 auctionId) payable external;
    function withdrawBid(uint256 auctionId) external;
    function withdrawAuction(uint256 auctionId) external;
    function cancelAuction(uint256 auctionId) external;
}


contract AnyMoeAuction is Context, ERC165, IERC1155Receiver, AnyMoeNFTAuctionInterface {
    using Address for address;

    address payable private _owner;

    address private _nft_contract_address;
    IERC1155 private _nft_contract;

    uint256 private _increment_auction_id = 0x0;

    mapping(address => mapping(uint256 => uint256)) private _nft_balances;

    struct Auction {
        address owner;
        uint256 tokenId;
        uint256 amount;
        uint baseBid;
        uint bidIncrement;
        uint duration;
        uint startTime;
        bool settled;
        bool withdrawed;

        uint heighestBid;
        address heighestBidder;
        mapping(address => uint) bids;
        uint bidderCount;
    }

    mapping(uint256 => Auction) private _auctions;

    uint private _fee;

    uint private _fee_percentage;

    constructor(address nft_address, uint fee_percentage) {
        _owner = payable(_msgSender());
        _nft_contract_address = nft_address;
        _nft_contract = IERC1155(nft_address);
        _fee_percentage = fee_percentage;
    }

    function adminChangeFee(uint fee_percentage) public virtual {
        require(_msgSender() == _owner, "only anymoe team is allowed");
        _fee_percentage = fee_percentage;
    }

    function adminWithdrawFee() public virtual {
        require(_msgSender() == _owner, "only anymoe team is allowed");
        _owner.transfer(_fee);
        _fee = 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external virtual override returns(bytes4) {
        require(_msgSender() == _nft_contract_address, "nft must be from specified contract");
        _nft_balances[_from][_id] += _value;
        emit TransferIn(_from, _id, _value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual override returns(bytes4) {
        require(_msgSender() == _nft_contract_address, "nft must be from specified contract");
        require(_ids.length == _values.length, "ids and amounts length mismatch");
        for (uint256 i = 0; i < _ids.length; ++i) {
            _nft_balances[_from][_ids[i]] += _values[i];
            emit TransferIn(_from, _ids[i], _values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function withdrawToken(uint256 id, uint256 amount) public virtual override {
        address owner = _msgSender();
        require(_nft_balances[owner][id] >= amount, "no enough nfts");
        _nft_balances[owner][id] -= amount;
        _nft_contract.safeTransferFrom(address(this), owner, id, amount, "");
        emit TransferOut(owner, id, amount);
    }

    function createAuction(uint256 tokenId, uint256 amount, uint baseBid, uint bidIncrement, uint duration) public virtual override returns (uint256) {
        address owner = _msgSender();
        require(_nft_balances[owner][tokenId] >= amount, "no enough nfts");
        uint256 auctionId = _increment_auction_id++;
        _nft_balances[owner][tokenId] -= amount;

        require(baseBid <= 2 ether, "baseBid is too heigh");
        require(bidIncrement <= 0.8 ether, "bidIncrement is too heigh");
        require(duration <= 2 weeks, "duration is too long");
        require(duration >= 12 hours, "duration is too short");
        _auctions[auctionId].owner = owner;
        _auctions[auctionId].tokenId = tokenId;
        _auctions[auctionId].amount = amount;
        _auctions[auctionId].baseBid = baseBid;
        _auctions[auctionId].bidIncrement = bidIncrement;
        _auctions[auctionId].duration = duration;

        emit CreateAuction(auctionId, owner, tokenId, amount, baseBid, bidIncrement, duration);
        return auctionId;
    }

    function placeBid(uint256 auctionId) public payable virtual override {
        require(_auctions[auctionId].owner != address(0), "no such auction");
        address bidder = _msgSender();
        if (_auctions[auctionId].startTime == 0) { // haven't start
            require(msg.value >= _auctions[auctionId].baseBid, "no enough money");
            _auctions[auctionId].startTime = block.timestamp;
            _auctions[auctionId].heighestBid = msg.value;
            _auctions[auctionId].heighestBidder = bidder;
            _auctions[auctionId].bids[bidder] = msg.value;
        } else {
            uint stopTime = _auctions[auctionId].startTime + _auctions[auctionId].duration;
            require(stopTime > block.timestamp, "auction already ended");
            _auctions[auctionId].bids[bidder] += msg.value;
            require(_auctions[auctionId].bids[bidder] >= _auctions[auctionId].heighestBid + _auctions[auctionId].bidIncrement, "no enough money");
            _auctions[auctionId].heighestBid = _auctions[auctionId].bids[bidder];
            _auctions[auctionId].heighestBidder = bidder;
            if (stopTime - block.timestamp <= 15 minutes) {
                _auctions[auctionId].duration += 15 minutes;
                emit DelayAuction(auctionId);
            }
        }
        _auctions[auctionId].bidderCount += 1;
        emit PlaceBid(auctionId, bidder, _auctions[auctionId].heighestBid);
    }

    function withdrawBid(uint256 auctionId) public virtual override {
        require(_auctions[auctionId].owner != address(0), "no such auction");
        address payable bidder = payable(_msgSender());
        require(bidder != _auctions[auctionId].heighestBidder, "heighest bidder can not withdraw");
        uint amount = _auctions[auctionId].bids[bidder];
        require(amount > 0, "you poor");
        _auctions[auctionId].bids[bidder] = 0;
        _auctions[auctionId].bidderCount -= 1;
        if (!bidder.send(amount)) {
            _auctions[auctionId].bids[bidder] = amount;
            _auctions[auctionId].bidderCount += 1;
        } else {
            emit WithdrawBid(auctionId, bidder);
        }
    }

    function settleAuction(uint256 auctionId) public payable virtual override {
        address payable sender = payable(_msgSender());
        require(_auctions[auctionId].owner != address(0), "no such auction");
        require(_auctions[auctionId].startTime != 0, "not start");
        require(_auctions[auctionId].settled == false, "already settled");
        require(_auctions[auctionId].startTime + _auctions[auctionId].duration < block.timestamp, "auction continue");
        require(sender == _auctions[auctionId].heighestBidder, "must heighest bidder");
        uint fee = _auctions[auctionId].heighestBid * _fee_percentage / 100;
        require(msg.value >= fee, "must pay enough fee");
        _auctions[auctionId].settled = true;
        _nft_balances[sender][_auctions[auctionId].tokenId] = _auctions[auctionId].amount;
        if (msg.value > fee) {
            sender.transfer(msg.value - fee);
        }
        _fee += fee;
        emit SettleAuction(auctionId, sender, _auctions[auctionId].amount);
    }

    function withdrawAuction(uint256 auctionId) public virtual override {
        address payable owner = payable(_msgSender());
        require(owner == _auctions[auctionId].owner, "must be owner");
        require(_auctions[auctionId].startTime != 0, "not start");
        require(_auctions[auctionId].withdrawed == false, "already withdrawed");
        require(_auctions[auctionId].startTime + _auctions[auctionId].duration < block.timestamp, "auction continue");
        _auctions[auctionId].withdrawed = true;
        uint fee = _auctions[auctionId].heighestBid * _fee_percentage / 100;
        uint withdraw = _auctions[auctionId].heighestBid - fee;
        if (!owner.send(withdraw)) {
            _auctions[auctionId].withdrawed = false;
        }
        _fee += fee;
        emit WithdrawAuction(auctionId, owner, withdraw);
    }

    function cancelAuction(uint256 auctionId) public virtual override {
        require(_auctions[auctionId].owner == _msgSender(), "only owner can cancel");
        require(_auctions[auctionId].startTime == 0, "started auction can not be canceled");
        _nft_balances[_msgSender()][_auctions[auctionId].tokenId] += _auctions[auctionId].amount;
        delete _auctions[auctionId];
        emit CancelAuction(auctionId);
    }
}