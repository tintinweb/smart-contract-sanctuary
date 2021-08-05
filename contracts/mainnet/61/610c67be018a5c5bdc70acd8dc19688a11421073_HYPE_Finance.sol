/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-05
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function transferFromStake(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
     constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    uint256 ownerFee = 20; // 2%
    uint256 rewardMakerFee = 20; // 2% 
   address exemptWallet;
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        
         require(account != address(0), "ERC20: checking balanceOf from the zero address");
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        require(amount > 0, "amount should be > 0");
         require(recipient != address(0), "ERC20: recipient shoud not be the zero address");
         
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        require(owner != address(0), "ERC20: owner from the zero address");
        require(spender != address(0), "ERC20: spender to the zero address");
        
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        require(amount > 0, "amount should be > 0");
         require(spender != address(0), "ERC20: spender shoud not be the zero address");
         
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: recipient is set to the zero address");
        require(sender != address(0), "ERC20: sending to the zero address");
        require(amount > 0, "amount should be > 0");
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function transferFromStake(address sender, address recipient, uint amount) public override returns (bool) {
         require(recipient != address(0), "ERC20: recipient is set to the zero address");
        require(sender != address(0), "ERC20: sending to the zero address");
        
        
        _transferstake(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        require(addedValue > 0, "Value should be > 0");
        require(spender != address(0), "ERC20: increaseAllowance from the zero address");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "Value should be > 0");
        require(spender != address(0), "ERC20: decreaseAllowance from the zero address");
        
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function setExemptWallet(address wallet_) external onlyOwner returns (address){
        require(wallet_ != address(0), "ERC20: zero address cant be exempted");
        
        exemptWallet = wallet_;
        return exemptWallet;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        address mainOwner = 0x7BB705FD59D2bA9D236eF8506d3B981f097ABb24;
        address rewardMaker = 0x181b3a5c476fEecC97Cf7f31Ea51093f324B726f;
       
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        
       
        uint256 burntAmount1 = (onePercent(amount).mul(ownerFee)).div(10); 
        uint256 leftAfterBurn1 = amount.sub(burntAmount1);
   
        uint256 burntAmount2 = (onePercent(amount).mul(rewardMakerFee)).div(10); 
        uint256 leftAfterBurn2 = leftAfterBurn1.sub(burntAmount2);
        
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
        if(sender != exemptWallet && sender != owner && sender != mainOwner && sender != rewardMaker){
            
            _balances[recipient] = _balances[recipient].add(leftAfterBurn2);
    
            _balances[mainOwner] = _balances[mainOwner].add(burntAmount1);       
             _balances[rewardMaker] = _balances[rewardMaker].add(burntAmount2); 
             
             emit Transfer(sender, rewardMaker, burntAmount2);
            emit Transfer(sender, mainOwner, burntAmount1);
        }
        else {
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        
        emit Transfer(sender, recipient, amount);
    }
    
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    function _transferstake(address sender, address recipient, uint amount) internal {
      
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       
      
        
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

       
        emit Transfer(sender, recipient, amount);
    }
   
 
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
       
        emit Transfer(account, address(0), amount);
}
}
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        
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



library Address {
    function isContract(address _addr) internal view returns (bool){
      uint32 size;
      assembly {
        size := extcodesize(_addr)
      }
      return (size > 0);
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



contract HYPE_Finance is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  
  
  //address public owner;
  
  constructor () ERC20Detailed("HYPE-Finance", "HYPE", 18) {
      owner = msg.sender;
    _totalSupply = 10000 *(10**uint256(18));

    
	_balances[msg.sender] = _totalSupply;
  }
}