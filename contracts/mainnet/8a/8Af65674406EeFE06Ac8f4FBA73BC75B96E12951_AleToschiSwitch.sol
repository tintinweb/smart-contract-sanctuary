/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT

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

// File: contracts\AleToschiSwitch.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



interface IVotingToken is IERC20 {
    function burn(uint256 amount) external;
}

interface AleToschiSwitchPriceDumper {
    function pricePerETH(address) external view returns(uint256);
}

contract AleToschiSwitch {

    address private creator = msg.sender;

    address private switchPriceDumper;
    address private destinationTokenAddress;
    address[] private tokenAddresses;
    uint256[] private conversionsPerToken;
    uint256 private totalSupply;
    uint256 private snapshotBlock;
    uint256 private startBlock;

    constructor(address _switchPriceDumper, address _destinationTokenAddress, address[] memory _tokenAddresses, uint256 _totalSupply, uint256 _snapshotBlock, uint256 _startBlock) {
        switchPriceDumper = _switchPriceDumper;
        destinationTokenAddress = _destinationTokenAddress;
        tokenAddresses = _tokenAddresses;
        totalSupply = _totalSupply;
        snapshotBlock = _snapshotBlock;
        startBlock = _startBlock;
    }

    function info() external view returns(address, address, address[] memory, uint256[] memory, uint256, uint256, uint256) {
        return (switchPriceDumper, destinationTokenAddress, tokenAddresses, conversionsPerToken, totalSupply, snapshotBlock, startBlock);
    }

    function snapshot() external {
        require(block.number >= snapshotBlock, "too early");
        require(conversionsPerToken.length == 0, "already done");
        require(msg.sender == creator, "only creator");
        uint256[] memory tokenMarketCaps = new uint256[](tokenAddresses.length);
        uint256[] memory tokenTotalSupplies = new uint256[](tokenAddresses.length);
        uint256 cumulativeMarketCap = 0;
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 tokenPrice = AleToschiSwitchPriceDumper(switchPriceDumper).pricePerETH(tokenAddresses[i]);
            uint256 tokenTotalSupply = IERC20(tokenAddresses[i]).totalSupply();
            uint256 tokenMarketCap = tokenPrice * tokenTotalSupply;
            tokenTotalSupplies[i] = tokenTotalSupply;
            tokenMarketCaps[i] = tokenMarketCap;
            cumulativeMarketCap += tokenMarketCap;
        }
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 tokenRatio = (tokenMarketCaps[i] * 1e18) / cumulativeMarketCap;
            uint256 tokenNumerator = tokenRatio * totalSupply;
            uint256 conversionPerToken = tokenNumerator / tokenTotalSupplies[i];
            conversionsPerToken.push(conversionPerToken);
        }
    }

    modifier preConditionCheck(uint256 tokenAddressIndex, uint256 amount) {
        require(block.number >= startBlock, "too early");
        require(conversionsPerToken.length > 0, "snapshot");
        require(tokenAddressIndex < tokenAddresses.length, "unsupported");
        require(amount > 0, "amount");
        _;
    }

    function performSwitch(uint256 tokenAddressIndex, uint256 amount, address receiverInput) external preConditionCheck(tokenAddressIndex, amount) {
        address tokenAddress = tokenAddresses[tokenAddressIndex];
        IVotingToken token = IVotingToken(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        token.burn(amount);
        uint256 value = calculateAmount(tokenAddressIndex, amount);
        address receiver = receiverInput == address(0) ? msg.sender : receiverInput;
        IERC20(destinationTokenAddress).transfer(receiver, value);
    }

    function calculateAmount(uint256 tokenAddressIndex, uint256 amount) public preConditionCheck(tokenAddressIndex, amount) view returns(uint256) {
        return (conversionsPerToken[tokenAddressIndex] * amount) / 1e18;
    }
}