# MetaWhale BTC by DEFILABS
#
# Find out more about MetaWhale @ metawhale.io
#
# A TOKEN TESTED BY DEFI LABS @ HTTPS://DEFILABS.ETH.LINK
# CREATOR: Dr. Mantis => @dr_mantis_defilabs
#
# Official Announcement Channel @ https://t.me/metawhale_official
# But better join the fantastic community @ https://t.me/defilabs_community

from vyper.interfaces import ERC20

implements: ERC20

interface IReserves:
    def swapInactiveToWETH(amountIn: uint256, inactive: address) -> bool: nonpayable
    def swapTokensForWETH(amountIn: uint256) -> bool: nonpayable
    def addLiquidity(reserveBal: uint256) -> bool: nonpayable
    def swapForSecondaryAndBurn() -> bool: nonpayable
    def swapForTerciary() -> bool: nonpayable
    def checkTerciarySize() -> bool: nonpayable
    def close() -> bool: nonpayable
    def baseAssetLP() -> address: view
    def reserveAsset() -> address: view
    def KingAsset() -> address: view
    def AirdropAddress() -> address: view
    def NFTFaucet() -> address: view
    def MarketingFaucet() -> address: view
    def devFaucet() -> address: view

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
min_supply: public(uint256)
final_supply: public(uint256)
final_reserve: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
last5pctmove: public(HashMap[address, uint256])
lastIndividualTrade: public(HashMap[address, uint256])
lastTrade: public(uint256)
passlist: public(HashMap[address, bool])
dexReserve: public(address)
total_supply: uint256
deployer: public(address)
reserve: public(address)
inactive_sell: public(uint256)
dividends: uint256
dividend_split: uint256
nft_total_dividend: public(HashMap[uint256, uint256])
dev_total_dividend: public(HashMap[uint256, uint256])
marketing_total_dividend: public(HashMap[uint256, uint256])
reserveManager: public(address[50])
reservecounter: public(uint256)
onepct: public(uint256)
burn_pct: public(uint256)
reserve_pct: public(uint256)
reserve_threshold: public(uint256)
tradingIO: public(bool)
n_trades: public(uint256)
switcher: public(uint256)
incentive: public(uint256)
conclusiontime: public(uint256)
Airdrop_Eligibility: public(HashMap[address, uint256])
manager: public(uint256)
airdropExpiryDate: public(uint256)
lpaddress: public(address)
airdropAddress: public(address)
nftyield_addy: public(address)
marketing_addy: public(address)
dev_addy: public(address)
reserve_asset: public(address)
dexcheckpoint: public(uint256)
dexstep: public(uint256)
dexAllocation: public(uint256)
dexRebaseCount: public(uint256)

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.min_supply = 1 * 10 ** _decimals
    self.deployer = msg.sender
    deciCalc: decimal = convert(10 ** _decimals, decimal)
    self.onepct = convert(0.01 * deciCalc, uint256)
    self.burn_pct = convert(0.0125 * deciCalc, uint256)
    self.reserve_pct = convert(0.0125 * deciCalc, uint256)
    self.inactive_sell = convert(0.06 * deciCalc, uint256)
    self.reserve_threshold = convert(0.0035 * deciCalc, uint256)
    self.passlist[msg.sender] = False
    self.reserve = self.deployer
    self.last5pctmove[self.deployer] = block.timestamp
    self.tradingIO = True
    self.switcher = 1
    self.reservecounter = 0
    self.dividends = 0
    self.dividend_split = 0
    self.dexRebaseCount = 0
    self.lastTrade = block.timestamp
    self.airdropExpiryDate = block.timestamp + 2600000
    self.lpaddress = ZERO_ADDRESS
    self.reserve_asset = ZERO_ADDRESS
    self.airdropAddress = ZERO_ADDRESS
    self.nftyield_addy = ZERO_ADDRESS
    self.marketing_addy = ZERO_ADDRESS
    self.dev_addy = ZERO_ADDRESS
    self.manager = 3
    self.incentive = 0
    self.n_trades = 0
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@internal
def _pctCalc_minusScale(_value: uint256, _pct: uint256) -> uint256:
    res: uint256 = (_value * _pct) / 10 ** self.decimals
    return res

