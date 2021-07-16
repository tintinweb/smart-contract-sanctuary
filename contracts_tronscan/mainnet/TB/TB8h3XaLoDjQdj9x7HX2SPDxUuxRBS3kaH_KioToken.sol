//SourceUnit: TokenD.tron.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;
// pragma solidity ^0.7.0;


contract Context {
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this;
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


    library SafeERC20 {
        using SafeMath for uint256;
        
        function isContract(address account) public view returns (bool) {
            uint256 size;
            assembly { size := extcodesize(account) }
            return size > 0;
        }

        function safeTransfer(IERC20 token, address to, uint256 value) internal {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }

        function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
            callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        }
    
        function callOptionalReturn(IERC20 token, bytes memory data) private {
            // require(address(token).isContract(), "SafeERC20: call to non-contract");
            require(isContract(address(token)), "SafeERC20: call to non-contract");
            (bool success, bytes memory returndata) = address(token).call(data);
            require(success, "SafeERC20: low-level call failed");
            if (returndata.length > 0) { // Return data is optional
                require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
            }
        }
    }


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



library Address {
      
        function isContract(address account) internal view returns (bool) {
            uint256 size;
            assembly { size := extcodesize(account) }
            return size > 0;
        }


        function sendValue(address payable recipient, uint256 amount) internal {
            require(address(this).balance >= amount, "Address: insufficient balance");

            // (bool success, ) = recipient.call{ value: amount }("");
            (bool success, ) = recipient.call.value(amount)("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }


        function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        }

        function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
            return functionCallWithValue(target, data, 0, errorMessage);
        }

        function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        }

       
        function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
            require(address(this).balance >= value, "Address: insufficient balance for call");
            require(isContract(target), "Address: call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            // (bool success, bytes memory returndata) = target.call{ value: value }(data);
            (bool success, bytes memory returndata) = target.call.value(value)(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }

       
        function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
            return functionStaticCall(target, data, "Address: low-level static call failed");
        }

    
        function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
            require(isContract(target), "Address: static call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.staticcall(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }

       
        function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
            return functionDelegateCall(target, data, "Address: low-level delegate call failed");
        }

     
        function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
            require(isContract(target), "Address: delegate call to non-contract");

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = target.delegatecall(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }

        function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
            if (success) {
                return returndata;
            } else {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly

                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert(errorMessage);
                }
            }
        }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
   
    function name() public view returns (string memory) {
        return _name;
    }
   
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public  view  returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public  view  returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }

  
    function approve(address spender, uint256 amount) public   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
   
    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    uint public constant MaxAmount = 6_0000_0000 * (10 ** 9);
   
    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        require(_totalSupply <= MaxAmount, "_totalSupply <= MaxAmount");

        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}


library PowerMath64x64 {

  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); 
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); 
    }
  }

  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; 
          require (re < 128); 
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; 
          require (xe < 128); 
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

}


interface IDToken {
    function getLockATokenAmount(address _user) external view returns (uint);
    function getOut24HoursLastStakingUser() external view returns (address);
}


