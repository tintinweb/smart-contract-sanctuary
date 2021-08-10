# @version 0.2.12

"""
@title Unagii EthFundManager 0.1.1
@author stakewith.us
@license AGPL-3.0-or-later
"""

from vyper.interfaces import ERC20


interface Vault:
    def token() -> address: view
    def debt() -> uint256: view
    def borrow(amount: uint256) -> uint256: nonpayable
    def repay(amount: uint256) -> uint256: payable
    def report(gain: uint256, loss: uint256): payable


interface IStrategy:
    def fundManager() -> address: view
    def token() -> address: view
    def withdraw(amount: uint256) -> uint256: nonpayable
    def migrate(newVersion: address): nonpayable


# interface to new version of FundManager used for migration
interface FundManager:
    def token() -> address: view
    def vault() -> address: view
    def totalDebt() -> uint256: view
    def totalDebtRatio() -> uint256: view
    def queue(i: uint256) -> address: view
    def strategies(
        addr: address,
    ) -> (bool, bool, bool, uint256, uint256, uint256, uint256): view
    def initialize(): payable


# maximum number of active strategies
MAX_QUEUE: constant(uint256) = 20


struct Strategy:
    approved: bool
    active: bool
    activated: bool  # sent to True once after strategy is active
    debtRatio: uint256  # ratio of total assets this strategy can borrow
    debt: uint256  # current amount borrowed
    minBorrow: uint256  # minimum amount to borrow per call to borrow()
    maxBorrow: uint256  # maximum amount to borrow per call to borrow()


event SetNextTimeLock:
    nextTimeLock: address


event AcceptTimeLock:
    timeLock: address


event SetAdmin:
    admin: address


event SetGuardian:
    guardian: address


event SetWorker:
    worker: address


event SetPause:
    paused: bool


event SetVault:
    vault: address


event ApproveStrategy:
    strategy: indexed(address)


event RevokeStrategy:
    strategy: indexed(address)


event AddStrategyToQueue:
    strategy: indexed(address)


event RemoveStrategyFromQueue:
    strategy: indexed(address)


event SetQueue:
    queue: address[MAX_QUEUE]


event SetDebtRatios:
    debtRatios: uint256[MAX_QUEUE]


event SetMinMaxBorrow:
    strategy: indexed(address)
    minBorrow: uint256
    maxBorrow: uint256


event ReceiveEth:
    sender: indexed(address)
    amount: uint256


event BorrowFromVault:
    vault: indexed(address)
    amount: uint256
    borrowed: uint256


event RepayVault:
    vault: indexed(address)
    amount: uint256
    repaid: uint256


event ReportToVault:
    vault: indexed(address)
    total: uint256
    debt: uint256
    gain: uint256
    loss: uint256


event Withdraw:
    vault: indexed(address)
    amount: uint256
    actual: uint256
    loss: uint256


event WithdrawStrategy:
    strategy: indexed(address)
    debt: uint256
    need: uint256
    loss: uint256
    diff: uint256


event Borrow:
    strategy: indexed(address)
    amount: uint256
    borrowed: uint256


event Repay:
    strategy: indexed(address)
    amount: uint256
    repaid: uint256


event Report:
    strategy: indexed(address)
    gain: uint256
    loss: uint256
    debt: uint256


event MigrateStrategy:
    oldStrategy: indexed(address)
    newStrategy: indexed(address)


event Migrate:
    fundManager: address
    bal: uint256
    totalDebt: uint256


paused: public(bool)
initialized: public(bool)

vault: public(Vault)
ETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
# privileges - time lock >= admin >= guardian, worker
timeLock: public(address)
nextTimeLock: public(address)
admin: public(address)
guardian: public(address)
worker: public(address)

totalDebt: public(uint256)  # sum of all debts of strategies
MAX_TOTAL_DEBT_RATIO: constant(uint256) = 10000
totalDebtRatio: public(uint256)  # sum of all debtRatios of strategies
strategies: public(HashMap[address, Strategy])  # all strategies
queue: public(address[MAX_QUEUE])  # list of active strategies

# migration
OLD_MAX_QUEUE: constant(uint256) = 20  # must be <= MAX_QUEUE
oldFundManager: public(FundManager)


