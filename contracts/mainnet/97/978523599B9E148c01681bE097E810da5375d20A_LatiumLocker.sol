pragma solidity ^0.4.15;

contract Latium {
    string public constant name = "Latium";
    string public constant symbol = "LAT";
    uint8 public constant decimals = 16;
    uint256 public constant totalSupply =
        30000000 * 10 ** uint256(decimals);

    // owner of this contract
    address public owner;

    // balances for each account
    mapping (address => uint256) public balanceOf;

    // triggered when tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint _value);

    // constructor
    function Latium() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    // transfer the balance from sender&#39;s account to another one
    function transfer(address _to, uint256 _value) {
        // prevent transfer to 0x0 address
        require(_to != 0x0);
        // sender and recipient should be different
        require(msg.sender != _to);
        // check if the sender has enough coins
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        // check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // subtract coins from sender&#39;s account
        balanceOf[msg.sender] -= _value;
        // add coins to recipient&#39;s account
        balanceOf[_to] += _value;
        // notify listeners about this transfer
        Transfer(msg.sender, _to, _value);
    }
}

contract LatiumLocker {
    address private constant _latiumAddress = 0xBb31037f997553BEc50510a635d231A35F8EC640;
    Latium private constant _latium = Latium(_latiumAddress);

    // total amount of Latium tokens that can be locked with this contract
    uint256 private _lockLimit = 10000000;

    // variables for release tiers and iteration thru them
    uint32[] private _timestamps = [
        1535803200 // 2018-09-01 12:00:00 UTC
        , 1567339200 // 2019-09-01 12:00:00 UTC
        , 1598961600 // 2020-09-01 12:00:00 UTC
        , 1630497600 // 2021-09-01 12:00:00 UTC
    ];
    uint32[] private _tokensToRelease = [ // without decimals
        2500000
        , 2500000
        , 2500000
        , 2500000
    ];
    mapping (uint32 => uint256) private _releaseTiers;

    // owner of this contract
    address public owner;

    // constructor
    function LatiumLocker() {
        owner = msg.sender;
        // initialize release tiers with pairs:
        // "UNIX timestamp" => "amount of tokens to release" (with decimals)
        for (uint8 i = 0; i < _timestamps.length; i++) {
            _releaseTiers[_timestamps[i]] =
                _tokensToRelease[i] * 10 ** uint256(_latium.decimals());
            _lockLimit += _releaseTiers[_timestamps[i]];
        }
    }

    // function to get current Latium balance (with decimals)
    // of this contract
    function latiumBalance() constant returns (uint256 balance) {
        return _latium.balanceOf(address(this));
    }

    // function to get total amount of Latium tokens (with decimals)
    // that can be locked with this contract
    function lockLimit() constant returns (uint256 limit) {
        return _lockLimit;
    }

    // function to get amount of Latium tokens (with decimals)
    // that are locked at this moment
    function lockedTokens() constant returns (uint256 locked) {
        locked = 0;
        uint256 unlocked = 0;
        for (uint8 i = 0; i < _timestamps.length; i++) {
            if (now >= _timestamps[i]) {
                unlocked += _releaseTiers[_timestamps[i]];
            } else {
                locked += _releaseTiers[_timestamps[i]];
            }
        }
        uint256 balance = latiumBalance();
        if (unlocked > balance) {
            locked = 0;
        } else {
            balance -= unlocked;
            if (balance < locked) {
                locked = balance;
            }
        }
    }

    // function to get amount of Latium tokens (with decimals)
    // that can be withdrawn at this moment
    function canBeWithdrawn() constant returns (uint256 unlockedTokens, uint256 excessTokens) {
        unlockedTokens = 0;
        excessTokens = 0;
        uint256 tiersBalance = 0;
        for (uint8 i = 0; i < _timestamps.length; i++) {
            tiersBalance += _releaseTiers[_timestamps[i]];
            if (now >= _timestamps[i]) {
                unlockedTokens += _releaseTiers[_timestamps[i]];
            }
        }
        uint256 balance = latiumBalance();
        if (unlockedTokens > balance) {
            // actual Latium balance of this contract is smaller
            // than can be released at this moment
            unlockedTokens = balance;
        } else if (balance > tiersBalance) {
            // if actual Latium balance of this contract is greater
            // than can be locked, all excess tokens can be withdrawn
            // at any time
            excessTokens = (balance - tiersBalance);
        }
    }

    // functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // function to withdraw Latium tokens that are unlocked at this moment
    function withdraw(uint256 _amount) onlyOwner {
        var (unlockedTokens, excessTokens) = canBeWithdrawn();
        uint256 totalAmount = unlockedTokens + excessTokens;
        require(totalAmount > 0);
        if (_amount == 0) {
            // withdraw all available tokens
            _amount = totalAmount;
        }
        require(totalAmount >= _amount);
        uint256 unlockedToWithdraw =
            _amount > unlockedTokens ?
                unlockedTokens :
                _amount;
        if (unlockedToWithdraw > 0) {
            // update tiers data
            uint8 i = 0;
            while (unlockedToWithdraw > 0 && i < _timestamps.length) {
                if (now >= _timestamps[i]) {
                    uint256 amountToReduce =
                        unlockedToWithdraw > _releaseTiers[_timestamps[i]] ?
                            _releaseTiers[_timestamps[i]] :
                            unlockedToWithdraw;
                    _releaseTiers[_timestamps[i]] -= amountToReduce;
                    unlockedToWithdraw -= amountToReduce;
                }
                i++;
            }
        }
        // transfer tokens to owner&#39;s account
        _latium.transfer(msg.sender, _amount);
    }
}