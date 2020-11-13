/*



   __  __      _ __              
  / / / /___  (_) /   ____  _  __
 / / / / __ \/ / /   / __ \| |/_/
/ /_/ / / / / / /___/ /_/ />  <  
\____/_/ /_/_/_____/\____/_/|_|  
                                 

(LOX) 

Securing The DeFi Space

Website:   https://unilox.io

Telegram:  https://t.me/unilox

Twitter:   https://twitter.com/Uniloxio

Discord:   https://discord.gg/PcaQ473


LOX token sale begins September 18, 2020

LOX Uniswap Listing September 20, 2020

LOX token sale price is 0.0001 ETH
(2X Bonus of $PRELOX holders)

To gain the 2X bonus buyers of $LOX must hold at least 1,000 $PRELOX tokens

Buy PRELOX here:   


*/

pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function addBalance(address account, uint amount) internal {
        require(account != address(0), "ERC20: add to the zero address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LOX is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  uint256 public tokenSalePrice = 0.0001 ether;
  uint public liquidityTokens = 0;  
  bool public _tokenSaleMode = true;
  uint256 public teamLockTime;
  address public admin;
  bool public teamUnlocked = false;
  bool public liquidityTokensAdded = false;
  address public _loxPreAddress = 0x4C08F3aCc79463aDA063EFcd5888161006601964;
  uint public minLoxPreTokens = 1000e18;
  uint public presaleMultiplier = 2;
  uint public minPreSalePurchase = 0.25 ether;
  
 
  constructor () public ERC20Detailed("UniLox.io", "LOX", 18) {
      admin = msg.sender;
      teamLockTime = now + 360*86400; //lock team tokens for 1 year
  }

    function checkPreBalance(address _user)  public view returns(bool) {
      IERC20 preLox = IERC20(_loxPreAddress); 

      if (preLox.balanceOf(_user) >= minLoxPreTokens) {
          return true;
      } else {
        return false;
      }  
  }

function checkMyBonus()  public view returns(bool) {
      IERC20 preLox = IERC20(_loxPreAddress); 

      if (preLox.balanceOf(msg.sender) >= minLoxPreTokens) {
          return true;
      } else {
        return false;
      }  
  }

   function burn(uint256 amount) public {
      _burn(msg.sender, amount);
  }
  
  function buyToken() public payable {
      require(_tokenSaleMode, "token sale is over");
      require(msg.value >= minPreSalePurchase, "minimum purchase amount not met");
      uint256 tokenMultiplier = 1;

      if (checkPreBalance(msg.sender)) {
          tokenMultiplier = presaleMultiplier;
      } else {
          tokenMultiplier = 1;
      }

      uint256 newTokens = SafeMath.mul(SafeMath.div(msg.value, tokenSalePrice),1e18);
      newTokens = newTokens * tokenMultiplier;
      addBalance(msg.sender, newTokens);
      liquidityTokens = liquidityTokens.add(newTokens);
  }

   function unlockTeamTokens() public payable {    // team tokens are locked for 1 year
      require(msg.sender == admin, "!not allowed");
      require(now > teamLockTime, "!too early");   
      require(!teamUnlocked, "!already unlocked");  
      teamUnlocked = true;
      uint256 newTokens = 400000e18;  // 400,000 team tokens
      addBalance(msg.sender, newTokens);
      
  }

  function() external payable {
      buyToken();
  }

  function getLiquidityTokens() public {
      require(msg.sender == admin, "!not allowed");
      require(!liquidityTokensAdded, "!already added");
      liquidityTokensAdded = true;
      uint _liqTokens = SafeMath.mul(liquidityTokens,4);
      addBalance(msg.sender, _liqTokens);
  } 


  function endTokenSale() public {
      require(msg.sender == admin, "!not allowed");
      _tokenSaleMode = false;
  }

   function setPreloxAddress(address loxPreAddress) public {
      require(msg.sender == admin, "!not allowed");
      _loxPreAddress = loxPreAddress;
  }

   function withdraw() external {
      require(msg.sender == admin, "!not allowed");
      msg.sender.transfer(address(this).balance);
  }

   function withdrawPartial(uint _amount) external {
      require(msg.sender == admin, "!not allowed");
      require(_amount <= address(this).balance, "!exceeds balance");
      msg.sender.transfer(_amount);
  }

   function myPreLox() external view returns(uint) {
      IERC20 preLox = IERC20(_loxPreAddress); 
      return preLox.balanceOf(msg.sender);
  }

 function setPreLoxMin(uint _min) external {
      require(msg.sender == admin, "!not allowed");
      minLoxPreTokens = _min;
  }

   function setPresaleMultiplier(uint _mult) external {
      require(msg.sender == admin, "!not allowed");
      presaleMultiplier = _mult;
  }

   function setMinPresale(uint _min) external {
      require(msg.sender == admin, "!not allowed");
      minPreSalePurchase = _min;
  }
  


}