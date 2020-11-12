#
# Galore - A token made for traders.
#
# Galore has rules based on turns
# Galore burns, mints, aidrops and keeps a supply
# range between 100,000 GAL and 10,000 GAL
#
# Find out more about Galore @ https://galore.defilabs.eth.link
#
# A TOKEN TESTED BY DEFI LABS @ HTTPS://DEFILABS.ETH.LINK
# CREATOR: Dr. Mantis
#
# Telegram @ https://t.me/defilabs_community & @dr_mantis_defilabs

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

owner: public(address)
airdrop_address: public(address)
name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
max_supply: public(uint256)
min_supply: public(uint256)
balanceOf: public(HashMap[address, uint256])
isBurning: public(bool)
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: public(uint256)
turn: public(uint256)
tx_n: public(uint256)
inc_z: public(uint256)
mint_pct: public(decimal)
burn_pct: public(decimal)
airdrop_pct: public(decimal)
treasury_pct: public(decimal)
airdropQualifiedAddresses: public(address[200])
airdropAddressCount: public(uint256)

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256, _min_supply: uint256, _max_supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.owner = msg.sender
    self.airdrop_address = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.min_supply = _min_supply * 10 ** _decimals
    self.max_supply = _max_supply * 10 ** _decimals
    self.turn = 0
    self.isBurning = True
    self.tx_n = 0
    self.inc_z = 10000
    self.mint_pct = 0.0125
    self.burn_pct = 0.0125
    self.airdrop_pct = 0.0085
    self.treasury_pct = 0.0050
    self.airdropAddressCount = 0
    self.airdropQualifiedAddresses[0] = self.airdrop_address
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@view
@external
def totalSupply() -> uint256:
    return self.total_supply

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]

@internal
def _rateadj():
    if self.isBurning == True:
        self.burn_pct += 0.00125
        self.mint_pct += 0.00125
        self.airdrop_pct += 0.00085
        self.treasury_pct += 0.00050
    else:
        self.burn_pct -= 0.00100
        self.mint_pct -= 0.00100
        self.airdrop_pct -= 0.00068
        self.treasury_pct -= 0.00040
    if self.burn_pct > 0.2 or self.mint_pct > 0.2:
        self.mint_pct -= 0.005
        self.burn_pct -= 0.005
        self.airdrop_pct -= 0.006
        self.treasury_pct -= 0.0038
    if self.burn_pct < 0.01 or self.mint_pct < 0.01 or self.airdrop_pct < 0.0017 or self.treasury_pct < 0.001:
        self.mint_pct = 0.0125
        self.burn_pct = 0.0125
        self.airdrop_pct = 0.0085
        self.treasury_pct = 0.0050
    else:
        pass

@external
def setAirdropAddress(_airdropAddress: address):
    assert msg.sender != ZERO_ADDRESS
    assert _airdropAddress != ZERO_ADDRESS
    assert msg.sender == self.owner
    assert msg.sender == self.airdrop_address
    self.airdrop_address = _airdropAddress

@internal
def _minsupplyadj():
    if self.turn == 3:
        self.min_supply = 1000 * 10 ** self.decimals
    elif self.turn == 5:
        self.min_supply = 10000 * 10 ** self.decimals
    elif self.turn == 7:
        self.min_supply = 10 * 10 ** self.decimals
    elif self.turn == 9:
        self.min_supply = 10000 * 10 ** self.decimals

@internal
def _airdrop():
    split_calc: decimal = convert(self.balanceOf[self.airdrop_address] / 250, decimal)
    split: uint256 = convert(split_calc, uint256)
    self.airdropAddressCount = 0
    for x in self.airdropQualifiedAddresses:
        self.balanceOf[self.airdrop_address] -= split
        self.balanceOf[x] += split
        log Transfer(self.airdrop_address, x, split)

@internal
def _mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS, "Invalid Address."
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _turn():
    self.turn += 1
    self._rateadj()
    self._minsupplyadj()

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS, "Invalid Address."
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)

@external
def transfer(_to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS, "Invalid Address"
    if self.total_supply >= self.max_supply:
        self._turn()
        self.isBurning = True
    elif self.total_supply <= self.min_supply:
        self._turn()
        self.isBurning = False
    if self.airdropAddressCount == 0:
        self._rateadj()
    if self.isBurning == True and (self.turn % 2) != 0:
        val: decimal = convert(_value, decimal)
        burn_amt: uint256 = convert(val * self.burn_pct, uint256)
        airdrop_amt: uint256 = convert(val * self.airdrop_pct, uint256)
        treasury_amt: uint256 = convert(val * self.treasury_pct, uint256)
        tx_amt: uint256 = _value - burn_amt - airdrop_amt - treasury_amt
        self._burn(msg.sender, burn_amt)
        self.balanceOf[msg.sender] -= tx_amt
        self.balanceOf[_to] += tx_amt
        log Transfer(msg.sender, _to, tx_amt)
        self.balanceOf[msg.sender] -= treasury_amt
        self.balanceOf[self.owner] += treasury_amt
        log Transfer(msg.sender, self.owner, treasury_amt)
        self.balanceOf[msg.sender] -= airdrop_amt
        self.balanceOf[self.airdrop_address] += airdrop_amt
        log Transfer(msg.sender, self.airdrop_address, airdrop_amt)
        self.tx_n += 1
        self.airdropAddressCount += 1
        if self.airdropAddressCount < 199:
            self.airdropQualifiedAddresses[self.airdropAddressCount] = msg.sender
        elif self.airdropAddressCount == 199:
            self.airdropQualifiedAddresses[self.airdropAddressCount] = msg.sender
            self._airdrop()
    
    elif self.isBurning == False and (self.turn % 2) == 0:
        val: decimal = convert(_value, decimal)
        mint_amt: uint256 = convert(val * self.mint_pct, uint256)
        airdrop_amt: uint256 = convert(val * self.airdrop_pct, uint256)
        treasury_amt: uint256 = convert(val * self.treasury_pct, uint256)
        tx_amt: uint256 = _value - airdrop_amt - treasury_amt
        self._mint(msg.sender, mint_amt)
        self.balanceOf[msg.sender] -= tx_amt
        self.balanceOf[_to] += tx_amt
        log Transfer(msg.sender, _to, tx_amt)
        self.balanceOf[msg.sender] -= treasury_amt
        self.balanceOf[self.owner] += treasury_amt
        log Transfer(msg.sender, self.owner, treasury_amt)
        self.balanceOf[msg.sender] -= airdrop_amt
        self.balanceOf[self.airdrop_address] += airdrop_amt
        log Transfer(msg.sender, self.airdrop_address, airdrop_amt)
        self.tx_n += 1
        self.airdropAddressCount += 1
        if self.airdropAddressCount < 199:
            self.airdropQualifiedAddresses[self.airdropAddressCount] = msg.sender
        elif self.airdropAddressCount == 199:
            self.airdropQualifiedAddresses[self.airdropAddressCount] = msg.sender
            self._airdrop()
    else:
        raise "Error at TX Block"
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True