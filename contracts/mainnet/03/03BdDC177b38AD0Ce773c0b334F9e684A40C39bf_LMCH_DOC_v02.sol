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

contract LMCH_DOC_v02 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private admin;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    string private last_useVersion;

    struct LockDetails{
        uint256 lockedTokencnt;
        uint256 releaseTime;
    }
    struct managerDetail{
        string managername;
        uint8 managerlevel;
    }
    mapping(address => LockDetails) private Locked_list;
    address[] private managerList;
    mapping(address => managerDetail) private Managers;
    mapping(address => mapping(bytes32 => string)) user_dataList;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    //////////////////////////////////////// Mint handle //////////////////////////////////////////


    function Contadmin() public view returns (address) {return admin;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function getlast_useVersion() public view returns (string memory) {return last_useVersion;}
    function decimals() public view returns (uint8) {return _decimals;}
    //////////////////////////////////////// manager handle //////////////////////////////////////////
    function admin_Add_manager(address adr, string memory mname, uint8 mlevel) public returns (bool) {
        managerDetail memory isManager = Managers[msg.sender];
        require( msg.sender == admin, "This is manager only");
        isManager = Managers[adr];
        bytes memory a1 = bytes(isManager.managername);
        bytes memory a2 = bytes("del");
        if(keccak256(a1) == keccak256(a2)) {
            isManager.managername = mname;
            isManager.managerlevel = mlevel;
        }else if( isManager.managerlevel != 0 ){
            isManager.managername = mname;
            isManager.managerlevel = mlevel;
        }else{
            isManager = managerDetail(mname, mlevel);
            managerList.push(adr);
        }
        Managers[adr] = isManager;
        return true;
    }
    function get_nth_adr_manager(uint256 nth) public view returns (address) {
        //managerDetail memory isManager = Managers[msg.sender];
        //require( isManager.managerlevel > 14, "This is manager level over 15 only ecode-02");
        require( nth > 0 && nth <= managerList.length,"outofrange");
        return managerList[nth];
    }
    function remove_manager( address adr) public returns (bool) {
        require( admin != adr, "contract creater cannot be deleted");
        managerDetail memory isManager = Managers[msg.sender];
        require( isManager.managerlevel > 14, "This is manager level over 15 only ecode-03");
        isManager = managerDetail("del", 0);
        Managers[adr] = isManager;
        return true;
    }

    function get_count_manager() public view returns (uint256) {
        //managerDetail memory isManager = Managers[msg.sender];
        //require( isManager.managerlevel > 14, "This is manager level over 15 only ecode-04");
        return managerList.length;
    }
    function get_managername(address adr) public view returns (string memory) {
        //managerDetail memory isManager = Managers[msg.sender];
        //require( isManager.managerlevel > 14, "This is manager level over 15 only ecode-05");
        managerDetail memory isManager = Managers[adr];
        return isManager.managername;
    }

    function get_managerLevel(address adr) public view returns (uint8) {
        managerDetail memory isManager = Managers[msg.sender];
        //require( isManager.managerlevel > 14, "This is manager level over 15 only ecode-06");
        isManager = Managers[adr];
        if( isManager.managerlevel > 0 ){
            return isManager.managerlevel;
        }else{
            return 0;
        }
    }

    //////////////////////////////////////// Lock token handle //////////////////////////////////////////
    function Lock_wallet(address _adr, uint256 lockamount,uint256 releaseTime ) public returns (bool) {
        require(Managers[msg.sender].managerlevel > 9 , "Latam Manager only");
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
    }
    function admin_TransLock(address recipient, uint256 amount,uint256 releaseTime) public returns (bool) {
        require(Managers[msg.sender].managerlevel > 9 , "Latam Manager only");
        require(recipient != address(0), "ERC20: transfer to the zero address");
         _Lock_wallet(recipient,amount,releaseTime);
        _transfer(msg.sender, recipient, amount);
        return true;
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
        last_useVersion = "Ver 1";
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 LockhasTime = Locked_list[sender].releaseTime;
        uint256 LockhasMax = Locked_list[sender].lockedTokencnt;
        if( block.timestamp < LockhasTime){
            //uint256 OK1 = _balances[sender] - LockhasMax;
            uint256 OK1 = _balances[sender].sub(LockhasMax, "ERC20: the amount to unlock is bigger then locked token count");
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
        _burn(msg.sender, amount);
    }
    function burnFrom(address account, uint256 amount) public returns (bool) {
        _burnFrom(account, amount);
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
    function _burnFrom(address account, uint256 amount) internal {
        //_approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
        _burn(account, amount);
    }

    //////////////////////////////////////// Lock token handle //////////////////////////////////////////

    function getStringData(bytes32 key) public view returns (string memory) {
        return user_dataList[msg.sender][key];
    }
    function setStringData(bytes32 key, string memory value) public {
        user_dataList[msg.sender][key] = value;
    }

}