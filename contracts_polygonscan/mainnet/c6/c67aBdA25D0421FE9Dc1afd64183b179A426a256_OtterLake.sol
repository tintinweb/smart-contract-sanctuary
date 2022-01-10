// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// import 'hardhat/console.sol';

import './interfaces/IERC20.sol';
import './interfaces/IPearlNote.sol';
import './interfaces/IStakingDistributor.sol';
import './interfaces/IOtterLake.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

import './types/Pausable.sol';
import './types/ReentrancyGuard.sol';

// @dev: Modified from: https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract OtterLake is IOtterLake, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Term {
        IPearlNote note;
        uint256 minLockAmount;
        uint256 lockPeriod;
        uint16 multiplier; // 100 = x1, 120 = x1.2
        bool enabled;
    }

    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 endTime;
        uint256 totalReward; // accumulated rewards
        uint256 reward;
        uint256 totalLocked;
        uint256 rewardPerBoostPoint;
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable pearl;
    IStakingDistributor public distributor;
    bool public finalized;

    uint256 _epoch;
    mapping(uint256 => Epoch) public epochs;
    // epoch -> unlocked boost points
    mapping(uint256 => uint256) public unlockedBoostPoints;

    // note address -> term
    mapping(address => Term) public terms;
    address[] public termAddresses;

    // note address -> token id -> reward paid
    mapping(address => mapping(uint256 => uint256))
        public rewardPerBoostPointPaid;
    // note address  -> token id -> reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address pearl_,
        uint256 epochLength_,
        uint256 firstEpochNumber_,
        uint256 firstEpochEndTime_
    ) {
        require(pearl_ != address(0));
        pearl = IERC20(pearl_);

        epochs[firstEpochNumber_] = Epoch({
            length: epochLength_,
            number: firstEpochNumber_,
            endTime: firstEpochEndTime_,
            totalReward: 0,
            reward: 0,
            totalLocked: 0,
            rewardPerBoostPoint: 0
        });
        _epoch = firstEpochNumber_;
    }

    /* ========== VIEWS ========== */

    function epoch() external view override returns (uint256) {
        return _epoch;
    }

    function totalLocked() external view returns (uint256) {
        return epochs[_epoch].totalLocked;
    }

    function balanceOf(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return terms[noteAddr].note.lockAmount(tokenId);
    }

    function termsCount() external view returns (uint256) {
        return termAddresses.length;
    }

    function totalBoostPoint(address owner)
        external
        view
        returns (uint256 sum)
    {
        for (uint256 i = 0; i < termAddresses.length; i++) {
            IPearlNote note = terms[termAddresses[i]].note;
            uint256 balance = note.balanceOf(owner);
            for (uint256 j = 0; j < balance; j++) {
                uint256 tokenId = note.tokenOfOwnerByIndex(owner, j);
                if (note.endEpoch(tokenId) > _epoch) {
                    sum = sum.add(
                        boostPointOf(
                            address(note),
                            note.tokenOfOwnerByIndex(owner, j)
                        )
                    );
                }
            }
        }
    }

    function boostPointOf(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        Term memory term = terms[noteAddr];
        return term.note.lockAmount(tokenId).mul(term.multiplier).div(100);
    }

    function validEpoch(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        IPearlNote note = terms[noteAddr].note;
        return
            _epoch < note.endEpoch(tokenId)
                ? _epoch
                : note.endEpoch(tokenId).sub(1);
    }

    function rewardPerBoostPoint(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        // console.log(
        //     'reward/point: %s, paid: %s',
        //     epochs[e].rewardPerBoostPoint,
        //     rewardPerBoostPointPaid[noteAddr][tokenId]
        // );
        return
            epochs[validEpoch(noteAddr, tokenId)].rewardPerBoostPoint.sub(
                rewardPerBoostPointPaid[noteAddr][tokenId]
            );
    }

    function reward(address noteAddr, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return
            rewards[noteAddr][tokenId].add(_pendingReward(noteAddr, tokenId));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function lock(address noteAddr, uint256 amount)
        external
        nonReentrant
        notPaused
    {
        // console.log(
        //     'lock epoch: %s term: %s: amount: %s',
        //     _epoch,
        //     termIndex,
        //     amount
        // );
        harvest();

        Term memory term = terms[noteAddr];
        require(amount > 0, 'OtterLake: cannot lock 0 amount');
        require(term.enabled, 'PearVault: term disabled');
        require(
            amount >= term.minLockAmount,
            'OtterLake: amount < min lock amount'
        );
        pearl.safeTransferFrom(msg.sender, address(this), amount);
        pearl.safeApprove(address(term.note), amount);
        uint256 endEpoch = _epoch.add(term.lockPeriod);
        uint256 tokenId = term.note.mint(msg.sender, amount, endEpoch);

        rewardPerBoostPointPaid[noteAddr][tokenId] = epochs[_epoch]
            .rewardPerBoostPoint;
        uint256 boostPoint = boostPointOf(noteAddr, tokenId);
        epochs[_epoch].totalLocked = epochs[_epoch].totalLocked.add(boostPoint);
        unlockedBoostPoints[endEpoch] = unlockedBoostPoints[endEpoch].add(
            boostPoint
        );

        emit Locked(msg.sender, noteAddr, tokenId, amount);
    }

    function extendLock(
        address noteAddr,
        uint256 tokenId,
        uint256 amount
    ) public nonReentrant notPaused {
        harvest();

        Term memory term = terms[noteAddr];
        require(amount > 0, 'OtterLake: cannot lock 0 amount');
        require(term.enabled, 'PearVault: term disabled');
        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 prevEndEpoch = term.note.endEpoch(tokenId);
        require(prevEndEpoch > _epoch, 'OtterLake: the note is expired');
        _updateReward(noteAddr, tokenId);

        pearl.safeTransferFrom(msg.sender, address(this), amount);
        pearl.safeApprove(address(term.note), amount);

        uint256 prevBoostPoint = term
            .note
            .lockAmount(tokenId)
            .mul(term.multiplier)
            .div(100);

        uint256 endEpoch = _epoch.add(term.lockPeriod);
        term.note.extendLock(tokenId, amount, endEpoch);

        uint256 boostPoint = boostPointOf(noteAddr, tokenId);
        epochs[_epoch].totalLocked = epochs[_epoch].totalLocked.add(
            amount.mul(term.multiplier).div(100)
        );
        unlockedBoostPoints[prevEndEpoch] = unlockedBoostPoints[prevEndEpoch]
            .sub(prevBoostPoint);
        unlockedBoostPoints[endEpoch] = unlockedBoostPoints[endEpoch].add(
            boostPoint
        );

        emit Locked(msg.sender, noteAddr, tokenId, amount);
    }

    function claimAndLock(address noteAddr, uint256 tokenId) external {
        uint256 extendingReward = claimReward(noteAddr, tokenId);
        // console.log('claim and lock: %s', extendingReward);
        extendLock(noteAddr, tokenId, extendingReward);
    }

    function redeem(address noteAddr, uint256 tokenId) public nonReentrant {
        harvest();

        Term memory term = terms[noteAddr];
        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 amount = term.note.burn(tokenId);

        emit Redeemed(msg.sender, noteAddr, tokenId, amount);
    }

    function claimReward(address noteAddr, uint256 tokenId)
        public
        nonReentrant
        returns (uint256)
    {
        harvest();

        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 claimableReward = _updateReward(noteAddr, tokenId);
        // uint256 reward = pendingReward(termIndex, tokenId);
        if (claimableReward > 0) {
            // console.log('reward: %s', claimableReward);
            rewards[noteAddr][tokenId] = 0;
            pearl.transfer(msg.sender, claimableReward);
            emit RewardPaid(msg.sender, noteAddr, tokenId, claimableReward);
            return claimableReward;
        }
        return 0;
    }

    function exit(address note, uint256 tokenId) external {
        claimReward(note, tokenId);
        redeem(note, tokenId);
    }

    function harvest() public {
        if (epochs[_epoch].endTime <= block.timestamp) {
            Epoch storage e = epochs[_epoch];
            if (e.totalLocked > 0) {
                e.rewardPerBoostPoint = e
                    .totalReward
                    .sub(epochs[_epoch.sub(1)].totalReward)
                    .mul(1e18)
                    .div(e.totalLocked)
                    .add(epochs[_epoch.sub(1)].rewardPerBoostPoint);
            } else {
                e.totalReward = e.totalReward.sub(e.reward);
            }
            // console.log(
            //     'distributed epoch: %s locked: %s reward/point: %s',
            //     _epoch,
            //     e.totalLocked,
            //     e.rewardPerBoostPoint
            // );

            uint256 current = pearl.balanceOf(address(this));
            distributor.distribute();
            uint256 epochReward = pearl.balanceOf(address(this)).sub(current);

            // advance to next epoch
            _epoch = _epoch.add(1);
            epochs[_epoch] = Epoch({
                length: e.length,
                number: _epoch,
                endTime: e.endTime.add(e.length),
                totalReward: e.totalReward.add(epochReward),
                reward: epochReward,
                totalLocked: e.totalLocked.sub(unlockedBoostPoints[_epoch]),
                rewardPerBoostPoint: e.rewardPerBoostPoint
            });
            // console.log(
            //     'start epoch: %s locked: %s reward: %s',
            //     _epoch,
            //     epochs[_epoch].totalLocked,
            //     epochReward
            // );
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _updateReward(address noteAddr, uint256 tokenId)
        internal
        returns (uint256)
    {
        rewards[noteAddr][tokenId] = rewards[noteAddr][tokenId].add(
            _pendingReward(noteAddr, tokenId)
        );
        rewardPerBoostPointPaid[noteAddr][tokenId] = epochs[
            validEpoch(noteAddr, tokenId)
        ].rewardPerBoostPoint;
        return rewards[noteAddr][tokenId];
    }

    function _pendingReward(address noteAddr, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            boostPointOf(noteAddr, tokenId)
                .mul(rewardPerBoostPoint(noteAddr, tokenId))
                .div(1e18);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDistributor(address distributor_) external onlyOwner {
        distributor = IStakingDistributor(distributor_);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        if (finalized) {
            // @dev if something wrong, dev can extract reward to recover the lose
            require(
                tokenAddress != address(pearl),
                'OtterLake: Cannot withdraw the pearl'
            );
        }
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function finalize() external onlyOwner {
        finalized = true;
    }

    function addTerm(
        address note_,
        uint256 minLockAmount_,
        uint256 lockPeriod_,
        uint16 multiplier_
    ) public onlyOwner {
        require(
            multiplier_ < 1000,
            'OtterLake: multiplier cannot larger than x10'
        );
        require(
            terms[note_].multiplier == 0,
            'OtterLake: duplicate note added'
        );
        IPearlNote note = IPearlNote(note_);
        // @dev: check the note address is valid
        note.lockAmount(0);
        terms[note_] = Term({
            note: note,
            minLockAmount: minLockAmount_,
            lockPeriod: lockPeriod_,
            multiplier: multiplier_,
            enabled: true
        });
        termAddresses.push(note_);
        emit TermAdded(note_, minLockAmount_, lockPeriod_, multiplier_);
    }

    enum TERM_SETTING {
        MIN_LOCK_AMOUNT,
        LOCK_PERIOD
    }

    function setTerm(
        address note_,
        TERM_SETTING setting_,
        uint256 value_
    ) external onlyOwner {
        if (setting_ == TERM_SETTING.MIN_LOCK_AMOUNT) {
            // 0
            terms[note_].minLockAmount = value_;
        } else if (setting_ == TERM_SETTING.LOCK_PERIOD) {
            // 1
            terms[note_].lockPeriod = value_;
        }
        emit TermUpdated(note_, setting_, value_);
    }

    function disableTerm(address note_) external onlyOwner {
        terms[note_].enabled = false;
        emit TermDisabled(note_);
    }

    function removeTermAt(uint256 index) external onlyOwner {
        require(index < termAddresses.length);
        address termAddress = termAddresses[index];
        address note = address(terms[termAddress].note);

        // delete from map
        delete terms[termAddress];

        // delete from array
        termAddresses[index] = termAddresses[termAddresses.length - 1];
        delete termAddresses[termAddresses.length - 1];

        emit TermRemoved(note);
    }

    /* ========== EVENTS ========== */

    event TermAdded(
        address indexed note,
        uint256 minLockAmount,
        uint256 lockPeriod,
        uint16 multiplier
    );
    event TermDisabled(address indexed note);
    event TermRemoved(address indexed note);
    event TermUpdated(
        address indexed note,
        TERM_SETTING setting,
        uint256 value
    );
    event RewardAdded(uint256 epoch, uint256 reward);
    event Locked(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 amount
    );
    event Redeemed(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 amount
    );
    event RewardPaid(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 reward
    );
    event Recovered(address token, uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

interface IPearlNote is IERC721Enumerable {
    function lockAmount(uint256 tokenId) external view returns (uint256);

    function endEpoch(uint256 tokenId) external view returns (uint256);

    /// @dev Extend the NFT lock period
    /// @param _tokenId the token id need to extend
    /// @param _amount The extra lock amount
    /// @param _endEpoch The lock due date
    function extendLock(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _endEpoch
    ) external;

    /// @dev Mint a new ERC721 to represent receipt of lock
    /// @param _user The locker, who will receive this token
    /// @param _amount The lock amount
    /// @param _endEpoch The lock due date
    /// @return token id minted
    function mint(
        address _user,
        uint256 _amount,
        uint256 _endEpoch
    ) external returns (uint256);

    /// @dev Burn the NFT and get token locked inside back
    /// @param tokenId the token id which got burned
    /// @return the amount of unlocked token
    function burn(uint256 tokenId) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

interface IStakingDistributor {
    function distribute() external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOtterLake {
    function epoch() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';

import './SafeMath.sol';
import './Counters.sol';
import './Address.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";

// https://docs.synthetix.io/contracts/source/contracts/pausable
abstract contract Pausable is Ownable {
    uint public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(_owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity 0.7.5;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './SafeMath.sol';

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), 'Address: delegate call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = '0123456789abcdef';
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}