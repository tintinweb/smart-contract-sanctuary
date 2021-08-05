//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./Ownable.sol";

contract Mona__Token is IERC20, Context, Ownable {
    
    using SafeMath for uint;
    using Address for address;
 
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    
    uint public _totalSupply            = 250000 ether;
    uint256 public presaleTokens         = 18750 ether;
    uint256 public poolLisaTokens        = 78750 ether;
    uint256 public poolLisaEthTokens    = 140000 ether;
    uint256 public devMaxSuply           = 12500 ether;
    uint256 public devDailyFund             = 25 ether;
    
    uint256 public lastDevGetFounds = 0;
    uint256 public devGetFundsTimelock = 24 hours;
    
    address public presaleAccount;
    address public poolLisaAccount;
    address public poolLisaEthAccount;
    

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    
    constructor() {
        _symbol = "LISA";
        _name = "mona.finance";
        _decimals = 18;
        
        lastDevGetFounds = block.timestamp.add( devGetFundsTimelock );
        devMaxSuply = devMaxSuply.sub( devDailyFund ); 
        _balances[_owner] = devDailyFund;
        emit Transfer(address(0), _owner, devDailyFund);
    }

    receive() external payable {
        revert();
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
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

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public  onlyOwner{
        IERC20(tokenAddress).transfer(_owner, tokenAmount);
    }

    function registerPresale( address _presaleAccount ) public onlyOwner returns (bool) {
        require( presaleAccount == address(0), "registerPresale: has already been done");
        
        presaleAccount = _presaleAccount; 
        _balances[presaleAccount] = presaleTokens;
        
        emit Transfer(address(0), presaleAccount, presaleTokens);
        
        return true;
    }
    
    function registerFarmingPoolLisa( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolLisaAccount == address(0), "registerFarmingPoolLisa: has already been done");

        poolLisaAccount = _poolAccount; 
        _balances[poolLisaAccount] = poolLisaTokens;
        
        emit Transfer(address(0), poolLisaAccount, poolLisaTokens);
        
        return true;
    }
    function registerFarmingPoolLisaEth( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolLisaEthAccount == address(0), "registerFarmingPoolLisaEth: has already been done");
        
        poolLisaEthAccount = _poolAccount; 
        _balances[poolLisaEthAccount] = poolLisaEthTokens;
        
        emit Transfer(address(0), poolLisaEthAccount, poolLisaEthTokens);
        
        return true;
    }
    function getDevFunds() public onlyOwner returns (bool) {
        
        require(block.timestamp > lastDevGetFounds, '24h time lock');
        require(devMaxSuply > 0, 'dev funds is empty');
 
        lastDevGetFounds = block.timestamp.add( devGetFundsTimelock );
        devMaxSuply = devMaxSuply.sub( devDailyFund ); 
        
        _balances[_owner] = _balances[_owner].add( devDailyFund );
        
        emit Transfer(address(0), _owner, devDailyFund);
        
        return true;
        
    }
}
