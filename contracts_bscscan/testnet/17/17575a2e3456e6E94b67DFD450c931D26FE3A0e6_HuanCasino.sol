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
import "./LoserGameRankData.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract HuanCasino is ERC1155Holder {
  address public owner;

  //check the pullFuns
  address public checker;

  address public lowbTokenAddress;

  address public uyangTonesGates;

  bool public checkerAllow = false;

  bool public poolSwitch1 = true;
  bool public poolSwitch2 = true;
  bool public poolSwitch3 = true;

  // The total amount of Ether bet for this current game
  uint256 public totalBet_1;

  uint256 public totalBet_5;

  uint256 public totalBet_10;

  uint256 public wuyangTotal;

  // The total number of bets the users have made
  uint256 public numberOfBets_1;

  uint256 public numberOfBets_5;

  uint256 public numberOfBets_10;


  // The max user of bets that cannot be exceeded to avoid excessive gas consumption
  // when distributing the prizes and restarting the game
  uint256 public maximumBetsNr = 10;

  // Save player when betting number
  address[] public players_1;

  address[] public players_5;

  address[] public players_10;


  // The number that won the last game
  uint public numberWinner_1;

  uint public numberWinner_5;

  uint public numberWinner_10;


  // Save player info
  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  // The address of the player and => the user info
  mapping(address => Player) public playerInfo_1;

  mapping(address => Player) public playerInfo_5;

  mapping(address => Player) public playerInfo_10;


  mapping (address => uint) public pendingWithdrawals;

  mapping (address => uint) public scoreMap;

  mapping (address => mapping(uint => uint)) public winnerMap_1;
  mapping (address => mapping(uint => uint)) public winnerMap_5;
  mapping (address => mapping(uint => uint)) public winnerMap_10;

  mapping (uint => uint) public totalWinnerMap_1;
  mapping (uint => uint) public totalWinnerMap_5;
  mapping (uint => uint) public totalWinnerMap_10;

  mapping (uint => uint) public nftsOfBalance;
  mapping (uint=> uint) public numberMapNftId_1;
  mapping (uint=> uint) public numberMapNftId_5;
  mapping (uint=> uint) public numberMapNftId_10;

  // Event watch when player win
  event Won(bool _status, address _address, uint _winnumber);

  event Bet(address _address, uint _amount, uint score);



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address lowbToken_, address checker_, address _uyangNft ) public payable {
    lowbTokenAddress = lowbToken_;
    owner = msg.sender;
    checker = checker_;
    uyangTonesGates = _uyangNft;
    numberMapNftId_1[1] = 1;
    numberMapNftId_1[1] = 1;
    numberMapNftId_1[1] = 1;
    numberMapNftId_1[1] = 1;
    numberMapNftId_1[1] = 1;
    numberMapNftId_1[1] = 1;
  }


  // fallback
 fallback() external payable {}

  // function kill() public {
  //   if (msg.sender == owner) 
  //     selfdestruct(owner);
  // }

  function setCheckerAllow(bool allow_) public {
    require(msg.sender == checker);
    checkerAllow = allow_;
  }

  function setPlloSwitch1(bool open_) public onlyOwner {
    poolSwitch1 = open_;
  }

  function setPlloSwitch2(bool open_) public onlyOwner {
    poolSwitch2 = open_;
  }

  function setPlloSwitch3(bool open_) public onlyOwner {
    poolSwitch3 = open_;
  }

  function setMaxBetsNr(uint256 _maximumBetsNr) public onlyOwner {
    if (_maximumBetsNr >= 0) {
      maximumBetsNr = _maximumBetsNr;
    }
  }



  function getPendingWithdrawals() public view returns(uint) {
    return pendingWithdrawals[msg.sender];
  }

  function getScore() public view returns(uint) {
    return scoreMap[msg.sender];
  }

  function getOtherScore(address player) public view returns(uint) {
    return scoreMap[player];
  }

