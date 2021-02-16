/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.11;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0);
        z = x / y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < RAY / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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

contract HedgehogERC20 is IERC20 {
    using SafeMath for uint;
    
    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

contract Hedgehog is HedgehogERC20{
  using SafeMath for uint256;

  bool public initialized;
  address public asset;

  uint256 public timestamp;
  uint256 public oracle;
  uint256 public oracle_prev;

  event Deposit(address indexed from, uint256 asset_value, uint256 token_value);
  event Withdraw(address indexed from, uint256 asset_value, uint256 token_value);
  event Oracle(uint256 timestamp, uint256 new_price, uint256 old_price);

  uint256 private unlocked = 1;
  modifier lock() {
      require(unlocked == 1, 'Hedgehog: LOCKED');
      unlocked = 0;
      _;
      unlocked = 1;
  }

  function initialize(address _asset) public {
      require(initialized == false, "Hedgehog_initialize: already initialized");
      asset = _asset;
      initialized = true;
      string memory _name = IERC20(asset).name();
      name = append("Hedgehog ", _name);
      string memory _symbol = IERC20(asset).symbol();
      symbol = append("h", _symbol);
      decimals = 5;
  }

  function price() public view returns (uint256) {
      uint256 token_price = calculateAssetIn(1e5);
      return token_price;
  }
  
  function deposit(uint256 token_amount, uint256 expected_assets) public lock {
      uint256 asset_deposit = calculateAssetIn(token_amount);
      require(asset_deposit > 0, "Hedgehog_Deposit: zero asset deposit"); 
      require(asset_deposit <= expected_assets, "Hedgehog_Deposit: deposit assets above expected");
      _oracle();
      TransferHelper.safeTransferFrom(asset, msg.sender, address(this), asset_deposit); 
      _mint(msg.sender, token_amount);
      Deposit(msg.sender, asset_deposit, token_amount);
  }

  function withdraw(uint256 token_amount, uint256 expected_assets) public lock {
      uint256 asset_withdraw = calculateAssetOut(token_amount);
      require(asset_withdraw > 0, "Hedgehog_withdraw: zero asset withdraw"); 
      require(asset_withdraw >= expected_assets, "Hedgehog_Deposit: withdraw assets below expected");
      _oracle();
      _burn(msg.sender, token_amount);
      TransferHelper.safeTransfer(asset, msg.sender, asset_withdraw);
      Withdraw(msg.sender, asset_withdraw, token_amount);
  }

  function calculateAssetIn(uint256 token_amount) public view returns (uint256) {
      uint256 asset_balance = IERC20(asset).balanceOf(address(this));
      uint256 token_balance_new = totalSupply.add(token_amount);
      uint256 asset_balance_new = token_balance_new.mul(token_balance_new);
      return asset_balance_new.sub(asset_balance);
  }

  function calculateAssetOut(uint256 token_amount) public view returns (uint256) {
      uint256 asset_balance = IERC20(asset).balanceOf(address(this));
      uint256 token_balance_new = totalSupply.sub(token_amount);
      uint256 asset_balance_new = token_balance_new.mul(token_balance_new);
      return asset_balance.sub(asset_balance_new);
  }

  function _oracle() internal {
      if (timestamp < block.timestamp && totalSupply > 0){
          timestamp = block.timestamp;
          oracle_prev = oracle;
          oracle = price();
          Oracle(timestamp, oracle, oracle_prev);
      }
  }

  function append(string memory a, string memory b) internal pure returns (string memory) {
      return string(abi.encodePacked(a, b));
  }
}

contract HedgehogFactory {

    mapping(address =>  address) public hedgehog;
    address[] public allHedgehogs;
 
    function allHedgehogsLength() external view returns (uint) {
        return allHedgehogs.length;
    }
    function createHedgehog(address asset) public returns (address) {
        require(asset != address(0), "HedgehogFactory: zero asset");
        require(hedgehog[asset] == address(0), "HedgehogFactory: existing hedgehog");
        Hedgehog _hedgehog = new Hedgehog();
        hedgehog[asset] = address(_hedgehog);
        allHedgehogs.push(address(_hedgehog));
        _hedgehog.initialize(asset);
        return address(_hedgehog);
    }
}