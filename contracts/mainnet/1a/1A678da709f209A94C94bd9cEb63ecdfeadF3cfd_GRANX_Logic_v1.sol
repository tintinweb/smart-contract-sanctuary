/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity 0.5.0;
//import "./SafeMath.sol"; 0x9205C049C231DdA51bAce0ba569f047E3E1e9979
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
}

contract GRANX_Logic_v1 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint8 private isInit;
    address private admin;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;


    struct LockDetails{
        uint256 lockedTokencnt;
        uint256 releaseTime;
    }

    mapping(address => LockDetails) private Locked_list;
    mapping(address => mapping(bytes32 => string)) user_dataList;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event lockwallet(address account, uint256 amount,uint256 releaseTime);

    function token_mint(address account) public returns (bool){
        require(isInit == 0 , "Token already mint!");
        require(account != address(0), "ERC20: mint to the zero address");
        admin               = account;
        _name               = "GRANX CHAIN";
        _symbol             = "GRANX";
        _decimals           = 18;
        uint256 INIT_SUPPLY = 3000000000 * (10 ** uint256(_decimals));

        _totalSupply = INIT_SUPPLY;
        _balances[account] = INIT_SUPPLY;
        isInit = 1;
        emit Transfer(address(0), account, _totalSupply);
        return true;
    }

    //////////////////////////////////////// Mint handle //////////////////////////////////////////
    function Contadmin() public view returns (address) {return admin;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    //////////////////////////////////////// manager handle //////////////////////////////////////////



    //////////////////////////////////////// Lock token handle //////////////////////////////////////////
    function Lock_wallet(address _adr, uint256 lockamount,uint256 releaseTime ) public returns (bool) {
        require(_adr != address(0), "ERC20: transfer to the zero address");
        require(msg.sender== admin, "admin only function");
        require(releaseTime > block.timestamp , "Lock time must larger than now");
        require(lockamount >= _balances[_adr] , "Lock amount must bigger than balance");
        _Lock_wallet(_adr,lockamount,releaseTime);
        return true;
    }
    function _Lock_wallet(address account, uint256 amount,uint256 releaseTime) internal {
        LockDetails memory eaLock = Locked_list[account];
        if( eaLock.releaseTime > 0 ){
            eaLock.lockedTokencnt = amount;
            eaLock.releaseTime = releaseTime;
        }else{
            eaLock = LockDetails(amount, releaseTime);
        }
        Locked_list[account] = eaLock;
        emit lockwallet(account, amount, releaseTime);
    }

    function getwithdrawablemax(address account) public view returns (uint256) {
        return Locked_list[account].lockedTokencnt;
    }

    function getLocked_list(address account) public view returns (uint256) {
        return Locked_list[account].releaseTime;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 LockhasTime = Locked_list[sender].releaseTime;
        uint256 LockhasMax = Locked_list[sender].lockedTokencnt;
        if( block.timestamp < LockhasTime){
            uint256 OK1 = _balances[sender].sub(LockhasMax, "ERC20: transfer amount exceeds allowance");
            require( OK1 >= amount , "Your Wallet has time lock");
        }

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function burn(uint256 amount) public returns (bool) {
        require(msg.sender== admin, "admin only function");
        require(amount >= _balances[msg.sender] , "burn amount must bigger than balance");
        _burn(msg.sender, amount);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(msg.sender == admin, "Admin only can burn  8547");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //////////////////////////////////////// Lock token handle //////////////////////////////////////////

    function getStringData(bytes32 key) public view returns (string memory) {
        return user_dataList[msg.sender][key];
    }
    function setStringData(bytes32 key, string memory value) public {
        user_dataList[msg.sender][key] = value;
    }
}