contract KioToken is ERC20, IDToken {  
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
      
    bool private unlocked = true;           
    modifier lock() {
        require(unlocked == true, 'unlocked == true');
        unlocked = false;
        _;
        unlocked = true;
    }

    address public Admin = 0x0EB89976bf47A5AF9596979FeAFDbF390C9BB700;  //TBK3bwWCzkfwj8KrMzNX2ag8gkzC7Qj5A9;       

    modifier onlyAdmin {
        require(msg.sender == Admin);         
        _;                                   
    }
   
    constructor(address _admin) public {     
        _name = "KioToken";
        _symbol = "Kio";
        _decimals = 6;                        

        Admin = _admin;
    }   

    address public LastStakingUser = address(0);               
    uint    public LastStakingTime = 0;                       
    uint    public StakingOutTime = 1 days;

    function getOut24HoursLastStakingUser() external view returns (address) {
        if (LastStakingUser != address(0) && LastStakingTime > 0 && LastStakingTime + (StakingOutTime) < block.timestamp) {
            return LastStakingUser;
        }
        return address(0);
    }

    address public AToken;

    function setAToken(address _A) external onlyAdmin {
        AToken = _A;
    }

    mapping(address => uint) public userATokenAmoutOf;         
    mapping(address => uint) public userATokenTimeOf;           
    mapping(address => uint) public userATokenFirstTimeOf;         

    function getLockATokenAmount(address _user) external view returns (uint) {
        return userATokenAmoutOf[_user];
    }

    event OnExchange(address indexed _user, uint _AAmount, uint _DBalance);

    function exchange(uint _AAmount, bool _IsSafeTransfer) external returns (bool) {
        updateDTokenAmount();                                                       

        LastStakingTime = block.timestamp;
        LastStakingUser = msg.sender;

        require(_AAmount > 0, "require _AAmount > 0");
        uint b1 = IERC20(AToken).balanceOf(address(this));
        if (_IsSafeTransfer) {  
            IERC20(AToken).safeTransferFrom(msg.sender, address(this), _AAmount);   //approve  
        }
        else {
            IERC20(AToken).transferFrom(msg.sender, address(this), _AAmount);       //approve  
        }
        uint b2 = IERC20(AToken).balanceOf(address(this));
        require(b1.add(_AAmount) == b2, "require b1.add(_amount) == b2");
        
        userATokenAmoutOf[msg.sender]  = userATokenAmoutOf[msg.sender] +  _AAmount;
        userATokenTimeOf[msg.sender] = block.timestamp;                             //
        if (userATokenFirstTimeOf[msg.sender] == 0) {
            userATokenFirstTimeOf[msg.sender] = block.timestamp;
        }     

        emit OnExchange(msg.sender, _AAmount, balanceOf(msg.sender));
        return true;
    }

    function updateDTokenAmount() public {
        uint da = getUserWaitingDTokenAmount(msg.sender);
        if (da > 0) {
            _mint(msg.sender, da);  
            userATokenTimeOf[msg.sender] = block.timestamp; 
        }
    }

    uint public DownSpeed100 = 99;                   
    uint public DownDays = 5 days;                    
    // uint public DownDays = 1 minutes;                    //for test


    uint public constant Num64Max = 2**64;

    
    function calPow64(uint exp, uint den, uint num) public pure returns (int128) {
        int128 base = int128(den * Num64Max / num);
        int128 result = PowerMath64x64.pow(base, exp);               //64.64
        return result;
    }

    function getUserWaitingDTokenAmount(address _user) public view returns (uint) {
        if(userATokenTimeOf[_user]  > 0 &&  userATokenAmoutOf[_user] > 0) {
            uint FirstTimeStamp = userATokenFirstTimeOf[_user];
            uint LastTimeStamp = userATokenTimeOf[_user];
            uint amount =  userATokenAmoutOf[_user];
            if (FirstTimeStamp == 0 || LastTimeStamp == 0 || amount == 0) {
                return 0;
            }

            //1, block.timestamp - FirstTimeStamp 
            uint exp1 = (block.timestamp - FirstTimeStamp) / DownDays;
            if (exp1 == 0) {
                return ( block.timestamp .sub(LastTimeStamp) ) * amount / DownDays;
            }

            uint Qn64 = uint(calPow64(exp1, DownSpeed100, uint(100)));
            // uint Sn = amount * ( 1 - Qn) / (1 -Q);
            uint Sn1 = amount * (Num64Max.sub(Qn64)) * 100 / (100 - 99) / Num64Max;                  
            uint add1 = amount * (block.timestamp.sub(FirstTimeStamp).sub(exp1 * DownDays)) * Qn64 / DownDays / Num64Max; 
            Sn1 = Sn1 + add1;

            if (LastTimeStamp == FirstTimeStamp) {
                return Sn1;
            }
            require(LastTimeStamp > FirstTimeStamp);

            //2, LastTimeStamp - FirstTimeStamp 
            uint exp2 = (LastTimeStamp - FirstTimeStamp) / DownDays;
            // if (exp2 == 0) {
            //     return Sn1;
            // }
            Qn64 = uint(calPow64(exp2, DownSpeed100, uint(100)));
            // uint Sn = amount * ( 1 - Qn) / (1 -Q);
            uint Sn2 = amount * (Num64Max .sub(Qn64)) * 100 / (100 - 99) / Num64Max;
            uint add2 = amount * (LastTimeStamp .sub(FirstTimeStamp).sub(exp2 * DownDays)) * Qn64 /  DownDays / Num64Max;
            Sn2 = Sn2 + add2;         

            return Sn1 - Sn2;  
        }
        return 0;
    }

    // test function 
    
    function _testCalPow64(uint amount, uint exp, uint den, uint num) public pure returns (uint) {
        int128 p64 = calPow64(exp, den, num);
        return amount * uint(p64) / Num64Max;   
    }

    function _testGetUserWaitingDTokenAmount(address _user) public view returns (uint exp1, uint Sn1, uint add1) {
        if(userATokenTimeOf[_user]  > 0 &&  userATokenAmoutOf[_user] > 0) {
            uint FirstTimeStamp = userATokenFirstTimeOf[_user];
            uint LastTimeStamp = userATokenTimeOf[_user];
            uint amount =  userATokenAmoutOf[_user];
            if (FirstTimeStamp == 0 || LastTimeStamp == 0 || amount == 0) {
                return (0, 0, 0);
            }

            //1, block.timestamp - FirstTimeStamp 
            exp1 = (block.timestamp - FirstTimeStamp) / DownDays;
            if (exp1 == 0) {
                return (exp1, 0, ( block.timestamp .sub(LastTimeStamp) ) * amount / DownDays);
            }

            uint Qn64 = uint(calPow64(exp1, DownSpeed100, uint(100)));
            // uint Sn = amount * ( 1 - Qn) / (1 -Q);
            Sn1 = amount * (Num64Max.sub(Qn64)) * 100 / (100 - 99) / Num64Max;                 
            add1 = amount * (block.timestamp.sub(FirstTimeStamp).sub(exp1 * DownDays)) * Qn64 / DownDays / Num64Max; 

            return (exp1, Sn1, add1);         
        }

        return (0, 0, 0);
    }

   

}