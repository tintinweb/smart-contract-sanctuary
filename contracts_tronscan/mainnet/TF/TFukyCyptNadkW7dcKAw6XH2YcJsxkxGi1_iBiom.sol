//SourceUnit: Context.sol

pragma solidity ^0.6.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITRC20 {
    
     function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function destroyBlackFunds(address) external;
    
    function removeBlackList(address) external;
    
    function addBlackList(address) external;
    
    function getBlackListStatus(address) external view returns(bool);
    
    function burn(uint256) external returns(bool);
    
    function mint(uint256) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: iBiom.sol

pragma solidity ^0.6.0;

import "./ITRC20.sol";
import "./Context.sol";


contract iBiom is Context, ITRC20 {
    mapping (address => uint256) private _balances;
    mapping (address => bool) public isBlackListed;
    mapping (address => mapping (address => uint256)) private _allowances;

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    uint256 private _totalSupply = 1000000000;

    string private _name = "iBiom";
    string private _symbol = "iBiom";
    address owner;
    bool public pause = false;
    
    constructor(address _owner)public{
        owner = _owner;
        _balances[_owner] = _totalSupply;
    }

    function togglePause()public returns(bool){
        if(pause == false){
            pause = true;
            return(true);
        }else{
            pause = false;
            return(true);
        }
    }
    function changeOwner(address _newOwner)public returns(bool){
        require(msg.sender == owner);
        owner = _newOwner;
        return(true);
    }
  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

     function mint(uint256 _amount)public override returns(bool){
         require(msg.sender == owner);
         _mint(msg.sender, _amount);
         return(true);
     }
     
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

     
    function burn(uint256 _amount)public override returns(bool){
        require(msg.sender == owner);
         _burn(msg.sender, _amount);
         return(true);
     }
     
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function getBlackListStatus(address _maker) public view override returns (bool) {
        return isBlackListed[_maker];
    }
    
    function addBlackList (address _evilUser) public override {
        require(msg.sender == owner);
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public override {
        require(msg.sender == owner);
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public override {
        require(msg.sender == owner);
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
       emit  DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
    
    
}