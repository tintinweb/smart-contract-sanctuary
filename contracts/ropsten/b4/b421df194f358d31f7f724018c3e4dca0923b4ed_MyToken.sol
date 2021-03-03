/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.4.26;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage); return a % b;
    }
}

library Address {
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(target));
        return functionCall(target, data);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory){
        require(isContract(target));
        return functionCallWithValue(target, data, value);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory){
        require(isContract(target));
        return functionStaticCall(target, data);
    }
}

contract Ownable {
    
    address public owner;
    address public newOwner;
    
    constructor () internal {owner = msg.sender;}

    modifier onlyOwner {require(msg.sender == owner);_;}
    
    function transferOwnership(address _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

contract Destructible is Ownable {}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name; _symbol = symbol; _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ERC20 is IERC20, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public totalSupply;

    function totalSupply() public view returns (uint256) {
        return totalSupply;
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

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));}
}

library Roles {
    
    struct Role {mapping (address => bool) bearer;}

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

contract MinterRole is Ownable {
    
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private minters;
    
    mapping (address => bool) public _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }
    
    function addMinter(address _minter) internal {
      _minters[_minter] = true;
    }
    
    function removeMinter(address _minter) internal {
      _minters[_minter] = false;
    }

    function isMinter(address account) public view returns (bool) {
        return minters.has(account);
    }
}

contract ERC20Mintable is ERC20, MinterRole {
    
    uint256 public mintingStartTime;
    function mint() public returns (bool);
    function annualPercentage() internal view returns (uint256);
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        mint(account, amount);
        return true;
    }
}

contract MyToken is ERC20, ERC20Detailed, ERC20Mintable {
    using SafeMath for uint256;
    using Address for address;
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    uint256 public totalInitialSupply;
    uint256 public maximumSupply = 50000000e18;
    uint256 public presaleSupply = 3000000e18;
    
    uint public mintingStartTime;
    uint public chainStartTime; //Chain Start Time
    uint public chainStartBlockNumber; //Chain start block number

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

    constructor() ERC20Detailed ("MyToken","TKN",18) public {
       totalInitialSupply = 2000000e18;
        _balances[msg.sender] = totalInitialSupply;
        mintingStartTime = now + 5 days;
        chainStartTime = now;
        chainStartBlockNumber = block.number;
    }

//--------------------------------------------------------------------------------------
//Minting
//--------------------------------------------------------------------------------------
    
    uint public basePercentage = 9125; //Default percentage rate 91.25%
    uint constant public rewardInterval = 365 days;

    address ContractOwner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeBasePercentage (uint256);
    
    mapping(address => uint256) _balances;
    
    bool public minting = true;
    
    modifier onlyMinter() {
        require(msg.sender == owner);
        require(_balances[msg.sender] > 0);
        require(totalSupply <= maximumSupply);
        _;}
    
    function transfer(address _to) external returns (bool) {
        if(msg.sender == _to) return mint();
        require(msg.sender == owner);
        require(_minters[msg.sender], "!minter");
        require(minting == true);
        return true;
    }

    function mint() public onlyMinter returns (bool) {
        require(msg.sender == owner);
        require(_minters[msg.sender], "!minter");
        require(minting == true);
        require(totalSupply <= maximumSupply);
        if(msg.sender == ContractOwner) revert();
        if(_balances[msg.sender] <= 0) revert();
        if(reward <= 0) return false;
        uint reward = getMintingReward(); reward == maximumSupply;
        totalSupply = totalInitialSupply.add(reward);
        _balances[msg.sender] = _balances[msg.sender].add(reward);
        return super.mint(msg.sender, reward);
        emit Transfer(address(0), msg.sender, reward);
    }
    
    function annualPercentage() internal view returns (uint percentage) {
        uint _now = now;
        percentage = basePercentage;
        if((_now.sub(mintingStartTime)) == 0){
            //1st years : 1825%
            percentage = percentage.mul(20);
        } else if((_now.sub(mintingStartTime)) == 1){
            //2nd years percentage : 1460%
            percentage = percentage.mul(16);
        } else if((_now.sub(mintingStartTime)) == 2){
            //3rd years percentage : 1095%
            percentage = percentage.mul(12);
        } else if((_now.sub(mintingStartTime)) == 3){
            //4th years percentage : 730%
            percentage = percentage.mul(8);
        } else if((_now.sub(mintingStartTime)) == 4){
            //5th years percentage : 365%
            percentage = percentage.mul(4);
        } else if((_now.sub(mintingStartTime)) == 5){
            //6th years percentage : 182.5%
            percentage = percentage.mul(2);
        }
    }
    
    function getMintingReward() internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now;
        uint percentage = basePercentage;
        uint minter = _balances[msg.sender];
        if((_now.sub(mintingStartTime)) == 0){
            //1st years : 1825%
            percentage = percentage.mul(20);
        } else if((_now.sub(mintingStartTime)) == 1){
            //2nd years percentage : 1460%
            percentage = percentage.mul(16);
        } else if((_now.sub(mintingStartTime)) == 2){
            //3rd years percentage : 1095%
            percentage = percentage.mul(12);
        } else if((_now.sub(mintingStartTime)) == 3){
            //4th years percentage : 730%
            percentage = percentage.mul(8);
        } else if((_now.sub(mintingStartTime)) == 4){
            //5th years percentage : 365%
            percentage = percentage.mul(4);
        } else if((_now.sub(mintingStartTime)) == 5){
            //6th years percentage : 182.5%
            percentage = percentage.mul(2);
        }
        return minter.mul(percentage).div(rewardInterval).div(1e4);
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function changeBasePercentage(uint256 _basePercentage) public onlyOwner {
        basePercentage = _basePercentage;
        emit ChangeBasePercentage(basePercentage);
    }
    //Dev set stake start time
    //Public minting will be set after presale is close
    function SetMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }
    
//--------------------------------------------------------------------------------------
//Change Maxixum Supply,  and Burn Supply
//--------------------------------------------------------------------------------------

    event ChangeMaximumSupply (uint256);
    
    function changeMaximumSupply(uint256 _maximumSupply) public onlyOwner {
        maximumSupply = _maximumSupply;
        emit ChangeMaximumSupply(maximumSupply);
    }
    
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function mintSupply(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply <= maximumSupply);
        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------

    event ChangeRate(uint256 _value);
    event Purchase(address indexed purchaser, uint256 value);
    
    bool public closed;
    
    uint public rate = 1000; //1 ETH = 1000 ETHC
    uint public startDate = now;
    uint public constant EthMin = 0.001 ether; //Minimum purchase
    uint public constant EthMax = 50 ether; //Maximum purchase

    function () external payable {
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= EthMin, "Sender cannot sent less than minimum");
        require(msg.value <= EthMax, "Sender cannot sent exceed than maximum");
        uint amountOfPurchase; amountOfPurchase = msg.value * rate;
        owner.transfer(msg.value);
        _balances[msg.sender] = _balances[msg.sender].add(amountOfPurchase);
        totalSupply = totalInitialSupply + _balances[msg.sender];
        presaleSupply = presaleSupply - _balances[msg.sender];
        require(amountOfPurchase <= presaleSupply);
        emit Transfer(address(0), msg.sender, amountOfPurchase);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        emit ChangeRate(rate);
    }
}