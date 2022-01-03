/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: No License

pragma solidity 0.6 .12;


// 
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

// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
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

// 
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

// 
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

contract MiniGame is Ownable {

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    struct Match {
        uint256 state;
        uint256 maxPlayer;
        IERC20 joiningToken;
        uint256 joiningFee;
        uint256 id;


        mapping(address => Reward[]) rewards;

        address[] allJoinedAddresses;

        address[] matchWinners;
    }

    uint256 private constant MATCH_ENDED = 2;
    uint256 private constant MATCH_STARTED = 1;
    uint256 private constant MATCH_PENDING = 0;
    uint256 private constant MATCH_CANCELLED = 3;

    Match[] public matches;

    event ClaimReward(address addr, uint256 num);
    event ClaimNftReward(address addr, address nftAddress, uint256 tokenId, uint256 quantity);

    event ParticipantListChanged(address addr, uint256 matchId, bool joinMatch);

    event MatchStatusChanged(uint256 matchId, uint256 matchStatus);

    struct Reward {
        IERC165 nft;
        uint256 tokenId;

        bool isNft;

        IERC20 token;
        uint256 amount;

        bool claimed;
    }

    constructor() public {

    }

    function getParticipants(uint256 _matchId) public view  returns(address[] memory) {
        for (uint256 i = 0; i < matches.length; i++) {
            if (matches[i].id == _matchId) {
                return matches[i].allJoinedAddresses;
            }
        }

        revert('Match not found');
    }

    function getWinners(uint256 _matchId) public view  returns(address[] memory) {
        for (uint256 i = 0; i < matches.length; i++) {
            if (matches[i].id == _matchId) {
                return matches[i].matchWinners;
            }
        }

        revert('Match not found');
    }

    function getMatch(uint256 _matchId) internal returns(Match storage) {
        for (uint256 i = 0; i < matches.length; i++) {
            if (matches[i].id == _matchId) {
                return matches[i];
            }
        }

        revert('Match not found');
    }

     function getMatchMemory(uint256 _matchId) internal view returns(Match memory) {
        for (uint256 i = 0; i < matches.length; i++) {
            if (matches[i].id == _matchId) {
                return matches[i];
            }
        }

        revert('Match not found');
    }

    function endMatch(uint256 _matchId, address[] memory _winners) external onlyOwner {
        // require(_winners.length == _values.length, "Invalid length");
        Match storage mt = getMatch(_matchId);

        mt.matchWinners = _winners;
        mt.state = MATCH_ENDED;
        emit MatchStatusChanged(_matchId, MATCH_ENDED);
    }

    function setTokenRewards(uint256 _matchId, IERC20 _token, address[] memory _winners, uint256[] memory _values) external onlyOwner {
        require(_winners.length == _values.length, "Invalid length");
        Match storage mt = getMatch(_matchId);

        for (uint256 i = 0; i < _winners.length; i++) {
            mt.rewards[_winners[i]].push(Reward({
                isNft: false,
                token: _token,
                amount: _values[i],
                claimed: false,
                nft: IERC165(0x0000000000000000000000000000000000000000),
                tokenId: 0
            }));
        }

    }

    function setNftRewards(uint256 _matchId, IERC165 _nft, address[] memory _winners, uint256[] memory _tokenIds) external onlyOwner {
        require(_winners.length == _tokenIds.length, "Invalid length");
        Match storage mt = getMatch(_matchId);

        for (uint256 i = 0; i < _winners.length; i++) {
            mt.rewards[_winners[i]].push(Reward({
                isNft: true,
                token: IERC20(0x0000000000000000000000000000000000000000),
                amount: 0,
                claimed: false,
                nft: IERC165(_nft),
                tokenId: _tokenIds[i]
            }));
        }

    }


    function claim(uint256 _matchId) external {
        Match storage mt = getMatch(_matchId);

        Reward[] storage rewards = mt.rewards[_msgSender()];

        for (uint256 i = 0; i < rewards.length; i++) {

            if (!rewards[i].claimed) {
                if (!rewards[i].isNft) {
                    if (rewards[i].token.transfer(msg.sender, rewards[i].amount) == true) {
                        rewards[i].claimed = true;
                        emit ClaimReward(msg.sender, rewards[i].amount);
                    }
                } else {
                    address nftAddress = address(rewards[i].nft);
                    if (_supportERC721(nftAddress)) {
                        IERC721 nft = IERC721(nftAddress);

                        IERC721(nftAddress).safeTransferFrom(address(this), _msgSender(), rewards[i].tokenId);
                        rewards[i].claimed = true;
                        emit ClaimNftReward(msg.sender, nftAddress, rewards[i].tokenId, 1);
                    } else if (_supportERC1155(nftAddress)) {
                        IERC1155 nft = IERC1155(nftAddress);

                        IERC1155(nftAddress).safeTransferFrom(address(this), _msgSender(), rewards[i].tokenId, 1, '');
                        rewards[i].claimed = true;
                        emit ClaimNftReward(msg.sender, nftAddress, rewards[i].tokenId, 1);
                    } else {
                        revert("Invalid NFT address.");
                    }
                }
            }
        }
        // mapping(IERC20 => uint256) tokenRewards = mt.tokenRewards[_msgSender()];

        //uint256 amount = rewards[msg.sender][token];

        /*  require(amount > 0, "Nothing to claim");

         if (token.transfer(msg.sender, amount) == true) {
             rewards[msg.sender][token] = 0;
             emit ClaimReward(msg.sender, amount);
         } */
    }

    function startMatch(uint256 _matchId) public onlyOwner {
        Match storage mt = getMatch(_matchId);
        mt.state = MATCH_STARTED;
        emit MatchStatusChanged(_matchId, MATCH_STARTED);
    }

    function createMatch(uint256 _newMatchId, uint256 _maxPlayer, address _joiningFeeToken, uint256 _joiningFee) public onlyOwner {
        // matchStates[_newMatchId] = MATCH_PENDING;
        uint256 mp = _maxPlayer;
        Match memory mt = Match({
            id: _newMatchId,
            state: MATCH_PENDING,
            maxPlayer: _maxPlayer,
            joiningFee: _joiningFee,
            joiningToken: IERC20(_joiningFeeToken),
            allJoinedAddresses: new address[](0),
            matchWinners: new address[](0)
        });

        matches.push(mt);

        emit MatchStatusChanged(_newMatchId, MATCH_PENDING);
    }

    function cancelMatch(uint256 _matchId) public onlyOwner {
        Match storage mt = getMatch(_matchId);

        require(mt.state == MATCH_PENDING, "Match has started");

        for (uint256 i = 0; i < mt.allJoinedAddresses.length; i++) {

            IERC20(mt.joiningToken).transfer(
                mt.allJoinedAddresses[i],
                mt.joiningFee);

            emit ParticipantListChanged(mt.allJoinedAddresses[i], _matchId, false);
        }

        mt.allJoinedAddresses = new address[](mt.maxPlayer);

        mt.state = MATCH_CANCELLED;
    }

    function hasJoined(address _addr, uint256 _matchId) public view returns(bool)  {
          Match memory mt = getMatchMemory(_matchId);

        address[] memory joinedAddresses = mt.allJoinedAddresses;
          bool hasJoined = false;
          for (uint256 i = 0; i < joinedAddresses.length; i++) {
            if (joinedAddresses[i] == _addr) {
                hasJoined = true;
            }
        }
        return hasJoined;
    }

    function join(uint256 _matchId) public {
        Match storage mt = getMatch(_matchId);
        address me = _msgSender();
        require(mt.state == MATCH_PENDING, "Match has started");

        address[] memory joinedAddresses = mt.allJoinedAddresses;
        bool hasJoined = false;
        for (uint256 i = 0; i < joinedAddresses.length; i++) {
            if (joinedAddresses[i] == me) {
                hasJoined = true;
            }
        }

        require(joinedAddresses.length < mt.maxPlayer, "Max player reached");
        require(!hasJoined, "You have joined before");

        IERC20(mt.joiningToken).transferFrom(
            _msgSender(),
            address(this),
            mt.joiningFee
        );

        mt.allJoinedAddresses.push(me);
        emit ParticipantListChanged(me, _matchId, true);
    }

    function unjoin(uint256 _matchId) public {
        address me = _msgSender();
        Match storage mt = getMatch(_matchId);
        uint256 index = 9999;
        for (uint256 i = 0; i < mt.allJoinedAddresses.length; i++) {
            if (mt.allJoinedAddresses[i] == me) {
                index = i;
            }
        }

        require(mt.state == MATCH_PENDING, "Match has started");

        require(index != 9999, "You have not joined before");

        mt.allJoinedAddresses[index] = mt.allJoinedAddresses[mt.allJoinedAddresses.length - 1];
        mt.allJoinedAddresses.pop();

        IERC20(mt.joiningToken).transfer(
            _msgSender(),
            mt.joiningFee
        );

        emit ParticipantListChanged(me, _matchId, false);
    }

    function _supportERC721(address _nftAddress) private view returns(bool) {
        return IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721);
    }

    function _supportERC1155(address _nftAddress) private view returns(bool) {
        return IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155);
    }


}