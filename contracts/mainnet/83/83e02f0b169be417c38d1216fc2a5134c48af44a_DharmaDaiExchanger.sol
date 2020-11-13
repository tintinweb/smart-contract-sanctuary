pragma solidity 0.6.12;


interface DharmaDaiExchangerInterface {
  event Deposit(address indexed account, uint256 tokensReceived, uint256 daiSupplied, uint256 dDaiSupplied);
  event Withdraw(address indexed account, uint256 tokensSupplied, uint256 daiReceived, uint256 dDaiReceived);

  function deposit(uint256 dai, uint256 dDai) external returns (uint256 tokensMinted);
  function withdraw(uint256 tokensToBurn) external returns (uint256 dai, uint256 dDai);
  function mintTo(address account, uint256 daiToSupply) external returns (uint256 dDaiMinted);
  function redeemUnderlyingTo(address account, uint256 daiToReceive) external returns (uint256 dDaiBurned);
  
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
}


interface DTokenInterface {
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function transfer(address recipient, uint256 dTokenAmount) external returns (bool ok);
  function transferFrom(address sender, address recipient, uint256 dTokenAmount) external returns (bool ok);
  
  function exchangeRateCurrent() external view returns (uint256 dTokenExchangeRate);
  function balanceOf(address account) external view returns (uint256);
}


interface ERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address recipient, uint256 amount) external returns (bool ok);
  function approve(address spender, uint256 amount) external returns (bool ok);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool ok);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}


contract ERC20 is ERC20Interface {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount, "ERC20: burn amount exceeds total supply");
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


