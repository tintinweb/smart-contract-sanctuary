// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./data/Tax.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IHODLRewardDistributor.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./SwapHandler.sol";

contract ReflectionERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    struct Whitlisted {
        bool maxTx;
        bool tax;
    }

    uint256 constant BASE = 10 ** 18;


    address public wavax;
    address public swapRouter;
    address public wavaxPair;


    address public teamWallet;
    address public charityWallet;
    address public treasuryWallet;

    uint256 public maxTx = 500000 * BASE;

    Tax public buyerTax = Tax(
        1, // TEAM
        1, // HOLDER
        1, // TREASURY
        0 // CHARITY
    );
    Tax public sellerTax = Tax(
        2, // TEAM
        2, // HOLDER
        0, // TREASURY
        1 // CHARITY
    );
    Tax public transferTax = Tax(
        1, // TEAM
        1, // HOLDER 
        1, // TREASURY
        0 // CHARITY
    );

    mapping(address => bool) public isLpPair;

    mapping(address => Whitlisted) public whitlisted;

    IHODLRewardDistributor public hodlRewardDistributor;

    bool public isDistributorSet;

    bool public reflectionEnabled = false;

    SwapHandler public swapHundler;


    uint256 public _teamReserved;
    uint256 public _hodlReserved;
    uint256 public _treasuryReserved;
    uint256 public _charityReserved;

    constructor(
        string memory name_,
        string memory symbol_,
        address wavax_,
        address swapRouter_,
        address payable team_,
        address payable treasury_,
        address payable charity_
    ) ERC20(name_, symbol_) {
        // init wallets addresses
        wavax = wavax_;
        swapRouter = swapRouter_;
        teamWallet = team_;
        charityWallet = treasury_;
        treasuryWallet = charity_;

        // create pair for OPSY/
        wavaxPair = IFactory(
            IRouter(swapRouter_).factory()
        ).createPair(wavax_, address(this));

        isLpPair[wavaxPair] = true;

        swapHundler = new SwapHandler(swapRouter_, wavax_);

        // whiteliste wallets
        whitlisted[team_] = Whitlisted(
            true,
            true
        );

        whitlisted[treasury_] = Whitlisted(
            true,
            true
        );

        whitlisted[charity_] = Whitlisted(
            true,
            true
        );

        whitlisted[address(this)] = Whitlisted(
            true,
            true
        );

        whitlisted[address(swapHundler)] = Whitlisted(
            true,
            true
        );
        // mint supply to wallet
        _mint(treasury_, 100000000 * BASE);
    }

    function initDistributor(
        address distributor_
    ) external onlyOwner {
        hodlRewardDistributor = IHODLRewardDistributor(distributor_);

        require(hodlRewardDistributor.owner() == address(this), "initDistributor: Erc20 not owner");

        hodlRewardDistributor.excludeFromRewards(wavaxPair);
        hodlRewardDistributor.excludeFromRewards(swapRouter);
        hodlRewardDistributor.excludeFromRewards(teamWallet);
        hodlRewardDistributor.excludeFromRewards(treasuryWallet);
        hodlRewardDistributor.excludeFromRewards(charityWallet);
        hodlRewardDistributor.excludeFromRewards(address(this));
        hodlRewardDistributor.excludeFromRewards(address(swapHundler));

        whitlisted[distributor_] = Whitlisted(
            true,
            true
        );

        isDistributorSet = true;
    }

    function transfer(
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        return _customTransfer(_msgSender(), to_, amount_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        // check allowance
        require(allowance(from_, _msgSender()) >= amount_, "> allowance");
        bool success = _customTransfer(from_, to_, amount_);
        approve(from_, allowance(from_, _msgSender()).sub(amount_));
        return success;
    }


    /**
        When taxes are generated from swaps 
        we cannot make the swap to avax due to reentrency gard
        on LPpool , so unstead we add it to a reserve , on next transfer
        this function is called and can also be called by any user
        if they are willing to pay gas
    */
    function processReserves() public {
        swapHundler.swapToAvax(
            _teamReserved,
            _hodlReserved,
            _treasuryReserved,
            _charityReserved
        );

        _teamReserved = 0;
        _hodlReserved = 0;
        _treasuryReserved = 0;
        _charityReserved = 0;
    }

    function setTeamWallet(
        address newTeamWallet_
    ) external onlyOwner {
        require(newTeamWallet_ != teamWallet, "ReflectionERC20: same as current wallet");
        require(newTeamWallet_ != address(0), "ReflectionERC20: cannot be address(0)");
        teamWallet = newTeamWallet_;
    }

    function setCharityWallet(
        address newCharityWallet_
    ) external onlyOwner {
        require(newCharityWallet_ != charityWallet, "ReflectionERC20: same as current wallet");
        require(newCharityWallet_ != address(0), "ReflectionERC20: cannot be address(0)");
        charityWallet = newCharityWallet_;
    }

    function setTreasuryWallet(
        address newTreasuryWallet_
    ) external onlyOwner {
        require(
            newTreasuryWallet_ != treasuryWallet,
            "ReflectionERC20: same as current wallet"
        );
        require(
            newTreasuryWallet_ != address(0),
            "ReflectionERC20: cannot be address(0)"
        );
        treasuryWallet = newTreasuryWallet_;
    }

    /**
        Sets the whitlisting of a wallet 
        you can set it's whitlisting from maxTransfer #fromMaxTx
        or from payign tax #fromTax separatly
    */
    function whitelist(
        address wallet_,
        bool fromMaxTx_,
        bool fromTax_
    ) external onlyOwner {
        whitlisted[wallet_] = Whitlisted(
            fromMaxTx_,
            fromTax_
        );
    }

    /**
        this wallet will be excluded from rewards 
        it is had any amount of rewards they will be
        distributed to all share holders
    */
    function excludeFromHodlRewards(
        address wallet_
    ) external onlyOwner {
        hodlRewardDistributor.excludeFromRewards(wallet_);
    }

    /**
        This wallet will be included in rewards
    */
    function includeFromHodlRewards(
        address wallet_
    ) external onlyOwner {
        hodlRewardDistributor.includeInRewards(wallet_);
    }

    function setBuyerTax(
        uint256 team_,
        uint256 holder_,
        uint256 treasury_,
        uint256 charity_
    ) external onlyOwner {
        transferTax = Tax(
            team_, holder_, treasury_, charity_
        );
    }

    function setSellerTax(
        uint256 team_,
        uint256 holder_,
        uint256 treasury_,
        uint256 charity_
    ) external onlyOwner {
        transferTax = Tax(
            team_, holder_, treasury_, charity_
        );
    }

    function setTransferTax(
        uint256 team_,
        uint256 holder_,
        uint256 treasury_,
        uint256 charity_
    ) external onlyOwner {
        transferTax = Tax(
            team_, holder_, treasury_, charity_
        );
    }

    function setReflection(
        bool isEnabled_
    ) external onlyOwner {
        require(isDistributorSet, "Distributor_not_set");
        reflectionEnabled = isEnabled_;
    }

    function setMaxTx(
        uint256 maxTx_
    ) external onlyOwner {
        maxTx = maxTx_;
    }


    function setisPair(
        address pair_,
        bool isPair_
    ) external onlyOwner {
        isLpPair[pair_] = isPair_;
    }
    /**
        prevents accidental renouncement of owner ship 
        can sill renounce if set explicitly to dead address
     */
    function renounceOwnership() public virtual override onlyOwner {}


        /**
        this is the implementation the custom transfer for this token
     */
    function _customTransfer(
        address from_,
         address to_,
          uint256 amount_
    ) internal returns (bool) {
        // if whitlisted or we are internally swapping no tax
        if (whitlisted[from_].tax || whitlisted[to_].tax) {
            _transfer(from_, to_, amount_);
        } else {
            require(whitlisted[from_].maxTx || amount_ <= maxTx, "ReflectionERC20: > maxTX");
            uint256 netTransfer = amount_;


            if (reflectionEnabled) {
                Tax memory currentAppliedTax = isLpPair[from_] ? buyerTax : isLpPair[to_] ? sellerTax : transferTax;
                uint256 prevTotal = _teamReserved + _hodlReserved + _treasuryReserved + _charityReserved;
                _teamReserved += amount_.mul(currentAppliedTax.team).div(100);
                _hodlReserved += amount_.mul(currentAppliedTax.holder).div(100);
                _treasuryReserved += amount_.mul(currentAppliedTax.treasury).div(100);
                _charityReserved += amount_.mul(currentAppliedTax.charity).div(100);
                uint256 totalTax = _teamReserved + _hodlReserved + _treasuryReserved + _charityReserved;
                netTransfer = amount_.sub(totalTax);

                _transfer(from_, address(swapHundler), totalTax.sub(prevTotal));

                // if we have tokens and we are not in in swap => swap and distribute to wallets
                if (totalTax > 0 && from_ != wavaxPair && to_ != wavaxPair)
                    processReserves();                
            }
            // transfer 
            _transfer(from_, to_, netTransfer);
            // this will trigger after transfer and will update shares for from_ and to_ is needed
        }
        return true;
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        if (isDistributorSet) {
            _updateShare(from_);
            _updateShare(to_);
        }
    }

    function _updateShare(
        address wallet
    ) internal {
        if (!hodlRewardDistributor.excludedFromRewards(wallet))
            hodlRewardDistributor.setShare(wallet, balanceOf(wallet));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRouter {
    function factory() external returns (address);
    /**
        for AMMs that cloned uni without changes to functions names
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    /**
        for joe AMM that cloned uni and changed functions names
    */
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IHODLRewardDistributor.sol";

interface IReflectionERC20 {
    function teamWallet () external returns(address);
    function charityWallet() external returns(address);
    function treasuryWallet() external returns(address);
    function hodlRewardDistributor() external returns(IHODLRewardDistributor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../data/ShareHolder.sol';

interface IHODLRewardDistributor {

    function excludedFromRewards(
        address wallet_
    ) external view returns (bool);

    function pending(
        address sharholderAddress_
    ) external view returns (uint256 pendingAmount);

    function totalPending () external view returns (uint256 );

    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory);

    function depositWavaxRewards(
        uint256 amount_
    ) external;

    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) external;

    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external;

    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external;

    function claimPending(
        address sharholderAddress_
    ) external;

    function owner() external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Tax {
    uint256 team;
    uint256 holder;
    uint256 treasury;
    uint256 charity;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ShareHolder {
    uint256 shares;
    uint256 rewardDebt;
    uint256 claimed;
    uint256 pending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IReflectionERC20.sol";

contract SwapHandler is Ownable {

    address immutable swapRouter;
    address immutable wavax;
    IReflectionERC20 immutable erc20;

    bool private _inSwap = false;

    modifier isInSwap () {
        require(!_inSwap, "SwapHandler: Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor (
        address swapRouter_,
        address wavax_
    ) {
        swapRouter = swapRouter_;
        wavax = wavax_;
        erc20 = IReflectionERC20(msg.sender);
    }

    /**
        this will swap the amounts to avax/eth and send them to the respective wallets
     */
    function swapToAvax(
        uint256 teamAmount_,
        uint256 holderAmount_,
        uint256 treasuryAmount_,
        uint256 charityAmount_
    ) isInSwap onlyOwner external {
        if (teamAmount_ > 0)
            _swap(teamAmount_, erc20.teamWallet());

        if (holderAmount_ > 0)
            _swap(holderAmount_, address(erc20.hodlRewardDistributor()));

        if (treasuryAmount_ > 0)
            _swap(treasuryAmount_, erc20.treasuryWallet());

        if (charityAmount_ > 0)
            _swap(charityAmount_, erc20.charityWallet());
    }

    /**
        swap helper function
     */
    function _swap(
        uint amount_,
        address to_
    ) internal {
        IERC20(owner()).approve(swapRouter, amount_);
        // make the swap to wavax
        address[] memory path = new address[](2);
        path[0] = owner();
        path[1] = wavax;

        // Avax AMMs use a modified uniswapv2 where the function is called
        if (block.chainid == 43114) 
            IRouter(swapRouter).swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                amount_,
                0,
                path,
                to_,
                block.timestamp + 10000
            );
        // all other chains use swapExactETH
        else
            IRouter(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount_,
                0,
                path,
                to_,
                block.timestamp + 10000
            );
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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