/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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
    constructor () public { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
   
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
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
    function _transfer(address sender, address recipient, uint amount) public {
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

    constructor (string memory name, string memory symbol, uint8 decimals) public{
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



contract GOLDT is ERC20, ERC20Detailed
{
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;
  
  
  address public ownership;

  constructor () ERC20Detailed("Gold Token", "GOLDT", 18) public{
      ownership = msg.sender;
    _totalSupply = 1000000000 * (10**uint256(18)) ;
	_balances[ownership] = _totalSupply;
  }
}


contract tokenSale is Ownable{
     
    using SafeMath for uint256;

  // The token being sold
    ERC20 public token;
    address public _owner = msg.sender;
    address payable wallet;
    address[] tokenHolders;
    constructor(ERC20 _token) public
    {
         
         require(address(_token) != address(0));

    
    wallet = 0x122bA888fa8DaACd03722D6E8E81Fd0aEE163091;
    token = _token;
    }
    fallback () payable external{
        buy(msg.sender);
    }
    
    receive() payable external {
        buy(msg.sender);
    }
    uint256 public weiUSD;
   
    uint256 public amountOfTokens;
    
    
    function _forwardFunds(uint256 _wei) internal 
    {
        wallet.transfer(_wei);
    }
    
    function buy(address beneficiary) payable  public
    {
        require(msg.value >= 0," No value transfered");
      
       
        uint256 unitPrice = msg.value;
        
        amountOfTokens =  unitPrice; //1 GoldT token
        
        _forwardFunds(msg.value);
        uint256 twoPercent = calculateTwoPercent(amountOfTokens);

        token.transfer(beneficiary, (amountOfTokens + twoPercent));
    
    } 
  
    function calculateTwoPercent(uint256 _amountOfTokens) internal returns (uint256)
    {
         uint256 _twoPercent = 2 * _amountOfTokens / 100 ;
         return _twoPercent;
    }
    
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
  
    function getGoldCoin(address _beneficiary, uint256 numberCoin) public returns(string memory)
    {
      require(_beneficiary != address(0), "It should be real address" );
      require(token.balanceOf(_beneficiary) >= (1 * (10**18)) + (5 * (10 ** 16)), "You should have atleast 1.1 GOLDT in your wallet"); 
      if(token.balanceOf(_beneficiary) >= numberCoin * ((1 * (10**18)) + (5 * (10 ** 16))))
      {
          token._transfer(_beneficiary, wallet, (numberCoin * 5*(10**16)));
        
          token._transfer(_beneficiary, burnAddress, numberCoin * 1 * (10**18));
          
          tokenHolders.push(_beneficiary);
       
          return "Hurrah !! You can claim your Gold Coin.";
           
      }
      else
      {
          return "Alert !! You should have atleast 1.05 GOLDT tokens to claim a real Gold Coin.";
      }
      
    }

  
    function claimCoin(address claimer) public returns (bytes memory)
    {
        require(claimer != address(0),"It should be a real address");
        for(uint256 a= 0 ; a<= tokenHolders.length; a++)
        {
            if(tokenHolders[a] == claimer)
            {
            return 'Congratulations!! You will be rewarded with a physical gold coin. Please connect with us to get your reward.';
            break;
            }
           
        }
        
      
    }
    function getHolders() public onlyOwner returns(address[] memory)
    {
        return tokenHolders;
    }
    
   
}