@external
def __init__(guardian: address, worker: address, oldFundManager: address):
    self.timeLock = msg.sender
    self.admin = msg.sender
    self.guardian = guardian
    self.worker = worker

    if oldFundManager != ZERO_ADDRESS:
        self.oldFundManager = FundManager(oldFundManager)
        assert self.oldFundManager.token() == ETH, "old fund manager token != ETH"


@external
@payable
def __default__():
    log ReceiveEth(msg.sender, msg.value)


@external
@view
def token() -> address:
    return ETH


@internal
def _sendEth(to: address, amount: uint256):
    assert to != ZERO_ADDRESS, "to = 0 address"
    raw_call(to, b"", value=amount)


@internal
def _safeTransfer(token: address, receiver: address, amount: uint256):
    res: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(res) > 0:
        assert convert(res, bool), "transfer failed"


@external
@payable
def initialize():
    """
    @notice Initialize fund manager. Transfer ETH and copy states if
            old fund manager is set.
    """
    assert not self.initialized, "initialized"

    if self.oldFundManager.address == ZERO_ADDRESS:
        assert msg.sender in [self.timeLock, self.admin], "!auth"
    else:
        assert msg.sender == self.oldFundManager.address, "!old fund manager"

        assert (
            self.vault.address == self.oldFundManager.vault()
        ), "old fund manager vault != vault"

        self.totalDebt = self.oldFundManager.totalDebt()
        self.totalDebtRatio = self.oldFundManager.totalDebtRatio()

        for i in range(OLD_MAX_QUEUE):
            addr: address = self.oldFundManager.queue(i)
            if addr == ZERO_ADDRESS:
                break

            assert (
                IStrategy(addr).fundManager() == self
            ), "strategy fund manager != self"

            approved: bool = False
            active: bool = False
            activated: bool = False
            debtRatio: uint256 = 0
            debt: uint256 = 0
            minBorrow: uint256 = 0
            maxBorrow: uint256 = 0
            (
                approved,
                active,
                activated,
                debtRatio,
                debt,
                minBorrow,
                maxBorrow,
            ) = self.oldFundManager.strategies(addr)
            assert approved, "!approved"
            assert active, "!active"
            assert activated, "!activated"

            self.queue[i] = addr
            self.strategies[addr] = Strategy(
                {
                    approved: True,
                    active: True,
                    activated: True,
                    debtRatio: debtRatio,
                    debt: debt,
                    minBorrow: minBorrow,
                    maxBorrow: maxBorrow,
                }
            )

    self.initialized = True


# Migration steps to new fund manager
#
# v = vault
# f1 = fund manager 1
# f2 = fund manager 2
# strats = active strategies of f1
#
# action                         | caller
# ----------------------------------------
# 1. f2.setVault(v)              | time lock
# 2. f1.setPause(true)           | admin
# 3. for s in strats             |
#      s.setFundManager(f2)      | time lock
# 4. send ETH to f2              | f1
# 5. f2 copy states from f1      | f2
#    - totalDebt                 |
#    - totalDebtRatio            |
#    - queue                     |
#    - active strategy params    |
# 6. f1 reset state              | f1
#    - totalDebt                 |
#    - active strategy debt      |
# 7. v.setFundManager(f2)        | time lock


@external
def migrate(fundManager: address):
    """
    @notice Migrate to new fund manager
    @param fundManager Address of new fund manager
    """
    assert msg.sender == self.timeLock, "!time lock"
    assert self.initialized, "!initialized"
    assert self.paused, "!paused"

    assert FundManager(fundManager).token() == ETH, "new fund manager token != ETH"
    assert (
        FundManager(fundManager).vault() == self.vault.address
    ), "new fund manager vault != vault"

    for strat in self.queue:
        if strat == ZERO_ADDRESS:
            break
        assert (
            IStrategy(strat).fundManager() == fundManager
        ), "strategy fund manager != new fund manager"

    bal: uint256 = self.balance
    FundManager(fundManager).initialize(value=bal)

    log Migrate(fundManager, bal, self.totalDebt)

    self.totalDebt = 0

    for strat in self.queue:
        if strat == ZERO_ADDRESS:
            break
        self.strategies[strat].debt = 0


@external
def setNextTimeLock(nextTimeLock: address):
    """
    @notice Set next time lock
    @param nextTimeLock Address of next time lock
    """
    assert msg.sender == self.timeLock, "!time lock"
    self.nextTimeLock = nextTimeLock
    log SetNextTimeLock(nextTimeLock)