/// @author 0age
contract DharmaDaiExchanger is DharmaDaiExchangerInterface, ERC20 {
  DTokenInterface private _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );
  
  ERC20Interface private _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );
  
  constructor() public {
    // Approve Dharma Dai to move Dai on behalf of this contract to support minting.
    require(
      _DAI.approve(address(_DDAI), type(uint256).max),
      "DharmaDaiExchanger: Dai approval for Dharma Dai failed."
    );

    // Ensure that LP token balance is non-zero — at least 1 Dai must be "donated" as well.
    _mint(address(this), 1e18);
    emit Deposit(address(this), 1e18, 1e18, 0);
  }

  /**
   * @notice Supply a specified Dai and/or Dharma Dai amount and receive back
   * liquidity provider tokens in exchange. Approval must be given to this
   * contract before calling this function.
   * @param dai uint256 The amount of Dai to supply.
   * @param dDai uint256 The amount of Dharma Dai to supply.
   * @return tokensReceived The amount of LP tokens received.
   */
  function deposit(uint256 dai, uint256 dDai) external override returns (uint256 tokensReceived) {
    require(dai > 0 || dDai > 0, "DharmaDaiExchanger: No funds specified to deposit.");
    
    // Get the current Dai <> dDai exchange rate.
    uint256 exchangeRate = _DDAI.exchangeRateCurrent();

    // Determine Dai-equivalent value of funds currently in the pool (rounded up).
    uint256 originalLiquidityValue = _getCurrentLiquidityValue(exchangeRate, true);
    require(
      originalLiquidityValue >= 1e18,
      "DharmaDaiExchanger: Must seed contract with at least 1 Dai before depositing."
    );
    
    // Transfer in supplied dai & dDai amounts.
    if (dai > 0) {
      require(
        _DAI.transferFrom(msg.sender, address(this), dai),
        "DharmaDaiExchanger: Dai transfer in failed — ensure allowance is correctly set."
      );
    }

    if (dDai > 0) {
      require(
        _DDAI.transferFrom(msg.sender, address(this), dDai),
        "DharmaDaiExchanger: Dharma Dai transfer in failed — ensure allowance is correctly set."
      );
    }
    
    // Determine the new Dai-equivalent liquidity value (rounded down).
    uint256 newLiquidityValue = _getCurrentLiquidityValue(exchangeRate, false);
    require(
      newLiquidityValue > originalLiquidityValue,
      "DharmaDaiExchanger: Supplied funds did not sufficiently increase liquidity value."
    );

    // Determine LP tokens to mint by applying liquidity value ratio to current supply.
    uint256 originalLPTokens = totalSupply();
    uint256 newLPTokens = originalLPTokens.mul(newLiquidityValue) / originalLiquidityValue;
    require(
      newLPTokens > originalLPTokens,
      "DharmaDaiExchanger: Supplied funds are insufficient to mint LP tokens."
    );
    tokensReceived = newLPTokens - originalLPTokens;
    
    // Mint the LP tokens.
    _mint(msg.sender, tokensReceived);
    
    emit Deposit(msg.sender, tokensReceived, dai, dDai);
  }

  /**
   * @notice Supply a specified number of liquidity provider tokens and
   * get back the proportion of Dai and/or Dharma Dai tokens currently held
   * by this contract in exchange.
   * @param tokensToSupply The amount of LP tokens to supply.
   * @return dai uint256 The amount of Dai received.
   * @return dDai uint256 The amount of Dharma Dai received.
   */
  function withdraw(uint256 tokensToSupply) external override returns (uint256 dai, uint256 dDai) {
    require(tokensToSupply > 0, "DharmaDaiExchanger: No funds specified to withdraw.");
    
    // Get the total supply, as well as current Dai & dDai balances.
    uint256 originalLPTokens = totalSupply();
    uint256 daiBalance = _DAI.balanceOf(address(this));
    uint256 dDaiBalance = _DDAI.balanceOf(address(this));
 
     // Apply LP token ratio to Dai & dDai balances to determine amount to transfer out.
    dai = daiBalance.mul(tokensToSupply) / originalLPTokens;
    dDai = dDaiBalance.mul(tokensToSupply) / originalLPTokens;
    require(
      dai.add(dDai) > 0,
      "DharmaDaiExchanger: Supplied tokens are insufficient to withdraw liquidity."
    );
    
    // Burn the LP tokens.
    _burn(msg.sender, tokensToSupply);
    
    // Transfer out the proportion of Dai & dDai associated with the burned tokens.
    if (dai > 0) {
      require(
        _DAI.transfer(msg.sender, dai),
        "DharmaDaiExchanger: Dai transfer out failed."
      );
    }

    if (dDai > 0) {
      require(
        _DDAI.transfer(msg.sender, dDai),
        "DharmaDaiExchanger: Dharma Dai transfer out failed."
      );
    }
    
    emit Withdraw(msg.sender, tokensToSupply, dai, dDai);
  }

  /**
   * @notice Supply a specified amount of Dai and receive Dharma Dai to
   * the specified account in exchange. Dai approval must be given to
   * this contract before calling this function.
   * @param account The recipient of the minted Dharma Dai.
   * @param daiToSupply uint256 The amount of Dai to supply.
   * @return dDaiMinted uint256 The amount of Dharma Dai received.
   */
  function mintTo(address account, uint256 daiToSupply) external override returns (uint256 dDaiMinted) {
    // Get the current Dai <> dDai exchange rate.
    uint256 exchangeRate = _DDAI.exchangeRateCurrent();
    
    // Get the dDai to mint in exchange for the supplied Dai (round down).
    dDaiMinted = _fromUnderlying(daiToSupply, exchangeRate, false);
    require(
      dDaiMinted > 0,
      "DharmaDaiExchanger: Supplied Dai is insufficient to mint Dharma Dai."
    );
      
    // Get the current dDai balance.
    uint256 dDaiBalance = _DDAI.balanceOf(address(this));
    
    // Transfer in Dai to supply.
    require(
      _DAI.transferFrom(msg.sender, address(this), daiToSupply),
      "DharmaDaiExchanger: Dai transfer in failed — ensure allowance is correctly set."
    );
    
    // Only perform a mint if insufficient dDai is currently available.
    if (dDaiBalance < dDaiMinted) {
      // Provide enough Dai to leave equal Dai and dDai value after transfer.
      uint256 daiBalance = _DAI.balanceOf(address(this));
      uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, false);
      uint256 daiToSupplyInBatch = (daiBalance.add(daiToSupply)).sub(dDaiBalanceInDai) / 2;
      _DDAI.mint(daiToSupplyInBatch);
    }

    // Transfer the dDai to the specified recipient.
    require(
      _DDAI.transfer(account, dDaiMinted),
      "DharmaDaiExchanger: Dharma Dai transfer out failed."
    );
  }

  /**
   * @notice Supply a specified amount of Dharma Dai (denominated in Dai)
   * and receive Dai to the specified account in exchange. Dharma Dai
   * approval must be given to this contract before calling this function.
   * @param account The recipient of the received Dai.
   * @param daiToReceive uint256 The amount of Dai to receive back in
   * exchange for supplied Dharma Dai.
   * @return dDaiBurned uint256 The amount of Dharma Dai redeemed.
   */
  function redeemUnderlyingTo(address account, uint256 daiToReceive) external override returns (uint256 dDaiBurned) {
    // Get the current Dai <> dDai exchange rate.
    uint256 exchangeRate = _DDAI.exchangeRateCurrent();
    
    // Get the dDai to burn in exchange for the received Dai (round up).
    dDaiBurned = _fromUnderlying(daiToReceive, exchangeRate, true);
    require(
      dDaiBurned > 0,
      "DharmaDaiExchanger: Dai amount to receive is insufficient to redeem Dharma Dai."
    );

    // Get the current Dai balance.
    uint256 daiBalance = _DAI.balanceOf(address(this));

    // Transfer in required dDai to burn.
    require(
      _DDAI.transferFrom(msg.sender, address(this), dDaiBurned),
      "DharmaDaiExchanger: Dharma Dai transfer in failed — ensure allowance is correctly set."
    );

    // Only perform a redeem if insufficient Dai is currently available.
    if (daiBalance < daiToReceive) {
      // Provide enough Dai to leave equal Dai and dDai value after transfer.
      uint256 dDaiBalance = _DDAI.balanceOf(address(this));
      uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, false);
      uint256 daiToReceiveInBatch = (dDaiBalanceInDai.add(daiToReceive)).sub(daiBalance) / 2;
      _DDAI.redeemUnderlying(daiToReceiveInBatch);
    }

    // Transfer the Dai to the specified recipient.
    require(
      _DAI.transfer(account, daiToReceive),
      "DharmaDaiExchanger: Dai transfer out failed."
    );
  }

  function name() external pure override returns (string memory) {
    return "Dai <> Dharma Dai Exchanger (Liquidity Provider token)";
  }

  function symbol() external pure override returns (string memory) {
    return "Dai-dDai-LP";
  }

  function decimals() external pure override returns (uint8) {
    return 18;
  }

  /**
   * @notice Internal view function to get the the current combined value of
   * Dai and Dharma Dai held by this contract, denominated in Dai.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUp bool Whether the final amount should be rounded up - it will
   * instead be truncated (rounded down) if this value is false.
   * @return totalValueInDai The combined value in Dai held by this contract.
   */  
  function _getCurrentLiquidityValue(uint256 exchangeRate, bool roundUp) internal view returns (uint256 totalValueInDai) {
    uint256 daiBalance = _DAI.balanceOf(address(this));
    uint256 dDaiBalance = _DDAI.balanceOf(address(this));
    uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, roundUp);
    totalValueInDai = daiBalance.add(dDaiBalanceInDai);
  }
 
  /**
   * @notice Internal pure function to convert an underlying amount to a dToken
   * amount using an exchange rate and fixed-point arithmetic.
   * @param underlying uint256 The underlying amount to convert.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUp bool Whether the final amount should be rounded up - it will
   * instead be truncated (rounded down) if this value is false.
   * @return amount The dToken amount.
   */
  function _fromUnderlying(
    uint256 underlying, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 amount) {
    if (roundUp) {
      amount = (
        (underlying.mul(1e18)).add(exchangeRate.sub(1))
      ).div(exchangeRate);
    } else {
      amount = (underlying.mul(1e18)).div(exchangeRate);
    }
  }

  /**
   * @notice Internal pure function to convert a dToken amount to the
   * underlying amount using an exchange rate and fixed-point arithmetic.
   * @param amount uint256 The dToken amount to convert.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUp bool Whether the final amount should be rounded up - it will
   * instead be truncated (rounded down) if this value is false.
   * @return underlying The underlying amount.
   */
  function _toUnderlying(
    uint256 amount, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 underlying) {
    if (roundUp) {
      underlying = (
        (amount.mul(exchangeRate).add(999999999999999999)
      ) / 1e18);
    } else {
      underlying = amount.mul(exchangeRate) / 1e18;
    }
  }
}