// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IgOHM is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function index() external view returns (uint256);
    function balanceFrom(uint256 _amount) external view returns (uint256);
    function balanceTo(uint256 _amount) external view returns (uint256);
    function migrate( address _staking, address _sOHM ) external;
}

interface IsOHM is IERC20 {
    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function gonsForBalance( uint amount ) external view returns ( uint );
    function balanceForGons( uint gons ) external view returns ( uint );
    function index() external view returns ( uint );
    function toG(uint amount) external view returns (uint);
    function fromG(uint amount) external view returns (uint);
    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;
    function debtBalances(address _address) external view returns (uint256);
}

interface IBondingCalculator {
    function markdown( address _LP ) external view returns ( uint );
    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}


interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);
    function claim(address _recipient, bool _rebasing) external returns (uint256);
    function forfeit() external returns (uint256);
    function toggleLock() external;
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);
    function rebase() external;
    function index() external view returns (uint256);
    function contractBalance() external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function supplyInWarmup() external view returns (uint256);
}

interface IDepository {
    struct Bond {
        IERC20 principal; // token to accept as payment
        address calculator; // contract to value principal
        Terms terms; // terms of bond
        bool termsSet; // have terms been set
        uint256 capacity; // capacity remaining
        bool capacityIsPayout; // capacity limit is for payout vs principal
        uint256 totalDebt; // total debt from bond
        uint256 lastDecay; // last block when debt was decayed
    }

    struct Terms {
        uint256 controlVariable; // scaling variable for price
        bool fixedTerm; // fixed term or fixed expiration
        uint256 vestingTerm; // term in blocks (fixed-term)
        uint256 expiration; // block number bond matures (fixed-expiration)
        uint256 conclusion; // block number bond no longer offered
        uint256 minimumPrice; // vs principal value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }


    function bonds(uint256 _BID) external view returns(Bond memory bond);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor,
        uint256 _BID,
        address _feo
    ) external returns(uint256 payout, uint256 index);
}

interface ITeller {
    struct Bond {
        address principal;
        uint256 principalPaid;
        uint256 payout;
        uint256 vested;
        uint256 created;
        uint256 redeemed;
    }

    function bonderInfo(address _bonder, uint256 _index) external view returns(Bond memory bond);
    function newBond( 
        address _bonder, 
        address _principal,
        uint _principalPaid,
        uint _payout, 
        uint _expires,
        address _feo
    ) external returns ( uint index_ );
    function redeemAll(address _bonder) external returns (uint256);
    function redeem(address _bonder, uint256[] memory _indexes) external returns (uint256);
    function getReward() external;
    function setFEReward(uint256 reward) external;
    function updateIndexesFor(address _bonder) external;
    function pendingFor(address _bonder, uint256 _index) external view returns (uint256);
    function pendingForIndexes(address _bonder, uint256[] memory _indexes) external view returns (uint256 pending_);
    function totalPendingFor(address _bonder) external view returns (uint256 pending_);
    function percentVestedFor(address _bonder, uint256 _index) external view returns (uint256 percentVested_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import { IBondingCalculator } from "../external/OlympusV2Interfaces.sol";

contract MockCalculator is IBondingCalculator {
    function markdown(address) external view override returns(uint256) {
        return 19585640961024441895;
    }

    function valuation(address, uint256 _amount) external view override returns(uint256) {
        return 77385122008359 * _amount / 1e18;
    }
}