// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "../types/BondOwnable.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/FixedPoint.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IHelper.sol";
import "./Fees.sol";

contract CustomBond is BondOwnable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event BondCreated(uint256 deposit, uint256 payout, uint256 expires);

    event BondRedeemed(address recipient, uint256 payout, uint256 remaining);

    event BondPriceChanged(uint256 internalPrice, uint256 debtRatio);

    event ControlVariableAdjustment(uint256 initialBCV, uint256 newBCV, uint256 adjustment, bool addition);

    event LPAdded(address lpAddress, uint256 lpAmount);

    IERC20 public immutable PAYOUT_TOKEN; // token paid for principal
    ITreasury public immutable CUSTOM_TREASURY; // pays for and receives principal
    address public immutable SUBSIDY_ROUTER; // pays subsidy in TAO to custom treasury
    address public immutable HELPER; // helper for helping swap, lend to get lp token
    address public immutable FEES; // Fees contract
    address public OLY_TREASURY; // receives fee
    address public principalToken; // inflow token
    uint256 public totalPrincipalBonded;
    uint256 public totalPayoutGiven;
    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint256 public lastDecay; // reference block for debt decay
    uint256 public payoutSinceLastSubsidy; // principal accrued since subsidy paid
    uint256 public maxFeeAllowed = 50000; //maximum amount of fee allowed to charged - 5%
    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data
    bool public lpTokenAsFeeFlag;//
    bool public bondWithOneAssetFlag;

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 vestingTerm; // in blocks
        uint256 minimumPrice; // vs principal value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // payout token decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // payout token remaining to be paid
        uint256 vesting; // Blocks left to vest
        uint256 lastBlock; // Last interaction
        uint256 truePricePaid; // Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in blocks) between adjustments
        uint256 lastBlock; // block when last adjustment made
    }

    receive() external payable {}

    constructor(
        address _customTreasury,
        address _payoutToken,
        address _principalToken,
        address _olyTreasury,
        address _subsidyRouter,
        address _initialOwner,
        address _helper,
        address _fees
    ) {
        require(_customTreasury != address(0), "Factory: customTreasury bad");
        CUSTOM_TREASURY = ITreasury(_customTreasury);
        require(_payoutToken != address(0), "Factory: payoutToken bad");
        PAYOUT_TOKEN = IERC20(_payoutToken);
        require(_principalToken != address(0), "Factory: principalToken bad");
        principalToken = _principalToken;
        require(_olyTreasury != address(0), "Factory: olyTreasury bad");
        OLY_TREASURY = _olyTreasury;
        require(_subsidyRouter != address(0), "Factory: subsidyRouter bad");
        SUBSIDY_ROUTER = _subsidyRouter;
        require(_initialOwner != address(0), "Factory: initialOwner bad");
        policy = _initialOwner;
        bondManager = _initialOwner;
        require(_helper != address(0), "Factory: helper bad");
        HELPER = _helper;
        require(_fees != address(0), "Factory: FEES bad");
        FEES = _fees;

        lpTokenAsFeeFlag = true;
    }

    /* ======== INITIALIZATION ======== */

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBond(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external onlyPolicy {

        require(terms.controlVariable == 0 && _controlVariable > 0, "initializeBond: controlVariable must be 0");

        require(_vestingTerm >= 10000, "Vesting must be longer than 36 hours");

        require(_maxPayout <= 1000, "Payout cannot be above 1 percent");

        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });

        totalDebt = _initialDebt;
        lastDecay = block.number;
        CUSTOM_TREASURY.toggleBondContract(address(this));
    }

    /// @notice set fee flag
    /// @param _lpTokenAsFeeFlag bool
    function setLPtokenAsFee(bool _lpTokenAsFeeFlag) external onlyPolicy {
        lpTokenAsFeeFlag = _lpTokenAsFeeFlag;
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {
        VESTING,
        PAYOUT,
        DEBT
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint256 _input) external onlyBondManager {
        if (_parameter == PARAMETER.VESTING) {// 0
            require(_input >= 10000, "Vesting must be longer than 36 hours");
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {// 1
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.DEBT) {// 2
            terms.maxDebt = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external onlyBondManager {
        require(_increment <= terms.controlVariable.mul(30).div(1000), "Increment too large");
        require(_target > 0, "setAdjustment: target greater than 0");

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
    }

    /**
     *  @notice change address of Treasury
     *  @param _olyTreasury uint
     */
    function changeOlyTreasury(address _olyTreasury) external {
        address dao = Fees(FEES).DAO();
        require(msg.sender == dao, "changeOlyTreasury: Only DAO can replace OLY_TREASURY");
        OLY_TREASURY = _olyTreasury;
    }

    /**
     *  @notice subsidy controller checks payouts since last subsidy and resets counter
     *  @return payoutSinceLastSubsidy_ uint
     */
    function paySubsidy() external returns (uint256 payoutSinceLastSubsidy_) {
        require(msg.sender == SUBSIDY_ROUTER, "Only subsidy controller");

        payoutSinceLastSubsidy_ = payoutSinceLastSubsidy;
        payoutSinceLastSubsidy = 0;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256) {
        require(_depositor != address(0), "Invalid address");

        return __deposit(_amount, _maxPrice, principalToken, _depositor, true);
    }

    /**
     *  @notice deposit bond with an asset(i.e: USDT)
     *  @param _depositAmount amount of deposit asset
     *  @param _depositAsset deposit asset
     *  @param _incomingAsset asset address for swap from deposit asset
     *  @param _depositor address of depositor
     *  @return uint
     */
    function depositWithAsset(
        uint256 _depositAmount,
        uint256 _maxPrice,
        address _depositAsset,
        address _incomingAsset,
        address _depositor
    ) external returns (uint256) {
        require(_depositor != address(0), "depositWithAsset: Invalid depositor");

        (address lpAddress, uint256 lpAmount) = __lpAddressAndAmount(_depositAmount, _depositAsset, _incomingAsset);

        // remain payoutToken is transferred to user
        __transferAssetToCaller(msg.sender, address(PAYOUT_TOKEN));

        require(lpAddress != address(0), "depositWithAsset: Invalid lpAddress");

        require(lpAmount > 0, "depositWithAsset: Insufficient lpAmount");

        return __deposit(lpAmount, _maxPrice, lpAddress, _depositor, false);
    }


    /// @notice internal process of deposit()
    /// @param _lpAmount amount of principleToken
    /// @param _maxPrice amount
    /// @param _lpAddress principleToken
    /// @param _depositor address of depositor
    /// @param _flag if deposit(), true and if depositWithAsset(), false
    /// @return uint
    function __deposit(
        uint256 _lpAmount,
        uint256 _maxPrice,
        address _lpAddress,
        address _depositor,
        bool _flag
    ) internal returns (uint256) {
        
        decayDebt();
        
        require(totalDebt <= terms.maxDebt, "Max capacity reached");

        uint256 nativePrice = trueBondPrice();

        require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

        uint256 value = CUSTOM_TREASURY.valueOfToken(_lpAddress, _lpAmount);
        uint256 payout = _payoutFor(value); // payout to bonder is computed

        // must be > 0.01 payout token ( underflow protection )
        require(payout >= 10**PAYOUT_TOKEN.decimals() / 100, "Bond too small");

        require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // principal is transferred in
        // approved and deposited into the treasury, returning (_amount - profit) payout token
         if(_flag) {
            IERC20(_lpAddress).safeTransferFrom(msg.sender, address(this), _lpAmount);
         }

        // profits are calculated
        uint256 fee;

        // principal is been taken as fee and trasfered to dao
        if (lpTokenAsFeeFlag) {
            fee = _lpAmount.mul(currentFluxFee()).div(1e6);
            if (fee != 0) {
                IERC20(_lpAddress).transfer(OLY_TREASURY, fee);
            }
        } else {
            fee = payout.mul(currentFluxFee()).div(1e6);
        }

        IERC20(_lpAddress).approve(address(CUSTOM_TREASURY), _lpAmount);
        CUSTOM_TREASURY.deposit(_lpAddress, _lpAmount.sub(fee), payout);

        if (!lpTokenAsFeeFlag && fee != 0) { // fee is transferred to dao
            PAYOUT_TOKEN.transfer(OLY_TREASURY, fee);
        }

        // total debt is increased
        totalDebt = totalDebt.add(value);

        // depositor info is stored
        if(lpTokenAsFeeFlag){
            bondInfo[_depositor] = Bond({
                payout: bondInfo[_depositor].payout.add(payout),
                vesting: terms.vestingTerm,
                lastBlock: block.number,
                truePricePaid: trueBondPrice()
            });
        } else {
            bondInfo[_depositor] = Bond({
                payout: bondInfo[_depositor].payout.add(payout.sub(fee)),
                vesting: terms.vestingTerm,
                lastBlock: block.number,
                truePricePaid: trueBondPrice()
            });
        }

        // indexed events are emitted
        emit BondCreated(_lpAmount, payout, block.number.add(terms.vestingTerm));
        emit BondPriceChanged(_bondPrice(), debtRatio());

        totalPrincipalBonded = totalPrincipalBonded.add(_lpAmount); // total bonded increased
        totalPayoutGiven = totalPayoutGiven.add(payout); // total payout increased
        payoutSinceLastSubsidy = payoutSinceLastSubsidy.add(payout); // subsidy counter increased

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @return uint
     */
    function redeem(address _depositor) external returns (uint) {
        Bond memory info = bondInfo[_depositor];

        uint percentVested = percentVestedFor(_depositor); // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 10000) { // if fully vested
            delete bondInfo[_depositor]; // delete user info
            emit BondRedeemed(_depositor, info.payout, 0); // emit bond data

            if(info.payout > 0) {
                PAYOUT_TOKEN.transfer(_depositor, info.payout);
            }

            return info.payout;
        } else { // if unfinished
            // calculate payout vested
            uint256 payout = info.payout.mul(percentVested).div(10000);

            // store updated deposit info
            bondInfo[_depositor] = Bond({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.number.sub(info.lastBlock)),
                lastBlock: block.number,
                truePricePaid: info.truePricePaid
            });

            emit BondRedeemed(_depositor, payout, bondInfo[_depositor].payout);

            if(payout > 0) {
                PAYOUT_TOKEN.transfer(_depositor, payout);
            }

            return payout;
        }
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /// @notice makes incremental adjustment to control variable
    function adjust() internal {
        uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
        if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
            uint256 initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(adjustment.rate);
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlock = block.number;
            
            emit ControlVariableAdjustment(initial, terms.controlVariable, adjustment.rate, adjustment.add);
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.number;
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(10**(uint256(PAYOUT_TOKEN.decimals()).sub(5)));
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        } else if (terms.minimumPrice != 0) {
            terms.minimumPrice = 0;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).div(10**(uint256(PAYOUT_TOKEN.decimals()).sub(5)));
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate true bond price a user pays
     *  @return price_ uint
     */
    function trueBondPrice() public view returns (uint256 price_) {
        price_ = bondPrice().add(bondPrice().mul(currentFluxFee()).div(1e6));
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        uint256 totalSupply = PAYOUT_TOKEN.totalSupply();
        if(totalSupply > 10**18*10**PAYOUT_TOKEN.decimals()) totalSupply = 10**18*10**PAYOUT_TOKEN.decimals();
        return totalSupply.mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate total interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function _payoutFor(uint256 _value) internal view returns (uint256) {
        return FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e11);
    }

    /**
     *  @notice calculate user's interest due for new bond, accounting for Flux Fee
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value) external view returns (uint256) {
        uint256 total = FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e11);
        return total.sub(total.mul(currentFluxFee()).div(1e6));
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @notice protocols using Flux Pro should be careful when quickly adding large %s to total supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint256 debtRatio_) {
        debtRatio_ = FixedPoint
            .fraction(currentDebt().mul(10**PAYOUT_TOKEN.decimals()), PAYOUT_TOKEN.totalSupply())
            .decode112with18()
            .div(1e18);
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint256) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint256 decay_) {
        uint256 blocksSinceLast = block.number.sub(lastDecay);
        decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint256 blocksSinceLast = block.number.sub(bond.lastBlock);
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = blocksSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    /**
     *  @notice current fee Flux takes of each bond
     *  @return currentFee_ uint
     */
    function currentFluxFee() public view returns (uint256 currentFee_) {

        uint256[] memory tierCeilings = Fees(FEES).getTierCeilings();
        uint256[] memory fees = Fees(FEES).getFees();

        uint256 feesLength = fees.length;
        for (uint256 i; i < feesLength; i++) {
            if (totalPrincipalBonded < tierCeilings[i] || i == feesLength - 1) {
                if(fees[i] > maxFeeAllowed){
                    return maxFeeAllowed;
                }else{
                    return fees[i];
                }

            }
        }
    }

    /// @dev Helper to transfer full contract balances of assets to the caller
    function __transferAssetToCaller(address _caller, address _asset) private {
        uint256 transferAmount = IERC20(_asset).balanceOf(address(this));
        if (transferAmount > 0) {
            IERC20(_asset).safeTransfer(_caller, transferAmount);
        }
    }

    /// @notice Swap and AddLiquidity on the UniswapV2
    function __lpAddressAndAmount(
        uint256 _depositAmount,
        address _depositAsset,
        address _incomingAsset
    ) public payable returns (address lpAddress_, uint256 lpAmount_) {

        if(_depositAsset == address(0)) {//ETH
            payable(address(HELPER)).transfer(address(this).balance);
        } else {
            IERC20(_depositAsset).safeTransferFrom(msg.sender, address(this), _depositAmount);

            IERC20(_depositAsset).approve(address(HELPER), _depositAmount);
        }

        bytes memory swapArgs = abi.encode(_depositAmount, _depositAsset, address(PAYOUT_TOKEN), _incomingAsset);

        (lpAddress_, lpAmount_) = IHelper(HELPER).swapForDeposit(swapArgs);

        emit LPAdded(lpAddress_, lpAmount_);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

contract BondOwnable {
    address public policy;
    address public bondManager;

    constructor() {
        policy = msg.sender;
        bondManager = msg.sender;
    }

    modifier onlyPolicy() {
        require(msg.sender == policy, "BondOwnable: caller is not the owner");
        _;
    }

    modifier onlyBondManager() {
        require(msg.sender == bondManager, "BondOwnable: caller is not the bond manager");
        _;
    }
    function transferBondManagement(address _newManager) external onlyPolicy {
        require(_newManager != address(0), "BondOwnable: _newManager must not be zero address");
        bondManager = _newManager;
    }

    function transferOwnership(address _newOwner) external onlyPolicy {
        require(_newOwner != address(0), "BondOwnable: newOwner must not be zero address");
        policy = _newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

import "../libraries/FullMath.sol";
import "../libraries/Babylonian.sol";
import "../libraries/BitMath.sol";

library FixedPoint {
    struct Uq112x112 {
        uint224 _x;
    }

    struct Uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(Uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(Uq112x112 memory self) internal pure returns (uint256) {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (Uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.Uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return Uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return Uq112x112(uint224(result));
        }
    }

    // square root of a Uq112x112
    // lossy between 0/1 and 40 bits
    function sqrt(Uq112x112 memory self) internal pure returns (Uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return Uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return Uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

/// @title CustomTreasury Interface
interface ITreasury {
        
    function deposit(
        address _principleTokenAddress,
        uint256 _amountPrincipleToken,
        uint256 _amountPayoutToken
    ) external;

    function valueOfToken(
        address _principleTokenAddress, 
        uint256 _amount
    ) external view returns (uint256 value_);

    function toggleBondContract(address _bondContract) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

/// @notice Interface for Helper
interface IHelper {

    function swapForDeposit(
        bytes calldata _swapArgs
    ) external returns (address lpAddress_, uint256 lpAmount_);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "../libraries/SafeMath.sol";

contract Fees {    
    using SafeMath for uint256;
    
    address public DAO;

    uint256[] private tierCeilings; 
    uint256[] private fees;

    event FeesAndTierCeilings(uint256[] tierCeilings, uint256[] fees);

    modifier onlyDAO() {
        require(msg.sender == DAO, "Only DAO call");
        _;
    }

    constructor(address _dao) {
        require(_dao != address(0), "Fees: DAO bad address");
        DAO = _dao;
    }

    /// @notice set fee for creating bond
    /// @param _tierCeilings uint[]
    /// @param _fees uint[]
    function setTiersAndFees(
        uint256[] calldata _tierCeilings, 
        uint256[] calldata _fees
    ) external onlyDAO {
        require(_tierCeilings.length == _fees.length, "setTiersAndFees: Bad items length");

        uint256 feeSum = 0;
        for (uint256 i; i < _fees.length; i++) {
            feeSum = feeSum.add(_fees[i]);
        }
        
        require(feeSum > 0, "setTiersAndFees: Bad fees");

        for (uint256 i; i < _fees.length; i++) {
            tierCeilings.push(_tierCeilings[i]);
            fees.push(_fees[i]);
        }

        emit FeesAndTierCeilings(_tierCeilings, _fees);
    }

    /// @notice Get fees for bond
    function getFees() external view returns (uint256[] memory) {
        return fees;
    }

    /// @notice Get tierCeilings for bond
    function getTierCeilings() external view returns (uint256[] memory) {
        return tierCeilings;
    }
}

// SPDX-License-Identifier: GPL-3.0

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory _hex = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = _hex[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = _hex[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 k, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        k = x * y;
        h = mm - k;
        if (mm < k) h -= 1;
    }

    function fullDiv(
        uint256 k,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        k /= pow2;
        k += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return k * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 k, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > k) h -= 1;
        k -= mm;
        require(h < d, "FullMath::mulDiv: overflow");
        return fullDiv(k, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}