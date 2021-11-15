// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BattleContract is Ownable {
    enum Status {READY, BEGIN, END}
    struct Battle {
        string name;
        string uri;
        uint256 award;
        uint256 level;
        uint256 readyTime;
        Status status;
    }

    struct Participant {
        uint256 nftId;
        address nftOwner;
    }

    Battle[] public battles;
    uint256 public battlesCount;

    mapping(uint256 => Participant[]) participants;

    IERC20 private gfx_;
    INFTContract private nft_;

    uint256 frozenTime = 30 seconds;
    uint256 battleTime = 1 minutes;

    event NewBattle(uint256 battleId);
    event NewParticipant(uint256 battleId, uint256 tokenId);
    event StartBattle(uint256 battleId);
    event EndBattle(uint256 battleId, uint256 nftId);
    event NewWinner(uint256 battleId, uint256 nftId);

    constructor() {
        battlesCount = 0;
    }

    function initialize(address _from, address _gfx) external onlyOwner {
        gfx_ = IERC20(_gfx);
        nft_ = INFTContract(_from);
    }

    modifier _isValidBattleId(uint256 _battleId) {
        require(
            _battleId == 0 || _battleId < battlesCount,
            "BattleContract: Invalide Battle ID"
        );
        _;
    }

    modifier _canParticipate(uint256 _battleId, uint256 _nftId) {
        uint256 level = nft_.getNFTLevelById(_nftId);
        require(
            battles[_battleId].level == level,
            "BattleContract: Level is different"
        );

        address owner = nft_.ownerOf(_nftId);
        require(
            owner == msg.sender,
            "BattleContract: Only owner can participate this token"
        );
        _;
    }

    modifier _canStartBattle(uint256 _battleId) {
        require(
            battles[_battleId].status == Status.READY,
            "BattleContract: Battle is not ready to start"
        );
        _;
    }

    modifier _canEndBattle(uint256 _battleId) {
        require(
            battles[_battleId].status == Status.BEGIN,
            "BattleContract: Battle was not started"
        );
        _;
    }

    modifier _canPermitBattle(uint256 _battleId) {
        require(
            battles[_battleId].readyTime <= block.timestamp,
            "BattleContract: Battle is not ready to start."
        );

        require(
            participants[_battleId].length > 0,
            "BattleContract: No Participants"
        );
        _;
    }

    function createBattle(
        string memory _name,
        string memory _uri,
        uint256 _award,
        uint256 _level
    ) external onlyOwner returns (uint256) {
        Battle memory newBattle;
        newBattle.name = _name;
        newBattle.uri = _uri;
        newBattle.award = _award;
        newBattle.level = _level;
        newBattle.readyTime = block.timestamp + frozenTime;
        newBattle.status = Status.READY;

        battles.push(newBattle);

        emit NewBattle(battlesCount);

        battlesCount++;

        return battlesCount - 1;
    }

    function participateBattle(uint256 _battleId, uint256 _nftId)
        external
        _isValidBattleId(_battleId)
        _canParticipate(_battleId, _nftId)
    {
        Participant memory participant;
        participant.nftId = _nftId;
        participant.nftOwner = nft_.ownerOf(_nftId);

        participants[_battleId].push(participant);

        nft_.transferNFT(address(this), _nftId);
    }

    function startBattle(uint256 _battleId)
        external
        onlyOwner
        _isValidBattleId(_battleId)
        _canStartBattle(_battleId)
        _canPermitBattle(_battleId)
    {
        battles[_battleId].readyTime = block.timestamp + battleTime;
        battles[_battleId].status = Status.BEGIN;
    }

    function endBattle(uint256 _battleId)
        external
        onlyOwner
        _isValidBattleId(_battleId)
        _canEndBattle(_battleId)
    {
        battles[_battleId].status = Status.END;

        uint256 winnerIndex =
            _generateRandomNumber(participants[_battleId].length);
        for (uint32 i = 0; i < participants[_battleId].length; i++) {
            if (i == winnerIndex) {
                _setWinner(_battleId, i, participants[_battleId][i].nftId);
            } else {
                _setLoser(participants[_battleId][i].nftId);
            }
        }
    }

    function _generateRandomNumber(uint256 _length)
        private
        pure
        returns (uint256)
    {
        uint256 randomNumber = uint256(keccak256("GAMYFI"));
        return randomNumber % _length;
    }

    function _setWinner(
        uint256 _battleId,
        uint256 _participantIndex,
        uint256 _nftId
    ) private {
        Battle memory battle = battles[_battleId];

        nft_.setNFTLevelUp(_nftId);
        nft_.setNFTURI(_nftId, battle.uri);

        Participant memory participant =
            participants[_battleId][_participantIndex];
        nft_.transferNFT(participant.nftOwner, _nftId);

        // _claimGFX(_battleId, participant.nftOwner);
    }

    function _setLoser(uint256 _nftId) private {
        nft_.burnNFT(_nftId);
    }

    function _claimGFX(uint256 _battleId, address _to) private {
        Battle memory battle = battles[_battleId];
        address owner = owner();

        gfx_.transferFrom(owner, _to, battle.award);
    }

    function testTransfer(address _to) public {
        address owner = owner();
        uint256 amount = 100;
        gfx_.transferFrom(owner, _to, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function burnNFT(uint256 _nftId) external;

    function transferNFT(address _to, uint256 _nftId) external;

    function getNFTLevelById(uint256 _nftId) external returns (uint256);

    function getNFTById(uint256 _nftId)
        external
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        );

    function setNFTLevelUp(uint256 _nftId) external;

    function setNFTURI(uint256 _nftId, string memory _uri) external;

    function ownerOf(uint256 _nftId) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