@internal
def _pctCalc_pctofwhole(_portion: uint256, _ofWhole: uint256) -> uint256:
    res: uint256 = (_portion*10**self.decimals)/_ofWhole
    return res

@view
@external
def totalSupply() -> uint256:
    return self.total_supply

@view
@external
def minSupply() -> uint256:
    return self.min_supply

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]

@view
@external
def nDIVIDEND() -> uint256:
    return self.dividends

@view
@external
def nftDividend(_tranche: uint256) -> uint256:
    return self.nft_total_dividend[_tranche]

@view
@external
def marketingDividend(_tranche: uint256) -> uint256:
    return self.marketing_total_dividend[_tranche]

@view
@external
def devDividend(_tranche: uint256) -> uint256:
    return self.dev_total_dividend[_tranche]

@view
@external
def showReserveManagers() -> address[50]:
    return self.reserveManager

@external
def setReserve(_address: address) -> bool:
    assert self.manager == 3
    assert msg.sender == self.deployer
    assert _address != ZERO_ADDRESS
    self.reserve = _address
    return True

@external
def setDEXcheckpointAndAllocation(_allocation: uint256) -> bool:
    assert self.manager == 3
    assert msg.sender == self.deployer
    self.dexstep = self._pctCalc_minusScale(self.total_supply, self.onepct*5)
    self.dexcheckpoint = self.total_supply - self.dexstep
    self.dexAllocation = _allocation * 10 ** self.decimals
    return True

@external
def setPasslist(_address: address) -> bool:
    assert self.manager >= 1
    assert _address != ZERO_ADDRESS
    assert msg.sender == self.deployer
    self.passlist[_address] = True
    return True

@external
def remPasslist(_address: address) -> bool:
    assert self.manager >= 1
    assert _address != ZERO_ADDRESS
    assert msg.sender == self.deployer
    self.passlist[_address] = False
    return True

@internal
def _approve(_owner: address, _spender: address, _amount: uint256):
    assert _owner != ZERO_ADDRESS, "ERC20: Approve from zero addy"
    assert _spender != ZERO_ADDRESS, "ERC20: Approve to zero addy"
    self.allowances[_owner][_spender] = _amount
    log Approval(_owner, _spender, _amount)

@external
def approve(_spender : address, _value : uint256) -> bool:
    self._approve(msg.sender, _spender, _value)
    return True

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)

@internal
def _sendtoReserve(_from: address, _value: uint256):
    self.balanceOf[_from] -= _value
    self.balanceOf[self.reserve] += _value
    log Transfer(_from, self.reserve, _value)

@external
def inactivityBurn(_address: address) -> bool:
    assert _address != ZERO_ADDRESS
    assert msg.sender != ZERO_ADDRESS
    assert self.passlist[_address] != True
    assert block.timestamp > self.lastIndividualTrade[_address] + 10518972, "MetaWhale: Addy is still active." #4 months 
    half: uint256 = self.balanceOf[_address]/2
    self.balanceOf[_address] -= half
    self.balanceOf[msg.sender] += half
    log Transfer(_address, msg.sender, half)
    self._burn(_address, self.balanceOf[_address])
    return True

@internal
def _mint(_to: address, _value: uint256) -> bool:
    assert _to != ZERO_ADDRESS
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)
    return True

@external
def setAirdropEligibility(_eligibleAddresses: address[100], _amounts: uint256[100]) -> bool:
    assert msg.sender == self.deployer
    assert self.manager == 3
    for x in range(0, 100):
        if _eligibleAddresses[x] != ZERO_ADDRESS:
            self.Airdrop_Eligibility[_eligibleAddresses[x]] = _amounts[x]*10**(self.decimals-4)
        else:
            break
    return True

@external
def managerLevelDecrease() -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert msg.sender == self.deployer
    assert self.manager >= 1
    if self.manager == 2:
        self.airdropExpiryDate = block.timestamp + 86400 #1day
    self.manager -= 1
    return True

@external
def claimAirdrop() -> bool:
    assert self.manager <= 1
    assert msg.sender != ZERO_ADDRESS
    assert self.Airdrop_Eligibility[msg.sender] > 0
    assert block.timestamp < self.airdropExpiryDate
    self._mint(msg.sender, self.Airdrop_Eligibility[msg.sender])
    self.Airdrop_Eligibility[msg.sender] = 0
    self.last5pctmove[msg.sender] = block.timestamp
    self.lastIndividualTrade[msg.sender] = block.timestamp
    return True

