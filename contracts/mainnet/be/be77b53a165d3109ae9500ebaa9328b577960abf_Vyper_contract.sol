#@version 0.2.7
"""
@title Yearn Token Vault
@license GNU AGPLv3
@author yearn.finance
@notice
    Yearn Token Vault. Holds an underlying token, and allows users to interact
    with the Yearn ecosystem through Strategies connected to the Vault.
    Vaults are not limited to a single Strategy, they can have as many Strategies
    as can be designed (however the withdrawal queue is capped at 20.)

    Deposited funds are moved into the most impactful strategy that has not
    already reached its limit for assets under management, regardless of which
    Strategy a user's funds end up in, they receive their portion of yields
    generated across all Strategies.

    When a user withdraws, if there are no funds sitting undeployed in the
    Vault, the Vault withdraws funds from Strategies in the order of least
    impact. (Funds are taken from the Strategy that will disturb everyone's
    gains the least, then the next least, etc.) In order to achieve this, the
    withdrawal queue's order must be properly set and managed by the community
    (through governance).

    Vault Strategies are parameterized to pursue the highest risk-adjusted yield.

    There is an "Emergency Shutdown" mode. When the Vault is put into emergency
    shutdown, assets will be recalled from the Strategies as quickly as is
    practical (given on-chain conditions), minimizing loss. Deposits are
    halted, new Strategies may not be added, and each Strategy exits with the
    minimum possible damage to position, while opening up deposits to be
    withdrawn by users. There are no restrictions on withdrawals above what is
    expected under Normal Operation.

    For further details, please refer to the specification:
    https://github.com/iearn-finance/yearn-vaults/blob/master/SPECIFICATION.md
"""

API_VERSION: constant(String[28]) = "0.1.3"

# TODO: Add ETH Configuration
# TODO: Add Delegated Configuration
from vyper.interfaces import ERC20

implements: ERC20

interface DetailedERC20:
    def name() -> String[42]: view
    def symbol() -> String[20]: view
    def decimals() -> uint256: view

interface Strategy:
    def distributeRewards(_shares: uint256): nonpayable
    def estimatedTotalAssets() -> uint256: view
    def withdraw(_amount: uint256): nonpayable
    def migrate(_newStrategy: address): nonpayable

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

token: public(ERC20)
governance: public(address)
guardian: public(address)
pendingGovernance: address

struct StrategyParams:
    performanceFee: uint256  # Strategist's fee (basis points)
    activation: uint256  # Activation block.number
    debtLimit: uint256  # Maximum borrow amount
    rateLimit: uint256  # Increase/decrease per block
    lastReport: uint256  # block.number of the last time a report occured
    totalDebt: uint256  # Total outstanding debt that Strategy has
    totalReturns: uint256  # Total returns that Strategy has realized for Vault

event StrategyAdded:
    strategy: indexed(address)
    debtLimit: uint256  # Maximum borrow amount
    rateLimit: uint256  # Increase/decrease per block
    performanceFee: uint256  # Strategist's fee (basis points)

event StrategyReported:
    strategy: indexed(address)
    returnAdded: uint256
    debtAdded: uint256
    totalReturn: uint256
    totalDebt: uint256
    debtLimit: uint256

# NOTE: Track the total for overhead targeting purposes
strategies: public(HashMap[address, StrategyParams])
MAXIMUM_STRATEGIES: constant(uint256) = 20

# Ordering that `withdraw` uses to determine which strategies to pull funds from
# NOTE: Does *NOT* have to match the ordering of all the current strategies that
#       exist, but it is recommended that it does or else withdrawal depth is
#       limited to only those inside the queue.
# NOTE: Ordering is determined by governance, and should be balanced according
#       to risk, slippage, and/or volatility. Can also be ordered to increase the
#       withdrawal speed of a particular Strategy.
# NOTE: The first time a ZERO_ADDRESS is encountered, it stops withdrawing
withdrawalQueue: public(address[MAXIMUM_STRATEGIES])

emergencyShutdown: public(bool)

depositLimit: public(uint256)  # Limit for totalAssets the Vault can hold
debtLimit: public(uint256)  # Debt limit for the Vault across all strategies
totalDebt: public(uint256)  # Amount of tokens that all strategies have borrowed
lastReport: public(uint256)  # Number of blocks since last report

rewards: public(address)  # Rewards contract where Governance fees are sent to
managementFee: public(uint256)  # Governance Fee for management of Vault (given to `rewards`)
performanceFee: public(uint256)  # Governance Fee for performance of Vault (given to `rewards`)
FEE_MAX: constant(uint256) = 10_000  # 100%, or 10k basis points
BLOCKS_PER_YEAR: constant(uint256) = 2_300_000

