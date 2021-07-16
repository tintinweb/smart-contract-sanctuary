//SourceUnit: TokenY.tron.sol

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
   
    function totalSupply() external view returns (uint256); //total

    function balanceOf(address account) external view returns (uint256);// balanceOf(kia)
  
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
    
  
    address public Admin = 0x0EB89976bf47A5AF9596979FeAFDbF390C9BB700;  //TBK3bwWCzkfwj8KrMzNX2ag8gkzC7Qj5A9;  //default admin address   
    
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
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);                //approve  
        }
        else {
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);                    //approve  
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

 
interface IYToken {    
    function getLockXTokenAmount(address _user) external view returns (uint);     
    function getOut12HoursLastStakingUser() external view returns (address);
}


contract KisToken is TokenPay, IYToken {  
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
    
   
    constructor(address _admin) public {     
        _name = "Kis Token";
        _symbol = "Kis";
        _decimals = 6;                           

        Admin = _admin;
    }   

    address public DToken;   
    address public XToken;   

    function setDXToken(address _D, address _X) external onlyAdmin {
        DToken = _D;
        XToken = _X;
    }

    mapping(address => uint) public userXTokenTimeOf;           

    function getLockXTokenAmount(address _user) external view returns (uint) {
        return tokenUserAmountOf[XToken][_user];        
    }

    address public LastStakingUser = address(0);                
    uint    public LastStakingTime = 0;                       
    uint constant public StakingOutTime = 12 hours;             
   

    function getOut12HoursLastStakingUser() external view returns (address) {
        if (LastStakingUser != address(0) && LastStakingTime > 0 && LastStakingTime + (StakingOutTime) < block.timestamp) {
            return LastStakingUser;
        }
        return address(0);
    }

    event OnExchange(address indexed _user, uint _XAmount, uint _CBalance);

    function exchange(uint _XAmount, bool _IsSafeTransfer) external returns (bool) {
        updateYTokenAmount();

        require(_XAmount > 0, "require _amount > 0");
        require(_depositToken(XToken, _XAmount, _IsSafeTransfer), "_depositToken(XToken, _XAmount, _IsSafeTransfer");

        LastStakingUser = msg.sender;                                  
        LastStakingTime = block.timestamp;
         
        userXTokenTimeOf[msg.sender] = block.timestamp;               

        emit OnExchange(msg.sender, _XAmount, balanceOf(msg.sender));
        return true;
    }
  
    function depositDToken(uint _amount, bool _IsSafeTransfer) public lock returns (bool) {
        updateYTokenAmount();
        return _depositToken(DToken, _amount, _IsSafeTransfer);
    }

    function withdrawDTokenAll(bool _IsSafeTransfer) public lock returns (bool) {
        updateYTokenAmount();
        uint DTAmount = tokenUserAmountOf[DToken][msg.sender];
        return _withdrawToken(DToken, DTAmount, _IsSafeTransfer); 
    }

    function withdrawDToken(uint _amount, bool _IsSafeTransfer) public lock returns (bool) {
        updateYTokenAmount();
        return _withdrawToken(DToken, _amount, _IsSafeTransfer); 
    }

    function withdrawXTokenAll(bool _IsSafeTransfer) public lock returns (bool) {
        updateYTokenAmount();
        uint XTAmount = tokenUserAmountOf[XToken][msg.sender];
        return _withdrawToken(XToken, XTAmount, _IsSafeTransfer); 
    }

    function withdrawXToken(uint _amount, bool _IsSafeTransfer) public lock returns (bool) {
        updateYTokenAmount();
        return _withdrawToken(XToken, _amount, _IsSafeTransfer); 
    }

    function updateYTokenAmount() public {
        uint ca = getUserWaitingYTokenAmount(msg.sender);
        if (ca > 0) {
            _mint(msg.sender, ca);  
            userXTokenTimeOf[msg.sender] = block.timestamp;
        }
    }

    uint public KioAddSpeedTimes = 5;       //five times
        
    function getUserWaitingYTokenAmount(address _user) public view returns (uint) {
        uint XTAmount = tokenUserAmountOf[XToken][_user];
        uint DTAmount = tokenUserAmountOf[DToken][_user];
        if(userXTokenTimeOf[_user]  > 0 &&  XTAmount > 0) {
            uint time =  block.timestamp - userXTokenTimeOf[_user];
            uint ca = (XTAmount +  DTAmount * KioAddSpeedTimes) * time / (48 hours);    
            return ca;  
        }
        return 0;
    }


}