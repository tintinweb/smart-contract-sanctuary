/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity >=0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPair {
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint256 timestamp);
}

contract TokenBase is IERC20 { 
    string private _name = "PNToken";
    string private _symbol = "PNT";
    uint8 private _decimals = 18;
    uint256 public _totalSupply;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    
    event Mint(address indexed owner, uint indexAmount, uint amount0, uint amount1);
    event Burn(address indexed owner, uint indexAmount, uint amount0, uint amount1);

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (_balances[msg.sender] >= _value && _value > 0) {
            _balances[msg.sender] -= _value;
            _balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (_balances[_from] >= _value && _allowances[_from][msg.sender] >= _value && _value > 0) {
            _balances[_to] += _value;
            _balances[_from] -= _value;
            _allowances[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
    
    function totalSupply() public override view returns (uint256 total) {
        return _totalSupply;
    }
}

contract Index is TokenBase {
    
    using SafeMath for uint;

    address public token0;
    address public token1;
    IPair public pair;
    
    constructor(
        address _token0, 
        address _token1,
        address _pair
        
    ) {
        token0 = _token0;
        token1 = _token1;
        pair = IPair(_pair);
    }

    function _mint(uint256 amount0, uint256 amount1) private returns (uint256 indexAmount) {
        require(amount0 != 0 && amount1 != 0, "Adjusted token amount is equal to zero.");
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amount0);
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);

        uint256 amount = Math.sqrt(SafeMath.mul(amount0, amount1));
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Mint(msg.sender, amount, amount0, amount1);
        emit Transfer(address(0), msg.sender, amount);
        
        return amount;
    }
    
    function mint(uint amount0, uint amount1) public returns (uint256 indexAmount) {
        require(amount1 != 0, "Token1 amount is equal to zero.");
        require(amount0 != 0, "Token0 amount is equal to zero.");
        (uint256 amount0R, uint256 amount1R,) = pair.getReserves();
        uint256 amount1S = amount0 / 2 * amount1R / amount0R;
        
        if(amount1S < amount1) {
            return _mint(amount0, amount1S);
        } else {
            uint256 amount0S = amount1 * 2 * amount0R / amount1R;
            return _mint(amount0S, amount1);
        }
    }
    
    
    function burn(uint256 amount) public returns (uint256 amount0, uint256 amount1) {
        require(amount != 0, "Index token amount is equal to zero.");
        require(_balances[msg.sender] >= amount, "Not enough index token.");
        (uint256 amount0R, uint256 amount1R,) = pair.getReserves();
        amount0 = amount / Math.sqrt(amount1R / (2 * amount0R));
        amount1 = (amount0 / 2) * (amount1R / amount0R);
        TransferHelper.safeTransferFrom(token0, address(this), msg.sender, amount0);
        TransferHelper.safeTransferFrom(token1, address(this), msg.sender, amount1);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burn(msg.sender, amount, amount0, amount1);
        emit Transfer(address(0), msg.sender, amount);
    }
}