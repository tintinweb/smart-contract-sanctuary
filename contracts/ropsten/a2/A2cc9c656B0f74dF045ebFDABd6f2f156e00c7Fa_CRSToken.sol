/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity 0.5.12;

//---------------------------------- Define Ownable
contract Ownable {
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }
    function getOwner() public view returns(address){
        return owner;
    }
}
//---------------------------------- Define Pausable
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool private paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() onlyOwner whenNotPaused public returns(bool){
        paused = true;
        emit Pause();
        return true;
    }
    function unpause() onlyOwner whenPaused public returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}
//---------------------------------- ERC20Basic
contract ERC20Basic {
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
//---------------------------------- BasicToken
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
//---------------------------------- Define BlackList
contract BlackList is Ownable {
    function getBlackListStatus(address _userAddress) external view returns (bool) {
        return CRS_BLACK_LIST[_userAddress];
    }
    mapping (address => bool) internal CRS_BLACK_LIST;
    function addBlackList (address _exceptedUser) public onlyOwner {
        CRS_BLACK_LIST[_exceptedUser] = true;
        emit AddedBlackList(_exceptedUser);
    }
    function removeBlackList (address _whiteUser) public onlyOwner {
        CRS_BLACK_LIST[_whiteUser] = false;
        emit RemovedBlackList(_whiteUser);
    }
    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
}
//---------------------------------- Define Migrations
contract Migrations {
    address private owner;
    uint public last_completed_migration;
    modifier limited() {
        if (msg.sender == owner) _;
    }
    constructor() public {
        owner = msg.sender;
    }
    function setCompleted(uint completed) public limited {
        last_completed_migration = completed;
    }
    function upgrade(address newAddress) public limited {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
    function getOwner() public view returns (address){
        return owner;
    }
}
//---------------------------------- Define ERC20
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
//---------------------------------- Define STD_TOKEN
contract STD_TOKEN is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    function plus_Approval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function minus_Approval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}
//---------------------------------- Define STD_TOKEN_WithFees
contract STD_TOKEN_WithFees is STD_TOKEN, Ownable {
    uint256 internal pointsCount = 0;
    uint256 internal txFee = 0;
    uint256 constant internal MAX_DEFINED_POINTS = 20;
    uint256 constant internal MAX_DEFINED_FEE = 50;
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    uint internal _totalSupply;
    uint internal constant MAX_UINT = 2**256 - 1;
    function getFeeNow(uint _value) public view returns (uint) {
        uint fee = (_value.mul(pointsCount)).div(10000);
        if (fee > txFee) {
            fee = txFee;
        }
        return fee;
    }
    function transfer(address _to, uint _value) public returns (bool) {
        uint fee = getFeeNow(_value);
        uint sendAmount = _value.sub(fee);
        super.transfer(_to, sendAmount);
        if (fee > 0) {
            super.transfer(getOwner(), fee);
        }
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        uint fee = getFeeNow(_value);
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (allowed[_from][msg.sender] < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, sendAmount);
        if (fee > 0) {
          balances[getOwner()] = balances[getOwner()].add(fee);
          emit Transfer(_from, getOwner(), fee);
        }
        return true;
    }
    function set_Contract_Vars(uint newPoints, uint newTxFee) public onlyOwner {
        require(newPoints < MAX_DEFINED_POINTS);
        require(newTxFee < MAX_DEFINED_FEE);
        pointsCount = newPoints;
        txFee = newTxFee.mul(uint(10)**decimals);
        emit contract_Vars_Changed(pointsCount, txFee);
    }
    function get_MAX_DEFINED_POINTS() public pure returns(uint256){
        return MAX_DEFINED_POINTS;
    }
    function get_MAX_DEFINED_FEE() public pure returns(uint256){
        return MAX_DEFINED_FEE;
    }
    function get_name() public view returns(string memory){
        return name;
    }
    function get_symbol() public view returns(string memory){
        return symbol;
    }
    function get_decimals() public view returns(uint256){
        return decimals;
    }
    function get_MAX_UINT() public pure returns(uint256){
        return MAX_UINT;
    }
    event contract_Vars_Changed(uint feeBasisPoints, uint maxFee);
}
//|---------------------------------------------------------------------------------------------------------------------------------------| 
//|-------------------------------------------------------------- CRS TOKEN --------------------------------------------------------------|
//|---------------------------------------------------------------------------------------------------------------------------------------|
contract UpgradedSTD_TOKEN is STD_TOKEN {
    uint public _totalSupply;
    function transferByLegacy(address from, address to, uint value) public returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public returns (bool);
    function approveByLegacy(address from, address spender, uint value) public returns (bool);
    function plus_ApprovalByLegacy(address from, address spender, uint addedValue) public returns (bool);
    function minus_ApprovalByLegacy(address from, address spender, uint subtractedValue) public returns (bool);
}
contract CRSToken is Pausable, STD_TOKEN_WithFees, BlackList {
    address public upgradedAddress;
    bool public deprecated;
    constructor(uint _initialSupply, string memory _name, string memory _symbol, uint8 _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[getOwner()] = _initialSupply;
        deprecated = false;
    }
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        require(!CRS_BLACK_LIST[msg.sender]);
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        require(!CRS_BLACK_LIST[_from]);
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }
    function balanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }
    function oldBalanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return super.balanceOf(who);
        }
    }
    function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }
    function plus_Approval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).plus_ApprovalByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.plus_Approval(_spender, _addedValue);
        }
    }
    function minus_Approval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        if (deprecated) {
            return UpgradedSTD_TOKEN(upgradedAddress).minus_ApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.minus_Approval(_spender, _subtractedValue);
        }
    }
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) {
            return STD_TOKEN(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(_upgradedAddress != address(0));
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
    function totalSupply() public view returns (uint) {
        if (deprecated) {
            return STD_TOKEN(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }
    function addTokenToContract(uint amount) public onlyOwner {
        balances[getOwner()] = balances[getOwner()].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit token_Added_Contract(amount);
        emit Transfer(address(0), getOwner(), amount);
    }
    function delTokenFromContract(uint amount) public onlyOwner {
        _totalSupply = _totalSupply.sub(amount);
        balances[getOwner()] = balances[getOwner()].sub(amount);
        emit token_deleted_Contract(amount);
        emit Transfer(getOwner(), address(0), amount);
    }
    function deleteBlackFunds (address _exceptedUser) public onlyOwner {
        require(CRS_BLACK_LIST[_exceptedUser]);
        uint dirtyFunds = balanceOf(_exceptedUser);
        balances[_exceptedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit BlackFundsDeleted(_exceptedUser, dirtyFunds);
    }
    event BlackFundsDeleted(address indexed _exceptedUser, uint _balance);
    event token_Added_Contract(uint amount);
    event token_deleted_Contract(uint amount);
    event Deprecate(address newAddress);
}
//---------------------------------------------------------- safe Math library
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}