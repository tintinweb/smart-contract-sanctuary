//SourceUnit: TokenX.Tron.sol

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

   
    uint public constant MaxAmount = 30_0000_0000 * (10 ** 9);
   
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


contract TokenPay is ERC20 {   
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

    event OnDeposit (address indexed _token, address indexed _user, uint _amount, uint _balance);
    event OnWithdraw(address indexed _token, address indexed _user, uint _amount, uint _balance);

    mapping (address => mapping (address => uint)) public tokenUserAmountOf;           

    function _depositToken(address _token,  uint _amount, bool _IsSafeTransfer) internal  returns (bool) {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(_amount > 0, "require _amount > 0");
        require(_token != address(0), "_token != address(0)");
        
        uint b1 = IERC20(_token).balanceOf(address(this));
        if (_IsSafeTransfer) {  
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);                //approve _approvedAmount 
        }
        else {
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);                    //approve _approvedAmount 
        }
        uint b2 = IERC20(_token).balanceOf(address(this));
        require(b1.add(_amount) == b2, "require b1.add(_amount) == b2");

        tokenUserAmountOf[_token][msg.sender] = tokenUserAmountOf[_token][msg.sender].add(_amount);
        emit OnDeposit(_token, msg.sender, _amount, tokenUserAmountOf[_token][msg.sender]);

        return true;
    }

    function _withdrawToken(address _token, uint _amount, bool _IsSafeTransfer) internal returns (bool) {
        require(_amount > 0);
        require (tokenUserAmountOf[_token][msg.sender] >= _amount);

        tokenUserAmountOf[_token][msg.sender] = tokenUserAmountOf[_token][msg.sender].sub(_amount);
        if (_IsSafeTransfer) {  
            IERC20(_token).safeTransfer(msg.sender, _amount);       
        }
        else {
            IERC20(_token).transfer(msg.sender, _amount);           
        }

        emit OnWithdraw(_token, msg.sender, _amount, tokenUserAmountOf[_token][msg.sender]);
        return true;
    } 

}


interface IDToken {
    function getLockATokenAmount(address _user) external view returns (uint);
}


interface IYToken {
    function getOut12HoursLastStakingUser() external returns (address);
}