@external
def acceptTimeLock():
    """
    @notice Accept time lock
    @dev Only `nextTimeLock` can claim time lock
    """
    assert msg.sender == self.nextTimeLock, "!next time lock"
    self.timeLock = msg.sender
    self.nextTimeLock = ZERO_ADDRESS
    log AcceptTimeLock(msg.sender)


@external
def setAdmin(admin: address):
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    self.admin = admin
    log SetAdmin(admin)


@external
def setGuardian(guardian: address):
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    self.guardian = guardian
    log SetGuardian(guardian)


@external
def setWorker(worker: address):
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    self.worker = worker
    log SetWorker(worker)


@external
def setPause(paused: bool):
    assert msg.sender in [self.timeLock, self.admin, self.guardian], "!auth"
    self.paused = paused
    log SetPause(paused)


@external
def setVault(vault: address):
    """
    @notice Set vault
    @param vault Address of vault
    """
    assert msg.sender == self.timeLock, "!time lock"
    assert Vault(vault).token() == ETH, "vault token != ETH"

    self.vault = Vault(vault)

    log SetVault(vault)


@internal
@view
def _totalAssets() -> uint256:
    """
    @notice Total amount of ETH in this fund manager + total amount borrowed
            by strategies
    @dev Returns total amount of ETH managed by this contract
    """
    return self.balance + self.totalDebt


@external
@view
def totalAssets() -> uint256:
    return self._totalAssets()


# array functions tested in test/Array.vy
@internal
def _pack():
    arr: address[MAX_QUEUE] = empty(address[MAX_QUEUE])
    i: uint256 = 0
    for strat in self.queue:
        if strat != ZERO_ADDRESS:
            arr[i] = strat
            i += 1
    self.queue = arr


@internal
def _append(strategy: address):
    assert self.queue[MAX_QUEUE - 1] == ZERO_ADDRESS, "queue > max"
    self.queue[MAX_QUEUE - 1] = strategy
    self._pack()


@internal
def _remove(i: uint256):
    assert i < MAX_QUEUE, "i >= max"
    assert self.queue[i] != ZERO_ADDRESS, "!zero address"
    self.queue[i] = ZERO_ADDRESS
    self._pack()


@internal
@view
def _find(strategy: address) -> uint256:
    for i in range(MAX_QUEUE):
        if self.queue[i] == strategy:
            return i
    raise "not found"


@external
def approveStrategy(strategy: address):
    """
    @notice Approve strategy
    @param strategy Address of strategy
    """
    assert msg.sender == self.timeLock, "!time lock"

    assert not self.strategies[strategy].approved, "approved"
    assert IStrategy(strategy).fundManager() == self, "strategy fund manager != this"
    assert IStrategy(strategy).token() == ETH, "strategy token != ETH"

    self.strategies[strategy] = Strategy(
        {
            approved: True,
            active: False,
            activated: False,
            debtRatio: 0,
            debt: 0,
            minBorrow: 0,
            maxBorrow: 0,
        }
    )

    log ApproveStrategy(strategy)


@external
def revokeStrategy(strategy: address):
    """
    @notice Disapprove strategy
    @param strategy Address of strategy
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    assert self.strategies[strategy].approved, "!approved"
    assert not self.strategies[strategy].active, "active"

    self.strategies[strategy].approved = False
    log RevokeStrategy(strategy)


@external
def addStrategyToQueue(
    strategy: address, debtRatio: uint256, minBorrow: uint256, maxBorrow: uint256
):
    """
    @notice Activate strategy
    @param strategy Address of strategy
    @param debtRatio Ratio of total assets this strategy can borrow
    @param minBorrow Minimum amount to borrow per call to borrow()
    @param maxBorrow Maximum amount to borrow per call to borrow()
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    assert self.strategies[strategy].approved, "!approved"
    assert not self.strategies[strategy].active, "active"
    assert self.totalDebtRatio + debtRatio <= MAX_TOTAL_DEBT_RATIO, "ratio > max"
    assert minBorrow <= maxBorrow, "min borrow > max borrow"

    self._append(strategy)
    self.strategies[strategy].active = True
    self.strategies[strategy].activated = True
    self.strategies[strategy].debtRatio = debtRatio
    self.strategies[strategy].minBorrow = minBorrow
    self.strategies[strategy].maxBorrow = maxBorrow
    self.totalDebtRatio += debtRatio

    log AddStrategyToQueue(strategy)


