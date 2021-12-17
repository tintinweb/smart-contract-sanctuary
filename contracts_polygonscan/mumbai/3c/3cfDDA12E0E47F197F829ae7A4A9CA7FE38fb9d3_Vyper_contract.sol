# @version ^0.3.0

from vyper.interfaces import ERC20


implements: ERC20


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Bugger:
    value: uint256
    message: String[32]

user_interest: public(HashMap[address, uint256])
    


name: public(String[64])
symbol: public(String[32])
decimals: public(int128)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: address
_buyrate: uint256 
_sellrate: uint256
accumulatedRewardPerShare: uint256
lastRewardCalcTimeStamp: uint256
totalContractBalance: uint256
lastAtokenBalance: uint256


lendingpool: address

aave_referal: uint256

USDC_contract: constant(address) = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e # 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
AMUSDC_contract: constant(address) = 0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9 # 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F


interface aave:
    def getLendingPool() -> address: nonpayable

@external
def __init__():
    init_supply: uint256 = 1000000000 * 10 ** 8
    self.name = "fAED Stablecoin"
    self.symbol = "fAED"
    self.decimals = 8
    self.balanceOf[self] = init_supply
    self.totalSupply = init_supply
    self.minter = self
    self._buyrate = 367
    self._sellrate = 367

    self.aave_referal = 0
    self.lendingpool = aave(0x178113104fEcbcD7fF8669a0150721e231F0FD4B).getLendingPool()
    _response: Bytes[32] = raw_call(USDC_contract,concat(method_id("approve(address,uint256)"),convert(self.lendingpool, bytes32),convert(MAX_UINT256, bytes32)),max_outsize=32)
    
    if len(_response) != 0:
            assert convert(_response, bool)
    log Transfer(ZERO_ADDRESS, self, init_supply)


@internal
def get_contract_atoken_balance() -> uint256:
    return ERC20(AMUSDC_contract).balanceOf(self)

@external
def get_public_contract_atoken_balance() -> uint256:
    return ERC20(AMUSDC_contract).balanceOf(self)


@internal
def saveAtokenBalance():
    self.lastAtokenBalance = ERC20(AMUSDC_contract).balanceOf(self)


@internal
def updateInterest():
    if block.timestamp <= self.lastRewardCalcTimeStamp:
        return
    current_atoken_balance: uint256 = self.get_contract_atoken_balance()
    log Bugger(current_atoken_balance, 'balance current')
    log Bugger(self.lastAtokenBalance, 'balance last')
    if current_atoken_balance == 0:
        return
    interest_difference: uint256 = (current_atoken_balance - self.lastAtokenBalance)
    
    log Bugger((current_atoken_balance - self.lastAtokenBalance) * 10**12, 'balance difference scaled')
    self.accumulatedRewardPerShare = self.accumulatedRewardPerShare + ((interest_difference * 10**12)/self.totalContractBalance)  
    log Bugger(self.accumulatedRewardPerShare, 'rewardPerShare')
    log Bugger(interest_difference, 'rewardPerSeconds') 
    self.lastRewardCalcTimeStamp = block.timestamp

@external
def setbuyrate(_amount: uint256):
    assert msg.sender == self.minter, "only owner"
    self._buyrate = _amount

@external
def setsellrate(_amount: uint256):
    assert msg.sender == self.minter, "only owner"
    self._sellrate = _amount

@external
@view
def getbuyrate() -> uint256:
    return self._buyrate

@external
@view
def getsellrate() -> uint256:
    return self._sellrate


@internal 
def _transfer(_from: address, _to: address, _value: uint256) ->bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)
    return True
    
@external
def transfer(_to : address, _value : uint256) -> bool:
    self._transfer(msg.sender,_to,_value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@external
def mint(_to: address, _value: uint256):
    self._mint(_to, _value)

@internal
def _burn(_to: address, _value: uint256):
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    assert msg.sender == self.minter
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    assert msg.sender == self.minter
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)


@external
@view
def getPool()->address:
   return self.lendingpool




@external
def fxbuy(withdraw: uint256) -> bool:
    self.updateInterest()
    amount:uint256 = withdraw * 10**6 
    ERC20(USDC_contract).transferFrom(msg.sender,self,amount)
    
    amount2: uint256 = (amount*self._sellrate) * 10**2
    self._mint(msg.sender,amount2)
    
    raw_call(
                    self.lendingpool,
                    concat(
                        method_id("deposit(address,uint256,address,uint16)"),
                        convert(USDC_contract, bytes32),
                        convert(amount, bytes32),
                        convert(self, bytes32),
                        convert(self.aave_referal,bytes32),
                    )
                )
    self.totalContractBalance += amount2
    log Bugger(self.accumulatedRewardPerShare, 'rewardPerShare')
    self.saveAtokenBalance()
    return True


@external
def fxsell(withdraw: uint256) -> bool:
    self.updateInterest()
    assert ERC20(self).balanceOf(msg.sender) >= withdraw, "not enough balance"

    self._burn(msg.sender,withdraw)

    usd_amount: uint256 = (withdraw / self._buyrate) / 10**2
    interest_on_amount: uint256 = (self.accumulatedRewardPerShare * usd_amount)
    log Bugger((interest_on_amount / 10**12) * 10**6, 'interest on withdrawal')
    usd_amount_plus_interest: uint256 = usd_amount + ((interest_on_amount / 10**12) * 10**6 )
    log Bugger(usd_amount_plus_interest, 'interest + withdrawal')
    
    raw_call(
                    self.lendingpool,
                    concat(
                        method_id("withdraw(address,uint256,address)"),
                        convert(USDC_contract, bytes32),
                        convert(usd_amount_plus_interest, bytes32),
                        convert(self, bytes32),
                    )
                )

    ERC20(USDC_contract).transfer(msg.sender, usd_amount_plus_interest)
    self.totalContractBalance -= withdraw
    self.saveAtokenBalance()
    return True


@external
def getbalance(_coin: address) -> bool:
    assert msg.sender == self.minter, "only owner"
    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(msg.sender, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True