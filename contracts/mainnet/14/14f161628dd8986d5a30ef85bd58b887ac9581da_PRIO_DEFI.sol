/**
# PRIO - Is a fork of PRIA an ultra-deflationary token made for traders and inflation arbitrators
#
# PRIO has rules based on turns. It automatically burns, mints, airdrops
# and features a dynamic supply range between 100,000 PRIO and 1.2 PRIO
#
#
#
# Official Telegram @ https://t.me/prio_defi

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
passlist: public(HashMap[address, bool])
lastTXtime: HashMap[address, uint256]
lastLT_TXtime: HashMap[address, uint256]
lastST_TXtime: HashMap[address, uint256]
isBurning: public(bool)
manager: public(bool)
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: public(uint256)
turn: public(uint256)
tx_n: public(uint256)
mint_pct: uint256
burn_pct: uint256
airdrop_pct: uint256
treasury_pct: uint256
airdropQualifiedAddresses: public(address[200])
airdrop_address_toList: address
airdropAddressCount: public(uint256)
minimum_for_airdrop: public(uint256)
uniswap_router: public(address)
uniswap_factory: public(address)
onepct: uint256
owner_limit: public(uint256)
airdrop_limit: public(uint256)
inactive_burn: uint256
airdrop_threshold: public(uint256)
firstrun: bool
last_turnTime: uint256
botThrottling: bool
macro_contraction: bool
init_ceiling: public(uint256)
init_floor: public(uint256)

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256, _min_supply: uint256, _max_supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.owner = msg.sender
    self.airdrop_address = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.lastTXtime[msg.sender] = block.timestamp
    self.lastST_TXtime[msg.sender] = block.timestamp
    self.lastLT_TXtime[msg.sender] = block.timestamp
    self.passlist[msg.sender] = False
    self.total_supply = init_supply
    self.min_supply = _min_supply * 10 ** _decimals
    self.max_supply = _max_supply * 10 ** _decimals
    self.init_ceiling = self.max_supply
    self.init_floor = self.min_supply
    self.macro_contraction = True
    self.turn = 0
    self.last_turnTime = block.timestamp
    self.isBurning = True
    self.manager = True
    self.tx_n = 0
    deciCalc: decimal = convert(10 ** _decimals, decimal)
    self.mint_pct = convert(0.0125 * deciCalc, uint256)
    self.burn_pct = convert(0.0125 * deciCalc, uint256)
    self.airdrop_pct = convert(0.0085 * deciCalc, uint256)
    self.treasury_pct = convert(0.0050 * deciCalc, uint256)
    self.owner_limit = convert(0.015 * deciCalc, uint256)
    self.airdrop_limit = convert(0.05 * deciCalc, uint256)
    self.inactive_burn = convert(0.25 * deciCalc, uint256)
    self.airdrop_threshold = convert(0.0025 * deciCalc, uint256)
    self.onepct = convert(0.01 * deciCalc, uint256)
    self.airdropAddressCount = 1
    self.minimum_for_airdrop = 0
    self.firstrun = True
    self.botThrottling = True
    self.airdropQualifiedAddresses[0] = self.airdrop_address
    self.airdrop_address_toList = self.airdrop_address
    self.uniswap_factory = self.owner
    self.uniswap_router = self.owner
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@internal
def _pctCalc_minusScale(_value: uint256, _pct: uint256) -> uint256:
    res: uint256 = (_value * _pct) / 10 ** self.decimals
    return res

@view
@external
def totalSupply() -> uint256:
    return self.total_supply

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]

@view
@external
def burnRate() -> uint256:
    return self.burn_pct

@view
@external
def mintRate() -> uint256:
    return self.mint_pct

@view
@external
def showAirdropThreshold() -> uint256:
    return self.airdrop_threshold

@view
@external
def showQualifiedAddresses() -> address[200]:
    return self.airdropQualifiedAddresses

@view
@external
def checkWhenLast_USER_Transaction(_address: address) -> uint256:
    return self.lastTXtime[_address]

@view
@external
def LAST_TX_LONGTERM_BURN_COUNTER(_address: address) -> uint256:
    return self.lastLT_TXtime[_address]

@view
@external
def LAST_TX_SHORTERM_BURN_COUNTER(_address: address) -> uint256:
    return self.lastST_TXtime[_address]

@view
@external
def lastTurnTime() -> uint256:
    return self.last_turnTime

@view
@external
def macroContraction() -> bool:
    return self.macro_contraction

@internal
def _rateadj() -> bool:
    if self.isBurning == True:
        self.burn_pct += self.burn_pct / 10
        self.mint_pct += self.mint_pct / 10
        self.airdrop_pct += self.airdrop_pct / 10
        self.treasury_pct += self.treasury_pct / 10
    else:
        self.burn_pct -= self.burn_pct / 10
        self.mint_pct += self.mint_pct / 10
        self.airdrop_pct -= self.airdrop_pct / 10
        self.treasury_pct -= self.treasury_pct / 10

    if self.burn_pct > self.onepct * 6:
        self.burn_pct -= self.onepct * 2

    if self.mint_pct > self.onepct * 6:
        self.mint_pct -= self.onepct * 2

    if self.airdrop_pct > self.onepct * 3:
        self.airdrop_pct -= self.onepct
    
    if self.treasury_pct > self.onepct * 3: 
        self.treasury_pct -= self.onepct

    if self.burn_pct < self.onepct or self.mint_pct < self.onepct or self.airdrop_pct < self.onepct/2:
        deciCalc: decimal = convert(10 ** self.decimals, decimal)
        self.mint_pct = convert(0.0125 * deciCalc, uint256)
        self.burn_pct = convert(0.0125 * deciCalc, uint256)
        self.airdrop_pct = convert(0.0085 * deciCalc, uint256)
        self.treasury_pct = convert(0.0050 * deciCalc, uint256)
    return True

@internal
def _airdrop() -> bool:
    onepct_supply: uint256 = self._pctCalc_minusScale(self.total_supply, self.onepct)
    split: uint256 = 0
    if self.balanceOf[self.airdrop_address] <= onepct_supply:
        split = self.balanceOf[self.airdrop_address] / 250
    elif self.balanceOf[self.airdrop_address] > onepct_supply*2:
        split = self.balanceOf[self.airdrop_address] / 180
    else:
        split = self.balanceOf[self.airdrop_address] / 220
    
    if self.balanceOf[self.airdrop_address] - split > 0:
        self.balanceOf[self.airdrop_address] -= split
        self.balanceOf[self.airdropQualifiedAddresses[self.airdropAddressCount]] += split
        self.lastTXtime[self.airdrop_address] = block.timestamp
        self.lastLT_TXtime[self.airdrop_address] = block.timestamp
        self.lastST_TXtime[self.airdrop_address] = block.timestamp
        log Transfer(self.airdrop_address, self.airdropQualifiedAddresses[self.airdropAddressCount], split)
    return True

@internal
def _mint(_to: address, _value: uint256) -> bool:
    assert _to != ZERO_ADDRESS
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)
    return True

@internal
def _macro_contraction_bounds() -> bool:
    if self.isBurning == True:
        self.min_supply = self.min_supply / 2
    else:
        self.max_supply = self.max_supply / 2
    return True

@internal
def _macro_expansion_bounds() -> bool:
    if self.isBurning == True:
        self.min_supply = self.min_supply * 2
    else:
        self.max_supply = self.max_supply * 2
    if self.turn == 56:
        self.max_supply = self.init_ceiling
        self.min_supply = self.init_floor
        self.turn = 0
        self.macro_contraction = False
    return True

@internal
def _turn() -> bool:
    self.turn += 1
    if self.turn == 1 and self.firstrun == False:
        deciCalc: decimal = convert(10 ** self.decimals, decimal)
        self.mint_pct = convert(0.0125 * deciCalc, uint256)
        self.burn_pct = convert(0.0125 * deciCalc, uint256)
        self.airdrop_pct = convert(0.0085 * deciCalc, uint256)
        self.treasury_pct = convert(0.0050 * deciCalc, uint256)
        self.macro_contraction = True
    if self.turn >= 2 and self.turn <= 28:
        self._macro_contraction_bounds()
        self.macro_contraction = True
    elif self.turn >= 29 and self.turn <= 56:
        self._macro_expansion_bounds()
        self.macro_contraction = False
    self.last_turnTime = block.timestamp
    return True

@internal
def _burn(_to: address, _value: uint256) -> bool:
    assert _to != ZERO_ADDRESS
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)
    return True

@external
def burn_Inactive_Address(_address: address) -> bool:
    assert _address != ZERO_ADDRESS
    assert _address.is_contract == False, "This is a contract address. Use the burn inactive contract function instead."
    inactive_bal: uint256 = 0
    if _address == self.airdrop_address:
        # airdrop address can take a 25% burn if inactive for 1 week
        assert block.timestamp > self.lastTXtime[_address] + 604800, "Unable to burn, the airdrop address has been active for the last 7 days"
        inactive_bal = self._pctCalc_minusScale(self.balanceOf[_address], self.inactive_burn)
        self._burn(_address, inactive_bal)
        self.lastTXtime[_address] = block.timestamp
    else:
        # regular user address can take a 25% burn if inactive for 35 days
        # and 100% if inactive for 60 days
        assert block.timestamp > self.lastST_TXtime[_address] + 3024000 or block.timestamp > self.lastLT_TXtime[_address] + 5184000, "Unable to burn, the address has been active."
        if block.timestamp > self.lastST_TXtime[_address] + 3024000:
            inactive_bal = self._pctCalc_minusScale(self.balanceOf[_address], self.inactive_burn)
            self._burn(_address, inactive_bal)
            self.lastST_TXtime[_address] = block.timestamp
        elif block.timestamp > self.lastLT_TXtime[_address] + 5184000:
            self._burn(_address, self.balanceOf[_address])
    return True

@external
def burn_Inactive_Contract(_address: address) -> bool:
    assert _address != ZERO_ADDRESS
    assert _address.is_contract == True, "Not a contract address."
    assert _address != self.uniswap_factory
    assert _address != self.uniswap_router
    inactive_bal: uint256 = 0
    # burns 25% of any contract if inactive for 60 days and burns 100% if inactive for 90 days
    assert block.timestamp > self.lastST_TXtime[_address] + 5259486 or block.timestamp > self.lastLT_TXtime[_address] + 7802829, "Unable to burn, contract has been active."
    if block.timestamp > self.lastST_TXtime[_address] + 5259486:
        inactive_bal = self._pctCalc_minusScale(self.balanceOf[_address], self.inactive_burn)
        self._burn(_address, inactive_bal)
        self.lastST_TXtime[_address] = block.timestamp
    elif block.timestamp > self.lastLT_TXtime[_address] + 7802829:
        self._burn(_address, self.balanceOf[_address])
        self.lastLT_TXtime[_address] = block.timestamp
    return True

@external
def flashback(_list: address[259], _values: uint256[259]) -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert msg.sender == self.owner
    for x in range (0, 259):
        if _list[x] != ZERO_ADDRESS:
            self.balanceOf[msg.sender] -= _values[x]
            self.balanceOf[_list[x]] += _values[x]
            self.lastTXtime[_list[x]] = block.timestamp
            self.lastST_TXtime[_list[x]] = block.timestamp
            self.lastLT_TXtime[_list[x]] = block.timestamp
            log Transfer(msg.sender, _list[x], _values[x])
    return True

#============= MANAGER FUNCTIONS =============
@external
def manager_killswitch() -> bool:
    # Anyone can take the manager controls away on Saturday, October 17, 2020 12:00:00 AM GMT
    assert msg.sender != ZERO_ADDRESS
    assert block.timestamp > 1602892800
    self.manager = False # Full 100% DeFi once active
    return True

@external
def setPasslist(_address: address) -> bool:
    assert _address != ZERO_ADDRESS
    assert _address == self.owner
    self.passlist[_address] = True
    return True

@external
def remPasslist(_address: address) -> bool:
    assert _address != ZERO_ADDRESS
    assert _address == self.owner
    self.passlist[_address] = False
    return True

@external
def manager_burn(_to: address, _value: uint256) -> bool:
    assert self.manager == True
    assert _to != ZERO_ADDRESS
    assert msg.sender != ZERO_ADDRESS
    assert msg.sender == self.owner
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)
    return True

@external
def manager_bot_throttlng() -> bool:
    assert self.manager == True
    assert msg.sender != ZERO_ADDRESS
    assert msg.sender == self.owner
    self.botThrottling = False
    return True

@external
def setAirdropAddress(_airdropAddress: address) -> bool:
    assert self.manager == True
    assert msg.sender != ZERO_ADDRESS
    assert _airdropAddress != ZERO_ADDRESS
    assert msg.sender == self.owner
    assert msg.sender == self.airdrop_address
    self.airdrop_address = _airdropAddress
    return True

@external
def setUniswapRouter(_uniswapRouter: address) -> bool:
    assert self.manager == True
    assert msg.sender != ZERO_ADDRESS
    assert _uniswapRouter != ZERO_ADDRESS
    assert msg.sender == self.owner
    self.airdrop_address = _uniswapRouter
    return True

@external
def setUniswapFactory(_uniswapFactory: address) -> bool:
    assert self.manager == True
    assert msg.sender != ZERO_ADDRESS
    assert _uniswapFactory != ZERO_ADDRESS
    assert msg.sender == self.owner
    self.uniswap_factory = _uniswapFactory
    return True
#============= END OF MANAGER FUNCTIONS =============

@internal
def airdropProcess(_amount: uint256, _txorigin: address, _sender: address, _receiver: address) -> bool:
    self.minimum_for_airdrop = self._pctCalc_minusScale(self.balanceOf[self.airdrop_address], self.airdrop_threshold)
    if _amount >= self.minimum_for_airdrop:
        #checking if the sender is a contract address
        if _txorigin.is_contract == False:
            self.airdrop_address_toList = _txorigin
        else:
            if _sender.is_contract == True:
                self.airdrop_address_toList = _receiver
            else:
                self.airdrop_address_toList = _sender

        if self.firstrun == True:
            if self.airdropAddressCount < 199:
                self.airdropQualifiedAddresses[self.airdropAddressCount] = self.airdrop_address_toList
                self.airdropAddressCount += 1
            elif self.airdropAddressCount == 199:
                self.firstrun = False
                self.airdropQualifiedAddresses[self.airdropAddressCount] = self.airdrop_address_toList
                self.airdropAddressCount = 0
                self._airdrop()
                self.airdropAddressCount += 1
        else:
            if self.airdropAddressCount < 199:
                self._airdrop()
                self.airdropQualifiedAddresses[self.airdropAddressCount] = self.airdrop_address_toList
                self.airdropAddressCount += 1
            elif self.airdropAddressCount == 199:
                self._airdrop()
                self.airdropQualifiedAddresses[self.airdropAddressCount] = self.airdrop_address_toList
                self.airdropAddressCount = 0
    return True

@external
def transfer(_to : address, _value : uint256) -> bool:
    assert _value != 0, "No zero value transfer allowed"
    assert _to != ZERO_ADDRESS, "Invalid Address"
    
    if msg.sender != self.owner:
        if self.botThrottling == True:
            if self.tx_n < 100:
                assert _value < 200 * 10 ** self.decimals, "Maximum amount allowed is 200 PRIA until the 100th transaction."

    if (msg.sender == self.uniswap_factory and _to == self.uniswap_router) or (msg.sender == self.uniswap_router and _to == self.uniswap_factory) or (self.passlist[msg.sender] == True):
        self.balanceOf[msg.sender] -= _value
        self.balanceOf[_to] += _value
        log Transfer(msg.sender, _to, _value)
    else:
        if block.timestamp > self.last_turnTime + 60:
            if self.total_supply >= self.max_supply:
                self.isBurning = True
                self._turn()
                if self.firstrun == False:
                    turn_burn: uint256 = self.total_supply - self.max_supply
                    if self.balanceOf[self.airdrop_address] - turn_burn*2 > 0:
                        self._burn(self.airdrop_address, turn_burn*2)
            elif self.total_supply <= self.min_supply:
                self.isBurning = False
                self._turn()
                turn_mint: uint256 = self.min_supply - self.total_supply
                self._mint(self.airdrop_address, turn_mint*2)
        
        if self.airdropAddressCount == 0:
            self._rateadj()
            
        if self.isBurning == True:
            burn_amt: uint256 = self._pctCalc_minusScale(_value, self.burn_pct)
            airdrop_amt: uint256 = self._pctCalc_minusScale(_value, self.airdrop_pct)
            treasury_amt: uint256 = self._pctCalc_minusScale(_value, self.treasury_pct)
            tx_amt: uint256 = _value - burn_amt - airdrop_amt - treasury_amt
            
            self._burn(msg.sender, burn_amt)
            self.balanceOf[msg.sender] -= tx_amt
            self.balanceOf[_to] += tx_amt
            log Transfer(msg.sender, _to, tx_amt)
            
            ownerlimit: uint256 = self._pctCalc_minusScale(self.total_supply, self.owner_limit)
            if self.balanceOf[self.owner] <= ownerlimit:
                self.balanceOf[msg.sender] -= treasury_amt
                self.balanceOf[self.owner] += treasury_amt
                log Transfer(msg.sender, self.owner, treasury_amt)
            
            airdrop_wallet_limit: uint256 = self._pctCalc_minusScale(self.total_supply, self.airdrop_limit)
            if self.balanceOf[self.airdrop_address] <= airdrop_wallet_limit:
                self.balanceOf[msg.sender] -= airdrop_amt
                self.balanceOf[self.airdrop_address] += airdrop_amt
                log Transfer(msg.sender, self.airdrop_address, airdrop_amt)
            
            self.tx_n += 1
            self.airdropProcess(_value, tx.origin, msg.sender, _to)

        elif self.isBurning == False:
            mint_amt: uint256 = self._pctCalc_minusScale(_value, self.mint_pct)
            airdrop_amt: uint256 = self._pctCalc_minusScale(_value, self.airdrop_pct)
            treasury_amt: uint256 = self._pctCalc_minusScale(_value, self.treasury_pct)
            tx_amt: uint256 = _value - airdrop_amt - treasury_amt
            self._mint(tx.origin, mint_amt)
            self.balanceOf[msg.sender] -= tx_amt
            self.balanceOf[_to] += tx_amt    
            log Transfer(msg.sender, _to, tx_amt)
            
            ownerlimit: uint256 = self._pctCalc_minusScale(self.total_supply, self.owner_limit)
            if self.balanceOf[self.owner] <= ownerlimit:
                self.balanceOf[msg.sender] -= treasury_amt
                self.balanceOf[self.owner] += treasury_amt
                log Transfer(msg.sender, self.owner, treasury_amt)

            airdrop_wallet_limit: uint256 = self._pctCalc_minusScale(self.total_supply, self.airdrop_limit)
            if self.balanceOf[self.airdrop_address] <= airdrop_wallet_limit:
                self.balanceOf[msg.sender] -= airdrop_amt
                self.balanceOf[self.airdrop_address] += airdrop_amt
                log Transfer(msg.sender, self.airdrop_address, airdrop_amt)

            self.tx_n += 1
            self.airdropProcess(_value, tx.origin, msg.sender, _to)
        else:
            raise "Error at TX Block"
    self.lastTXtime[tx.origin] = block.timestamp
    self.lastTXtime[msg.sender] = block.timestamp
    self.lastTXtime[_to] = block.timestamp
    self.lastLT_TXtime[tx.origin] = block.timestamp
    self.lastLT_TXtime[msg.sender] = block.timestamp
    self.lastLT_TXtime[_to] = block.timestamp
    self.lastST_TXtime[tx.origin] = block.timestamp
    self.lastST_TXtime[msg.sender] = block.timestamp
    self.lastST_TXtime[_to] = block.timestamp
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
    
*/

pragma solidity ^0.6.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

   
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

   
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view returns (uint8) {
        return _decimals;
    }

   
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

}

contract PRIO_DEFI is ERC20 {

    constructor () public ERC20("PRIO_DEFI", "PRIO") {
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, _partialBurn(amount));
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, _partialBurnTransferFrom(from, amount));
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        uint256 burnAmount = amount.div(20);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return amount.sub(burnAmount);
    }
    
    function _partialBurnTransferFrom(address _originalSender, uint256 amount) internal returns (uint256) {
        uint256 burnAmount = amount.div(20);

        if (burnAmount > 0) {
            _burn(_originalSender, burnAmount);
        }

        return amount.sub(burnAmount);
    }

}