@external
def __init__(
    _token: address,
    _governance: address,
    _rewards: address,
    _nameOverride: String[64],
    _symbolOverride: String[32]
):
    """
    @notice
        Initializes the Vault, this is called only once, when the contract is
        deployed.
        The performance fee is set to 4.5% of yield, per Strategy.
        The management fee is set to 2%, per year.
        There is no initial deposit limit.
    @dev
        If `_nameOverride` is not specified, the name will be 'yearn'
        combined with the name of _token.

        If `_symbolOverride` is not specified, the symbol will be 'y'
        combined with the symbol of _token.
    @param _token The token that may be deposited into this Vault.
    @param _governance The address authorized for governance interactions.
    @param _rewards The address to distribute rewards to.
    @param _nameOverride Specify a custom Vault name. Leave empty for default choice.
    @param _symbolOverride Specify a custom Vault symbol name. Leave empty for default choice.
    """
    # TODO: Non-detailed Configuration?
    self.token = ERC20(_token)
    if _nameOverride == "":
        self.name = concat(DetailedERC20(_token).symbol(), " yVault")
    else:
        self.name = _nameOverride
    if _symbolOverride == "":
        self.symbol = concat("yv", DetailedERC20(_token).symbol())
    else:
        self.symbol = _symbolOverride
    self.decimals = DetailedERC20(_token).decimals()
    self.governance = _governance
    self.rewards = _rewards
    self.guardian = msg.sender
    self.performanceFee = 450  # 4.5% of yield (per Strategy)
    self.managementFee = 200  # 2% per year
    self.depositLimit = MAX_UINT256  # Start unlimited
    self.lastReport = block.number


@pure
@external
def apiVersion() -> String[28]:
    """
    @notice
        Used to track the deployed version of this contract. In practice you
        can use this version number to compare with yEarn's GitHub and
        determine which version of the source matches this deployed contract.
    @return API_VERSION which holds the current version of this contract.
    """
    return API_VERSION


@external
def setName(_name: String[42]):
    assert msg.sender == self.governance
    self.name = _name


@external
def setSymbol(_symbol: String[20]):
    assert msg.sender == self.governance
    self.symbol = _symbol


# 2-phase commit for a change in governance
@external
def setGovernance(_governance: address):
    """
    @notice
        Nominate a new address to use as governance.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed governance address has accepted the responsibility.

        This may only be called by the current governance address.
    @param _governance The address requested to take over Vault governance.
    """
    assert msg.sender == self.governance
    self.pendingGovernance = _governance


@external
def acceptGovernance():
    """
    @notice
        Once a new governance address has been proposed using setGovernance(),
        this function may be called by the proposed address to accept the
        responsibility of taking over governance for this contract.

        This may only be called by the proposed governance address.
    @dev
        setGovernance() should be called by the existing governance address,
        prior to calling this function.
    """
    assert msg.sender == self.pendingGovernance
    self.governance = msg.sender


@external
def setRewards(_rewards: address):
    """
    @notice
        Changes the rewards address. Any distributed rewards
        will cease flowing to the old address and begin flowing
        to this address once the change is in effect.

        This will not change any Strategy reports in progress, only
        new reports made after this change goes into effect.

        This may only be called by governance.
    @param _rewards The address to use for collecting rewards.
    """
    assert msg.sender == self.governance
    self.rewards = _rewards


@external
def setDepositLimit(_limit: uint256):
    """
    @notice
        Changes the maximum amount of tokens that can be deposited in this Vault.

        Note, this is not how much may be deposited by a single depositor,
        but the maximum amount that may be deposited across all depositors.

        This may only be called by governance.
    @param _limit The new deposit limit to use.
    """
    assert msg.sender == self.governance
    self.depositLimit = _limit


@external
def setPerformanceFee(_fee: uint256):
    """
    @notice
        Used to change the value of `performanceFee`.

        This may only be called by governance.
    @param _fee The new performance fee to use.
    """
    assert msg.sender == self.governance
    self.performanceFee = _fee


@external
def setManagementFee(_fee: uint256):
    """
    @notice
        Used to change the value of `managementFee`.

        This may only be called by governance.
    @param _fee The new management fee to use.
    """
    assert msg.sender == self.governance
    self.managementFee = _fee


@external
def setGuardian(_guardian: address):
    """
    @notice
        Used to change the address of `guardian`.

        This may only be called by governance or the existing guardian.
    @param _guardian The new guardian address to use.
    """
    assert msg.sender in [self.guardian, self.governance]
    self.guardian = _guardian


@external
def setEmergencyShutdown(_active: bool):
    """
    @notice
        Activates or deactivates Vault mode where all Strategies go into full
        withdrawal.

        During Emergency Shutdown:
        1. No Users may deposit into the Vault (but may withdraw as usual.)
        2. Governance may not add new Strategies.
        3. Each Strategy must pay back their debt as quickly as reasonable to
            minimally affect their position.
        4. Only Governance may undo Emergency Shutdown.

        See contract level note for further details.

        This may only be called by governance or the guardian.
    @param _active
        If true, the Vault goes into Emergency Shutdown. If false, the Vault
        goes back into Normal Operation.
    """
    assert msg.sender in [self.guardian, self.governance]
    self.emergencyShutdown = _active