@external
def setQuaternaryDividend() -> bool:
    assert msg.sender != ZERO_ADDRESS
    Polaris: address = 0x36F7E77A392a7B4a6fCB781aCE715ec2450F3Aca
    self.reserve_asset = IReserves(Polaris).KingAsset()
    self.airdropAddress = IReserves(Polaris).AirdropAddress()
    self.nftyield_addy = IReserves(Polaris).NFTFaucet()
    self.marketing_addy = IReserves(Polaris).MarketingFaucet()
    self.dev_addy = IReserves(Polaris).devFaucet()
    return True

@external
def forcedSell(_address: address) -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert _address != ZERO_ADDRESS
    assert self.passlist[_address] != True
    assert block.timestamp > self.last5pctmove[_address] + 3024000 #35days
    amount: uint256 = self._pctCalc_minusScale(self.balanceOf[_address], self.inactive_sell-self.onepct)
    callerIncentive: uint256 = self._pctCalc_minusScale(self.balanceOf[_address], self.onepct)
    self._sendtoReserve(_address, amount)
    IReserves(self.reserve).swapInactiveToWETH(amount, _address)
    self.last5pctmove[_address] = block.timestamp
    self.balanceOf[_address] -= callerIncentive
    self.balanceOf[msg.sender] += callerIncentive
    log Transfer(_address, msg.sender, callerIncentive)
    return True

@external
def setDEXreserve(_exReserve: address) -> bool:
    assert msg.sender == self.deployer
    assert self.manager >= 1
    assert _exReserve != ZERO_ADDRESS
    self.dexReserve = _exReserve
    return True

@external
def rebaseExchangeReserve() -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert self.dexReserve != ZERO_ADDRESS
    assert self.dexReserve != self
    if self.dexRebaseCount == 19:
        self._burn(self.dexReserve, self.balanceOf[self.dexReserve])
    else:
        if self.total_supply < self.dexcheckpoint:
            amount: uint256 = self._pctCalc_minusScale(self.dexAllocation, self.onepct*5)
            self._burn(self.dexReserve, amount)
            self.dexcheckpoint -= self.dexstep
            self.dexRebaseCount += 1
        else:
            pass
    return True

@external
def DEXchecker() -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert self.dexReserve != ZERO_ADDRESS
    assert self.dexReserve != self
    amount: uint256 = self._pctCalc_minusScale(self.dexAllocation, self.onepct*5)
    if self.balanceOf[self.dexReserve] > self.dexAllocation - (amount*self.dexRebaseCount):
        amt2correct: uint256 = self.balanceOf[self.dexReserve] - (self.dexAllocation - amount*self.dexRebaseCount)
        self._burn(self.dexReserve, amt2correct)
    return True

@internal
def _prepReserve() -> bool:
    assert self.total_supply <= self.min_supply
    assert self.tradingIO == True
    weth_addy: address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    secundary_asset_addy: address = IReserves(self.reserve).reserveAsset()
    self.final_supply = self.total_supply
    self.final_reserve = ERC20(secundary_asset_addy).balanceOf(self)
    _LPcontract: address = IReserves(self.reserve).baseAssetLP()
    LPbal: uint256 = ERC20(_LPcontract).balanceOf(self)
    ERC20(_LPcontract).transfer(self.reserve, LPbal)
    wethbal: uint256 = ERC20(weth_addy).balanceOf(self)
    ERC20(weth_addy).transfer(self.reserve, wethbal)
    IReserves(self.reserve).close()
    self.tradingIO = False
    self.switcher = 1
    self.conclusiontime = block.timestamp
    return True

@external
def finish() -> bool:
    assert self.total_supply <= self.min_supply
    assert self.tradingIO == True
    assert self.manager == 0
    self.switcher = 1
    self._prepReserve()
    return True

@external
def inactivityFinish() -> bool:
    assert self.tradingIO == True
    assert self.manager == 0
    if block.timestamp > self.lastTrade + 7889229: #3months
        self.min_supply = self.total_supply
        self.switcher = 1
        self._prepReserve()
    return True

