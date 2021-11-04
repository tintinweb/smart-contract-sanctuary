/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract ScaleDAOT2 is Context, IERC20{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor () public {
        _name = "ScaleDAOTest2";
        _symbol = "SCADT";
        _decimals = 18;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

  // Balance of SCAD
  function balanceOf(address owner) public view override returns (uint256) {
    uint256 lp_power = PowerFromLiquidity(owner);
    uint256 token_power = PowerFromToken(owner);

    return lp_power.add(token_power);
  }

  // Total supply of SCAD
  function totalSupply() public view override returns (uint256) {
    IERC20 sca = IERC20(0x11a819Beb0AA3327E39f52F90d65Cc9bCA499F33); // SCA token
    IERC20 cirus = IERC20(0x2a82437475A60BebD53e33997636fadE77604fc2); // Cirus token
    IERC20 torum = IERC20(0xE1C42BE9699Ff4E11674819c1885D43Bd92E9D15); // Torum token
    IERC20 ore = IERC20(0xD52f6CA48882Be8fbaa98ce390db18e1dbe1062d); // Ore token
    IERC20 niftsy = IERC20(0x432cdbC749FD96AA35e1dC27765b23fDCc8F5cf1); // Niftsy token
    uint256 sca_totalSca = sca.totalSupply(); // Total supply of SCA
    uint256 cirus_totalCirus = cirus.totalSupply(); // Total supply of Cirus
    uint256 torum_totalTorum = torum.totalSupply(); // Total supply of Torum
    uint256 ore_totalOre = ore.totalSupply(); // Total supply of Ore
    uint256 niftsy_totalNiftsy = niftsy.totalSupply(); // Total supply of Niftsy
    uint256 result = 0;
        {
            result = sca_totalSca.add(cirus_totalCirus).add(torum_totalTorum).add(ore_totalOre).add(niftsy_totalNiftsy);
        }
        return result;
  }

  // Voting power calculated based on the liquidity provision
  function PowerFromLiquidity(address owner) private view returns (uint256) {
    IPair pair = IPair(0x2922E104e1e81B5Ea5f6aC7b895f040ba2Be6a24); // SCA-WETH pair
    (uint256 lp_totalSCA, , ) = pair.getReserves(); // Total supply of SCA in the pair SCA-WETH
    uint256 lp_total = pair.totalSupply();
    uint256 lp_balance = pair.balanceOf(owner);

    return lp_totalSCA.mul(lp_balance).div(lp_total).mul(2);
  }

  // Voting power calculated based on the holding of SCA and external launched tokens
  // Each set will consist of 5 tokens launched on ScaleSwap
  function PowerFromTokenSet00001(address owner) private view returns (uint256) {
    IERC20 sca = IERC20(0x11a819Beb0AA3327E39f52F90d65Cc9bCA499F33); // SCA token
    IERC20 cirus = IERC20(0x2a82437475A60BebD53e33997636fadE77604fc2); // Cirus token
    IERC20 torum = IERC20(0xE1C42BE9699Ff4E11674819c1885D43Bd92E9D15); // Torum token
    IERC20 ore = IERC20(0xD52f6CA48882Be8fbaa98ce390db18e1dbe1062d); // Ore token
    IERC20 niftsy = IERC20(0x432cdbC749FD96AA35e1dC27765b23fDCc8F5cf1); // Niftsy token
    uint256 sca_balance = sca.balanceOf(owner); // The user's balance of SCA token
    uint256 cirus_balance = cirus.balanceOf(owner); // The user's balance of Cirus token
    uint256 torum_balance = torum.balanceOf(owner); // The user's balance of Torum token
    uint256 ore_balance = ore.balanceOf(owner); // The user's balance of Ore token
    uint256 niftsy_balance = niftsy.balanceOf(owner); // The user's balance of Niftsy token

    return sca_balance.add(cirus_balance).add(torum_balance).add(ore_balance).add(niftsy_balance);
  }

  function PowerFromToken(address owner) private view returns (uint256) {
    uint256 result = PowerFromTokenSet00001(owner);
    return result;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}