@external
def removeStrategyFromQueue(strategy: address):
    """
    @notice Deactivate strategy
    @param strategy Addres of strategy
    """
    assert msg.sender in [self.timeLock, self.admin, self.guardian], "!auth"
    assert self.strategies[strategy].active, "!active"

    self._remove(self._find(strategy))
    self.strategies[strategy].active = False
    self.totalDebtRatio -= self.strategies[strategy].debtRatio
    self.strategies[strategy].debtRatio = 0

    log RemoveStrategyFromQueue(strategy)


@external
def setQueue(queue: address[MAX_QUEUE]):
    """
    @notice Reorder queue
    @param queue Array of active strategies
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"

    # check no gaps in new queue
    zero: bool = False
    for i in range(MAX_QUEUE):
        strat: address = queue[i]
        if strat == ZERO_ADDRESS:
            if not zero:
                zero = True
        else:
            assert not zero, "gap"

    # Check old and new queue counts of non zero strategies are equal
    for i in range(MAX_QUEUE):
        oldStrat: address = self.queue[i]
        newStrat: address = queue[i]
        if oldStrat == ZERO_ADDRESS:
            assert newStrat == ZERO_ADDRESS, "new != 0"
        else:
            assert newStrat != ZERO_ADDRESS, "new = 0"

    # Check new strategy is active and no duplicate
    for i in range(MAX_QUEUE):
        strat: address = queue[i]
        if strat == ZERO_ADDRESS:
            break
        # code below will fail if duplicate strategy in new queue
        assert self.strategies[strat].active, "!active"
        self.strategies[strat].active = False

    # update queue
    for i in range(MAX_QUEUE):
        strat: address = queue[i]
        if strat == ZERO_ADDRESS:
            break
        self.strategies[strat].active = True
        self.queue[i] = strat

    log SetQueue(queue)


@external
def setDebtRatios(debtRatios: uint256[MAX_QUEUE]):
    """
    @notice Update debt ratios of active strategies
    @param debtRatios Array of debt ratios
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"

    # check that we're only setting debt ratio on active strategy
    for i in range(MAX_QUEUE):
        if self.queue[i] == ZERO_ADDRESS:
            assert debtRatios[i] == 0, "debt ratio != 0"

    # use memory to save gas
    totalDebtRatio: uint256 = 0
    for i in range(MAX_QUEUE):
        addr: address = self.queue[i]
        if addr == ZERO_ADDRESS:
            break

        debtRatio: uint256 = debtRatios[i]
        self.strategies[addr].debtRatio = debtRatio
        totalDebtRatio += debtRatio

    self.totalDebtRatio = totalDebtRatio

    assert self.totalDebtRatio <= MAX_TOTAL_DEBT_RATIO, "total > max"

    log SetDebtRatios(debtRatios)


