// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./lib/math/MathUtils.sol";

import "./IController.sol";
import "./ISmartYield.sol";

import "./IProvider.sol";

import "./model/IBondModel.sol";
import "./IBond.sol";
import "./JuniorToken.sol";

contract SmartYield is
    JuniorToken,
    ISmartYield
{
    using SafeMath for uint256;

    uint256 public constant MAX_UINT256 = uint256(-1);
    uint256 public constant EXP_SCALE = 1e18;

    // controller address
    address public override controller;

    // address of IProviderPool
    address public pool;

    // senior BOND (NFT)
    address public seniorBond; // IBond

    // junior BOND (NFT)
    address public juniorBond; // IBond

    // underlying amount in matured and liquidated juniorBonds
    uint256 public underlyingLiquidatedJuniors;

    // tokens amount in unmatured juniorBonds or matured and unliquidated
    uint256 public tokensInJuniorBonds;

    // latest SeniorBond Id
    uint256 public seniorBondId;

    // latest JuniorBond Id
    uint256 public juniorBondId;

    // last index of juniorBondsMaturities that was liquidated
    uint256 public juniorBondsMaturitiesPrev;
    // list of junior bond maturities (timestamps)
    uint256[] public juniorBondsMaturities;

    // checkpoints for all JuniorBonds matureing at (timestamp) -> (JuniorBondsAt)
    // timestamp -> JuniorBondsAt
    mapping(uint256 => JuniorBondsAt) public juniorBondsMaturingAt;

    // metadata for senior bonds
    // bond id => bond (SeniorBond)
    mapping(uint256 => SeniorBond) public seniorBonds;

    // metadata for junior bonds
    // bond id => bond (JuniorBond)
    mapping(uint256 => JuniorBond) public juniorBonds;

    // pool state / average bond
    // holds rate of payment by juniors to seniors
    SeniorBond public abond;

    bool public _setup;

    // emitted when user buys junior ERC20 tokens
    event BuyTokens(address indexed buyer, uint256 underlyingIn, uint256 tokensOut, uint256 fee);
    // emitted when user sells junior ERC20 tokens and forfeits their share of the debt
    event SellTokens(address indexed seller, uint256 tokensIn, uint256 underlyingOut, uint256 forfeits);

    event BuySeniorBond(address indexed buyer, uint256 indexed seniorBondId, uint256 underlyingIn, uint256 gain, uint256 forDays);

    event RedeemSeniorBond(address indexed owner, uint256 indexed seniorBondId, uint256 fee);

    event BuyJuniorBond(address indexed buyer, uint256 indexed juniorBondId, uint256 tokensIn, uint256 maturesAt);

    event RedeemJuniorBond(address indexed owner, uint256 indexed juniorBondId, uint256 underlyingOut);

    modifier onlyControllerOrDao {
      require(
        msg.sender == controller || msg.sender == IController(controller).dao(),
        "PPC: only controller/DAO"
      );
      _;
    }

    constructor(
      string memory name_,
      string memory symbol_,
      uint8 decimals_
    )
      JuniorToken(name_, symbol_, decimals_)
    {}

    function setup(
      address controller_,
      address pool_,
      address seniorBond_,
      address juniorBond_
    )
      external
    {
        require(
          false == _setup,
          "SY: already setup"
        );

        controller = controller_;
        pool = pool_;
        seniorBond = seniorBond_;
        juniorBond = juniorBond_;

        _setup = true;
    }

    // externals

    // change the controller, only callable by old controller or dao
    function setController(address newController_)
      external override
      onlyControllerOrDao
    {
      controller = newController_;
    }

    // buy at least _minTokens with _underlyingAmount, before _deadline passes
    function buyTokens(
      uint256 underlyingAmount_,
      uint256 minTokens_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_JUNIOR_TOKEN(),
          "SY: buyTokens paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyTokens deadline"
        );

        uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
        // (underlyingAmount_ - fee) * EXP_SCALE / price()
        uint256 getsTokens = (underlyingAmount_.sub(fee)).mul(EXP_SCALE).div(price());

        require(
          getsTokens >= minTokens_,
          "SY: buyTokens minTokens"
        );

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, underlyingAmount_);
        IProvider(pool)._depositProvider(underlyingAmount_, fee);
        _mint(buyer, getsTokens);

        emit BuyTokens(buyer, underlyingAmount_, getsTokens, fee);
    }

    // sell _tokens for at least _minUnderlying, before _deadline and forfeit potential future gains
    function sellTokens(
      uint256 tokenAmount_,
      uint256 minUnderlying_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          block.timestamp <= deadline_,
          "SY: sellTokens deadline"
        );

        // share of these tokens in the debt
        // tokenAmount_ * EXP_SCALE / totalSupply()
        uint256 debtShare = tokenAmount_.mul(EXP_SCALE).div(totalSupply());
        // (abondDebt() * debtShare) / EXP_SCALE
        uint256 forfeits = abondDebt().mul(debtShare).div(EXP_SCALE);
        // debt share is forfeit, and only diff is returned to user
        // (tokenAmount_ * price()) / EXP_SCALE - forfeits
        uint256 toPay = tokenAmount_.mul(price()).div(EXP_SCALE).sub(forfeits);

        require(
          toPay >= minUnderlying_,
          "SY: sellTokens minUnderlying"
        );

        // ---

        address seller = msg.sender;

        _burn(seller, tokenAmount_);
        IProvider(pool)._withdrawProvider(toPay, 0);
        IProvider(pool)._sendUnderlying(seller, toPay);

        emit SellTokens(seller, tokenAmount_, toPay, forfeits);
    }

    // Purchase a senior bond with principalAmount_ underlying for forDays_, buyer gets a bond with gain >= minGain_ or revert. deadline_ is timestamp before which tx is not rejected.
    // returns gain
    function buyBond(
        uint256 principalAmount_,
        uint256 minGain_,
        uint256 deadline_,
        uint16 forDays_
    )
      external override
      returns (uint256)
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_SENIOR_BOND(),
          "SY: buyBond paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyBond deadline"
        );

        require(
            0 < forDays_ && forDays_ <= IController(controller).BOND_LIFE_MAX(),
            "SY: buyBond forDays"
        );

        uint256 gain = bondGain(principalAmount_, forDays_);

        require(
          gain >= minGain_,
          "SY: buyBond minGain"
        );

        require(
          gain > 0,
          "SY: buyBond gain 0"
        );

        require(
          gain < underlyingLoanable(),
          "SY: buyBond underlyingLoanable"
        );

        uint256 issuedAt = block.timestamp;

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, principalAmount_);
        IProvider(pool)._depositProvider(principalAmount_, 0);

        SeniorBond memory b =
            SeniorBond(
                principalAmount_,
                gain,
                issuedAt,
                uint256(1 days) * uint256(forDays_) + issuedAt,
                false
            );

        _mintBond(buyer, b);

        emit BuySeniorBond(buyer, seniorBondId, principalAmount_, gain, forDays_);

        return gain;
    }

    // buy an nft with tokenAmount_ jTokens, that matures at abond maturesAt
    function buyJuniorBond(
      uint256 tokenAmount_,
      uint256 maxMaturesAt_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        // 1 + abond.maturesAt / EXP_SCALE
        uint256 maturesAt = abond.maturesAt.div(EXP_SCALE).add(1);

        require(
          block.timestamp <= deadline_,
          "SY: buyJuniorBond deadline"
        );

        require(
          maturesAt <= maxMaturesAt_,
          "SY: buyJuniorBond maxMaturesAt"
        );

        JuniorBond memory jb = JuniorBond(
          tokenAmount_,
          maturesAt
        );

        // ---

        address buyer = msg.sender;

        _takeTokens(buyer, tokenAmount_);
        _mintJuniorBond(buyer, jb);

        emit BuyJuniorBond(buyer, juniorBondId, tokenAmount_, maturesAt);

        // if abond.maturesAt is past we can liquidate, but juniorBondsMaturingAt might have already been liquidated
        if (block.timestamp >= maturesAt) {
            JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

            if (jBondsAt.price == 0) {
                _liquidateJuniorsAt(jb.maturesAt);
            } else {
                // juniorBondsMaturingAt was previously liquidated,
                _burn(address(this), jb.tokens); // burns user's locked tokens reducing the jToken supply
                // underlyingLiquidatedJuniors += jb.tokens * jBondsAt.price / EXP_SCALE
                underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.add(
                  jb.tokens.mul(jBondsAt.price).div(EXP_SCALE)
                );
                _unaccountJuniorBond(jb);
            }
            return this.redeemJuniorBond(juniorBondId);
        }
    }

    // Redeem a senior bond by it's id. Anyone can redeem but owner gets principal + gain
    function redeemBond(
      uint256 bondId_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
            block.timestamp >= seniorBonds[bondId_].maturesAt,
            "SY: redeemBond not matured"
        );

        // bondToken.ownerOf will revert for burned tokens
        address payTo = IBond(seniorBond).ownerOf(bondId_);
        // seniorBonds[bondId_].gain + seniorBonds[bondId_].principal
        uint256 payAmnt = seniorBonds[bondId_].gain.add(seniorBonds[bondId_].principal);
        uint256 fee = MathUtils.fractionOf(seniorBonds[bondId_].gain, IController(controller).FEE_REDEEM_SENIOR_BOND());
        payAmnt = payAmnt.sub(fee);

        // ---

        if (seniorBonds[bondId_].liquidated == false) {
            seniorBonds[bondId_].liquidated = true;
            _unaccountBond(seniorBonds[bondId_]);
        }

        // bondToken.burn will revert for already burned tokens
        IBond(seniorBond).burn(bondId_);

        IProvider(pool)._withdrawProvider(payAmnt, fee);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);

        emit RedeemSeniorBond(payTo, bondId_, fee);
    }

    // once matured, redeem a jBond for underlying
    function redeemJuniorBond(uint256 jBondId_)
        external override
    {
        _beforeProviderOp(block.timestamp);

        JuniorBond memory jb = juniorBonds[jBondId_];
        require(
            jb.maturesAt <= block.timestamp,
            "SY: redeemJuniorBond maturesAt"
        );

        JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

        // blows up if already burned
        address payTo = IBond(juniorBond).ownerOf(jBondId_);
        // jBondsAt.price * jb.tokens / EXP_SCALE
        uint256 payAmnt = jBondsAt.price.mul(jb.tokens).div(EXP_SCALE);

        // ---

        _burnJuniorBond(jBondId_);
        IProvider(pool)._withdrawProvider(payAmnt, 0);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);
        underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.sub(payAmnt);

        emit RedeemJuniorBond(payTo, jBondId_, payAmnt);
    }

    // returns the maximum theoretically possible daily rate for senior bonds,
    // in reality the actual rate given to a bond will always be lower due to slippage
    function maxBondDailyRate()
      external override
    returns (uint256)
    {
      return IBondModel(IController(controller).bondModel()).maxDailyRate(
        underlyingTotal(),
        underlyingLoanable(),
        IController(controller).providerRatePerDay()
      );
    }

    function liquidateJuniorBonds(uint256 upUntilTimestamp_)
      external override
    {
      require(
        upUntilTimestamp_ <= block.timestamp,
        "SY: liquidateJuniorBonds in future"
      );
      _beforeProviderOp(upUntilTimestamp_);
    }

  // /externals

  // publics

    // given a principal amount and a number of days, compute the guaranteed bond gain, excluding principal
    function bondGain(uint256 principalAmount_, uint16 forDays_)
      public override
    returns (uint256)
    {
      return IBondModel(IController(controller).bondModel()).gain(
        underlyingTotal(),
        underlyingLoanable(),
        IController(controller).providerRatePerDay(),
        principalAmount_,
        forDays_
      );
    }

    // jToken price * EXP_SCALE
    function price()
      public override
    returns (uint256)
    {
        uint256 ts = totalSupply();
        // (ts == 0) ? EXP_SCALE : (underlyingJuniors() * EXP_SCALE) / ts
        return (ts == 0) ? EXP_SCALE : underlyingJuniors().mul(EXP_SCALE).div(ts);
    }

    function underlyingTotal()
      public virtual override
    returns(uint256)
    {
      // underlyingBalance() - underlyingLiquidatedJuniors
      return IProvider(pool).underlyingBalance().sub(underlyingLiquidatedJuniors);
    }

    function underlyingJuniors()
      public virtual override
    returns (uint256)
    {
      // underlyingTotal() - abond.principal - abondPaid()
      return underlyingTotal().sub(abond.principal).sub(abondPaid());
    }

    function underlyingLoanable()
      public virtual override
    returns (uint256)
    {
        // underlyingTotal - abond.principal - abond.gain - queued withdrawls
        uint256 _underlyingTotal = underlyingTotal();
        // abond.principal - abond.gain - (tokensInJuniorBonds * price() / EXP_SCALE)
        uint256 _lockedUnderlying = abond.principal.add(abond.gain).add(
          tokensInJuniorBonds.mul(price()).div(EXP_SCALE)
        );

        if (_lockedUnderlying > _underlyingTotal) {
          // abond.gain and (tokensInJuniorBonds in underlying) can overlap, so there is a cases where _lockedUnderlying > _underlyingTotal
          return 0;
        }

        // underlyingTotal() - abond.principal - abond.gain - (tokensInJuniorBonds * price() / EXP_SCALE)
        return _underlyingTotal.sub(_lockedUnderlying);
    }

    function abondGain()
      public view override
    returns (uint256)
    {
        return abond.gain;
    }

    function abondPaid()
      public view override
    returns (uint256)
    {
        uint256 ts = block.timestamp * EXP_SCALE;
        if (ts <= abond.issuedAt || (abond.maturesAt <= abond.issuedAt)) {
          return 0;
        }

        uint256 duration = abond.maturesAt.sub(abond.issuedAt);
        uint256 paidDuration = MathUtils.min(ts.sub(abond.issuedAt), duration);
        // abondGain() * paidDuration / duration
        return abondGain().mul(paidDuration).div(duration);
    }

    function abondDebt()
      public view override
    returns (uint256)
    {
        // abondGain() - abondPaid()
        return abondGain().sub(abondPaid());
    }

  // /publics

  // internals

    // liquidates junior bonds up to upUntilTimestamp_ timestamp
    function _beforeProviderOp(uint256 upUntilTimestamp_) internal {
      // this modifier will be added to the begginging of all (write) functions.
      // The first tx after a queued liquidation's timestamp will trigger the liquidation
      // reducing the jToken supply, and setting aside owed_dai for withdrawals
      for (uint256 i = juniorBondsMaturitiesPrev; i < juniorBondsMaturities.length; i++) {
          if (upUntilTimestamp_ >= juniorBondsMaturities[i]) {
              _liquidateJuniorsAt(juniorBondsMaturities[i]);
              juniorBondsMaturitiesPrev = i.add(1);
          } else {
              break;
          }
      }
    }

    function _liquidateJuniorsAt(uint256 timestamp_)
      internal
    {
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[timestamp_];

        require(
          jBondsAt.tokens > 0,
          "SY: nothing to liquidate"
        );

        require(
          jBondsAt.price == 0,
          "SY: already liquidated"
        );

        jBondsAt.price = price();

        // ---

        // underlyingLiquidatedJuniors += jBondsAt.tokens * jBondsAt.price / EXP_SCALE;
        underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.add(
          jBondsAt.tokens.mul(jBondsAt.price).div(EXP_SCALE)
        );
        _burn(address(this), jBondsAt.tokens); // burns Junior locked tokens reducing the jToken supply
        tokensInJuniorBonds = tokensInJuniorBonds.sub(jBondsAt.tokens);
    }

    // removes matured seniorBonds from being accounted in abond
    function unaccountBonds(uint256[] memory bondIds_)
      external override
    {
      uint256 currentTime = block.timestamp;

      for (uint256 f = 0; f < bondIds_.length; f++) {
        if (
            currentTime >= seniorBonds[bondIds_[f]].maturesAt &&
            seniorBonds[bondIds_[f]].liquidated == false
        ) {
            seniorBonds[bondIds_[f]].liquidated = true;
            _unaccountBond(seniorBonds[bondIds_[f]]);
        }
      }
    }

    function _mintBond(address to_, SeniorBond memory bond_)
      internal
    {
        require(
          seniorBondId < MAX_UINT256,
          "SY: _mintBond"
        );

        seniorBondId++;
        seniorBonds[seniorBondId] = bond_;
        _accountBond(bond_);
        IBond(seniorBond).mint(to_, seniorBondId);
    }

    // when a new bond is added to the pool, we want:
    // - to average abond.maturesAt (the earliest date at which juniors can fully exit), this shortens the junior exit date compared to the date of the last active bond
    // - to keep the price for jTokens before a bond is bought ~equal with the price for jTokens after a bond is bought
    function _accountBond(SeniorBond memory b_)
      internal
    {
        uint256 _now = block.timestamp * EXP_SCALE;

        //abondDebt() + b_.gain
        uint256 newDebt = abondDebt().add(b_.gain);
        // for the very first bond or the first bond after abond maturity: abondDebt() = 0 => newMaturesAt = b.maturesAt
        // (abond.maturesAt * abondDebt() + b_.maturesAt * EXP_SCALE * b_.gain) / newDebt
        uint256 newMaturesAt = (abond.maturesAt.mul(abondDebt()).add(b_.maturesAt.mul(EXP_SCALE).mul(b_.gain))).div(newDebt);

        // (uint256(1) + ((abond.gain + b_.gain) * (newMaturesAt - _now)) / newDebt)
        uint256 newDuration = (abond.gain.add(b_.gain)).mul(newMaturesAt.sub(_now)).div(newDebt).add(1);
        // timestamp = timestamp - tokens * d / tokens
        uint256 newIssuedAt = newMaturesAt.sub(newDuration, "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal.add(b_.principal),
          abond.gain.add(b_.gain),
          newIssuedAt,
          newMaturesAt,
          false
        );
    }

    // when a bond is redeemed from the pool, we want:
    // - for abond.maturesAt (the earliest date at which juniors can fully exit) to remain the same as before the redeem
    // - to keep the price for jTokens before a bond is bought ~equal with the price for jTokens after a bond is bought
    function _unaccountBond(SeniorBond memory b_)
      internal
    {
        uint256 now_ = block.timestamp * EXP_SCALE;

        if ((now_ >= abond.maturesAt)) {
          // abond matured
          // abondDebt() == 0
          abond = SeniorBond(
            abond.principal.sub(b_.principal),
            abond.gain - b_.gain,
            now_.sub(abond.maturesAt.sub(abond.issuedAt)),
            now_,
            false
          );

          return;
        }
        // uint256(1) + (abond.gain - b_.gain) * (abond.maturesAt - now_) / abondDebt()
        uint256 newDuration = (abond.gain.sub(b_.gain)).mul(abond.maturesAt.sub(now_)).div(abondDebt()).add(1);
        // timestamp = timestamp - tokens * d / tokens
        uint256 newIssuedAt = abond.maturesAt.sub(newDuration, "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal.sub(b_.principal),
          abond.gain.sub(b_.gain),
          newIssuedAt,
          abond.maturesAt,
          false
        );
    }

    function _mintJuniorBond(address to_, JuniorBond memory jb_)
      internal
    {
        require(
          juniorBondId < MAX_UINT256,
          "SY: _mintJuniorBond"
        );

        juniorBondId++;
        juniorBonds[juniorBondId] = jb_;

        _accountJuniorBond(jb_);
        IBond(juniorBond).mint(to_, juniorBondId);
    }

    function _accountJuniorBond(JuniorBond memory jb_)
      internal
    {
        // tokensInJuniorBonds += jb_.tokens
        tokensInJuniorBonds = tokensInJuniorBonds.add(jb_.tokens);

        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        uint256 tmp;

        if (jBondsAt.tokens == 0 && block.timestamp < jb_.maturesAt) {
          juniorBondsMaturities.push(jb_.maturesAt);
          for (uint256 i = juniorBondsMaturities.length - 1; i >= MathUtils.max(1, juniorBondsMaturitiesPrev); i--) {
            if (juniorBondsMaturities[i] > juniorBondsMaturities[i - 1]) {
              break;
            }
            tmp = juniorBondsMaturities[i - 1];
            juniorBondsMaturities[i - 1] = juniorBondsMaturities[i];
            juniorBondsMaturities[i] = tmp;
          }
        }

        // jBondsAt.tokens += jb_.tokens
        jBondsAt.tokens = jBondsAt.tokens.add(jb_.tokens);
    }

    function _burnJuniorBond(uint256 bondId_) internal {
        // blows up if already burned
        IBond(juniorBond).burn(bondId_);
    }

    function _unaccountJuniorBond(JuniorBond memory jb_) internal {
        // tokensInJuniorBonds -= jb_.tokens;
        tokensInJuniorBonds = tokensInJuniorBonds.sub(jb_.tokens);
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        // jBondsAt.tokens -= jb_.tokens;
        jBondsAt.tokens = jBondsAt.tokens.sub(jb_.tokens);
    }

    function _takeTokens(address from_, uint256 amount_) internal {
        _transfer(from_, address(this), amount_);
    }

  // /internals

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathUtils {

    using SafeMath for uint256;

    uint256 public constant EXP_SCALE = 1e18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function compound(
        // in wei
        uint256 principal,
        // rate is * EXP_SCALE
        uint256 ratePerPeriod,
        uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
          // principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
      }

      return principal;
    }

    function compound2(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
        if (periods % 2 == 1) {
          //principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
        } else {
          //ratePerPeriod = ((2 * ratePerPeriod * EXP_SCALE) + (ratePerPeriod * ratePerPeriod)) / EXP_SCALE;
          ratePerPeriod = ((uint256(2).mul(ratePerPeriod).mul(EXP_SCALE)).add(ratePerPeriod.mul(ratePerPeriod))).div(EXP_SCALE);
          periods /= 2;
        }
      }

      return principal;
    }

    function linearGain(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      return principal.add(
        fractionOf(principal, ratePerPeriod.mul(periods))
      );
    }

    // computes a * f / EXP_SCALE
    function fractionOf(uint256 a, uint256 f) internal pure returns (uint256) {
      return a.mul(f).div(EXP_SCALE);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Governed.sol";
import "./IProvider.sol";
import "./ISmartYield.sol";

abstract contract IController is Governed {

    uint256 public constant EXP_SCALE = 1e18;

    address public pool; // compound provider pool

    address public smartYield; // smartYield

    address public oracle; // IYieldOracle

    address public bondModel; // IBondModel

    address public feesOwner; // fees are sent here

    // max accepted cost of harvest when converting COMP -> underlying,
    // if harvest gets less than (COMP to underlying at spot price) - HARVEST_COST%, it will revert.
    // if it gets more, the difference goes to the harvest caller
    uint256 public HARVEST_COST = 40 * 1e15; // 4%

    // fee for buying jTokens
    uint256 public FEE_BUY_JUNIOR_TOKEN = 3 * 1e15; // 0.3%

    // fee for redeeming a sBond
    uint256 public FEE_REDEEM_SENIOR_BOND = 100 * 1e15; // 10%

    // max rate per day for sBonds
    uint256 public BOND_MAX_RATE_PER_DAY = 719065000000000; // APY 30% / year

    // max duration of a purchased sBond
    uint16 public BOND_LIFE_MAX = 90; // in days

    bool public PAUSED_BUY_JUNIOR_TOKEN = false;

    bool public PAUSED_BUY_SENIOR_BOND = false;

    function setHarvestCost(uint256 newValue_)
      public
      onlyDao
    {
        require(
          HARVEST_COST < EXP_SCALE,
          "IController: HARVEST_COST too large"
        );
        HARVEST_COST = newValue_;
    }

    function setBondMaxRatePerDay(uint256 newVal_)
      public
      onlyDao
    {
      BOND_MAX_RATE_PER_DAY = newVal_;
    }

    function setBondLifeMax(uint16 newVal_)
      public
      onlyDao
    {
      BOND_LIFE_MAX = newVal_;
    }

    function setFeeBuyJuniorToken(uint256 newVal_)
      public
      onlyDao
    {
      FEE_BUY_JUNIOR_TOKEN = newVal_;
    }

    function setFeeRedeemSeniorBond(uint256 newVal_)
      public
      onlyDao
    {
      FEE_REDEEM_SENIOR_BOND = newVal_;
    }

    function setPaused(bool buyJToken_, bool buySBond_)
      public
      onlyDaoOrGuardian
    {
      PAUSED_BUY_JUNIOR_TOKEN = buyJToken_;
      PAUSED_BUY_SENIOR_BOND = buySBond_;
    }

    function setOracle(address newVal_)
      public
      onlyDao
    {
      oracle = newVal_;
    }

    function setBondModel(address newVal_)
      public
      onlyDao
    {
      bondModel = newVal_;
    }

    function setFeesOwner(address newVal_)
      public
      onlyDao
    {
      feesOwner = newVal_;
    }

    function yieldControllTo(address newController_)
      public
      onlyDao
    {
      IProvider(pool).setController(newController_);
      ISmartYield(smartYield).setController(newController_);
    }

    function providerRatePerDay() external virtual returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ISmartYield {

    // a senior BOND (metadata for NFT)
    struct SeniorBond {
        // amount seniors put in
        uint256 principal;
        // amount yielded at the end. total = principal + gain
        uint256 gain;
        // bond was issued at timestamp
        uint256 issuedAt;
        // bond matures at timestamp
        uint256 maturesAt;
        // was it liquidated yet
        bool liquidated;
    }

    // a junior BOND (metadata for NFT)
    struct JuniorBond {
        // amount of tokens (jTokens) junior put in
        uint256 tokens;
        // bond matures at timestamp
        uint256 maturesAt;
    }

    // a checkpoint for all JuniorBonds with same maturity date JuniorBond.maturesAt
    struct JuniorBondsAt {
        // sum of JuniorBond.tokens for JuniorBonds with the same JuniorBond.maturesAt
        uint256 tokens;
        // price at which JuniorBonds will be paid. Initially 0 -> unliquidated (price is in the future or not yet liquidated)
        uint256 price;
    }

    function controller() external view returns (address);

    function buyBond(uint256 principalAmount_, uint256 minGain_, uint256 deadline_, uint16 forDays_) external returns (uint256);

    function redeemBond(uint256 bondId_) external;

    function unaccountBonds(uint256[] memory bondIds_) external;

    function buyTokens(uint256 underlyingAmount_, uint256 minTokens_, uint256 deadline_) external;

    /**
     * sell all tokens instantly
     */
    function sellTokens(uint256 tokens_, uint256 minUnderlying_, uint256 deadline_) external;

    function buyJuniorBond(uint256 tokenAmount_, uint256 maxMaturesAt_, uint256 deadline_) external;

    function redeemJuniorBond(uint256 jBondId_) external;

    function liquidateJuniorBonds(uint256 upUntilTimestamp_) external;

    /**
     * token purchase price
     */
    function price() external returns (uint256);

    function abondPaid() external view returns (uint256);

    function abondDebt() external view returns (uint256);

    function abondGain() external view returns (uint256);

    /**
     * @notice current total underlying balance, without accruing interest
     */
    function underlyingTotal() external returns (uint256);

    /**
     * @notice current underlying loanable, without accruing interest
     */
    function underlyingLoanable() external returns (uint256);

    function underlyingJuniors() external returns (uint256);

    function bondGain(uint256 principalAmount_, uint16 forDays_) external returns (uint256);

    function maxBondDailyRate() external returns (uint256);

    function setController(address newController_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IProvider {

    function smartYield() external view returns (address);

    function controller() external view returns (address);

    function underlyingFees() external view returns (uint256);

    // deposit underlyingAmount_ into provider, add takeFees_ to fees
    function _depositProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

    // withdraw underlyingAmount_ from provider, add takeFees_ to fees
    function _withdrawProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

    function _takeUnderlying(address from_, uint256 amount_) external;

    function _sendUnderlying(address to_, uint256 amount_) external;

    function transferFees() external;

    // current total underlying balance as measured by the provider pool, without fees
    function underlyingBalance() external returns (uint256);

    function setController(address newController_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IBondModel {

    function gain(uint256 total_, uint256 loanable_, uint256 dailyRate_, uint256 principal_, uint16 forDays_) external pure returns (uint256);

    function maxDailyRate(uint256 total_, uint256 loanable_, uint256 dailyRate_) external pure returns (uint256);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBond is IERC721 {
    function smartYield() external view returns (address);

    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract JuniorToken is ERC20 {

    constructor(
      string memory name_,
      string memory symbol_,
      uint8 decimals_
    )
      ERC20(name_, symbol_)
    {
      _setupDecimals(decimals_);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

abstract contract Governed {

  address public dao;
  address public guardian;

  modifier onlyDao {
    require(
        dao == msg.sender,
        "GOV: not dao"
      );
    _;
  }

  modifier onlyDaoOrGuardian {
    require(
      msg.sender == dao || msg.sender == guardian,
      "GOV: not dao/guardian"
    );
    _;
  }

  constructor()
  {
    dao = msg.sender;
    guardian = msg.sender;
  }

  function setDao(address dao_)
    external
    onlyDao
  {
    dao = dao_;
  }

  function setGuardian(address guardian_)
    external
    onlyDao
  {
    guardian = guardian_;
  }

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