@external
def setWithdrawalQueue(_queue: address[MAXIMUM_STRATEGIES]):
    """
    @notice
        Updates the withdrawalQueue to match the addresses and order specified
        by `_queue`.

        There can be fewer strategies than the maximum, as well as fewer than
        the total number of strategies active in the vault. `withdrawalQueue`
        will be updated in a gas-efficient manner, assuming the input is well-
        ordered with 0x0 only at the end.

        This may only be called by governance.
    @dev
        This is order sensitive, specify the addresses in the order in which
        funds should be withdrawn (so `_queue`[0] is the first Strategy withdrawn
        from, `_queue`[1] is the second, etc.)

        This means that the least impactful Strategy (the Strategy that will have
        its core positions impacted the least by having funds removed) should be
        at `_queue`[0], then the next least impactful at `_queue`[1], and so on.
    @param _queue
        The array of addresses to use as the new withdrawal queue. This is
        order sensitive.
    """
    assert msg.sender == self.governance
    # HACK: Temporary until Vyper adds support for Dynamic arrays
    for i in range(MAXIMUM_STRATEGIES):
        if _queue[i] == ZERO_ADDRESS and self.withdrawalQueue[i] == ZERO_ADDRESS:
            break
        assert self.strategies[_queue[i]].activation > 0
        self.withdrawalQueue[i] = _queue[i]


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    # See note on `transfer()`.

    # Protect people from accidentally sending their shares to bad places
    assert not (_to in [self, ZERO_ADDRESS])
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)