@external
def setMinMaxBorrow(strategy: address, minBorrow: uint256, maxBorrow: uint256):
    """
    @notice Update `minBorrow` and `maxBorrow` of approved strategy
    @param minBorrow Minimum amount to borrow per call to borrow()
    @param maxBorrow Maximum amount to borrow per call to borrow()
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    assert self.strategies[strategy].approved, "!approved"
    assert minBorrow <= maxBorrow, "min borrow > max borrow"

    self.strategies[strategy].minBorrow = minBorrow
    self.strategies[strategy].maxBorrow = maxBorrow

    log SetMinMaxBorrow(strategy, minBorrow, maxBorrow)


# functions between Vault and this contract #
@external
def borrowFromVault(amount: uint256, _min: uint256):
    """
    @notice Borrow ETH from vault
    @param amount Amount of ETH to borrow
    @param _min Minimum amount to borrow
    """
    assert self.initialized, "!initialized"
    assert msg.sender in [self.timeLock, self.admin, self.worker], "!auth"
    # fails if vault not set
    borrowed: uint256 = self.vault.borrow(amount)
    assert borrowed >= _min, "borrowed < min"

    log BorrowFromVault(self.vault.address, amount, borrowed)


@external
def repayVault(amount: uint256, _min: uint256):
    """
    @notice Repay ETH to vault
    @param amount Amount to repay
    @param _min Minimum amount to repay
    """
    assert self.initialized, "!initialized"
    assert msg.sender in [self.timeLock, self.admin, self.worker], "!auth"
    # fails if vault not set
    repaid: uint256 = self.vault.repay(amount, value=amount)
    assert repaid >= _min, "repaid < min"

    log RepayVault(self.vault.address, amount, repaid)


@external
def reportToVault(_minTotal: uint256, _maxTotal: uint256):
    """
    @notice Report gain and loss to vault
    @param _minTotal Minumum of total assets
    @param _maxTotal Maximum of total assets
    @dev `_minTotal` and `_maxTotal` is used to check that totalAssets is
         within a reasonable range before this function is called
    """
    assert self.initialized, "!initialized"
    assert msg.sender in [self.timeLock, self.admin, self.worker], "!auth"

    total: uint256 = self._totalAssets()
    assert total >= _minTotal and total <= _maxTotal, "total not in range"

    debt: uint256 = self.vault.debt()
    gain: uint256 = 0
    loss: uint256 = 0

    if total > debt:
        gain = min(total - debt, self.balance)
    else:
        loss = debt - total

    if gain > 0 or loss > 0:
        self.vault.report(gain, loss, value=gain)

    log ReportToVault(self.vault.address, total, debt, gain, loss)


# functions between vault -> this contract -> strategies #
@internal
def _withdraw(amount: uint256) -> uint256:
    """
    @notice Withdraw ETH from active strategies
    @param amount Amount of ETH to withdraw
    @dev Returns sum of losses from active strategies that were withdrawn.
    """
    _amount: uint256 = amount
    totalLoss: uint256 = 0
    for strategy in self.queue:
        if strategy == ZERO_ADDRESS:
            break

        bal: uint256 = self.balance
        if bal >= _amount:
            break

        debt: uint256 = self.strategies[strategy].debt
        need: uint256 = min(_amount - bal, debt)
        if need == 0:
            continue

        # loss must be <= debt
        loss: uint256 = IStrategy(strategy).withdraw(need)
        diff: uint256 = self.balance - bal

        if loss > 0:
            _amount -= loss
            totalLoss += loss
            self.strategies[strategy].debt -= loss
            self.totalDebt -= loss

        self.strategies[strategy].debt -= diff
        self.totalDebt -= diff

        log WithdrawStrategy(strategy, debt, need, loss, diff)

    return totalLoss


@external
def withdraw(amount: uint256) -> uint256:
    """
    @notice Withdraw ETH from fund manager back to vault
    @param amount Amount of ETH to withdraw
    @dev Returns sum of losses from active strategies that were withdrawn.
    """
    assert self.initialized, "!initialized"
    assert msg.sender == self.vault.address, "!vault"

    total: uint256 = self._totalAssets()
    _amount: uint256 = min(amount, total)
    assert _amount > 0, "withdraw = 0"

    debt: uint256 = self.vault.debt()
    loss: uint256 = 0
    if debt > total:
        # debt > total can occur when strategies reported losses to this contract
        # but this contract has not reported losses back to vault
        loss = debt - total

    bal: uint256 = self.balance
    if _amount > bal:
        # try to withdraw until balance of fund manager >= _amount
        loss += self._withdraw(_amount)
        _amount = min(_amount, self.balance)

    if _amount > 0:
        self._sendEth(msg.sender, _amount)

    log Withdraw(msg.sender, amount, _amount, loss)

    return loss


# functions between this contract and strategies #
@internal
@view
def _calcMaxBorrow(strategy: address) -> uint256:
    """
    @notice Calculate how much ETH strategy can borrow
    @param strategy Address of strategy
    @dev Returns amount of ETH that `strategy` can borrow
    """
    if (not self.initialized) or self.paused or self.totalDebtRatio == 0:
        return 0

    # strategy debtRatio > 0 only if strategy is active
    limit: uint256 = (
        self.strategies[strategy].debtRatio * self._totalAssets() / self.totalDebtRatio
    )
    debt: uint256 = self.strategies[strategy].debt

    if debt >= limit:
        return 0

    available: uint256 = min(limit - debt, self.balance)

    if available < self.strategies[strategy].minBorrow:
        return 0
    else:
        return min(available, self.strategies[strategy].maxBorrow)


@external
@view
def calcMaxBorrow(strategy: address) -> uint256:
    return self._calcMaxBorrow(strategy)


@internal
@view
def _calcOutstandingDebt(strategy: address) -> uint256:
    """
    @notice Calculate amount of ETH that `strategy` should pay back to fund manager
    @param strategy Address of strategy
    @dev Returns minimum amount of ETH strategy should repay
    """
    if not self.initialized:
        return 0

    if self.totalDebtRatio == 0:
        return self.strategies[strategy].debt

    limit: uint256 = (
        self.strategies[strategy].debtRatio * self.totalDebt / self.totalDebtRatio
    )
    debt: uint256 = self.strategies[strategy].debt

    if self.paused:
        return debt
    elif debt <= limit:
        return 0
    else:
        return debt - limit


@external
@view
def calcOutstandingDebt(strategy: address) -> uint256:
    return self._calcOutstandingDebt(strategy)


@external
@view
def getDebt(strategy: address) -> uint256:
    """
    @notice Return debt of strategy
    @param strategy Address of strategy
    @dev Returns current debt of strategy
    """
    return self.strategies[strategy].debt


@external
@nonreentrant("lock")
def borrow(amount: uint256) -> uint256:
    """
    @notice Borrow ETH from fund manager
    @param amount Amount of ETH to borrow
    @dev Returns actual amount sent
    @dev Only active strategy can borrow
    """
    assert self.initialized, "!initialized"
    assert not self.paused, "paused"
    assert self.strategies[msg.sender].active, "!active"

    _amount: uint256 = min(amount, self._calcMaxBorrow(msg.sender))
    assert _amount > 0, "borrow = 0"

    self._sendEth(msg.sender, _amount)

    # include any fee on transfer to debt
    self.strategies[msg.sender].debt += _amount
    self.totalDebt += _amount

    log Borrow(msg.sender, amount, _amount)

    return _amount


@external
@payable
def repay(amount: uint256) -> uint256:
    """
    @notice Repay debt to fund manager
    @param amount Amount of ETH to repay
    @dev Returns actual amount repaid
    @dev Only approved strategy can repay
    """
    assert self.initialized, "!initialized"
    assert self.strategies[msg.sender].approved, "!approved"

    assert amount == msg.value, "amount != msg.value"
    assert amount > 0, "repay = 0"

    self.strategies[msg.sender].debt -= amount
    self.totalDebt -= amount

    log Repay(msg.sender, amount, amount)

    return amount


@external
@payable
def report(gain: uint256, loss: uint256):
    """
    @notice Report gain and loss from strategy
    @param gain Amount of profit
    @param loss Amount of loss
    """
    assert self.initialized, "!initialized"
    assert self.strategies[msg.sender].active, "!active"
    # can't have both gain and loss > 0
    assert (gain >= 0 and loss == 0) or (gain == 0 and loss >= 0), "gain and loss > 0"
    assert gain == msg.value, "gain != msg.value"

    if gain > 0:
        pass
    elif loss > 0:
        self.strategies[msg.sender].debt -= loss
        self.totalDebt -= loss

    log Report(msg.sender, gain, loss, self.strategies[msg.sender].debt)


@external
def migrateStrategy(oldStrat: address, newStrat: address):
    """
    @notice Migrate strategy
    @param oldStrat Address of current strategy
    @param newStrat Address of strategy to migrate to
    """
    assert self.initialized, "!initialized"
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    assert self.strategies[oldStrat].active, "old !active"
    assert self.strategies[newStrat].approved, "new !approved"
    assert not self.strategies[newStrat].activated, "activated"

    strat: Strategy = self.strategies[oldStrat]

    self.strategies[newStrat] = Strategy(
        {
            approved: True,
            active: True,
            activated: True,
            debtRatio: strat.debtRatio,
            debt: strat.debt,
            minBorrow: strat.minBorrow,
            maxBorrow: strat.maxBorrow,
        }
    )

    self.strategies[oldStrat].active = False
    self.strategies[oldStrat].debtRatio = 0
    self.strategies[oldStrat].debt = 0
    self.strategies[oldStrat].minBorrow = 0
    self.strategies[oldStrat].maxBorrow = 0

    # find and replace strategy
    i: uint256 = self._find(oldStrat)
    self.queue[i] = newStrat

    IStrategy(oldStrat).migrate(newStrat)
    log MigrateStrategy(oldStrat, newStrat)


@external
def sweep(token: address):
    """
    @notice Transfer any token accidentally sent to this contract to admin or
            time lock
    """
    assert msg.sender in [self.timeLock, self.admin], "!auth"
    self._safeTransfer(token, msg.sender, ERC20(token).balanceOf(self))