//get tones token
  function getTonesToken(address player, uint level, uint tonesIndex) public view returns(uint) {
    if (level == 1) {
      return winnerMap_1[player][tonesIndex];
    } else if (level == 2) {
      return winnerMap_5[player][tonesIndex];
    } else if (level == 3) {
      return winnerMap_10[player][tonesIndex];
    } else {
      return 0;
    }
  }

  function getTotalTonesToken(uint level, uint tonesIndex) public view returns(uint) {
    if (level == 1) {
      return totalWinnerMap_1[tonesIndex];
    } else if (level == 2) {
      return totalWinnerMap_5[tonesIndex];
    } else if (level == 3) {
      return totalWinnerMap_10[tonesIndex];
    } else {
      return 0;
    }
  }


  /// @notice Check if a player exists in the current game
  /// @param player The address of the player to check
  /// @return bool Returns true is it exists or false if it doesn't
  function checkPlayerExists(address player) public view returns(bool) {
    for (uint256 i = 0; i < players_1.length; i++) {
      if (players_1[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_5.length; i++) {
      if (players_5[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_10.length; i++) {
      if (players_10[i] == player) 
        return true;
    }

    return false;
  }

  /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_5(uint256 numberSelected) public payable {

    uint256 betValue5 = 50000 ether;

    require(poolSwitch2, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);

    require(numberOfBets_5 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_5++;
    
    //发送到合约
    IERC20 lowb = IERC20(lowbTokenAddress);
    require(lowb.transferFrom(msg.sender, address(this), betValue5), "Lowb transfer failed");
    pendingWithdrawals[address(this)] += betValue5;

    //扣除手续费
    wuyangTotal += betValue5 / 100;

    // Set the number bet for that player
    playerInfo_5[msg.sender].amountBet = betValue5;
    playerInfo_5[msg.sender].numberSelected = numberSelected;
    players_5.push(msg.sender);
    totalBet_5 += betValue5;
    scoreMap[msg.sender] += betValue5 / 100;
    
    if (numberOfBets_5 >= maximumBetsNr) {
       generateNumberWinner_5(); 
    } else {
      emit Bet(msg.sender, betValue5, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_5() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_5 = numberGenerated;
    distributePrizes_5(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_5(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_5.length; i++) {
      uint256 playernum = uint256(uint160(address(players_5[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_5 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_5.length; i++) {
      address playerAddress = players_5[i];
      if (playerInfo_5[playerAddress].numberSelected == numberWinner_5) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        winnerMap_5[playerAddress][numberWinner_5] += 1;
        totalWinnerMap_5[numberWinner_5] += 1;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
    }

    if (countWin != 0) {
      //每个赢家分到的盈利
      for (uint256 j = 0; j < countWin; j++){
        if (winners[j] != address(0)) {
          //赢家的权重*100，算出结果后在除100
        
          emit Won(true, winners[j], numberWinner_5);
        }
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_5.length; i++) {
          address playerAddress = players_5[i];
          
        }
    }

    for (uint256 l = 0; l < losers.length; l++){
      if (losers[l] != address(0))
        emit Won(false, losers[l], 0);
    }


    for (uint256 i = 0; i < players_5.length; i++) {
      delete playerInfo_5[players_5[i]];
    }

    resetData_5();
  }

  function getRankScore() public view returns(uint256) {
    return scoreMap[msg.sender];
  }

  function getBetNumber(address player, uint bettype) public view returns(uint) {
    if (bettype == 1) {
      return playerInfo_1[player].numberSelected;
    } else if (bettype == 5) {
      return playerInfo_5[player].numberSelected;
    } else if (bettype == 10) {
      return playerInfo_10[player].numberSelected;
    } else {
      return 0;
    }
    
  }

  // Restart game
  function resetData_5() private {
    delete players_5;
    totalBet_5 = 0;
    numberOfBets_5 = 0;
  }

  function pullFunds() public {
      require(msg.sender == owner, "Only owner can pull the funds!");
      require(checkerAllow, "pull the funds need checher agree");
      IERC20 lowb = IERC20(lowbTokenAddress);
      lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
      pendingWithdrawals[address(this)] = 0;
  }


    /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_1(uint256 numberSelected) public payable {

    uint256 betValue1 = 10000 ether;
    require(poolSwitch1, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);

    require(numberOfBets_1 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_1++;


    IERC20 lowb = IERC20(lowbTokenAddress);
    require(lowb.transferFrom(msg.sender, address(this), betValue1), "Lowb transfer failed");
    pendingWithdrawals[address(this)] += betValue1;


    wuyangTotal += betValue1 / 100;

    // Set the number bet for that player
    playerInfo_1[msg.sender].amountBet = betValue1;
    playerInfo_1[msg.sender].numberSelected = numberSelected;
    players_1.push(msg.sender);
    totalBet_1 += betValue1;
    scoreMap[msg.sender] += betValue1 / 100;
    
    if (numberOfBets_1 >= maximumBetsNr) {
       generateNumberWinner_1(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_1() private {
    uint256 numberGenerated = block.number % 10 + 1;
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
    for(uint256 i = 0; i < players_1.length; i++) {
      uint256 playernum = uint256(uint160(address(players_1[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_1 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_1.length; i++) {
      address playerAddress = players_1[i];
      if (playerInfo_1[playerAddress].numberSelected == numberWinner_1) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        winnerMap_1[playerAddress][numberWinner_1] += 1;
        totalWinnerMap_1[numberWinner_1] +=1;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
    }

    if (countWin != 0) {
      for (uint256 j = 0; j < countWin; j++){
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


    for (uint256 l = 0; l < losers.length; l++){
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


      /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_10(uint256 numberSelected) public payable {

    uint256 betValue1 = 100000 ether;
    require(poolSwitch3, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    require(numberOfBets_10 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_10++;

    IERC20 lowb = IERC20(lowbTokenAddress);
    require(lowb.transferFrom(msg.sender, address(this), betValue1), "Lowb transfer failed");
    pendingWithdrawals[address(this)] += betValue1;

    wuyangTotal += betValue1 / 100;

    // Set the number bet for that player
    playerInfo_10[msg.sender].amountBet = betValue1;
    playerInfo_10[msg.sender].numberSelected = numberSelected;
    players_10.push(msg.sender);
    totalBet_10 += betValue1;
    scoreMap[msg.sender] += betValue1 / 100;
    
    if (numberOfBets_10 >= maximumBetsNr) {
       generateNumberWinner_10(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_10() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_10 = numberGenerated;
    distributePrizes_10(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_10(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_10.length; i++) {
      uint256 playernum = uint256(uint160(address(players_10[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_10 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_10.length; i++) {
      address playerAddress = players_10[i];
      if (playerInfo_10[playerAddress].numberSelected == numberWinner_10) {
        winners[countWin] = playerAddress;
        //给赢家发送nft
        winnerMap_10[playerAddress][numberWinner_10] += 1;
        totalWinnerMap_10[numberWinner_10] += 1;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
    }

    if (countWin != 0) {
      for (uint256 j = 0; j < countWin; j++){
        if (winners[j] != address(0)) {
          //赢家的权重*100，算出结果后在除100
          emit Won(true, winners[j], numberWinner_10);
        }
      }
    } else {
        
    }

    for (uint256 l = 0; l < losers.length; l++){
      if (losers[l] != address(0))
        emit Won(false, losers[l], numberWinner_10);
    }


    for (uint256 i = 0; i < players_10.length; i++) {
      delete playerInfo_10[players_10[i]];
    }
    resetData_10();
  }

    // Restart game
  function resetData_10() private {
    delete players_10;
    totalBet_10 = 0;
    numberOfBets_10 = 0;
  }

  function pullFundsNft(uint id) public onlyOwner {
    IERC1155 nftToken = IERC1155(uyangTonesGates);
    nftToken.safeTransferFrom(address(this), owner, id, nftsOfBalance[id], "0x00");
  }

  function sendNftTo(address player, uint id) public {
    require(nftsOfBalance[id] > 0, "not enough nft");
    require(player != address(0), "player address invalid");
    IERC1155 nftToken = IERC1155(uyangTonesGates);
    nftToken.safeTransferFrom(address(this), player, id, 1, "0x00");
    nftsOfBalance[id] --;
  }

  function setNumberMapNftId_1(uint number, uint id) public onlyOwner {
    numberMapNftId_1[number] = id;
  }

  function setNumberMapNftId_5(uint number, uint id) public onlyOwner {
    numberMapNftId_5[number] = id;
  }

  function setNumberMapNftId_10(uint number, uint id) public onlyOwner {
    numberMapNftId_10[number] = id;
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
        for (uint i = 0; i < ids.length; i++) {
          nftsOfBalance[i] += values[i];
        }
        return this.onERC1155BatchReceived.selector;
    }

}

pragma solidity ^0.8.0;

contract LoserGameRankData{

  mapping(address => uint256) public scores;
  mapping(address => address) _nextPlayers;
  uint256 public listSize;
  address constant GUARD = address(1);
  address public lastAddress;
  //列表最大容量
  uint256 public listcapacity = 1000;


  constructor() public {
    _nextPlayers[GUARD] = GUARD;
  }

  function setListCapacity(uint256 capacity_) internal {
      listcapacity = capacity_;
  }

  function addPlayer(address player, uint256 score) internal {
    require(_nextPlayers[player] == address(0));
    address index = _findIndex(score);
    scores[player] = score;
    _nextPlayers[player] = _nextPlayers[index];
    _nextPlayers[index] = player;
    listSize++;
    if(_nextPlayers[player] == address(0)) {
        lastAddress = player;
    }
    if (listSize > listcapacity) {
        removePlayer(lastAddress);
    }
  }

  function increaseScore(address player, uint256 score) internal {
    updateScore(player, scores[player] + score);
  }

  function reduceScore(address player, uint256 score) internal {
    updateScore(player, scores[player] - score);
  }

  function updateScore(address player, uint256 newScore) internal {
    require(_nextPlayers[player] != address(0));
    address prevPlayer = _findPrevPlayer(player);
    address nextPlayer = _nextPlayers[player];
    if(_verifyIndex(prevPlayer, newScore, nextPlayer)){
      scores[player] = newScore;
    } else {
      removePlayer(player);
      addPlayer(player, newScore);
    }
  }

  function removePlayer(address player) internal {
    require(_nextPlayers[player] != address(0));
    address prevPlayer = _findPrevPlayer(player);
    _nextPlayers[prevPlayer] = _nextPlayers[player];
    _nextPlayers[player] = address(0);
    scores[player] = 0;
    listSize--;
  }

  function getTop(uint256 k) public view returns(address[] memory) {
    require(k <= listSize);
    address[] memory playerLists = new address[](k);
    address currentAddress = _nextPlayers[GUARD];
    for(uint256 i = 0; i < k; ++i) {
      playerLists[i] = currentAddress;
      currentAddress = _nextPlayers[currentAddress];
    }
    return playerLists;
  }


  function _verifyIndex(address prevPlayer, uint256 newValue, address nextPlayer)
    internal
    view
    returns(bool)
  {
    return (prevPlayer == GUARD || scores[prevPlayer] >= newValue) && 
           (nextPlayer == GUARD || newValue > scores[nextPlayer]);
  }

  function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextPlayers[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextPlayers[candidateAddress];
    }
  }

  function _isPrevPlayer(address player, address prevPlayer) internal view returns(bool) {
    return _nextPlayers[prevPlayer] == player;
  }

  function _findPrevPlayer(address player) internal view returns(address) {
    address currentAddress = GUARD;
    while(_nextPlayers[currentAddress] != GUARD) {
      if(_isPrevPlayer(player, currentAddress))
        return currentAddress;
      currentAddress = _nextPlayers[currentAddress];
    }
    return address(0);
  }
}

