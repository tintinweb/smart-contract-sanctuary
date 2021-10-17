// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract HuanCasino is ERC1155Holder {
    address public owner;

    //check the pullFuns
    address public checker;

    address public lowbTokenAddress;

    address public uyangTonesGates;

    address public uyangStone;

    bool public checkerAllow = false;

    bool public poolSwitch1 = true;

    // The max user of bets that cannot be exceeded to avoid excessive gas consumption
    // when distributing the prizes and restarting the game
    uint256 public maximumBetsNr = 5;
    uint256 public BET_BASE = 5;

    // The total amount of Ether bet for this current game
    uint256 public totalBet_1;

    uint256 public wuyangTotal;

    // The total number of bets the users have made
    uint256 public numberOfBets_1;

    // Save player when betting number
    address[] public players_1;

    // The number that won the last game
    uint256 public numberWinner_1;

    mapping (address => uint) public pendingWithdrawals;

    mapping (address => uint) public uyangPendingWithdrawals;

    // Save player info
    struct Player {
        uint256 amountBet;
        uint256 numberSelected;
    }

    // The address of the player and => the user info
    mapping(address => Player) public playerInfo_1;

    mapping(uint256 => uint256) public nftsOfBalance;
    mapping(uint256 => uint256) public numberMapNftId_1;

    // Event watch when player win
    event Won(bool _status, address _address, uint256 _winnumber);

    event Bet(address _address, uint256 _amount, uint256 score);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address lowbToken_,
        address checker_,
        address _uyangNft,
        address _uyangToken
    ) public payable {
        lowbTokenAddress = lowbToken_;
        owner = msg.sender;
        checker = checker_;
        uyangTonesGates = _uyangNft;
        uyangStone = _uyangToken;

        numberMapNftId_1[1] = 1;
        numberMapNftId_1[2] = 2;
        numberMapNftId_1[3] = 3;
        numberMapNftId_1[4] = 4;
        numberMapNftId_1[5] = 5;
        numberMapNftId_1[6] = 6;
        numberMapNftId_1[7] = 7;
        numberMapNftId_1[8] = 8;
        numberMapNftId_1[9] = 9;
        numberMapNftId_1[10] = 10;
    }

    // fallback
    fallback() external payable {}

  function deposit(uint amount) public {
    require(amount > 0, "You deposit nothing!");
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transferFrom(tx.origin, address(this), amount), "Lowb transfer failed");
    pendingWithdrawals[tx.origin] +=  amount;
  }

  function depositUyang(uint amount) public {
    require(amount > 0, "You deposit nothing!");
    IERC20 token = IERC20(uyangStone);
    require(token.transferFrom(tx.origin, address(this), amount), "Lowb transfer failed");
    uyangPendingWithdrawals[address(this)] +=  amount;
  }

  function withdraw(uint amount) public {
      require(amount <= pendingWithdrawals[tx.origin], "amount larger than that pending to withdraw");  
      pendingWithdrawals[tx.origin] -= amount;
      IERC20 token = IERC20(lowbTokenAddress);
      require(token.transfer(tx.origin, amount), "Lowb transfer failed");
  }

    // function kill() public {
    //   if (msg.sender == owner)
    //     selfdestruct(owner);
    // }

    function setBetBase(uint256 _base) public onlyOwner {
        BET_BASE = _base;
    }

    function setCheckerAllow(bool allow_) public {
        require(msg.sender == checker);
        checkerAllow = allow_;
    }

    function setPlloSwitch1(bool open_) public onlyOwner {
        poolSwitch1 = open_;
    }

    function setMaxBetsNr(uint256 _maximumBetsNr) public onlyOwner {
        if (_maximumBetsNr >= 0) {
            maximumBetsNr = _maximumBetsNr;
        }
    }

    /// @notice Check if a player exists in the current game
    /// @param player The address of the player to check
    /// @return bool Returns true is it exists or false if it doesn't
    function checkPlayerExists(address player) public view returns (bool) {
        for (uint256 i = 0; i < players_1.length; i++) {
            if (players_1[i] == player) return true;
        }

        return false;
    }

    function getBetNumber(address player) public view returns (uint256) {
        return playerInfo_1[player].numberSelected;
    }

    /// @notice To bet for a number by sending Ether
    /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
    function bet_1(uint256 numberSelected) public payable {
        uint256 betValue1 = 100000 ether;
        require(poolSwitch1, "the pool close");
        // Check that the player doesn't exists
        require(!checkPlayerExists(msg.sender), "the player is in beting");
        // Check that the number to bet is within the range
        require(numberSelected <= 10 && numberSelected >= 1);

        require(pendingWithdrawals[msg.sender] >= betValue1, "you dont desposit enough lowb");

        require(numberOfBets_1 <= maximumBetsNr, "maximum number of bet");
        numberOfBets_1++;
        pendingWithdrawals[msg.sender] -= betValue1 ;
        pendingWithdrawals[address(this)] += betValue1;

        uint256 uyangAmout = betValue1 / 100;
        wuyangTotal += uyangAmout;


        IERC20 uyangToken = IERC20(uyangStone);
        require(
            uyangToken.transfer(tx.origin, uyangAmout),
            "uyangStone transfer failed"
        );
        uyangPendingWithdrawals[address(this)] -=  uyangAmout;
 
        // Set the number bet for that player
        playerInfo_1[msg.sender].amountBet = betValue1;
        playerInfo_1[msg.sender].numberSelected = numberSelected;
        players_1.push(msg.sender);
        totalBet_1 += betValue1;

        if (numberOfBets_1 >= maximumBetsNr) {
            generateNumberWinner_1();
        } else {
            emit Bet(msg.sender, betValue1, 0);
        }

        //We need to change this in order to be secure
    }

    /// @notice Generates a random number between 1 and 10 both inclusive.
    /// Can only be executed when the game ends.
    function generateNumberWinner_1() private {
        uint256 numberGenerated = (block.number % BET_BASE) + 1;
        numberWinner_1 = numberGenerated;
        distributePrizes_1(numberGenerated);
    }

    /// @notice Sends the corresponding Ether to each winner then deletes all the
    /// players for the next game and resets the `totalBet` and `numberOfBets`
    function distributePrizes_1(uint256 numberWin) private {
        address[100] memory winners;
        address[100] memory losers;
        uint256 countWin = 0;
        uint256 countLose = 0;

        uint256 salt = 0;

        //随机数加盐
        for (uint256 i = 0; i < players_1.length; i++) {
            uint256 playernum = uint256(uint160(address(players_1[i])));
            salt += (playernum % BET_BASE) + 1;
        }

        numberWinner_1 = ((numberWin + salt) % BET_BASE) + 1;

        for (uint256 i = 0; i < players_1.length; i++) {
            address playerAddress = players_1[i];
            if (playerInfo_1[playerAddress].numberSelected == numberWinner_1) {
                winners[countWin] = playerAddress;
                sendNftTo(
                    playerAddress,
                    numberMapNftId_1[(block.number % 10) + 1],
                    1
                );
                countWin++;
            } else {
                losers[countLose] = playerAddress;
                countLose++;
            }
        }

        if (countWin != 0) {
            for (uint256 j = 0; j < countWin; j++) {
                if (winners[j] != address(0)) {
                    emit Won(true, winners[j], numberWinner_1);
                }
            }
        } else {
            //没有人中奖的时候，退回100%
            for (uint256 i = 0; i < players_1.length; i++) {
                address playerAddress = players_1[i];
            }
        }

        for (uint256 l = 0; l < losers.length; l++) {
            if (losers[l] != address(0))
                emit Won(false, losers[l], numberWinner_1);
        }

        for (uint256 i = 0; i < players_1.length; i++) {
            delete playerInfo_1[players_1[i]];
        }

        resetData_1();
    }

    // Restart game
    function resetData_1() private {
        delete players_1;
        totalBet_1 = 0;
        numberOfBets_1 = 0;
    }

    function pullFundsNft(uint256 id) public onlyOwner {
        IERC1155 nftToken = IERC1155(uyangTonesGates);
        nftToken.safeTransferFrom(address(this), owner, id, nftsOfBalance[id], "0x00");
    }

    function pullFundsLowb(uint256 amout) public onlyOwner {
        IERC20 lowb = IERC20(lowbTokenAddress);
        require(
            lowb.transferFrom(address(this), owner, amout),
            "Lowb transfer failed"
        );
    }
    
    /** not enough nft，you will not receive nft
     */
    function sendNftTo(address player, uint256 id, uint256 nftAmout) private {
        if (nftsOfBalance[id] >= nftAmout) {
            require(player != address(0), "player address invalid");
            IERC1155 nftToken = IERC1155(uyangTonesGates);
            nftToken.safeTransferFrom(address(this), player, id, nftAmout, "0x00");
            nftsOfBalance[id] -= nftAmout;
        }
    }

    function setNumberMapNftId_1(uint256 number, uint256 id) public onlyOwner {
        numberMapNftId_1[number] = id;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        nftsOfBalance[id] += value;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override returns (bytes4) {
        for (uint256 i = 0; i < ids.length; i++) {
            nftsOfBalance[i] += values[i];
        }
        return this.onERC1155BatchReceived.selector;
    }
}