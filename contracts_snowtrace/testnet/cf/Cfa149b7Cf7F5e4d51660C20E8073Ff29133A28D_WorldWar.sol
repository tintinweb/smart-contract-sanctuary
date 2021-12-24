/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-23
*/

/**
 *Submitted for verification at snowtrace.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IRandomContract {
    event NewRequest(bytes32 indexed id, bytes32 usersSeed);
    event RequestFilled(bytes32 indexed id, bytes32 usersSeed, bytes32 serverSeed, uint number);

    function requestRandom(bytes32 _usersSeed) external returns (bytes32 requestId);
}

interface IRandomReceiver {
    function randomReponse(bytes32 _requestId, uint _number) external;
}

contract WorldWar is Ownable, IERC721Receiver, IRandomReceiver  {
    
    struct Room {
        uint128 id;
        uint128 startAt;
        address[] players;
        bytes32[] seeds;
        uint256[] shares;
        uint256[] armies;
        bytes32 requestId;
        bool claimed;
        address winner;
    }

    uint public GAME_DURATION = 3600; // 1 heur
    uint public BURNING_FEES = 5000; // 5%

    // Database of rooms by their id
    mapping(uint128 => Room) private _rooms;
    // Store the request to random contract to update room after receiving response
    mapping(bytes32 => uint128) private _requests;

    // Counter of rooms and also define the id of rooms
    uint256 public roomCounter = 0;

    // Contract for Armies
    IERC721 manager;
    // Contract for random
    IRandomContract random;

    constructor(address _manager, address _random) {
        manager = IERC721(_manager);
        random = IRandomContract(_random);
    }

    function actualRoomId() view external returns(uint) {
        return _actualRoom().id;
    }

    function _actualRoom() view internal returns(Room memory) {
        Room memory _room = _rooms[uint128(roomCounter - 1)];
        return _room;
    }

    function _createRoom() internal returns(Room storage) {
        require(_actualRoom().startAt + GAME_DURATION <= block.timestamp, "WorldWar: Previous room has not ended");
        address[] memory players;
        bytes32[] memory seeds;
        uint256[] memory armies;
        uint256[] memory shares;
        Room memory _room = Room({
            id: uint128(roomCounter),
            startAt: uint128(block.timestamp),
            players: players,
            seeds: seeds,
            armies: armies,
            shares: shares,
            requestId: bytes32(0),
            claimed: false,
            winner: address(0)
        });
        roomCounter = roomCounter + 1;
        _rooms[_room.id] = _room;
        return _rooms[_room.id];
    }

    function _grabArmies(uint64[] memory _armies) internal {
        for (uint256 i = 0; i < _armies.length; i++) {
            manager.transferFrom(msg.sender, address(this), _armies[i]);
        }
    }

    function _sendArmies(uint64[] memory _armies, address to) internal {
        for (uint256 i = 0; i < _armies.length; i++) {
            manager.safeTransferFrom(address(this), to, _armies[i]);
        }
    }

    function randomReponse(bytes32 _requestId, uint _number) override external {
        require(msg.sender == address(random), "WorldWar: Only RandomContract can call this function");
        uint128 _roomId = _requests[_requestId];
        require(_roomId != 0, "WorldWar: Room can t be 0 :(");
        Room storage _room = _rooms[_roomId];
        require(_room.id != _roomId, "WorldWar: Room != Room");
        require(_room.armies.length != 0, "WorldWar: Pas de armies :((");
        uint _rolled = _number % _room.armies.length;
        uint _counter = 0;
        require(_room.shares.length != 0, "WorldWar: Pas de sahres :)");
        for (uint i = 0; i < _room.shares.length; i++) {
            require(_room.shares[i] > 0, "WorldWar: >0");
            _counter += _room.shares[i];
            address _winner = _room.players[i];
            require(_winner != address(0), "WorldWar: address 0 pas address 0");
            if(_rolled <= _counter) {
                _room.winner = _winner;
                return;
            }
        }
        require(false, "WorldWar: Impossible case");
    }

    function bet(uint64[] calldata _armies, string calldata _seed) external {
        Room memory _room = _rooms[uint128(roomCounter - 1)];
        Room storage _realRoom;
        if(_room.startAt + GAME_DURATION <= block.timestamp) {
            _realRoom = _createRoom();
        } else {
            _realRoom = _rooms[uint128(roomCounter - 1)];
        }
        _grabArmies(_armies);
        for (uint256 i = 0; i < _armies.length; i++) {
            _realRoom.armies.push(_armies[i]);
        }
        _realRoom.seeds.push(keccak256(bytes(_seed)));
        _realRoom.shares.push(_armies.length);
        _realRoom.players.push(msg.sender);
    }

    function claim(uint128 _roomId) external {
        Room storage _room = _rooms[_roomId];
        require(_room.claimed == false, "WorldWar: Room already claimed");
        require(_room.startAt + GAME_DURATION <= block.timestamp, "WorldWar: The room has not ended");
        require(_room.winner != address(0), "WorldWar: Winner not picked");
        uint _amountWinned = _room.armies.length - (_room.armies.length * BURNING_FEES) / 100000;
        for (uint256 i = 0; i < _amountWinned; i++) {
            uint _armyId = _room.armies[i];
            manager.safeTransferFrom(address(this), _room.winner, _armyId);
        }
        _room.claimed = true;
    }

    function pick(uint128 _roomId) external {
        Room storage _room = _rooms[_roomId];
        require(_room.winner == address(0), "WorldWar: Winner is already picked");
        require(_room.requestId == bytes32(0), "WorldWar: Request already sent");
        bytes memory _finalSeed;
        for (uint256 i = 0; i < _room.seeds.length; i++) {
            _finalSeed = abi.encodePacked(_finalSeed, _room.seeds[i]);
        }

        bytes32 requestId = random.requestRandom(keccak256(bytes(_finalSeed)));
        _room.requestId = requestId;
        _requests[requestId] = _roomId;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _initGame() external onlyOwner {
        address[] memory players;
        bytes32[] memory seeds;
        uint256[] memory armies;
        uint[] memory shares;
        Room memory _room = Room({
            id: uint128(roomCounter),
            startAt: uint128(block.timestamp),
            players: players,
            seeds: seeds,
            armies: armies,
            shares: shares,
            requestId: bytes32(0),
            claimed: false,
            winner: address(0)
        });
        roomCounter = roomCounter + 1;
        _rooms[_room.id] = _room;
    }

    function getWinnerOf(uint128 _roomId) view external returns(address) {
        return _rooms[_roomId].winner;
    }

    function getClaimedOf(uint128 _roomId) view external returns(bool) {
        return _rooms[_roomId].claimed;
    }

    function getRequestOf(uint128 _roomId) view external returns(bytes32) {
        return _rooms[_roomId].requestId;
    }

    function getArmiesOf(uint128 _roomId) view external returns(uint[] memory) {
        return _rooms[_roomId].armies;
    }

    function getSharesOf(uint128 _roomId) view external returns(uint[] memory) {
        return _rooms[_roomId].shares;
    }

    function getSeedsOf(uint128 _roomId) view external returns(bytes32[] memory) {
        return _rooms[_roomId].seeds;
    }

    function getPlayersOf(uint128 _roomId) view external returns(address[] memory) {
        return _rooms[_roomId].players;
    }

    function getStartAtOf(uint128 _roomId) view external returns(uint) {
        return _rooms[_roomId].startAt;
    }

    function _setGameDuration(uint newValue) external onlyOwner {
        GAME_DURATION = newValue;
    }

    function _setBurningFees(uint newValue) external onlyOwner {
        BURNING_FEES = newValue;
    }

    function _setManager(address newManager) external onlyOwner {
        manager = IERC721(newManager);
    }

    function _setRandom(address newRandom) external onlyOwner {
        random = IRandomContract(newRandom);
    }

    function _rescapeBurnedNft(uint64[] memory _armies) external onlyOwner {
        _sendArmies(_armies, owner());
    }
}