@external
def claimReserve() -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert self.tradingIO == False
    assert self.manager == 0
    callerbalance: uint256 = self.balanceOf[msg.sender]
    pctofbase: uint256 = self._pctCalc_pctofwhole(callerbalance, self.final_supply)
    pctofreserve: uint256 = self._pctCalc_minusScale(self.final_reserve, pctofbase)
    ERC20(IReserves(self.reserve).reserveAsset()).transfer(msg.sender, pctofreserve)
    self._burn(msg.sender, callerbalance)
    return True

@external
def bigreset() -> bool:
    assert self.conclusiontime != 0
    assert block.timestamp > self.conclusiontime + 2629743 #1month
    assert self.manager == 0
    newsupply: uint256 = (1000000*10**self.decimals) - self.total_supply
    self._mint(self.reserve, newsupply)
    #self._mint(self.dexReserve, self.dexAllocation)
    self.dexRebaseCount = 0
    self.dexcheckpoint = self.total_supply - self.dexstep
    self.min_supply = 1*10**self.decimals
    self.conclusiontime = 0
    self.switcher = 1
    self.tradingIO = True
    IReserves(self.reserve).swapTokensForWETH(self.balanceOf[self.reserve])
    return True

@internal
def _manageReserve(_caller: address) -> bool:
    assert _caller != ZERO_ADDRESS
    assert self.tradingIO == True
    assert self.manager <= 2
    if _caller in self.reserveManager:
        pass
    else:
        if self.reservecounter == 50:
            self.reservecounter = 0
        rsv_check: uint256 = self._pctCalc_minusScale(self.total_supply, self.reserve_threshold)
        if self.balanceOf[self.reserve] > rsv_check and self.n_trades > 40 and self.switcher == 1:
            amountIn: uint256 = self._pctCalc_minusScale(self.balanceOf[self.reserve], self.onepct*85)
            IReserves(self.reserve).swapTokensForWETH(amountIn)
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 2
            self.incentive = self._pctCalc_minusScale(amountIn, self.onepct)
            self._mint(_caller, self.incentive*2)
            return True
        elif self.switcher == 2:
            self._approve(self.reserve, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, self.balanceOf[self.reserve]/2)
            IReserves(self.reserve).addLiquidity(self.balanceOf[self.reserve]/2)
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 3
            self._mint(_caller, self.incentive*2)
            return True
        elif self.switcher == 3:
            IReserves(self.reserve).swapForSecondaryAndBurn()
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 4
            self._mint(_caller, self.incentive*6)
            return True
        elif self.switcher == 4:
            IReserves(self.reserve).swapForTerciary()
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 5
            self._mint(_caller, self.incentive*2)
            return True
        elif self.switcher == 5:
            terciarySize: uint256 = ERC20(self.reserve_asset).balanceOf(self)
            terciaryTS: uint256 = ERC20(self.reserve_asset).totalSupply()
            terciaryThreshold: uint256 = self._pctCalc_minusScale(terciaryTS, self.onepct)
            if terciarySize > terciaryThreshold:
                self.dividend_split = terciarySize/20
                ERC20(self.reserve_asset).transfer(self.airdropAddress, self.dividend_split*4)
                self.reserveManager[self.reservecounter] = _caller
                self.reservecounter += 1
                self.switcher = 6
                self._mint(_caller, self.incentive*2)
            else:
                self.reserveManager[self.reservecounter] = _caller
                self.reservecounter += 1
                self.switcher = 1
                self._mint(_caller, self.incentive)
            return True
        elif self.switcher == 6:
            pretxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.nftyield_addy)
            ERC20(self.reserve_asset).transfer(self.nftyield_addy, self.dividend_split*14)
            posttxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.nftyield_addy)
            self.nft_total_dividend[self.dividends] = posttxbal - pretxbal
            self._mint(_caller, self.incentive*2)
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 7
            return True
        elif self.switcher == 7:
            pretxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.marketing_addy)
            ERC20(self.reserve_asset).transfer(self.marketing_addy, self.dividend_split)
            posttxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.marketing_addy)
            self.marketing_total_dividend[self.dividends] = posttxbal - pretxbal
            self._mint(_caller, self.incentive*2)
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 8
            return True
        elif self.switcher == 8:
            pretxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.dev_addy)
            ERC20(self.reserve_asset).transfer(self.dev_addy, self.dividend_split)
            posttxbal: uint256 = ERC20(self.reserve_asset).balanceOf(self.dev_addy)
            self.dev_total_dividend[self.dividends] = posttxbal - pretxbal
            self._mint(_caller, self.incentive*2)
            self.reserveManager[self.reservecounter] = _caller
            self.reservecounter += 1
            self.switcher = 1
            self.dividends += 1
            return True
    return True

