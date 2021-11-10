pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./ERC20Interface.sol";

/**
    @title Non-Fungible ERC20
    @author Ben Hauser - @iamdefinitelyahuman
    @author with guidance from Gabriel Shapiro - @lex-node
    @dev
        Expands upon the ERC20 token standard
        https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
contract NFToken is ERC20Interface {

    using SafeMath for uint256;
    using SafeMath64 for uint64;

    uint256 constant MAX_UPPER_BOUND = (2**64) - 2;
    address constant ZERO_ADDRESS = address(0);

    /** depending on the intended totalSupply, you may wish to adjust this constant */
    uint256 constant SCOPING_MULTIPLIER = 16;

    /** cannot fractionalize non-fungibles */
    uint8 public constant decimals = 0;
    string public name;
    string public symbol;
    uint256 public totalSupply;

    uint64 upperBound;
    uint64[18446744073709551616] tokens;
    mapping (uint64 => Range) rangeMap;
    mapping (address => Balance) balances;
    mapping (address => mapping (address => uint256)) allowed;

    struct Balance {
        uint64 balance;
        uint64 length;
        uint64[9223372036854775808] ranges;
    }
    struct Range {
        address owner;
        uint64 stop;
    }

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TransferRange(
        address indexed from,
        address indexed to,
        uint256 start,
        uint256 stop,
        uint256 amount
    );

    /**
        @notice constructor method
        @param _name Token Name
        @param _symbol Token symbol
        @param _totalSupply Total supply (assigned to msg.sender)
     */
    constructor(string memory _name, string memory _symbol, uint64 _totalSupply) public {
        require(_totalSupply <= MAX_UPPER_BOUND);
        name = _name;
        symbol = _symbol;
        if (_totalSupply == 0) return;
        _setRange(1, msg.sender, _totalSupply+1);
        balances[msg.sender].balance = _totalSupply;
        balances[msg.sender].length = 1;
        balances[msg.sender].ranges[0] = 1;
        totalSupply = _totalSupply;
        upperBound = _totalSupply;
        emit Transfer(ZERO_ADDRESS, msg.sender, _totalSupply);
        emit TransferRange(ZERO_ADDRESS, msg.sender, 1, _totalSupply+1, _totalSupply);
    }

    /* modifier to ensure a range index is within bounds */
    function _checkBounds(uint256 _idx) internal view {
        require(_idx != 0 && _idx <= upperBound); // dev: index out of bounds
    }

    /**
        @notice ERC20 allowance standard
        @param _owner Owner of the tokens
        @param _spender Spender of the tokens
        @return integer
     */
    function allowance(
        address _owner,
        address _spender
     )
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice ERC20 balanceOf standard
        @param _owner Address of balance to query
        @return integer
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner].balance;
    }

    /**
        @notice Fetch information about a range
        @param _idx Token index number
        @return owner, start of range, stop of range, time restriction, tag
     */
    function getRange(
        uint256 _idx
    )
        external
        view
        returns (
            address _owner,
            uint64 _start,
            uint64 _stop
        )
    {
        _checkBounds(_idx);
        _start = _getPointer(_idx);
        Range storage r = rangeMap[_start];
        return (r.owner, _start, r.stop);
    }

    /**
        @notice Fetch the token ranges owned by an address
        @param _owner Address to query
        @return Array of [(start, stop),..]
     */
    function rangesOf(address _owner) external view returns (uint64[2][] memory) {
        Balance storage b = balances[_owner];
        uint64[2][] memory _ranges = new uint64[2][](balances[_owner].length);
        for (uint256 i; i < balances[_owner].length; i++) {
            _ranges[i] = [b.ranges[i], rangeMap[b.ranges[i]].stop];
        }
        return _ranges;
    }

    /**
        @notice ERC20 approve standard
        @param _spender Address approved to transfer tokens
        @param _value Amount approved for transfer
        @return bool success
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
        @notice ERC20 transfer standard
        @param _to Recipient
        @param _value Amount being transferred
        @return bool success
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice ERC20 transferFrom standard
        @dev This will transfer tokens starting from balance.ranges[0]
        @param _from Sender address
        @param _to Recipient address
        @param _value Number of tokens to send
        @return bool success
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        @notice transfer tokens with a specific index range
        @param _to Recipient address
        @param _start Transfer start index
        @param _stop Transfer stop index
        @return bool success
     */
    function transferRange(
        address _to,
        uint64 _start,
        uint64 _stop
    )
        external
        returns (bool)
    {
        _checkBounds(_start);
        _checkBounds(_stop.sub(1));
        require(_start < _stop); // dev: stop < start
        uint64 _pointer = _getPointer(_stop.sub(1));
        require(_pointer <= _start); // dev: multiple ranges

        uint64 _value = _stop.sub(_start);

        require(msg.sender == rangeMap[_pointer].owner); // dev: sender does not own

        balances[msg.sender].balance = balances[msg.sender].balance.sub(_value);
        balances[_to].balance = balances[_to].balance.add(_value);

        emit Transfer(msg.sender, _to, _value);
        if (msg.sender != _to && _value > 0) {
            _transferSingleRange(_pointer, msg.sender, _to, _start, _stop);
        }

    }

    /**
        @notice Internal transfer function
        @dev common logic for transfer() and transferFrom()
        @param _from Sender address
        @param _to Receiver address
        @param _bigValue Amount to transfer
     */
    function _transfer(address _from, address _to, uint256 _bigValue) internal {
        require(_bigValue <= MAX_UPPER_BOUND); // dev: uint64 overflow

        uint64[9223372036854775808] storage r = balances[_from].ranges;
        uint64 _value = uint64(_bigValue);

        balances[_from].balance = balances[_from].balance.sub(_value);
        balances[_to].balance = balances[_to].balance.add(_value);

        emit Transfer(_from, _to, _bigValue);
        if (_from == _to || _bigValue == 0) {
            return;
        }
        while (balances[_from].length > 0) {
            uint64 _start = r[0];
            uint64 _stop = rangeMap[_start].stop;
            uint64 _amount = _stop.sub(_start);
            if (_value < _amount) {
                _stop = _stop.sub(_amount.sub(_value));
                _value = 0;
            }
            else {
                _value = _value.sub(_amount);
            }
            _transferSingleRange(_start, _from, _to, _start, _stop);
            if (_value == 0) {
                return;
            }
        }
        revert(); // dev: unreachable
    }

    /**
        @notice internal - transfer ownership of a single range of tokens
        @param _pointer Range array pointer
        @param _from Sender address
        @param _to Recipient address
        @param _start Start index of range
        @param _stop Stop index of range
     */
    function _transferSingleRange(
        uint64 _pointer,
        address _from,
        address _to,
        uint64 _start,
        uint64 _stop
    )
        internal
    {
        Range storage r = rangeMap[_pointer];
        uint64 _rangeStop = r.stop;
        uint64 _prev = tokens[_start.sub(1)];
        emit TransferRange(_from, _to, _start, _stop, _stop-_start);

        if (_pointer == _start) {
            /* entire range is being transferred */
            if (_rangeStop == _stop) {
                _replaceInBalanceRange(_from, _start, 0);
                bool _left = (rangeMap[_prev].owner == _to);
                bool _right = (rangeMap[_stop].owner == _to);
                /* no merges with surrounding ranges */
                if (!_left && !_right) {
                    _replaceInBalanceRange(_to, 0, _start);
                    r.owner = _to;
                    return;
                }
                _setRangePointers(_pointer, _stop, 0);
                /* merging with previous range */
                if (!_right) {
                    delete rangeMap[_pointer];
                    rangeMap[_prev].stop = _stop;
                    _setRangePointers(_prev, _stop, _prev);
                    return;
                }
                /* merging with next range */
                if (!_left) {
                    _replaceInBalanceRange(_to, _stop, _start);
                    _setRange(_pointer, _to, rangeMap[_stop].stop);
                    delete rangeMap[_stop];
                    return;
                }
                /* merging with both ranges */
                _replaceInBalanceRange(_to, _stop, 0);
                delete rangeMap[_pointer];
                rangeMap[_prev].stop = rangeMap[_stop].stop;
                _setRangePointers(_prev, _start, 0);
                _setRangePointers(_stop, rangeMap[_stop].stop, 0);
                _setRangePointers(_prev, rangeMap[_prev].stop, _prev);
                delete rangeMap[_stop];
                return;
            }

            /* range to transfer starts at beginning of existing range */
            _setRangePointers(_start, _rangeStop, 0);
            _setRange(_stop, _from, _rangeStop);
            _replaceInBalanceRange(_from, _start, _stop);
            delete rangeMap[_pointer];

            /* merging with previous range */
            if (rangeMap[_prev].owner == _to) {
                _setRangePointers(_prev, _start, 0);
                _start = _prev;
            } else {
                _replaceInBalanceRange(_to, 0, _start);
            }
            _setRange(_start, _to, _stop);
            return;
        }

        /* shared logic - inside / ends at end */
        _setRangePointers(_pointer, _rangeStop, 0);
        r.stop = _start;
        _setRangePointers(_pointer, _start, _pointer);

        /* range to transfer ends at end of existing range */
        if (_rangeStop == _stop) {
            /* merging with next range */
            if (rangeMap[_stop].owner == _to) {
                _replaceInBalanceRange(_to, _stop, _start);
                _setRangePointers(_stop, rangeMap[_stop].stop, 0);
                uint64 _next = rangeMap[_stop].stop;
                delete rangeMap[_stop];
                _stop = _next;
            } else {
                _replaceInBalanceRange(_to, 0, _start);
            }
            _setRange(_start, _to, _stop);
            return;
        }

        /* range to transfer is inside the existing range */
        _replaceInBalanceRange(_to, 0, _start);
        _setRange(_start, _to, _stop);
        _replaceInBalanceRange(_from, 0, _stop);
        _setRange(_stop, _from, _rangeStop);
    }

    /**
        @notice sets a Range struct and associated pointers
        @dev keeping this as a seperate method reduces gas costs from SSTORE
        @param _pointer Range pointer to set
        @param _owner Address of range owner
        @param _stop Range stop index
     */
    function _setRange(uint64 _pointer, address _owner, uint64 _stop) internal {
        Range storage r = rangeMap[_pointer];
        if (r.owner != _owner) r.owner = _owner;
        if (r.stop != _stop) r.stop = _stop;
        _setRangePointers(_pointer, _stop, _pointer);
    }

    /**
        @notice modifies the balance range array
        @param _addr Balance address
        @param _old Token index to remove
        @param _new Token index to add
     */
    function _replaceInBalanceRange(
        address _addr,
        uint64 _old,
        uint64 _new
    )
        internal
    {
        uint64[9223372036854775808] storage r = balances[_addr].ranges;
        if (_old == 0) {
            // add a new range to the array
            r[balances[_addr].length] = _new;
            balances[_addr].length = balances[_addr].length.add(1);
            return;
        }
        for (uint256 i; i <= balances[_addr].length; i++) {
            if (r[i] == _old) {
                if (_new > 0) {
                    // replace an existing range
                    r[i] = _new;
                } else {
                    // delete an existing range
                    balances[_addr].length = balances[_addr].length.sub(1);
                    r[i] = r[balances[_addr].length];
                }
                return;
            }
        }
        revert(); // dev: unreachable
    }

    /**
        @notice Modify pointers in the token range
        @param _start Start index of range
        @param _stop Stop index of range
        @param _value Pointer value
     */
    function _setRangePointers(uint64 _start, uint64 _stop, uint64 _value) internal {
        _stop = _stop.sub(1);
        if (_start == _stop) {
            tokens[_start] = _value;
            return;
        }
        tokens[_stop] = _value;
        uint256 _interval = SCOPING_MULTIPLIER;
        while (true) {
            if (_stop < _interval) return;
            uint256 i = uint256(_stop).div(_interval).mul(_interval);

            _interval = _interval.mul(SCOPING_MULTIPLIER);
            if (i.mod(_interval) == 0) continue;
            if (i > _start) tokens[i] = _value;
        }
    }

    /**
        @notice Find an array range pointer
        @dev
            Given a token index, this will iterate through the range
            and return the mapping pointer that the index is present within.
        @param _idx Token index
     */
    function _getPointer(uint256 _idx) internal view returns (uint64) {
        uint256 _increment = 1;
        while (true) {
            if (tokens[_idx] != 0) return tokens[_idx];
            if (_idx.mod(_increment.mul(SCOPING_MULTIPLIER)) == 0) {
                _increment = _increment.mul(SCOPING_MULTIPLIER);
                require(_idx <= upperBound); // dev: exceeds upper bound
            }
            _idx = _idx.add(_increment);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view  returns (string memory) {
        require(tokenId < totalSupply, "token_not_minted");

        string memory baseURI = "https://ipfs.io/ipfs/QmZ1Wm9mzeVkLUwJ6jL7UBzwGkJsnpMQpNNmP7G8REF1Ci/";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }
}

pragma solidity ^0.5.11;


library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a); // dev: underflow
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a); // dev: overflow

        return c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b != 0);
        return _a % _b;
    }
}


library SafeMath64 {

    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        if (_a == 0) {
            return 0;
        }

        uint64 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0);
        uint64 c = _a / _b;

        return c;
    }

    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a); // dev: underflow
        uint64 c = _a - _b;

        return c;
    }

    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a); // dev: overflow

        return c;
    }

    function mod(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b != 0);
        return _a % _b;
    }
}

pragma solidity 0.5.16;

/**
    @title ERC Token Standard #20 Interface
    @notice https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}