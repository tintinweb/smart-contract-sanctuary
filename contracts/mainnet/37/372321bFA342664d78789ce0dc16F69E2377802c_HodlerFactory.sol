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
    
    /* Remove tranfer functionality for hodler token
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    */
}

contract HodlerERC20 is IERC20 {
    using SafeMath for uint;

    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint public override totalSupply;
    uint public totalWithdraw;
    mapping(address => uint) public override balanceOf;
    //mapping(address => mapping(address => uint)) public override allowance;

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

    function _burnCurve(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalWithdraw = totalWithdraw.add(value);
        emit Transfer(from, address(0), value);
    }

    /* Remove tranfer functionality for hodler token
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
    */
}

contract Hodler is HodlerERC20{
  using SafeMath for uint256;

  bool public initialized;
  address public asset;
  uint256 public start_amount;
  uint256 public min_percent;
  uint256 public max_percent;
  
  bool public started;
  uint256 public start_time;
  bool public ended;
  mapping(address => uint256) public end_time;
 
  event Deposit(address indexed from, uint256 amount);
  event Withdraw(address indexed from, uint256 asset_value, uint256 token_value, bool started);

  uint256 private unlocked = 1;
  modifier lock() {
      require(unlocked == 1, 'Hodler: LOCKED');
      unlocked = 0;
      _;
      unlocked = 1;
  }

  function initialize(address _asset, uint256 _amount, uint256 _min, uint256 _max) public {
      require(initialized == false, "Hodler_initialize: already initialized");
      initialized = true;
      asset = _asset;
      start_amount = _amount;
      min_percent = _min;
      max_percent = _max;
      string memory _name = IERC20(asset).name();
      name = append("Hodler ", _name);
      string memory _symbol = IERC20(asset).symbol();
      symbol = append("hodl", _symbol);
      decimals = IERC20(asset).decimals();
  }

  function deposit(uint256 amount) public lock {
      require(amount > 0, "Hodler_Deposit: zero asset deposit"); 
      require(ended == false, "Hodler_Deposit: game ended");
      require(started == false, "Hodler_Deposit: game started");
      if (totalSupply.add(amount) >= start_amount) {
          require(totalSupply.add(amount) < start_amount.mul(2), "Hodler_Deposit: final deposit out of range");
          started = true;
          start_time = block.timestamp;
      }
      TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amount); 
      _mint(msg.sender, amount);
      Deposit(msg.sender, amount);
  }

  function withdraw(uint256 token_amount) public lock {
      require(token_amount > 0, "Hodler_withdraw: zero token withdraw"); 
      require(ended == false, "Hodler_withdraw: game ended");
      uint256 asset_withdraw;
      if (started != true) {
          asset_withdraw = token_amount;
          _burn(msg.sender, token_amount);
      } else {
          asset_withdraw = calculateAssetOut(token_amount);
          if (totalWithdraw.add(token_amount) == totalSupply) {
              ended = true;
          }  
          require(asset_withdraw > 0, "Hodler_withdraw: zero asset withdraw");
          _burnCurve(msg.sender, token_amount);
          if (balanceOf[msg.sender] == 0) {end_time[msg.sender] = block.timestamp;}
      }
      TransferHelper.safeTransfer(asset, msg.sender, asset_withdraw);
      Withdraw(msg.sender, asset_withdraw, token_amount, started);
  }

  function calculateAssetOut(uint256 token_amount) public view returns (uint256) {
      uint256 rounding = totalSupply;
      /*
       1. Calc perc_assets_out_new = 40 * totalWithdraw/totalSupply + 80 
          -> At min this is 40 * 0 + 80 = 80% 
          -> At max this is 40 * 1 + 80 = 120% 
      */
      uint256 difference = max_percent.sub(min_percent);
      uint256 perc_assets_out_old = difference.mul(rounding).mul(totalWithdraw).div(totalSupply).add(min_percent.mul(rounding));
      uint256 new_totalWithdraw = totalWithdraw.add(token_amount);
      uint256 perc_assets_out_new = difference.mul(rounding).mul(new_totalWithdraw).div(totalSupply).add(min_percent.mul(rounding));
      /* 
        2. Calc mean percent difference -> perc_new - perc_old / 2 + perc_old
          -> at 120 perc_new and 100 perc_old = (120 - 100) / 2 + 100 = 110% 
          -> at 100 perc_new and 80 perc_old = (100 - 80) / 2 + 80 = 90%
      */
      uint256 mean_perc = (perc_assets_out_new.sub(perc_assets_out_old)).div(2).add(perc_assets_out_old);
      /* 
        3. Calc assets out -> token_amount * mean_perc_diff / 100
          -> at mean_perc_diff 110% = 110 * token_amount / 100
      */
      uint256 assets_out = mean_perc.mul(token_amount).div(rounding.mul(100));
      if (new_totalWithdraw == totalSupply) {
          IERC20 weth = IERC20(asset);
          assets_out = weth.balanceOf(address(this));
      }
      return assets_out;
  }

  function append(string memory a, string memory b) internal pure returns (string memory) {
      return string(abi.encodePacked(a, b));
  }
}

contract HodlerFactory {

    mapping(address => address[]) public hodler;
    mapping(address => uint256) public index;
    address[] public allHodlers;

    event Create(address hodler, address asset);
 
    function allHodlersLength() external view returns (uint) {
        return allHodlers.length;
    }

    function createHodler(address asset) public returns (address) {
        require(asset != address(0), "HodlerFactory: zero asset input");
        uint256 _index = index[asset];
        index[asset] += 1;
        if (_index > 0) {
            address previous = hodler[asset][_index - 1];
            Hodler _previous = Hodler(previous);
            bool started = _previous.started();
            require(started == true, "HodlerFactory: previous hodler did not start");
        }
        Hodler _hodler = new Hodler();
        _hodler.initialize(asset, 10**21, 80, 120);
        hodler[asset].push(address(_hodler));
        allHodlers.push(address(_hodler));
	    Create(address(_hodler), asset);
        return address(_hodler);
    }
}