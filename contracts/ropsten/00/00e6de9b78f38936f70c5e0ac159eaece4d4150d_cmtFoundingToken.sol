/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/


pragma solidity ^0.5.16;

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
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

contract cmtFoundingToken is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  
  uint coinAmount;
  uint public earnFund = 1;
  uint public isOpenSwap = 1;
  uint public isCloseSwap = 1;
  uint public min_unit = 2000000;
  uint public abs_price = 2;  //2 USDT
  IERC20 public token;
  address public governance;
  mapping(uint256 => uint8) public fundList;
  
  mapping (address => uint) private _bonus; //分红数组 ++++++++++++++
  address[] private _bonusIndices; //分红数组下标 ++++++++++++++
  
  //address constant public want = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);     //Tether USD (USDT)  6 point
  address constant public want = address(0xf6783C2764A66f449011635e55cB013640f75BB0);       //Tether USD (USDT) Ropsten  6 point


  constructor () public ERC20Detailed("Polynomial.2101.ABS.CM.finance", "POLYN", 6) {   //Ropsten
      //governance = 0x1360CFA0606E5b057df468D540fA81F75d8146E3;
      governance = 0x59c8F1a700dD17B45287108DDf8D593719c88a43;
      coinAmount = 3000 * 10 ** uint256(6);   //Ropsten
      
      token = IERC20(want);
      _mint(governance, coinAmount); 
  }
  
  function setGovernance(address _governance) public {
      require(msg.sender == governance, "!governance");
      governance = _governance;
  }
  
  function doMint(uint _amount) public {
      require(msg.sender == governance, "!governance");
      _mint(governance, _amount); 
  }
  
  function doBurn(uint _amount) public {
      require(msg.sender == governance, "!governance");
      _burn(msg.sender, _amount);
  }
  
  function inCaseTokensGetStuck(address _token, uint _amount) public {
      //转任意erc20
      require(msg.sender == governance, "!governance");
      IERC20(_token).safeTransfer(governance, _amount);
  }
  
  function setlatestFund(uint _earnFund) external {
        require(msg.sender == governance, "!governance");
        earnFund = _earnFund;
  }
    
  function getlatestFund() public view returns (uint)  {
        return earnFund;
  }
  
  function appendFundList(uint256 _times, uint8 _earnFund) external {
        require(msg.sender == governance, "!governance");
        fundList[_times] = _earnFund;
  }
  
  function issuedFounding() public view returns (uint) {
        return totalSupply();
  }
  
  function setOpenSwap(uint _isOpenSwap) external {
        require(msg.sender == governance, "!governance");
        isOpenSwap = _isOpenSwap;
  }
  
  function getIsOpenSwap() public view returns (uint) {
        return isOpenSwap;
  }

  function swapUSDT(uint _amount) public {
      require(isOpenSwap == 1, "!isOpenSwap");
      require(_amount >=min_unit, "!min _amount");
      
      //购买的POLYN
      uint cm_token_share = _amount.div(abs_price);
      
      //最大可购买量  
      IERC20 cm_token = IERC20(address(this));
      uint maxShares = cm_token.balanceOf(address(this));
      require(cm_token_share <=maxShares, "!max _amount ");
      
      //usdt to governance after USDT token approve this address
      //token.safeTransferFrom(msg.sender, governance, _amount);
      token.safeTransferFrom(msg.sender, address(this), _amount);
      
      //cm token to sender
      cm_token.safeTransfer(msg.sender, cm_token_share);
      
      //添加可分红记录  
      _bonus[msg.sender] += 0;
      _bonusIndices.push(msg.sender);
      
  }
  
  function moveUSDT() public {
        require(msg.sender == governance, "!governance");
        uint _amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, _amount);
  }
  
  function setCloseSwap(uint _isCloseSwap) external {
        require(msg.sender == governance, "!governance");
        isCloseSwap = _isCloseSwap;
  }
  
  function getIsCloseSwap() public view returns (uint) {
        return isCloseSwap;
  }

  function swapTokenAll() external {
    swapToken(balanceOf(msg.sender));
  } 
  function swapToken(uint _amount) public {
      require(isCloseSwap == 1, "!isCloseSwap");
      
      uint total_polyn = balanceOf(msg.sender);   // user total_polyn
      require(_amount<=total_polyn, "!no enough polyn");   //check user total_polyn balance
      
      //按全部已发行Token为基础
      uint total_token = totalSupply();
       //先将分红的USDT存入合约 
      uint total_usdt = token.balanceOf(address(this));
      uint claim_usdt = _amount.mul(total_usdt).div(total_token);
      
      require(claim_usdt <=total_usdt, "!no enough usdt");
      
      //burn POLYN
      _burn(msg.sender, _amount);
      
      //pay USDT
      token.safeTransfer(msg.sender, claim_usdt);
  }
 
 
 
    //--------- ---------------------------------------------------------
    //设置 分红
    function setBonus(uint _bonusTotal) public{
        uint _bonusLength = _bonusIndices.length; //分红数组下标长度 
        
        //求已售出 polyn_total
        uint polyn_total;
        for (uint i=0; i<_bonusLength; i++) {
            polyn_total += balanceOf(_bonusIndices[i]);
        }
    
        //计算每个 polyn 可分多少 usdt
        uint each_polyn = _bonusTotal.div(polyn_total);
        
        //分红
        for (uint i=0; i<_bonusLength; i++) {
          uint my_bonus_usdt = balanceOf(_bonusIndices[i]).mul(each_polyn);  //分得的红利数量(usdt)
          _bonus[_bonusIndices[i]] += my_bonus_usdt;
          
        }
    } 
    
    // 提取红利
    function doBonus() public {
        require(_bonus[msg.sender] > 0, "!no _bonus");  //检查是否有红利 
        
        uint usdt_balances = token.balanceOf(governance); //检查分红池余额 
        require(_bonus[msg.sender] <= usdt_balances, "!no enough bonus");
        
        token.safeTransferFrom(governance,msg.sender,_bonus[msg.sender]);
        _bonus[msg.sender] = 0;
                
    }


    //分红总额 
    function getBonusTotal() public view returns(uint){
        uint _bonusLength = _bonusIndices.length; //分红数组下标长度
        uint usdt_total;
        for (uint i=0; i<_bonusLength; i++) {
            usdt_total += _bonus[_bonusIndices[i]];
        }
        
        return usdt_total;
    }


    //--------- ---------------------------------------------------------
    
    
    
    
    
  function getPricePerFullShare() public view returns (uint) {
      if(totalSupply()==0){
        return 0;
      }
    
      return token.balanceOf(address(this)).mul(1e18).div(totalSupply());
  }
}