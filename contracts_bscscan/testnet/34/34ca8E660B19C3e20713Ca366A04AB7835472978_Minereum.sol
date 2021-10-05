/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
    
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event BuyToken(address indexed user, uint256 amount);
    event SellToken(address indexed user, uint256 amount);
    event Registration(address indexed user, address indexed referrer, uint256 amount);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


contract Ownable {
    address public owner;

    function Ownables() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract BasicToken is Ownable, ERC20Interface {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
   
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

}

contract BlackList is Ownable, BasicToken {
    
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

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


contract Minereum is ERC20Interface, Pausable, BlackList {

    using SafeMath for uint256;
    using Roles for Roles.Role;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => uint256) freezeAccount;
    
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
    
    mapping (address => uint256) public freezeList;
    
     // triggered when the total supply is decreased
    event Destruction(uint256 _amount);
    event FeeChange (uint256 fixedFee, uint256 minVariableFee, uint256 maxVariableFee, uint256 variableFeeNumerator);

    constructor() public {
        symbol = "MNM";
        name = "Minereum";
        decimals = 8;
        owner = msg.sender;
        _addMinter(msg.sender);
        _totalSupply = 100000000;
        balances[owner] = balances[owner].add(_totalSupply);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }


    function freeze(address freezeAddress) public onlyOwner returns (bool done)
    {
        freezeList[freezeAddress]=1;
        return isFreeze(freezeAddress);
        }

    function unFreeze(address freezeAddress) public onlyOwner returns (bool done)
    {
        delete freezeList[freezeAddress];
        return !isFreeze(freezeAddress); 
    }

    function isFreeze(address freezeAddress) public view returns (bool isFreezed) 
    {
        return freezeList[freezeAddress]==1;
    }
    

    function totalSupply() public view returns (uint) {
        return _totalSupply ;
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
         require(!isBlackListed[msg.sender]);
         require(!isFreeze(msg.sender));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function withdraw() external onlyOwner{
        require(msg.sender.send(address(this).balance));
    }
    

    function approve(address spender, uint tokens) public  whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
         require(!isBlackListed[msg.sender]);
         require(!isFreeze(msg.sender));
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        balances[to] = balances[to].add(tokens);
        
        emit Transfer(from, to, tokens);
        return true;
    }
    
    

     function reclaimToken(address _fromAddress, address _toAddress) public onlyOwner {
        uint256 balance = balanceOf(_fromAddress);
        balances[_fromAddress] = balances[_fromAddress].sub(balance);
        balances[_toAddress] = balances[_toAddress].add(balance);
        emit Transfer(_fromAddress, _toAddress, balance);
    }

    function allowance(address tokenOwner, address spender) public whenNotPaused view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function mint(address account, uint256 amount) public whenNotPaused onlyOwner{
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function burn(address account, uint256 value) public whenNotPaused onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function DestroyToken(address account, uint256 value) public whenNotPaused onlyOwner{
        require(account != address(0), "ERC20: Destroy from the zero address");

        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

  
  function buyToken() external payable{
        require(msg.value > 0, "Ener valid amount");
        emit BuyToken(msg.sender, msg.value);
    }
    
    
    function sellToken(uint256 amount) external payable{
        require(amount > 0, "Ener valid amount");
        require(balanceOf(msg.sender) > balanceOf(msg.sender) - amount, "ERC20: transfer amount exceeds balance");
         transfer(owner, amount);
        emit SellToken(msg.sender, amount);
    
    }
    
    function registrationExt(address referrerAddress) external payable{
        require(msg.value > 0, "Ener valid amount");
        emit Registration(msg.sender, referrerAddress, msg.value);
    }


    function() external payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    

    function hold (address _userAddress, uint _freezeValue) public whenNotPaused onlyOwner returns (bool) {
        require(_userAddress != address(0));
        require(_freezeValue > 0);
        freezeAccount[_userAddress] = _freezeValue;
        balances[_userAddress] = balances[_userAddress].sub(_freezeValue);
        return true;
    }
    
    function unhold (address _userAddress, uint _unFreezeValue) public whenNotPaused onlyOwner returns (bool) {
        require(freezeAccount[_userAddress]>= _unFreezeValue);
        freezeAccount[_userAddress] -= _unFreezeValue;
        balances[_userAddress] = balances[_userAddress].add(_unFreezeValue);
        return true;
    }
    
    function getHold_amount (address _userAddress) public view returns(uint){
        return freezeAccount[_userAddress];
    }
    
}