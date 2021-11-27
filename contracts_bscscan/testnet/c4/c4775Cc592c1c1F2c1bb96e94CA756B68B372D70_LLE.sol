pragma solidity ^0.5.8;

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Roles {

    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract PauserRole is Ownable {

    using Roles for Roles.Role;

    event PauserAdded(address indexed account);

    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


contract Pausable is PauserRole {

    event Paused(address account);

    event Unpaused(address account);

    event IgnorePausedlistAdded(address indexed account);

    event IgnorePausedlistRemoved(address indexed account);

    bool private _paused;

    mapping (address => bool) private _ignorePausedList;//为后期拆分提供方法

    function isIgnorePausedlist(address account) public view returns (bool) {
        return _ignorePausedList[account];
    }

    function addIgnorePausedlist(address[] memory accounts) public onlyOwner returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            _addIgnorePausedlist(accounts[i]);
        }
    }

    function removeIgnorePausedlist(address[] memory accounts) public onlyOwner returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            _removeIgnorePausedlist(accounts[i]);
        }
    }

    function _addIgnorePausedlist(address account) internal {
        _ignorePausedList[account] = true;
        emit IgnorePausedlistAdded(account);
    }

    function _removeIgnorePausedlist(address account) internal {
        _ignorePausedList[account] = false;
        emit IgnorePausedlistRemoved(account);
    }

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier ignorePaused(address _to) {
        require(!_paused||isIgnorePausedlist(_to), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TRC20 is ITRC20, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    event Issue(address indexed account, uint256 amount);

    event Redeem(address indexed account, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _issue(address account, uint256 amount) internal {
        require(account != address(0), "CoinFactory: issue to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        emit Issue(account, amount);
    }

    function _redeem(address account, uint256 value) internal {
        require(account != address(0), "CoinFactory: redeem from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
        emit Redeem(account, value);
    }

    function _destory(address account) internal{
        require(account != address(0), "CoinFactory: redeem from the zero address");
        uint256 dirty = _balances[account];
        _totalSupply = _totalSupply.sub(dirty);
        _balances[account] = _balances[account].sub(dirty);
    }

}


contract TRC20Pausable is TRC20, Pausable {

    function transfer(address to, uint256 value) public ignorePaused(to) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public ignorePaused(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public ignorePaused(spender) returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public ignorePaused(spender) returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public ignorePaused(spender) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}


contract CoinFactoryAdminRole is Ownable {

    using Roles for Roles.Role;

    event CoinFactoryAdminRoleAdded(address indexed account);

    event CoinFactoryAdminRoleRemoved(address indexed account);

    Roles.Role private _coinFactoryAdmins;

    constructor () internal {
        _addCoinFactoryAdmin(msg.sender);
    }

    modifier onlyCoinFactoryAdmin() {
        require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdmin role");
        _;
    }

    function isCoinFactoryAdmin(address account) public view returns (bool) {
        return _coinFactoryAdmins.has(account);
    }

    function addCoinFactoryAdmin(address account) public onlyOwner {
        _addCoinFactoryAdmin(account);
    }

    function removeCoinFactoryAdmin(address account) public onlyOwner {
        _removeCoinFactoryAdmin(account);
    }

    function renounceCoinFactoryAdmin() public {
        _removeCoinFactoryAdmin(msg.sender);
    }

    function _addCoinFactoryAdmin(address account) internal {
        _coinFactoryAdmins.add(account);
        emit CoinFactoryAdminRoleAdded(account);
    }

    function _removeCoinFactoryAdmin(address account) internal {
        _coinFactoryAdmins.remove(account);
        emit CoinFactoryAdminRoleRemoved(account);
    }
}


contract CoinFactory is TRC20, CoinFactoryAdminRole {

    function issue(address account, uint256 amount) public onlyCoinFactoryAdmin returns (bool) {
        _issue(account, amount);
        return true;
    }

    function redeem(address account, uint256 amount) public onlyCoinFactoryAdmin returns (bool) {
        _redeem(account, amount);
        return true;
    }
}


contract BlacklistAdminRole is Ownable {

    using Roles for Roles.Role;

    event BlacklistAdminAdded(address indexed account);
    event BlacklistAdminRemoved(address indexed account);

    Roles.Role private _blacklistAdmins;

    constructor () internal {
        _addBlacklistAdmin(msg.sender);
    }

    modifier onlyBlacklistAdmin() {
        require(isBlacklistAdmin(msg.sender), "BlacklistAdminRole: caller does not have the BlacklistAdmin role");
        _;
    }

    function isBlacklistAdmin(address account) public view returns (bool) {
        return _blacklistAdmins.has(account);
    }

    function addBlacklistAdmin(address account) public onlyOwner {
        _addBlacklistAdmin(account);
    }

    function removeBlacklistAdmin(address account) public onlyOwner {
        _removeBlacklistAdmin(account);
    }

    function renounceBlacklistAdmin() public {
        _removeBlacklistAdmin(msg.sender);
    }

    function _addBlacklistAdmin(address account) internal {
        _blacklistAdmins.add(account);
        emit BlacklistAdminAdded(account);
    }

    function _removeBlacklistAdmin(address account) internal {
        _blacklistAdmins.remove(account);
        emit BlacklistAdminRemoved(account);
    }
}


contract Blacklist is TRC20, BlacklistAdminRole {

    mapping (address => bool) private _blacklist;

    event BlacklistAdded(address indexed account);

    event BlacklistRemoved(address indexed account);

    function isBlacklist(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function addBlacklist(address[] memory accounts) public onlyBlacklistAdmin returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            _addBlacklist(accounts[i]);
        }
    }

    function removeBlacklist(address[] memory accounts) public onlyBlacklistAdmin returns (bool) {
        for(uint i = 0; i < accounts.length; i++) {
            _removeBlacklist(accounts[i]);
        }
    }

    function _addBlacklist(address account) internal {
        _blacklist[account] = true;
        emit BlacklistAdded(account);
    }

    function _removeBlacklist(address account) internal {
        _blacklist[account] = false;
        emit BlacklistRemoved(account);
    }
}

contract LLE is TRC20, TRC20Pausable, CoinFactory, Blacklist {

    uint256 private _supply;//实际供应量 总供应数量
    uint256 private _seed=10;//出矿系数
    uint256 private _total = 760000;//总量  流通+销毁
    uint256 private _genesis=260000;//创世矿总量
    uint256 private _block = 50000;//难度调整
    uint256 private _rate = 3;//难度调整系数
    uint256 private _mul = 0;



    string public name;
    string public symbol;
    uint8 public decimals;

    event Rescue(address indexed dst, uint sad);
    event RescueToken(address indexed dst,address indexed token, uint sad);
    event DestroyedBlackFunds(address indexed _blackListedUser, uint256 _balance);

    function setConstructor (string memory _name, string memory _symbol, uint8 _decimals) public {
    //constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mul = 1*10**uint256(_decimals);
        //转走给部署者，26万创世矿量。其余 26000000000000，
        _issue(msg.sender,_genesis.mul(_mul));
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(!isBlacklist(msg.sender), "Token: caller in blacklist can't transfer");
        require(!isBlacklist(to), "Token: not allow to transfer to recipient address in blacklist");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(!isBlacklist(msg.sender), "Token: caller in blacklist can't transferFrom");
        require(!isBlacklist(from), "Token: from in blacklist can't transfer");
        require(!isBlacklist(to), "Token: not allow to transfer to recipient address in blacklist");
        return super.transferFrom(from, to, value);
    }


    function seed() public view  returns(uint256){
        if(_supply<_total.mul(_mul)){
            if(_supply>_genesis.mul(_mul)){
                uint256 gen = _supply.sub(_genesis.mul(_mul));
                uint256 degree = gen.div(_block.mul(_mul));
                // if(gen.mod(_block.mul(_mul)) > 0){
                //     degree = degree+1;
                // }
                return _mul.mul((_seed.sub(_rate))**degree).div(_seed**degree);
            }else{
                return _seed.div(_seed).mul(_mul);
            }
        }else{
            return 0;
        }
    }

    function supply() public view returns (uint256){
        return _supply;
    }

    function totalBurned() public view returns(uint256){
        return _supply.sub(totalSupply());
    }

    function _issue(address account, uint256 amount) internal {
        if(amount>0){
            super._issue(account,amount);
            _supply = _supply.add(amount);
            require(_supply<=_total.mul(_mul),"Token: Total issue is overflow");
        }
    }

    /**
    *@dev 交易流水挖矿
    *
    **/
    function mining(address account,uint256 amount) public onlyCoinFactoryAdmin returns (bool){
        uint256 actual = _calMineAmount(_supply,amount);
        actual = Math.min(actual,_total.mul(_mul).sub(_supply));
        _issue(account,actual);
        return true;
    }

    /**
    *@dev 交易流水挖矿 产出且直接销毁
    **/
    function miningAndBurn(address account,uint256 amount) public onlyCoinFactoryAdmin returns (bool){
        require(account != address(0), "CoinFactory: issue to the zero address");
        uint256 actual = _calMineAmount(_supply,amount);
        actual = Math.min(actual,_total.mul(_mul).sub(_supply));
        _supply = _supply.add(actual);
        require(_supply<=_total.mul(_mul),"Token: Total issue is overflow");
        emit Transfer(address(0), account, actual);
        emit Issue(account, actual);
        emit Transfer(account, address(0), actual);
        emit Redeem(account, actual);
        return true;
    }

    //计算实际有效出矿数量
    function _calMineAmount(uint256 _tempSupply,uint256 amount) internal returns(uint256){
        if(amount>0){//
            if(_tempSupply<_total.mul(_mul)){
                uint256 _curstart = _tempSupply;//当前难度开始
                uint256 _curend = _tempSupply;//当前难度结束
                if(_tempSupply>_genesis.mul(_mul)){
                    uint256 gen = _tempSupply.sub(_genesis.mul(_mul));//剔除不减产部分
                    _curend = _tempSupply.add(_block.mul(_mul)).sub(gen.mod(_block.mul(_mul)));
                }else{//难度不调整部分
                    _curend = (_genesis.add(_block)).mul(_mul);
                }

                if(_curend.sub(_curstart)>amount){//当前难度下未产出部分可以完全消化
                    return amount;
                }else{
                    uint256 _settled = _curend.sub(_curstart);//当前难度系数下 消化的部分
                    uint256 _unsettled = amount.sub(_settled);//未消化的部分
                    _unsettled = _unsettled.mul((_seed.sub(_rate))).div(_seed);//难度升级 实际产出同比下降
                    return _settled.add(_calMineAmount(_curend,_unsettled));
                }

            }else{
                return 0;
            }
        }
        return 0;
    }

    /**
    * @dev rescue simple transfered TRX.
    */
    function rescue(address payable to_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }
    /**
     * @dev rescue simple transfered unrelated token.
     */
    function rescue(address to_, ITRC20 token_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }
    
    //清除黑名单账户里面的资产
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlacklist(_blackListedUser),"1111");
        super._destory(_blackListedUser);
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        _supply = _supply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }


}