@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice
        Transfers shares from the caller's address to `_to`. This function
        will always return true, unless the user is attempting to transfer
        shares to this contract's address, or to 0x0.
    @param _to
        The address shares are being transferred to. Must not be this contract's
        address, must not be 0x0.
    @param _value The quantity of shares to transfer.
    @return
        True if transfer is sent to an address other than this contract's or
        0x0, otherwise the transaction will fail.
    """
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice
        Transfers `_value` shares from `_from` to `_to`. This operation will
        always return true, unless the user is attempting to transfer shares
        to this contract's address, or to 0x0.

        Unless the caller has given this contract unlimited approval,
        transfering shares will decrement the caller's `allowance` by `_value`.
    @param _from The address shares are being transferred from.
    @param _to
        The address shares are being transferred to. Must not be this contract's
        address, must not be 0x0.
    @param _value The quantity of shares to transfer.
    @return
        True if transfer is sent to an address other than this contract's or
        0x0, otherwise the transaction will fail.
    """
    if self.allowance[_from][msg.sender] < MAX_UINT256:  # Unlimited approval (saves an SSTORE)
       self.allowance[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of
         `msg.sender`. Beware that changing an allowance with this method brings the risk
         that someone may use both the old and the new allowance by unfortunate transaction
         ordering. See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def increaseAllowance(_spender : address, _value : uint256) -> bool:
    """
    @dev Increase the allowance of the passed address to spend the total amount of tokens
         on behalf of msg.sender. This method mitigates the risk that someone may use both
         the old and the new allowance by unfortunate transaction ordering.
         See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to increase the allowance by.
    """
    self.allowance[msg.sender][_spender] += _value
    log Approval(msg.sender, _spender, self.allowance[msg.sender][_spender])
    return True


@external
def decreaseAllowance(_spender : address, _value : uint256) -> bool:
    """
    @dev Decrease the allowance of the passed address to spend the total amount of tokens
         on behalf of msg.sender. This method mitigates the risk that someone may use both
         the old and the new allowance by unfortunate transaction ordering.
         See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to decrease the allowance by.
    """
    self.allowance[msg.sender][_spender] -= _value
    log Approval(msg.sender, _spender, self.allowance[msg.sender][_spender])
    return True


@view
@internal
def _totalAssets() -> uint256:
    # See note on `totalAssets()`.
    return self.token.balanceOf(self) + self.totalDebt


@view
@external
def totalAssets() -> uint256:
    """
    @notice
        Returns the total quantity of all assets under control of this
        Vault, whether they're loaned out to a Strategy, or currently held in
        the Vault.
    @return The total assets under control of this Vault.
    """
    return self._totalAssets()


@view
@internal
def _balanceSheetOfStrategy(_strategy: address) -> uint256:
    # See note on `balanceSheetOfStrategy()`.
    return Strategy(_strategy).estimatedTotalAssets()


@view
@external
def balanceSheetOfStrategy(_strategy: address) -> uint256:
    """
    @notice
        Provide an accurate estimate for the total amount of assets
        (principle + return) that `_strategy` is currently managing,
        denominated in terms of `_token`.

        This total is the total realizable value that could *actually* be
        obtained from this Strategy if it were to divest its entire position
        based on current on-chain conditions.
    @param _strategy The Strategy to estimate the realizable assets of.
    @return An estimate of the total realizable assets in `_strategy`.
    """
    return self._balanceSheetOfStrategy(_strategy)


@view
@external
def totalBalanceSheet(_strategies: address[2 * MAXIMUM_STRATEGIES]) -> uint256:
    """
    @notice
        Measure the total balance sheet of this Vault, using the list of
        strategies given above.
        (2x the expected maximum is used to ensure completeness.)
        NOTE: The safety of this function depends *entirely* on the list of
            strategies given as the function argument. Care should be taken to
            choose this list to ensure that the estimate is accurate. No
            additional checking is used.
        NOTE: Guardian should use this value vs. `totalAssets()` to determine
            if a condition exists where the Vault is experiencing a dangerous
            'balance sheet' attack, leading Vault shares to be worth less than
            what their price on paper is (based on their debt)
    @param _strategies
        A list of strategies managed by this Vault, which will be included in
        the balance sheet calculation.
    @return The total balance sheet of this Vault.
    """
    balanceSheet: uint256 = self.token.balanceOf(self)

    for strategy in _strategies:
        if strategy == ZERO_ADDRESS:
            break
        balanceSheet += self._balanceSheetOfStrategy(strategy)

    return balanceSheet


@internal
def _issueSharesForAmount(_to: address, _amount: uint256) -> uint256:
    # Issues `_amount` Vault shares to `_to`.
    # Shares must be issued prior to taking on new collateral, or
    # calculation will be wrong. This means that only *trusted* tokens
    # (with no capability for exploitive behavior) can be used.
    shares: uint256 = 0
    # HACK: Saves 2 SLOADs (~4000 gas)
    totalSupply: uint256 = self.totalSupply
    if totalSupply > 0:
        # Mint amount of shares based on what the Vault is managing overall
        shares = _amount * totalSupply / self._totalAssets()
    else:
        # No existing shares, so mint 1:1
        shares = _amount

    # Mint new shares
    self.totalSupply = totalSupply + shares
    self.balanceOf[_to] += shares
    log Transfer(ZERO_ADDRESS, _to, shares)

    return shares


@external
def deposit(_amount: uint256 = MAX_UINT256, _recipient: address = msg.sender) -> uint256:
    """
    @notice
        Deposits `_amount` `token`, issuing shares to `_recipient`. If the
        Vault is in Emergency Shutdown, deposits will not be accepted and this
        call will fail.
    @dev
        Measuring quantity of shares to issues is based on the total
        outstanding debt that this contract has ("expected value") instead
        of the total balance sheet it has ("estimated value") has important
        security considerations, and is done intentionally. If this value were
        measured against external systems, it could be purposely manipulated by
        an attacker to withdraw more assets than they otherwise should be able
        to claim by redeeming their shares.

        On deposit, this means that shares are issued against the total amount
        that the deposited capital can be given in service of the debt that
        Strategies assume. If that number were to be lower than the "expected
        value" at some future point, depositing shares via this method could
        entitle the depositor to *less* than the deposited value once the
        "realized value" is updated from further reports by the Strategies
        to the Vaults.

        Care should be taken by integrators to account for this discrepancy,
        by using the view-only methods of this contract (both off-chain and
        on-chain) to determine if depositing into the Vault is a "good idea".
    @param _amount The quantity of tokens to deposit, defaults to all.
    @param _recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @return The issued Vault shares.
    """
    assert not self.emergencyShutdown  # Deposits are locked out

    amount: uint256 = _amount

    # If _amount not specified, transfer the full token balance
    if amount == MAX_UINT256:
        amount = self.token.balanceOf(msg.sender)

    # Ensure we are depositing something
    assert amount > 0

    # Ensure deposit limit is respected
    assert self._totalAssets() + amount <= self.depositLimit

    # Issue new shares (needs to be done before taking deposit to be accurate)
    # Shares are issued to recipient (may be different from msg.sender)
    # See @dev note, above.
    shares: uint256 = self._issueSharesForAmount(_recipient, amount)

    # Get new collateral
    reserve: uint256 = self.token.balanceOf(self)
    # Tokens are transferred from msg.sender (may be different from _recipient)
    self.token.transferFrom(msg.sender, self, amount)
    # TODO: `Deflationary` configuration only
    assert self.token.balanceOf(self) - reserve == amount  # Deflationary token check

    return shares  # Just in case someone wants them


@view
@internal
def _shareValue(_shares: uint256) -> uint256:
    # Determines the current value of `_shares`.
    return (_shares * (self._totalAssets())) / self.totalSupply


@view
@internal
def _sharesForAmount(_amount: uint256) -> uint256:
    # Determines how many shares `_amount` of token would receive.
    # See dev note on `deposit`.
    if self._totalAssets() > 0:
        return (_amount * self.totalSupply) / self._totalAssets()
    else:
        return 0


@view
@external
def maxAvailableShares() -> uint256:
    """
    @notice
        Determines the total quantity of shares this Vault can provide,
        factoring in assets currently residing in the Vault, as well as
        those deployed to strategies.
    @dev Regarding how shares are calculated, see dev note on `deposit`.
    @return The total quantity of shares this Vault can provide.
    """
    shares: uint256 = self._sharesForAmount(self.token.balanceOf(self))

    for strategy in self.withdrawalQueue:
        if strategy == ZERO_ADDRESS:
            break
        shares += self._sharesForAmount(self.strategies[strategy].totalDebt)

    return shares


@external
def withdraw(_shares: uint256 = MAX_UINT256, _recipient: address = msg.sender) -> uint256:
    """
    @notice
        Withdraws the calling account's tokens from this Vault, redeeming
        amount `_shares` for an appropriate amount of tokens.

        See note on `setWithdrawalQueue` for further details of withdrawal
        ordering and behavior.
    @dev
        Measuring the value of shares is based on the total outstanding debt
        that this contract has ("expected value") instead of the total balance
        sheet it has ("estimated value") has important security considerations,
        and is done intentionally. If this value were measured against external
        systems, it could be purposely manipulated by an attacker to withdraw
        more assets than they otherwise should be able to claim by redeeming
        their shares.

        On withdrawal, this means that shares are redeemed against the total
        amount that the deposited capital had "realized" since the point it
        was deposited, up until the point it was withdrawn. If that number
        were to be higher than the "expected value" at some future point,
        withdrawing shares via this method could entitle the depositor to
        *more* than the expected value once the "realized value" is updated
        from further reports by the Strategies to the Vaults.

        Under exceptional scenarios, this could cause earlier withdrawals to
        earn "more" of the underlying assets than Users might otherwise be
        entitled to, if the Vault's estimated value were otherwise measured
        through external means, accounting for whatever exceptional scenarios
        exist for the Vault (that aren't covered by the Vault's own design.)
    @param _shares How many shares to redeem for tokens, defaults to all.
    @param _recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @return The quantity of tokens redeemable for `_shares`.
    """
    shares: uint256 = _shares  # May reduce this number below

    # If _shares not specified, transfer full share balance
    if shares == MAX_UINT256:
        shares = self.balanceOf[msg.sender]

    # Limit to only the shares they own
    assert shares <= self.balanceOf[msg.sender]

    # See @dev note, above.
    value: uint256 = self._shareValue(shares)

    if value > self.token.balanceOf(self):
        # We need to go get some from our strategies in the withdrawal queue
        # NOTE: This performs forced withdrawals from each Strategy. There is
        #       a 0.5% withdrawal fee assessed on each forced withdrawal (<= 0.5% total)
        for strategy in self.withdrawalQueue:
            if strategy == ZERO_ADDRESS:
                break  # We've exhausted the queue

            amountNeeded: uint256 = value - self.token.balanceOf(self)

            if amountNeeded == 0:
                break  # We're done withdrawing

            # NOTE: Don't withdraw more than the debt so that Strategy can still
            #       continue to work based on the profits it has
            # NOTE: This means that user will lose out on any profits that each
            #       Strategy in the queue would return on next harvest, benefiting others
            amountNeeded = min(amountNeeded, self.strategies[strategy].totalDebt)
            if amountNeeded == 0:
                continue  # Nothing to withdraw from this Strategy, try the next one

            # Force withdraw amount from each Strategy in the order set by governance
            before: uint256 = self.token.balanceOf(self)
            Strategy(strategy).withdraw(amountNeeded)
            withdrawn: uint256 = self.token.balanceOf(self) - before

            # Reduce the Strategy's debt by the amount withdrawn ("realized returns")
            # NOTE: This doesn't add to returns as it's not earned by "normal means"
            self.strategies[strategy].totalDebt -= withdrawn
            self.totalDebt -= withdrawn

    # NOTE: We have withdrawn everything possible out of the withdrawal queue
    #       but we still don't have enough to fully pay them back, so adjust
    #       to the total amount we've freed up through forced withdrawals
    if value > self.token.balanceOf(self):
        value = self.token.balanceOf(self)
        shares = self._sharesForAmount(value)

    # Burn shares (full value of what is being withdrawn)
    self.totalSupply -= shares
    self.balanceOf[msg.sender] -= shares
    log Transfer(msg.sender, ZERO_ADDRESS, shares)

    # Withdraw remaining balance to _recipient (may be different to msg.sender) (minus fee)
    self.token.transfer(_recipient, value)

    return value


@view
@external
def pricePerShare() -> uint256:
    """
    @notice Gives the price for a single Vault share.
    @dev See dev note on `withdraw`.
    @return The value of a single share.
    """
    return self._shareValue(10 ** self.decimals)


@internal
def _organizeWithdrawalQueue():
    # Reorganize `withdrawalQueue` based on premise that if there is an
    # empty value between two actual values, then the empty value should be
    # replaced by the later value.
    # NOTE: Relative ordering of non-zero values is maintained.
    offset: uint256 = 0
    for idx in range(MAXIMUM_STRATEGIES):
        strategy: address = self.withdrawalQueue[idx]
        if strategy == ZERO_ADDRESS:
            offset += 1  # how many values we need to shift, always `<= idx`
        elif offset > 0:
            self.withdrawalQueue[idx-offset] = strategy
            self.withdrawalQueue[idx] = ZERO_ADDRESS


@external
def addStrategy(
    _strategy: address,
    _debtLimit: uint256,
    _rateLimit: uint256,
    _performanceFee: uint256,
):
    """
    @notice
        Add a Strategy to the Vault.

        This may only be called by governance.
    @dev
        The Strategy will be appended to `withdrawalQueue`, call
        `setWithdrawalQueue` to change the order.
    @param _strategy The address of the Strategy to add.
    @param _debtLimit The quantity of assets `_strategy` can manage.
    @param _rateLimit
        How many assets per block this Vault may deposit to or withdraw from
        `_strategy`.
    @param _performanceFee
        The fee the strategist will receive based on this Vault's performance.
    """
    assert msg.sender == self.governance
    assert self.strategies[_strategy].activation == 0
    self.strategies[_strategy] = StrategyParams({
        performanceFee: _performanceFee,
        activation: block.number,
        debtLimit: _debtLimit,
        rateLimit: _rateLimit,
        lastReport: block.number,
        totalDebt: 0,
        totalReturns: 0,
    })
    self.debtLimit += _debtLimit
    log StrategyAdded(_strategy, _debtLimit, _rateLimit, _performanceFee)

    # queue is full
    assert self.withdrawalQueue[MAXIMUM_STRATEGIES-1] == ZERO_ADDRESS
    self.withdrawalQueue[MAXIMUM_STRATEGIES-1] = _strategy
    self._organizeWithdrawalQueue()


@external
def updateStrategyDebtLimit(
    _strategy: address,
    _debtLimit: uint256,
):
    """
    @notice
        Change the quantity of assets `_strategy` may manage.

        This may only be called by governance.
    @param _strategy The Strategy to update.
    @param _debtLimit The quantity of assets `_strategy` may now manage.
    """
    assert msg.sender == self.governance
    assert self.strategies[_strategy].activation > 0
    self.debtLimit -= self.strategies[_strategy].debtLimit
    self.strategies[_strategy].debtLimit = _debtLimit
    self.debtLimit += _debtLimit


@external
def updateStrategyRateLimit(
    _strategy: address,
    _rateLimit: uint256,
):
    """
    @notice
        Change the quantity assets per block this Vault may deposit to or
        withdraw from `_strategy`.

        This may only be called by governance.
    @param _strategy The Strategy to update.
    @param _rateLimit The quantity of assets `_strategy` may now manage.
    """
    assert msg.sender == self.governance
    assert self.strategies[_strategy].activation > 0
    self.strategies[_strategy].rateLimit = _rateLimit


@external
def updateStrategyPerformanceFee(
    _strategy: address,
    _performanceFee: uint256,
):
    """
    @notice
        Change the fee the strategist will receive based on this Vault's
        performance.

        This may only be called by governance.
    @param _strategy The Strategy to update.
    @param _performanceFee The new fee the strategist will receive.
    """
    assert msg.sender == self.governance
    assert self.strategies[_strategy].activation > 0
    self.strategies[_strategy].performanceFee = _performanceFee


@external
def migrateStrategy(_oldVersion: address, _newVersion: address):
    """
    @notice
        Migrates a Strategy, including all assets from `_oldVersion` to
        `_newVersion`.

        This may only be called by governance.
    @dev
        Strategy must successfully migrate all capital and positions to new
        Strategy, or else this will upset the balance of the Vault.

        The new Strategy should be "empty" e.g. have no prior commitments to
        this Vault, otherwise it could have issues.
    @param _oldVersion The existing Strategy to migrate from.
    @param _newVersion The new Strategy to migrate to.
    """
    assert msg.sender == self.governance

    assert self.strategies[_oldVersion].activation > 0
    assert self.strategies[_newVersion].activation == 0

    strategy: StrategyParams = self.strategies[_oldVersion]
    self.strategies[_oldVersion] = empty(StrategyParams)
    self.strategies[_newVersion] = strategy

    Strategy(_oldVersion).migrate(_newVersion)
    # TODO: Ensure a smooth transition in terms of  Strategy return

    for idx in range(MAXIMUM_STRATEGIES):
        if self.withdrawalQueue[idx] == _oldVersion:
            self.withdrawalQueue[idx] = _newVersion
            return  # Don't need to reorder anything because we swapped


@external
def revokeStrategy(_strategy: address = msg.sender):
    """
    @notice
        Revoke a Strategy, setting its debt limit to 0 and preventing any
        future deposits.

        This function should only be used in the scenario where the Strategy is
        being retired but no migration of the positions are possible, or in the
        extreme scenario that the Strategy needs to be put into "Emergency Exit"
        mode in order for it to exit as quickly as possible. The latter scenario
        could be for any reason that is considered "critical" that the Strategy
        exits its position as fast as possible, such as a sudden change in market
        conditions leading to losses, or an imminent failure in an external
        dependency.

        This may only be called by governance, the guardian, or the Strategy
        itself. Note that a Strategy will only revoke itself during emergency
        shutdown.
    @param _strategy The Strategy to revoke.
    """
    assert msg.sender in [_strategy, self.governance, self.guardian]
    self.debtLimit -= self.strategies[_strategy].debtLimit
    self.strategies[_strategy].debtLimit = 0


@external
def addStrategyToQueue(_strategy: address):
    """
    @notice
        Adds `_strategy` to `withdrawalQueue`.

        This may only be called by governance.
    @dev
        The Strategy will be appended to `withdrawalQueue`, call
        `setWithdrawalQueue` to change the order.
    @param _strategy The Strategy to add.
    """
    assert msg.sender == self.governance
    # Must be a current Strategy
    assert self.strategies[_strategy].activation > 0 and self.strategies[_strategy].totalDebt > 0
    # Check if queue is full
    assert self.withdrawalQueue[MAXIMUM_STRATEGIES-1] == ZERO_ADDRESS
    # Can't already be in the queue
    for strategy in self.withdrawalQueue:
        if strategy == ZERO_ADDRESS:
            break
        assert strategy != _strategy
    self.withdrawalQueue[MAXIMUM_STRATEGIES-1] = _strategy
    self._organizeWithdrawalQueue()


@external
def removeStrategyFromQueue(_strategy: address):
    """
    @notice
        Remove `_strategy` from `withdrawalQueue`.

        This may only be called by governance.
    @dev
        We don't do this with revokeStrategy because it should still
        be possible to withdraw from the Strategy if it's unwinding.
    @param _strategy The Strategy to add.
    """
    assert msg.sender == self.governance
    for idx in range(MAXIMUM_STRATEGIES):
        if self.withdrawalQueue[idx] == _strategy:
            self.withdrawalQueue[idx] = ZERO_ADDRESS
            self._organizeWithdrawalQueue()
            return  # We found the right location and cleared it
    raise  # We didn't find the Strategy in the queue


@view
@internal
def _debtOutstanding(_strategy: address) -> uint256:
    # See note on `debtOutstanding()`.
    strategy_debtLimit: uint256 = self.strategies[_strategy].debtLimit
    strategy_totalDebt: uint256 = self.strategies[_strategy].totalDebt

    if self.emergencyShutdown:
        return strategy_totalDebt
    elif strategy_totalDebt <= strategy_debtLimit:
        return 0
    else:
        return strategy_totalDebt - strategy_debtLimit


@view
@external
def debtOutstanding(_strategy: address = msg.sender) -> uint256:
    """
    @notice
        Determines if `_strategy` is past its debt limit and if any tokens
        should be withdrawn to the Vault.
    @param _strategy The Strategy to check. Defaults to the caller.
    @return The quantity of tokens to withdraw.
    """
    return self._debtOutstanding(_strategy)


@view
@internal
def _creditAvailable(_strategy: address) -> uint256:
    # See note on `creditAvailable()`.
    if self.emergencyShutdown:
        return 0

    strategy_debtLimit: uint256 = self.strategies[_strategy].debtLimit
    strategy_totalDebt: uint256 = self.strategies[_strategy].totalDebt
    strategy_rateLimit: uint256 = self.strategies[_strategy].rateLimit
    strategy_lastReport: uint256 = self.strategies[_strategy].lastReport

    # Exhausted credit line
    if strategy_debtLimit <= strategy_totalDebt or self.debtLimit <= self.totalDebt:
        return 0

    # Start with debt limit left for the Strategy
    available: uint256 = strategy_debtLimit - strategy_totalDebt

    # Adjust by the global debt limit left
    available = min(available, self.debtLimit - self.totalDebt)

    # Adjust by the rate limit algorithm (limits the step size per reporting period)
    blockDelta: uint256 = block.number - strategy_lastReport
    # NOTE: Protect against unnecessary overflow faults here
    # NOTE: Set `strategy_rateLimit` to a really high number to disable the rate limit
    # NOTE: *NEVER* set `strategy_rateLimit` to 0 or else this will always throw
    if available / strategy_rateLimit >= blockDelta:
        available = min(available, strategy_rateLimit * blockDelta)

    # Can only borrow up to what the contract has in reserve
    # NOTE: Running near 100% is discouraged
    return min(available, self.token.balanceOf(self))


@view
@external
def creditAvailable(_strategy: address = msg.sender) -> uint256:
    """
    @notice
        Amount of tokens in Vault a Strategy has access to as a credit line.

        This will check the Strategy's debt limit, as well as the tokens
        available in the Vault, and determine the maximum amount of tokens
        (if any) the Strategy may draw on.

        In the rare case the Vault is in emergency shutdown this will return 0.
    @param _strategy The Strategy to check. Defaults to caller.
    @return The quantity of tokens available for the Strategy to draw on.
    """
    return self._creditAvailable(_strategy)


@view
@internal
def _expectedReturn(_strategy: address) -> uint256:
    # See note on `expectedReturn()`.
    strategy_lastReport: uint256 = self.strategies[_strategy].lastReport
    strategy_totalReturns: uint256 = self.strategies[_strategy].totalReturns
    strategy_activation: uint256 = self.strategies[_strategy].activation

    blockDelta: uint256 = (block.number - strategy_lastReport)
    if blockDelta > 0:
        return (strategy_totalReturns * blockDelta) / (block.number - strategy_activation)
    else:
        return 0  # Covers the scenario when block.number == strategy_activation


@view
@external
def expectedReturn(_strategy: address = msg.sender) -> uint256:
    """
    @notice
        Provide an accurate expected value for the return this `_strategy`
        would provide to the Vault the next time `report()` is called
        (since the last time it was called).
    @param _strategy The Strategy to determine the expected return for. Defaults to caller.
    @return
        The anticipated amount `_strategy` should make on its investment
        since its last report.
    """
    return self._expectedReturn(_strategy)


@external
def report(_return: uint256) -> uint256:
    """
    @notice
        Reports the amount of assets the calling Strategy has free (usually in
        terms of ROI).

        This may only be called by a Strategy managed by this Vault.
    @dev
        For approved strategies, this is the most efficient behavior.
        The Strategy reports back what it has free, then Vault "decides"
        whether to take some back or give it more. Note that the most it can
        take is `_return`, and the most it can give is all of the remaining
        reserves. Anything outside of those bounds is abnormal behavior.

        All approved strategies must have increased diligence around
        calling this function, as abnormal behavior could become catastrophic.
    @param _return
        Amount Strategy has made on it's investment since its last report,
        and is free to be given back to Vault as earnings
    @return Amount of debt outstanding (iff totalDebt > debtLimit).
    """

    # Only approved strategies can call this function
    assert self.strategies[msg.sender].activation > 0

    # Outstanding debt the Vault wants to take back from the Strategy (if any)
    debt: uint256 = self._debtOutstanding(msg.sender)

    # Issue new shares to cover fees
    # NOTE: In effect, this reduces overall share price by the combined fee
    governance_fee: uint256 = (
        self._totalAssets() * (block.number - self.lastReport) * self.managementFee
    ) / FEE_MAX / BLOCKS_PER_YEAR
    self.lastReport = block.number
    strategist_fee: uint256 = 0  # Only applies in certain conditions

    # NOTE: Applies if Strategy is not shutting down, or it is but all debt paid off
    # NOTE: No fee is taken when a Strategy is unwinding it's position, until all debt is paid
    if  _return > debt:
        strategist_fee = (
            (_return - debt) * self.strategies[msg.sender].performanceFee
        ) / FEE_MAX
        governance_fee += (_return - debt) * self.performanceFee / FEE_MAX

    # NOTE: This must be called prior to taking new collateral,
    #       or the calculation will be wrong!
    # NOTE: This must be done at the same time, to ensure the relative
    #       ratio of governance_fee : strategist_fee is kept intact
    total_fee: uint256 = governance_fee + strategist_fee
    reward: uint256 = self._issueSharesForAmount(self, total_fee)

    # Send the rewards out as new shares in this Vault
    if strategist_fee > 0:
        strategist_reward: uint256 = (strategist_fee * reward) / total_fee
        self._transfer(self, msg.sender, strategist_reward)
        Strategy(msg.sender).distributeRewards(strategist_reward)
    # NOTE: Governance earns any dust leftover from flooring math above
    self._transfer(self, self.rewards, self.balanceOf[self])

    # Compute the line of credit the Vault is able to offer the Strategy (if any)
    credit: uint256 = self._creditAvailable(msg.sender)

    # Give/take balance to Strategy, based on the difference between the return and
    # the credit increase we are offering (if any)
    # NOTE: This is just used to adjust the balance of tokens between the Strategy and
    #       the Vault based on the Strategy's debt limit (as well as the Vault's).
    if _return < credit:  # credit surplus, give to Strategy
        self.token.transfer(msg.sender, credit - _return)
    elif _return > credit:  # credit deficit, take from Strategy
        self.token.transferFrom(msg.sender, self, _return - credit)

    # else, don't do anything because it is performing well as is

    # Update the actual debt based on the full credit we are extending to the Strategy
    # or the returns if we are taking funds back
    # NOTE: credit + self.strategies[msg.sender].totalDebt is always < self.debtLimit
    # NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
    if credit > 0:
        self.strategies[msg.sender].totalDebt += credit
        self.totalDebt += credit

        # Returns are always "realized gains"
        self.strategies[msg.sender].totalReturns += _return

    elif debt > 0:  # We're repaying debt now, so there are no gains
        if _return <= debt:
            # Pay down our debt with profit
            # NOTE: Cannot return more than you borrowed
            self.strategies[msg.sender].totalDebt -= _return
            self.totalDebt -= _return
            debt -= _return  # Debt payment complete (to report back to Strategy)

        else:
            # Finish off our debt payments here
            self.totalDebt -= debt
            self.strategies[msg.sender].totalDebt -= debt

            # Returns are always "realized gains" (after we have paid off our debt)
            self.strategies[msg.sender].totalReturns += _return - debt
            debt = 0  # All debts paid off (to report back to Strategy)

    elif _return > 0:  # No debt to pay, nor credit to expand with, add to profit!
        self.strategies[msg.sender].totalReturns += _return

    # else, no credit/debt to manage, nor returns to report. Nothing really happened!

    # Update reporting time
    self.strategies[msg.sender].lastReport = block.number

    log StrategyReported(
        msg.sender,
        _return,
        credit,
        self.strategies[msg.sender].totalReturns,
        self.strategies[msg.sender].totalDebt,
        self.strategies[msg.sender].debtLimit,
    )

    if self.strategies[msg.sender].totalDebt == 0 or self.emergencyShutdown:
        # Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
        # NOTE: This is different than `debt` in order to extract *all* of the returns
        return self._balanceSheetOfStrategy(msg.sender)
    else:
        # Otherwise, just return what we have as debt outstanding
        return debt


@internal
def erc20_safe_transfer(_token: address, _to: address, _value: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed!"


@external
def sweep(_token: address):
    """
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used in case of accidentally sending the
        wrong kind of token to this Vault.

        Tokens will be sent to `governance`.

        This will fail if an attempt is made to sweep the tokens that this
        Vault manages.

        This may only be called by governance.
    @param _token The token to transfer out of this vault.
    """
    assert msg.sender == self.governance
    # Can't be used to steal what this Vault is protecting
    assert _token != self.token.address
    self.erc20_safe_transfer(_token, self.governance, ERC20(_token).balanceOf(self))