/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: OpenZeppelin/[email protected]/IERC721Receiver

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

// File: Oracle.sol

contract Oracle is IERC721Receiver {
    // The oracle operator
    address private operator;

    // The contract address of the Wrapped CryptoPunk ERC721
    // Mainnet: 0xb7f7f6c52f2e2fdb1963eab30438024864c313f6
    address public wrappedPunksContract;

    // The cost to complete an Oracle transaction
    uint256 public oraclePriceInWei;

    // Retrieves the balance of the given address
    mapping(address => uint256) public balanceOf;

    // Emitted when a Wrapped CryptoPunk ERC721 is received
    event CryptoPunkReceived(uint256 indexed id, address indexed from);

    // Emitted when the Oracle price has changed
    event OraclePriceChanged(uint256 indexed priceInWei);

    // Emitted when somebody funds the oracle
    event OracleFunded(uint256 indexed amountInWei, address indexed from);

    constructor(address _wrappedPunksContract, uint256 _oraclePriceInWei) {
        operator = msg.sender;
        wrappedPunksContract = _wrappedPunksContract;
        oraclePriceInWei = _oraclePriceInWei;
    }

    /**
     * @dev Modifier that only oracle operators may call
     */
    modifier onlyOracleOperator() {
        require(
            msg.sender == operator,
            "Only the oracle operator may perform this action"
        );
        _;
    }

    /**
     * @dev Sets the price to fulfill the oracle
     * @notice Only oracle operators may call this function
     */
    function setPrice(uint256 priceInWei) public onlyOracleOperator {
        oraclePriceInWei = priceInWei;
        emit OraclePriceChanged(priceInWei);
    }

    /**
     * @dev Fund the Oracle to cover gas fees and other costs
     * @notice Check the current price by retrieving `oraclePriceInWei`
     */
    function fundOracle() public payable {
        (bool sent, ) = operator.call{value: msg.value}("");
        require(sent, "Failed to send Ether to the oracle operator");
        balanceOf[msg.sender] += msg.value;
        emit OracleFunded(msg.value, msg.sender);
    }

    /**
     * @dev Implementation of IERC721Receiver
     * @notice Only accepts ERC721 tokens from the `wrappedPunksContract`
     * @notice The sender must have already funded the oracle with the `oraclePriceInWei`
     */
    function onERC721Received(
        address sender,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4 selector) {
        require(
            msg.sender == address(wrappedPunksContract),
            "The Oracle only accepts Wrapped CryptoPunks"
        );

        require(
            balanceOf[from] >= oraclePriceInWei,
            "You must fund the oracle with the price set in `oraclePriceInWei`"
        );

        emit CryptoPunkReceived(tokenId, sender);
        balanceOf[from] -= oraclePriceInWei;

        return this.onERC721Received.selector;
    }

    /**
     * @dev Returns the current oracle operator
     */
    function getOperator() external view returns(address) {
        return operator;
    }
}