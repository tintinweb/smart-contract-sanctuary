/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

contract SnowflakesInvasion is IERC1155Receiver {

  IERC1155[] public collectibles;
  IERC20 private _power;
  IERC20 private _movement;

  struct Position {
    address owner;
    address collectible;
    uint256 tokenId;
  }

  struct Player {
    address collectible;
    uint256[] tokensId;
    mapping(uint256 => uint8) x;
    mapping(uint256 => uint8) y;
    mapping(uint256 => uint256) lastMovement;
    bool playing;
  }

  mapping(uint8 => mapping(uint8 => Position)) public positions;
  mapping(address => Player) public players;

  mapping(address => mapping(uint256 => address)) public tokenPlayer;

  mapping(address => mapping(uint256 => bool)) private _tokenUsed;


  using SafeMath for uint256;
  using SafeMath for uint8;

  event PlayerMoved(address player,address collectible,uint256 tokenId,uint8 x,uint8 y);
  event Atack(address indexed from, address indexed to,bool win);
  event PlayerLeft(address indexed player,address indexed collectible,uint256 indexed tokenId);
  event PlayerJoined(address indexed player,address indexed collectible,uint256 indexed tokenId);


  constructor(IERC1155[] memory _collectibles,
              IERC20 power,
              IERC20 movement) public {
      collectibles = _collectibles;
      _power = power;
      _movement = _movement;
  }
  modifier tokenAllowed(address collectible){
    bool allowed = false;
    for(uint256 i = 0;i<collectibles.length;i++){
      if(collectible == address(collectibles[i])){
        allowed = true;
      }
    }
    require(allowed,"Token not playable in this game");
    _;
  }

  function respawn(address collectible,uint256 tokenId) public tokenAllowed(collectible) {

    require(_tokenUsed[collectible][tokenId] == false,"Token already being used in the game");
    //require(players[msg.sender].playing == false,"Already playing");
    if(players[msg.sender].playing == true){
      require(players[msg.sender].collectible == collectible,"Already playing with other collectibles collection");
    }
    IERC1155(collectible).safeTransferFrom(msg.sender,address(this),tokenId,1,'');
    if(collectible == address(collectibles[0])){
      players[msg.sender].x[tokenId] = uint8(0);
      players[msg.sender].y[tokenId] = uint8(0);
    } else {
      players[msg.sender].x[tokenId] = uint8(100);
      players[msg.sender].y[tokenId] = uint8(100);
    }
    players[msg.sender].collectible = collectible;
    players[msg.sender].playing = true;
    players[msg.sender].tokensId.push(tokenId);

    players[msg.sender].lastMovement[tokenId] = block.number;
    tokenPlayer[collectible][tokenId] = msg.sender;
    emit PlayerJoined(msg.sender,collectible,tokenId);
    emit PlayerMoved(msg.sender,players[msg.sender].collectible,tokenId,players[msg.sender].x[tokenId],players[msg.sender].x[tokenId]);

  }

  function stopPlaying() public {
    require(players[msg.sender].playing == true,
            "Not playing");
    uint256[] memory amounts = new uint256[](players[msg.sender].tokensId.length);
    for(uint256 i = 0;i<amounts.length;i++){
      amounts[i] = 1;
    }
    IERC1155(players[msg.sender].collectible).safeBatchTransferFrom(address(this),msg.sender,players[msg.sender].tokensId,amounts,'');
    for(uint256 i = 0 ; i < players[msg.sender].tokensId.length; i++){
      uint256 tokenId = players[msg.sender].tokensId[i];
      delete positions[ players[msg.sender].x[tokenId]][ players[msg.sender].y[tokenId]];
      delete tokenPlayer[players[msg.sender].collectible][tokenId];
      if(players[msg.sender].collectible == address(collectibles[0])){
        emit PlayerMoved(msg.sender,players[msg.sender].collectible,tokenId,uint8(0),uint8(0));
      } else {
        emit PlayerMoved(msg.sender,players[msg.sender].collectible,tokenId,uint8(100),uint8(100));
      }
      emit PlayerLeft(msg.sender,players[msg.sender].collectible,tokenId);

    }
    delete players[msg.sender];
  }

  function move(uint256 tokenId,uint8 x,uint8 y) public {
    require(players[msg.sender].playing == true,
            "Not playing");
    require(tokenPlayer[players[msg.sender].collectible][tokenId] == msg.sender,
            "Not allowed to move token");
    require(players[msg.sender].x[tokenId].add(getMovementPoints(msg.sender,tokenId)) >= x &&
            players[msg.sender].y[tokenId].add(getMovementPoints(msg.sender,tokenId)) >= y &&
            x <= uint8(100) &&
            y <= uint8(100) &&
            x >= uint8(0) &&
            y >= uint8(0),
            "Wrong units of movement for x and y axis / Out of game limit");
    if(players[msg.sender].x[tokenId] > getMovementPoints(msg.sender,tokenId)){
      require(players[msg.sender].x[tokenId].sub(getMovementPoints(msg.sender,tokenId)) <= x,"Wrong units of movement for x and y axis / Out of game limit");
    }
    if(players[msg.sender].y[tokenId] > getMovementPoints(msg.sender,tokenId)){
      require(players[msg.sender].y[tokenId].sub(getMovementPoints(msg.sender,tokenId)) <= y,"Wrong units of movement for x and y axis / Out of game limit");
    }
    require(players[msg.sender].lastMovement[tokenId].add(50) <= block.number,"Token need to wait 50 blocks since the last movement/respawn done");
    emit PlayerMoved(msg.sender,players[msg.sender].collectible,tokenId,x,y);
    if(positions[x][y].owner != address(0)){
      _atack(tokenId,x,y);
    } else {
      _occupyPosition(x,y,tokenId);
    }

  }

  function _atack(uint256 tokenId,uint8 x,uint8 y) private {
    address target = positions[x][y].owner;
    uint256 targetTokenId = positions[x][y].tokenId;
    address targetCollectible = players[target].collectible;
    require(targetCollectible != players[msg.sender].collectible,"Friendly unit occupies this land");
    // battle //
    bool win = _calculateWin(tokenId,target,targetCollectible,targetTokenId);
    emit Atack(msg.sender,positions[x][y].owner,win);
    if(win){
      IERC1155(targetCollectible).safeTransferFrom(address(this),
                                                   target,
                                                   targetTokenId,
                                                   1,'');

      _removeTokenId(target,targetTokenId);
      _occupyPosition(x,y,tokenId);
    } else {
      IERC1155(players[msg.sender].collectible).safeTransferFrom(address(this),msg.sender,tokenId,1,'');
      _removeTokenId(msg.sender,tokenId);

    }
  }

  function _calculateWin(uint256 tokenId,address target,address targetCollectible,uint256 targetTokenId) private returns(bool){
    uint256 lastMovementP1 = players[msg.sender].lastMovement[tokenId];
    uint256 lastMovementP2 = players[target].lastMovement[targetTokenId];
    uint256 movementAtackBonusP1 = (block.number.sub(lastMovementP1)).mul(10**14);
    uint256 movementAtackBonusP2 = (block.number.sub(lastMovementP2)).mul(10**14);
    uint256 powerP1 = uint256(0);
    uint256 powerP2 = uint256(0);
    uint256 totalTokensP1 = players[msg.sender].tokensId.length;
    uint256 totalTokensP2 = players[target].tokensId.length;
    uint256 balanceP2 = _power.balanceOf(target);
    powerP1 = powerP1.add((_power.balanceOf(msg.sender)).div(totalTokensP1));
    powerP2 = powerP2.add(balanceP2.div(totalTokensP2));
    powerP1 = powerP1 + movementAtackBonusP1;
    powerP2 = powerP2 + movementAtackBonusP2;
    uint256 basePowerHashAvatars = uint256(1*10**18);
    uint256 basePowerSnowflakes = uint256(2*10**18);
    bool win;
    if(targetCollectible == address(collectibles[1])){
      win = (basePowerSnowflakes + powerP2 < basePowerHashAvatars + powerP1);
    } else {
      win = (basePowerSnowflakes + powerP1 > basePowerHashAvatars + powerP2);
    }
    return(win);
  }

  function _removeTokenId(address target,uint256 tokenId) private {
    for(uint256 i = 0 ; i < players[target].tokensId.length; i++){
      delete positions[ players[target].x[tokenId]][ players[target].y[tokenId]];
      delete tokenPlayer[players[target].collectible][tokenId];
      if(players[target].tokensId[i] == tokenId){
        delete players[target].tokensId[i];
        players[target].tokensId.pop();
      }
      if(players[target].collectible == address(collectibles[0])){
        emit PlayerMoved(target,players[target].collectible,tokenId,uint8(0),uint8(0));
      } else {
        emit PlayerMoved(target,players[target].collectible,tokenId,uint8(100),uint8(100));
      }
    }
  }

  function _occupyPosition(uint8 x,uint8 y,uint256 tokenId) private {
    positions[x][y].owner = msg.sender;
    positions[x][y].collectible = players[msg.sender].collectible;
    positions[x][y].tokenId = tokenId;
    players[msg.sender].x[tokenId] = x;
    players[msg.sender].y[tokenId] = y;
    players[msg.sender].lastMovement[tokenId] = block.number;
  }


  function getTokenPos(address player,uint256 tokenId) public view returns(uint8 x,uint8 y){
    return(players[player].x[tokenId],players[player].y[tokenId]);
  }

  function getMovementPoints(address player,uint256 tokenId) public view returns(uint8 x){
    address colletible = players[player].collectible;
    uint256 lastMovement = players[player].lastMovement[tokenId];
    uint256 totalTokens = players[player].tokensId.length;
    uint256 movementPoints = 3;
    if(lastMovement > 0){
      movementPoints = block.number.sub(lastMovement).div(100);
    } else {
      movementPoints = 10;
    }
    uint256 extraMovement =  _movement.balanceOf(msg.sender).div(totalTokens).div(10**18).div(2);
    movementPoints = movementPoints.add(extraMovement);
    if(movementPoints > 20){
      movementPoints = 20;
    }
    return(uint8(movementPoints));
  }

  function canMoveToken(address player,uint256 tokenId) public view returns(bool){
    uint256 lastMovement = players[player].lastMovement[tokenId];
    uint256 blocks = 0;
    if(lastMovement > 0){
      blocks = block.number.sub(lastMovement);
    }
    bool canMove = (blocks >= 50);
    return(canMove);
  }

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
  )
      external
      override(IERC1155Receiver)
      returns(bytes4){
          return(bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
      }

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
  )
      external
      override(IERC1155Receiver)
      returns(bytes4){
          return(bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")));
      }

   function supportsInterface(bytes4 interfaceId) external view override(IERC165) returns (bool){
       return(true);
   }


}