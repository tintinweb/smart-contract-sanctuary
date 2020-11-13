/**
 *Submitted for verification at Etherscan.io on 2020-08-22
*/

pragma solidity 0.6.0;

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

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Keep is Ownable {
    using SafeMath for uint256;

    modifier validRecipient(address account) {
        //require(account != address(0x0));
        require(account != address(this));
        _;
    }

    struct keeper {
        uint256 snapshotPeriod;
        uint256 snapshotBalance;
    }

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogWhitelisted(address indexed addr);
    event LogUnlocked(uint256 timestamp);
    event Logstopinflations(uint256 totalSupply);
    event Logkeep(uint256 indexed period, uint256 candidatesLength, uint256 estimatedkeepers, uint256 keepedToken, uint256 availableUnits);

    // public constants
    string public constant name = "Keepstake.finance";
    string public constant symbol = "KEEP";
    uint256 public constant decimals = 9;

    // private constants
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_TOKENS = 21 * 10**6;
    uint256 private constant INITIAL_SUPPLY = INITIAL_TOKENS * 10**decimals;
    uint256 private constant TOTAL_UNITS = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);
    uint256 private constant POOL_SIZE = 50; // 50%
    uint256 private constant INIT_POOL_FACTOR = 60;
    uint256 private constant keep_MIN_BALANCE = 1000 * 10**decimals;
    uint256 private constant keep_ADDRESS_LIMIT = 1000;
    uint256 private constant TIMELOCK_TIME = 72 hours;
    uint256 private constant HALVING_PERIOD = 30;

    // mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _whitelist;
    mapping(address => keeper) private _keepers;
    mapping(address => bool) private _knownAddresses;
    mapping(uint256 => address) private _addresses;
    uint256 _addressesLength;

    // ints
    uint256 private _totalSupply;
    uint256 private _unitsPerToken;
    uint256 private _initialPoolToken;
    uint256 private _poolBalance;
    uint256 private _poolFactor;

    uint256 private _period;
    uint256 private _timelockkeeping;
    uint256 private _timelockstopinflations;

    // bools
    bool private _lockTransfer;
    bool private _lockkeeping;


    constructor() public override {
        _owner = msg.sender;

        // set toal supply = initial supply
        _totalSupply = INITIAL_SUPPLY;
        // set units per token based on total supply
        _unitsPerToken = TOTAL_UNITS.div(_totalSupply);

        // set pool balance = TOTAL_UNITS / 100 * POOL_SIZE
        _poolBalance = TOTAL_UNITS / 100 * POOL_SIZE;
        // set initial pool token balance
        _initialPoolToken = _poolBalance.div(_unitsPerToken);
        // set initial pool factor
        _poolFactor = INIT_POOL_FACTOR;

        // set owner balance
        _balances[_owner] = TOTAL_UNITS - _poolBalance;

        // init locks & set defaults
        _lockTransfer = true;
        _lockkeeping = true;

        emit Transfer(address(0x0), _owner, _totalSupply.sub(_initialPoolToken));
    }


    function whitelistAdd(address addr) external onlyOwner {
        _whitelist[addr] = true;
        emit LogWhitelisted(addr);
    }

    // main unlock function
    // 1. set period
    // 2. set timelocks
    // 3. allow token transfer
    function unlock() external onlyOwner {
        require(_period == 0, "contract is unlocked");
        _period = 1;
        _timelockkeeping = now.add(TIMELOCK_TIME);
        _timelockstopinflations = now.add(TIMELOCK_TIME);
        _lockTransfer = false;
        _lockkeeping = false;
        emit LogUnlocked(block.timestamp);
    }


    // stopinflations stuff
    function stopinflations() external onlyOwner {
        require(_lockTransfer == false, "contract is locked");
        require(_timelockstopinflations < now, "also stopinflations need time to rest");
        _timelockstopinflations = now.add(TIMELOCK_TIME);
        _totalSupply = _totalSupply.sub(_totalSupply.div(100));
        _unitsPerToken = TOTAL_UNITS.div(_totalSupply);
        emit Logstopinflations(_totalSupply);
    }

    function getSnapshotBalance(address addr) private view returns (uint256) {
        if (_keepers[addr].snapshotPeriod < _period) {
            return _balances[addr];
        }
        return  _keepers[addr].snapshotBalance;
    }

    // keep
    function keep() external onlyOwner {
        require(_lockTransfer == false, "contract is locked");
        require(_timelockkeeping < now, "timelock is active");
        _timelockkeeping = now.add(TIMELOCK_TIME);

        // need the sum of all keeper balances to calculate share in keep
        uint256 totalkeepersBalance = 0;

        // check if address is candidate
        address[] memory candidates = new address[](_addressesLength);
        uint256 candidatesLength = 0;
        for (uint256 i = 0; i < _addressesLength; i++) {
            address addr = _addresses[i];
            if(addr == address(0x0)) {
                continue;
            }
            uint256 snapbalance = getSnapshotBalance(addr);
            // dont put it on the list if too low
            if (snapbalance < keep_MIN_BALANCE.mul(_unitsPerToken)) {
                continue;
            }
            // put it on the list if on of both conditions are true
            // 1. snapshot is old [no coins moved]
            // 2. balance >= snapshot balance [no tokens out]
            if ((_keepers[addr].snapshotPeriod < _period) || (_balances[addr] >= snapbalance)) {
                candidates[candidatesLength] = addr;
                candidatesLength++;
            }
        }

        uint256 estimatedkeepers = 0;
        uint256 keepedUnits = 0;
        uint256 availableUnits = _initialPoolToken.div(_poolFactor).mul(_unitsPerToken);
        if(candidatesLength > 0) {
            estimatedkeepers = 1;
            // get lucky candidates keepers
            uint256 randomNumber = uint256(keccak256(abi.encodePacked((_addressesLength + _poolBalance + _period), now, blockhash(block.number))));
            uint256 randomIndex = randomNumber % 10;
            uint256 randomOffset = 0;
            if (candidatesLength >= 10) {
                estimatedkeepers = (candidatesLength - randomIndex - 1) / 10 + 1;
            }
            if (estimatedkeepers > keep_ADDRESS_LIMIT) {
                randomOffset = (randomNumber / 100) % estimatedkeepers;
                estimatedkeepers = keep_ADDRESS_LIMIT;
            }
            address[] memory keepers = new address[](estimatedkeepers);
            uint256 keepersLength = 0;
            for (uint256 i = 0; i < estimatedkeepers; i++) {
                address addr = candidates[(randomIndex + (i + randomOffset) * 10) % candidatesLength];
                keepers[keepersLength] = addr;
                keepersLength++;
                totalkeepersBalance = totalkeepersBalance.add(getSnapshotBalance(addr).div(_unitsPerToken));
            }


            for (uint256 i = 0; i < keepersLength; i++) {
                address addr = keepers[i];
                uint256 snapbalance = getSnapshotBalance(addr);
                uint256 tokensToAdd = availableUnits.div(_unitsPerToken).mul(snapbalance.div(_unitsPerToken)).div(totalkeepersBalance);
                uint256 unitsToAdd = tokensToAdd.mul(_unitsPerToken);
                _balances[addr] = _balances[addr].add(unitsToAdd);
                keepedUnits = keepedUnits.add(unitsToAdd);
            }

            if ((keepedUnits < availableUnits) && (keepersLength > 0)) {
                address addr = keepers[keepersLength-1];
                uint256 rest = availableUnits.sub(keepedUnits);
                _balances[addr] = _balances[addr].add(rest);
                keepedUnits = keepedUnits.add(rest);
            }
            if (keepedUnits > 0) {
                _poolBalance = _poolBalance.sub(keepedUnits);
            }
        }

        uint256 keepedTokens = 0;
        if(keepedUnits > 0) {
            keepedTokens = keepedUnits.div(_unitsPerToken);
        }
        emit Logkeep(_period, candidatesLength, estimatedkeepers, keepedTokens, availableUnits);

        if(_period % HALVING_PERIOD == 0) {
            _poolFactor = _poolFactor.add(_poolFactor);
        }
        _period = _period.add(1);
    }


    function calcShareInTokens(uint256 snapshotToken, uint256 totalkeepersToken, uint256 availableToken) private pure returns(uint256) {
        return availableToken.mul(snapshotToken).div(totalkeepersToken);
    }

    function isOwnerOrWhitelisted(address addr) private view returns (bool) {
        if (addr == _owner) {
            return true;
        }
        return _whitelist[addr];
    }

    function acquaintAddress(address candidate) private returns (bool) {
        if((_knownAddresses[candidate] != true) && (candidate != _owner)) {
            _knownAddresses[candidate] = true;
            _addresses[_addressesLength] = candidate;
            _addressesLength++;
            return true;
        }
        return false;
    }


    function period() public view returns (uint256) {
        return _period;
    }

    function poolBalance() public view returns (uint256) {
        return _poolBalance.div(_unitsPerToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].div(_unitsPerToken);
    }

    function processkeepersBeforeTransfer(address from, address to, uint256 units) private {

        // process sender
        // if we have no current snapshot, make it
        // snapshot is balance before sending
        if(_keepers[from].snapshotPeriod < _period) {
            _keepers[from].snapshotBalance = _balances[from];
            _keepers[from].snapshotPeriod = _period;
        } else {
            // snapshot is same period, set balance reduced by units (= current balance)
            _keepers[from].snapshotBalance = _balances[from].sub(units);
        }

        // process receiver
        // if we have no current snapshot, make it
        // snapshot is balance before receiving
        if(_keepers[to].snapshotPeriod < _period) {
            _keepers[to].snapshotBalance = _balances[to];
            _keepers[to].snapshotPeriod = _period;
        } else {
            // snapshot is same period, nothing to do -> new tokens have to rest at least 1 period
            // later in keeping we have also to check the snapshort period and update the balance if < to take care of no transfer/no updated snapshot balance situation
        }
    }

    function transfer(address recipient, uint256 value) public validRecipient(recipient) returns (bool) {
        require(((_lockTransfer == false) || isOwnerOrWhitelisted(msg.sender)), 'token transfer is locked');
        uint256 units = value.mul(_unitsPerToken);
        uint256 newSenderBalance = _balances[msg.sender].sub(units);
        processkeepersBeforeTransfer(msg.sender, recipient, units);
        _balances[msg.sender] = newSenderBalance;
        _balances[recipient] = _balances[recipient].add(units);
        acquaintAddress(recipient);
        emit Transfer(msg.sender, recipient, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) returns (bool) {
        require(((_lockTransfer == false) || isOwnerOrWhitelisted(msg.sender)), 'token transfer is locked');
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        uint256 units = value.mul(_unitsPerToken);
        processkeepersBeforeTransfer(from, to, units);
        uint256 newSenderBalance = _balances[from].sub(units);
        _balances[from] = newSenderBalance;
        _balances[to] = _balances[to].add(units);
        acquaintAddress(to);
        emit Transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

}