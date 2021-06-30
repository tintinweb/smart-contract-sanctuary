//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./VaultStorage.sol";
import "./OpenZeppelin/token/ERC721/ERC721Holder.sol";

interface IVaultFactory {
    function logic() external returns (address);
    function settings() external returns (address);

    function tokenParams()
        external
        returns (
            string memory name,
            string memory symbol,
            uint256 supply
        );

    function vaultParams()
        external
        returns (
            address curator,
            address token,
            uint256 id,
            uint256 price,
            uint256 fee
        );
}

contract VaultProxy is VaultStorage, ERC721Holder {
    // we need to be a bit fancy here due to stack too deep errors
    constructor() {
        {
            logic = IVaultFactory(msg.sender).logic();
            settings = IVaultFactory(msg.sender).settings();
        }

        {
            (
                name, 
                symbol, 
                totalSupply
            ) = IVaultFactory(msg.sender).tokenParams();
        }
        
        uint256 _price;
        {
            (
                curator,
                token,
                id,
                _price,
                fee
            ) = IVaultFactory(msg.sender).vaultParams();
        }

        {
            // Initialize mutable storage.
            auctionLength = 7 days;
            auctionState = State.inactive;
            lastClaimed = block.timestamp;
            votingTokens = _price == 0 ? 0 : totalSupply;
            reserveTotal = _price * totalSupply;
            userPrices[curator] = _price;
            balanceOf[curator] = totalSupply;
        }
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract VaultStorage {

    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public logic;

    /// -----------------------------------
    /// -------- ERC721 INFORMATION -------
    /// -----------------------------------

    address public token;
    uint256 public id;

    /// -----------------------------------
    /// -------- ERC20 INFORMATION --------
    /// -----------------------------------
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the length of auctions
    uint256 public auctionLength;

    /// @notice reservePrice * votingTokens
    uint256 public reserveTotal;

    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    /// @notice the current user winning the token auction
    address payable public winning;

    enum State { inactive, live, ended, redeemed }

    State public auctionState;

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    /// @notice the governance contract which gets paid in ETH
    address public settings;

    /// @notice the address who initially deposited the NFT
    address public curator;

    /// @notice the AUM fee paid to the curator yearly. 3 decimals. ie. 100 = 10%
    uint256 public fee;

    /// @notice the last timestamp where fees were claimed
    uint256 public lastClaimed;

    /// @notice a boolean to indicate if the vault has closed
    bool public vaultClosed;

    /// @notice the number of ownership tokens voting on the reserve price at any given time
    uint256 public votingTokens;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}