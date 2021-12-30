/**
 *Submitted for verification at BscScan.com on 2021-12-30
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

contract MiniGame is Ownable {

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

    Match[] public matches;

    event ClaimReward(address addr, uint256 num);

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

    function getMatch(uint256 _matchId) internal returns(Match storage) {
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

            if (!rewards[i].isNft) {
                if (rewards[i].token.transfer(msg.sender, rewards[i].amount) == true) {
                    rewards[i].claimed = true;
                    emit ClaimReward(msg.sender, rewards[i].amount);
                }
            } else {

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
            allJoinedAddresses: new address[](_maxPlayer),
            matchWinners: new address[](_maxPlayer)
        });

        matches.push(mt);

        emit MatchStatusChanged(_newMatchId, MATCH_PENDING);
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

        require(index != 9999, "You have not joined before");

        mt.allJoinedAddresses[index] = mt.allJoinedAddresses[mt.allJoinedAddresses.length - 1];
        mt.allJoinedAddresses.pop();

        IERC20(mt.joiningToken).transfer(
            _msgSender(),
            mt.joiningFee
        );

        emit ParticipantListChanged(me, _matchId, false);
    }


}