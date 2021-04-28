/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: contracts/EconomiGame.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity >=0.6.2 <0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /*
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function getNoteValue(uint256 _note) external view returns(uint256);
    function burnNote(uint256 _note) external;
    function updateNoteValue(uint256 _value, uint256 _note) external;
    function updateNoteOwner(address _owner, uint256 _note) external;
}

contract EconomiGame {
  using SafeMath for uint256;

  // variables.
  IERC721 public EconomiNFT;
  address public owner;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public randomEventTimer;
  uint256 public randomNumber;
  uint256 public nonce = 0;
  string public winner;
  bool public startGame = false;
  bool public eventCalled = false;
  // arrays 
  string[4] public teamNames = ["bankers", "programmers", "politicians", "traders"];
  uint256[] public noteIds;
  address[] public players;

  // structs.

  // mappings.
  mapping (string => mapping(address => uint256)) public teams;
  mapping (string => uint256) public teamGDP;
  mapping (string => uint256) public startTeamGDP;
  mapping (string => uint256) public accMultiplier;
  mapping (address => string) public teamViaAddress;
  mapping (uint256 => string) public teamViaId;
  mapping (uint256 => address) public addressViaId;

  // events.
  // [TODO] create an event that is triggered when a random event occurs in the game.

  // constructor.
  constructor (address _nft, uint256 _startTime) public {
    owner = msg.sender;
    EconomiNFT = IERC721(_nft);
    startTime = _startTime;
    endTime = _startTime.add(30 minutes);
  }

  // --- GET FUNCTIONS ---
  function getPlayer(uint256 _id) public view returns(address) {
    return players[_id];
  }

  function getPlayersLength() public view returns(uint256) {
    return players.length;
  }

  function getTeamsLength() public view returns(uint256) {
    return teamNames.length;
  }

  function getTeamMultiplier(uint256 _teamId) public view returns(uint256) {
    string memory team = teamNames[_teamId];
    return accMultiplier[team];
  }

  function getTotalGDP() public view returns(uint256) {
    uint256 _totalGDP;
    for (uint256 i=0; i < teamNames.length; i++) {
      _totalGDP = _totalGDP.add(teamGDP[teamNames[i]]);
    }
    return _totalGDP;
  }

  function getPlayersTeam(address _player) public view returns(string memory) {
    return teamViaAddress[_player];
  }

  function getPlayersNoteValue(string memory _team, address _player) public view returns(uint256) {
    return teams[_team][_player];
  }
  // ---------------------

  // --- POST FUNCTIONS ---
  function updateStartTime(uint256 _timestamp) public {
    startGame = false;
    startTime = _timestamp;
    endTime = startTime.add(30 minutes);
  }

  function updateNonce() internal {
    nonce++;
  }

  function getRandomNumber() public view returns(uint256) {
    require(randomNumber >= 0, "Random number is not set.");
    return randomNumber;
  }

  // using Chainlink VRF for randomness in production.
  function updateRandomNumber(uint256 _modulus) internal {
    updateNonce();
    randomNumber = uint256(keccak256(abi.encodePacked(now,
                                                      msg.sender,
                                                      nonce))) % 
                                                      _modulus;
  }

  function gameStart() public {
    require(msg.sender == owner, "Only the owner can start the game.");
    startTeamGDP[teamNames[0]] = teamGDP[teamNames[0]];
    startTeamGDP[teamNames[1]] = teamGDP[teamNames[1]];
    startTeamGDP[teamNames[2]] = teamGDP[teamNames[2]];
    startTeamGDP[teamNames[3]] = teamGDP[teamNames[3]];

    // determine the reward for each team.
    for (uint256 i=0; i < teamNames.length; i++) {
      uint256 _totalGDP = getTotalGDP();
      accMultiplier[teamNames[i]] = 
        _totalGDP
          .mul(100)
          .div(teamGDP[teamNames[i]]);
    }

    startGame = true;
    endTime = block.timestamp.add(30 minutes);
  }

  function endGame() public {
    require(msg.sender == owner, "Only the owner can end the game.");
    require(block.timestamp >= endTime, "Game has not ended.");

    // determine the winner.
    if (teamGDP[teamNames[0]] > teamGDP[teamNames[1]] && 
        teamGDP[teamNames[0]] > teamGDP[teamNames[2]] && 
        teamGDP[teamNames[0]] > teamGDP[teamNames[3]])
      winner = teamNames[0];
    else if (teamGDP[teamNames[1]] > teamGDP[teamNames[0]] && 
             teamGDP[teamNames[1]] > teamGDP[teamNames[2]] && 
             teamGDP[teamNames[1]] > teamGDP[teamNames[3]])
      winner = teamNames[1];
    else if (teamGDP[teamNames[2]] > teamGDP[teamNames[0]] && 
             teamGDP[teamNames[2]] > teamGDP[teamNames[1]] && 
             teamGDP[teamNames[2]] > teamGDP[teamNames[3]])
      winner = teamNames[2];
    else
      winner = teamNames[3];

    // change note value for winners & burn notes for losers.
    uint256 _id;
    uint256 _reward;
    for (uint256 i=0; i < noteIds.length; i++) {
      _id = noteIds[i];
      if (keccak256(abi.encodePacked((teamViaId[_id]))) ==
          keccak256(abi.encodePacked(winner))) {
        _reward = teams[winner][addressViaId[_id]].mul(accMultiplier[winner]).div(100);
        EconomiNFT.updateNoteValue(_reward, _id);
      } else {
        EconomiNFT.updateNoteOwner(address(0x0), _id);
        EconomiNFT.updateNoteValue(0, _id);
        EconomiNFT.burnNote(_id);
      }
    }
  }


  function getRandomEvent() public {
    require(startGame == true, "Game has not started.");
    require(block.timestamp < endTime, "Game has ended.");
    require(block.timestamp >= randomEventTimer, "Random event timer has not expired.");
    // [TESTING - 15 minutes in production]
    randomEventTimer = block.timestamp.add(3 minutes);

    /** 
      * generate random number from 0 - 4.
      * results will affect the team based on their index in the teams array.
      * 4 will affect all teams [global event].
      */
    updateRandomNumber(5);
  
    if (randomNumber < 4) {
      uint256 GDP = teamGDP[teamNames[randomNumber]];
      string memory team = teamNames[randomNumber];
      updateRandomNumber(2);
      if (randomNumber == 0)
        teamGDP[team] = GDP.add(GDP.div(10));
      else
        teamGDP[team] = GDP.sub(GDP.div(10));
    }
  }

  function joinGame(uint256 _noteId) public returns(string memory) {
    // ensure the game has not started.
    require(!startGame, "This game has already started.");
    // ensure the player is not already in the game.
    //require(teamViaAddress[msg.sender] == bytes4(0x0), "Hello");
    require(keccak256(abi.encodePacked(teamViaAddress[msg.sender])) ==
            keccak256(abi.encodePacked("")), "User has already joined game.");
    // ensure the sender owns the note.
    require(EconomiNFT.ownerOf(_noteId) == msg.sender, "You do not own the note.");
    // transfer the note to this address.
    EconomiNFT.transferFrom(msg.sender, owner, _noteId);
    // add player to game.
    players.push(msg.sender);
    // determine which team has the lowest GDP.
    string memory teamToJoin;
    if (teamGDP[teamNames[0]] <= teamGDP[teamNames[1]] && 
        teamGDP[teamNames[0]] <= teamGDP[teamNames[2]] && 
        teamGDP[teamNames[0]] <= teamGDP[teamNames[3]])
      teamToJoin = teamNames[0];
    else if (teamGDP[teamNames[1]] <= teamGDP[teamNames[0]] && 
             teamGDP[teamNames[1]] <= teamGDP[teamNames[2]] && 
             teamGDP[teamNames[1]] <= teamGDP[teamNames[3]])
      teamToJoin = teamNames[1];
    else if (teamGDP[teamNames[2]] <= teamGDP[teamNames[0]] && 
             teamGDP[teamNames[2]] <= teamGDP[teamNames[1]] && 
             teamGDP[teamNames[2]] <= teamGDP[teamNames[3]])
      teamToJoin = teamNames[2];
    else
      teamToJoin = teamNames[3];
    // join team.
    noteIds.push(_noteId);
    teamViaAddress[msg.sender] = teamToJoin;
    teamViaId[_noteId] = teamToJoin;
    addressViaId[_noteId] = msg.sender;
    uint256 noteValue = EconomiNFT.getNoteValue(_noteId);
    teams[teamToJoin][msg.sender] = noteValue;
    teamGDP[teamToJoin] = teamGDP[teamToJoin].add(noteValue);

    // check if the game can be started.
    if (block.timestamp > startTime)
      startGame = true;

    return teamToJoin;
  }
  // ----------------------
}