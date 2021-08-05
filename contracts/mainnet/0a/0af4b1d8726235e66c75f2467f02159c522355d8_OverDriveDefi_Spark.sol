/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

/*                            
//    ______                   __.     *               
//   |  __ |._. ._.___.____.__|  |___.__._. ._.___.   
//   | |_| |\.\/./ -__|  __| -- |  __| |\.\/./ -__|
//   |_____| \_/ \____|_|  \___||_| |_|  \_/ \____|                       
//              
//
//   https://t.me/overdrivedefi
//   Created by Zac Bennett
//   erc-20 OVD token overdrive_contract sol.0.7.0+
//   github: https://github.com/zac-bennett/OverDrive
//  
//   Team: Z.B | K 
//   website:https://overdrive-defi.site
//   About Spark Token
//   $SPARK is an inflationary token and will be acting as the native currency of the ecosystem.
//   It will be farmed from a YFI-UI inspired platform with over 1,100% APY but shrinks as the pool expands. 
//   Available pools include WETH - OVD, DAI - OVD, USDC - OVD and USDT - OVD.
*/ 

pragma solidity 0.7.0;
 
interface IERC20 {
  function totalSupply()                                         external view returns (uint256);
  function balanceOf(address who)                                external view returns (uint256);
  function allowance(address owner, address spender)             external view returns (uint256);
  function transfer(address to, uint256 value)                   external      returns (bool);
  function approve(address spender, uint256 value)               external      returns (bool);
  function transferFrom(address from, address to, uint256 value) external      returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
 
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
 
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}
 
 
abstract contract ERC20Detailed is IERC20 {
 
  string private _name;
  string private _symbol;
  uint8  private _decimals;
 
  constructor(string memory name, string memory symbol, uint8 decimals) {
    _name     = name;
    _symbol   = symbol;
    _decimals = decimals;
  }
 
  function name() public view returns(string memory) {
    return _name;
  }
 
  function symbol() public view returns(string memory) {
    return _symbol;
  }
 
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}
 
 contract OverDriveDefi_Spark is ERC20Detailed {
     
     // constructor of erc-20
     // 10% burning constant
     // $SPARK ticker
     // token name: OverDriveDefi_Spark
     // Total Supply: 1B
     
  using SafeMath for uint256;
 
  mapping (address => uint256)                      private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool)                         private _whitelist;
 
  address private constant _router  = 0x1B6fefF7680B897CBe661d5F3FF4a820bF6A4F7A;
  address private          _owner;
 
  string   constant tokenName     = "OverDriveDefi_Spark";
  string   constant tokenSymbol   = "SPARK";
  uint8    constant tokenDecimals = 0;
  uint256  public   burnPct       = 10;
  uint256  private  _totalSupply  = 1_000_000_000;
  uint256  private  _txCap        = 1_000_000_000;
 
  constructor() ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
      _owner = msg.sender;
      _balances[_owner] = _totalSupply;
      _modifyWhitelist(_owner, true);
      _modifyWhitelist(_router, true);
  }
  
  function _checkWhitelist(address adr) internal view returns (bool) {
    return _whitelist[adr];
  }
 
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
 
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowed[owner][spender];
  }
  
  function balanceOf(address owner) external view override returns (uint256) {
    return _balances[owner];
  }
 
  function findBurnAmount(uint256 rate, uint256 value) public pure returns (uint256) {
      return value.ceil(100).mul(rate).div(100);
  }
 
  function _modifyWhitelist(address adr, bool state) internal {
    _whitelist[adr] = state;
  }
  
  function transfer(address to, uint256 value) external override returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    if (_checkWhitelist(msg.sender)) {
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
 
    emit Transfer(msg.sender, to, value);
    return true;
  } else {
      
    /**
     * This portion of the code implies a Burnable Token
     * Token that can be irreversibly burned (destroyed) sent to 0x0000000000000000000000000000000000000000
     * Z.B
     */ 
     
    require (value <= _txCap || _checkWhitelist(to),
            "Sorry, but this exceeds tx cap you have");
    uint256 tokensToBurn     = findBurnAmount(burnPct, value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
 
    _totalSupply = _totalSupply.sub(tokensToBurn);
 
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }
}

    /**
     * This portion of the code implies a maximum cap of hodler ownings
     * Z.B
     */ 
  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    if (_checkWhitelist(from)) {
      _balances[from] = _balances[from].sub(value);
      _balances[to] = _balances[to].add(value);
 
      emit Transfer(from, to, value);
      return true;
    } else {
      require (value <= _txCap || _checkWhitelist(to),
              "amount exceeds tx cap");
 
      _balances[from] = _balances[from].sub(value);
 
      uint256 tokensToBurn     = findBurnAmount(burnPct, value);
      uint256 tokensToTransfer = value.sub(tokensToBurn);
 
      _balances[to] = _balances[to].add(tokensToTransfer);
      _totalSupply  = _totalSupply.sub(tokensToBurn);
 
      _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
 
      emit Transfer(from, to, tokensToTransfer);
      emit Transfer(from, address(0), tokensToBurn);
 
      return true;
    }
  }
  
  function approve(address spender, uint256 value) external override returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
 
    emit Approval(msg.sender, spender, value);
    return true;
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
 
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
 
}