contract KiaToken is TokenPay { 
     
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
                  
    constructor(address _admin, address _PayToken) public {     
        _name = "Kia Token";
        _symbol = "Kia";
        _decimals = 6;             

        Admin = _admin;
        PayToken = _PayToken;      
    }   


    address public PayToken;        //usdt 

    address public AToken;          //Kid,  
    address public DToken;          //Kit, Pool (AToken -> DToken)
    address public YToken;          //Kis, Pool (XToken -> YToken)

    address public Boss = 0xC842519F2c9781629Ef6b7001b64C975e7699109;   // TUE5bLb3yS7RY3DBgmNd21FQopk4CcdSBk 
    address public Dev  = 0x616ab434A6BC5586Fc01b4CF247872C0780de65E;   // TJrJNaumqBY8DYsPURBoULCWJ6nQdskCmp 

    function setADYToken(address _A, address _D, address _Y) external onlyAdmin {
        AToken = _A;
        DToken = _D;
        YToken = _Y;
    }

    uint constant PricePay2X = 200;                                 // 200 usdt => 1 XToken

    uint[] public RetrunPer100 = [30, 10, 5, 5, 5, 5, 5, 5, 5];      

    mapping(address => address) public buyerReferenceOf;          
    mapping(address => bool) public referenceIsOf;         

    event OnBuyToken(address indexed _user, address _reference, uint _PayTokenAmount, uint _XTokenAmount, uint _PayTokenToRef, uint _PayTokenToPrize, uint _PayTokenToPeople);

    function buyToken(uint _PayTokenAmount, address _reference, bool _IsSafeTransfer) external lock payable returns (bool) {
        uint XTokenAmount = _PayTokenAmount / PricePay2X;
        require(XTokenAmount >= 10**6, "XTokenAmount >= 10**6");

        _depositToken(PayToken, _PayTokenAmount, _IsSafeTransfer);

        if (buyerReferenceOf[msg.sender] == address(0) && _reference != address(0) && _reference != msg.sender) {
            if (!referenceIsOf[msg.sender]) {              
                buyerReferenceOf[msg.sender] = _reference;  
                referenceIsOf[_reference] = true;
            }            
        }

        require(tokenUserAmountOf[PayToken][msg.sender] >= _PayTokenAmount, "tokenUserAmountOf[PayToken][msg.sender] >= _PayTokenAmount");
        tokenUserAmountOf[PayToken][msg.sender] = tokenUserAmountOf[PayToken][msg.sender].sub(_PayTokenAmount);

        _mint(msg.sender, XTokenAmount);

        uint ToDev = _PayTokenAmount * 5 / uint(1000);           
        tokenUserAmountOf[PayToken][Dev] = tokenUserAmountOf[PayToken][Dev].add(ToDev);

        uint ToPrize = _PayTokenAmount / 5;
        tokenUserAmountOf[PayToken][address(this)] = tokenUserAmountOf[PayToken][address(this)].add(ToPrize);
       
        uint ToHigher = 0;
        address CurentUser = msg.sender;                                    
        for(uint i = 0; i < 9; i++) {
            address higher = buyerReferenceOf[CurentUser];                 
            if(higher != address(0)) {                
                uint ToH = RetrunPer100[i] * _PayTokenAmount / 100;
                tokenUserAmountOf[PayToken][higher] = tokenUserAmountOf[PayToken][higher].add(ToH);
                ToHigher = ToHigher + ToH;
                CurentUser = higher;                                     
            }
            else {
                break;
            }
        }

        uint ToBoss = _PayTokenAmount - ToHigher - ToPrize - ToDev;
        tokenUserAmountOf[PayToken][Boss] = tokenUserAmountOf[PayToken][Boss].add(ToBoss);

        emit OnBuyToken(msg.sender, buyerReferenceOf[msg.sender], _PayTokenAmount, XTokenAmount, ToHigher, ToPrize, ToBoss + ToDev);
        return true;
    }

    function depositDToken(uint _amount, bool _IsSafeTransfer) public lock returns (bool) {
        return _depositToken(DToken, _amount, _IsSafeTransfer);
    }

    event OnGetPayTokenFromA(address indexed _user, uint _ToUser, uint _YTAmount);

    function GetPayTokenFromY(bool _IsSafeTransfer) external lock {
        uint ToUser = tokenUserAmountOf[PayToken][address(this)] / 1000;
        uint YTAmount = 1e6;                                             //1 AToken
       
        address X2Y_User =  IYToken(YToken).getOut12HoursLastStakingUser();
        if (X2Y_User != address(0) && msg.sender == X2Y_User) {
            ToUser = tokenUserAmountOf[PayToken][address(this)];         //like fomo3d 
            YTAmount = 0;                                                //not AToken
        }
        else {
            // YToken Approve
            require(_depositToken(YToken,  YTAmount, _IsSafeTransfer), "_depositToken(YToken,  YTAmount, _IsSafeTransfer)");
        }

        tokenUserAmountOf[PayToken][address(this)] = tokenUserAmountOf[PayToken][address(this)].sub(ToUser);
        tokenUserAmountOf[PayToken][msg.sender] = tokenUserAmountOf[PayToken][msg.sender].add(ToUser);
        _withdrawToken(PayToken, tokenUserAmountOf[PayToken][msg.sender], _IsSafeTransfer);       
        emit OnGetPayTokenFromA(msg.sender, ToUser, YTAmount);
    }

    function withdrawTokenAll(address _token, bool _IsSafeTransfer) public lock returns (bool) {
        require(DToken != _token);                              
        uint _amount = tokenUserAmountOf[_token][msg.sender];
        return _withdrawToken(_token, _amount, _IsSafeTransfer); 
    }
    
    function withdrawToken(address _token, uint _amount, bool _IsSafeTransfer) public lock returns (bool) {
        require(DToken != _token);                             
        return _withdrawToken(_token, _amount, _IsSafeTransfer); 
    }


}