@internal
def _transfer(_from: address, _to: address, _value: uint256) -> bool:
    assert self.balanceOf[_from] >= _value, "Insufficient balance"
    assert _value != 0, "No zero value transfer allowed"
    assert _to != ZERO_ADDRESS, "Invalid To Address"
    assert _from != ZERO_ADDRESS, "Invalid From Address"
    
    if self.manager >= 2:
        if _from != self.deployer:
            if self.n_trades <= 1000:
                assert _value <= 1000 * 10 ** self.decimals, "Maximum amount allowed is 1000 MWBTC until the 100th transaction."
                assert self.lastIndividualTrade[_to] != block.timestamp, "One buy per block."
            else:
                pass
        else:
            self.manager = 2
    else:
        pass

    if self.tradingIO == True:
        if self.last5pctmove[_from] == 0:
            self.last5pctmove[_from] = block.timestamp
            self.lastIndividualTrade[_from] = block.timestamp
        if self.last5pctmove[_to] == 0:
            self.last5pctmove[_to] = block.timestamp
            self.lastIndividualTrade[_to] = block.timestamp
        if self.total_supply > self.min_supply:
            burn_amt: uint256 = self._pctCalc_minusScale(_value, self.burn_pct)
            reserve_amt: uint256 = self._pctCalc_minusScale(_value, self.reserve_pct)
            minForActive: uint256 = self._pctCalc_minusScale(self.balanceOf[_from], self.inactive_sell)
            if self.passlist[_from] == True and self.passlist[_to] == True:
                self.balanceOf[_from] -= _value
                self.balanceOf[_to] += _value
                log Transfer(_from, _to, _value)
            elif self.passlist[_from] == False and self.passlist[_to] == True:
                rsv: uint256 = reserve_amt*3
                val: uint256 = _value - burn_amt*2 - rsv
                self.balanceOf[_from] -= val
                self.balanceOf[_to] += val
                log Transfer(_from, _to, val)
                self._burn(_from, burn_amt*2)
                self._sendtoReserve(_from, rsv)              
                if _value > minForActive:
                    self.last5pctmove[_from] = block.timestamp
                self.lastIndividualTrade[_from] = block.timestamp
            elif self.passlist[_from] == True and self.passlist[_to] == False:
                self.balanceOf[_from] -= _value
                self.balanceOf[_to] += _value
                log Transfer(_from, _to, _value)
                self._burn(_to, burn_amt)
                self._sendtoReserve(_to, reserve_amt)
                if _value > minForActive:
                    self.last5pctmove[_to] = block.timestamp
                self.lastIndividualTrade[_to] = block.timestamp
            else:
                val: uint256 = _value - burn_amt - reserve_amt
                self._burn(_from, burn_amt)
                self._sendtoReserve(_to, reserve_amt)
                self.balanceOf[_from] -= val
                self.balanceOf[_to] += val
                log Transfer(_from, _to, val)
                if _value > minForActive:
                    self.last5pctmove[_from] = block.timestamp
                self.lastIndividualTrade[_from] = block.timestamp
            self.lastTrade = block.timestamp
            self.n_trades += 1
        else:
            pass
    else:
        pass
    return True

@external
def manageReserve() -> bool:
    self._manageReserve(msg.sender)
    return True

@external
def transfer(_to : address, _value : uint256) -> bool:
    self._transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient Allowance."
    assert _from != ZERO_ADDRESS, "Unable from Zero Addy"
    assert _to != ZERO_ADDRESS, "Unable to Zero Addy"
    self._transfer(_from, _to, _value)
    self._approve(_from, msg.sender, self.allowances[_from][msg.sender] - _value)
    return True