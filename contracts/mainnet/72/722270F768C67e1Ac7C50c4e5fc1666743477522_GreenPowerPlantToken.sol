pragma solidity >=0.4.21 <0.6.0;
//
interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface TokenVoluntaryUpgrade {
    function setUpgradeContract(address _upgradeContractAddress) external returns(bool);
    function burnAfterUpgrade(uint256 value) external returns (bool success);
    event UpgradeContractChange(address owner, address indexed _exchangeContractAddress);
    event UpgradeBurn(address indexed _exchangeContract, uint256 _value);
}
//
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        //
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function uintSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
// b7d60f2f9a849c5c2d59e24062f9c09f3390487a
// with some minor changes
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only owner can do that");
        _;
    }
    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "newOwner parameter must be set");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
//
//
contract GreenPowerPlantToken is Ownable, TokenVoluntaryUpgrade  {
    string  internal _name              = "Green Power Plant";
    string  internal _symbol            = "GPP";
    string  internal _standard          = "ERC20";
    uint8   internal _decimals          = 0;
    uint     internal _totalSupply      = 80000 * 1 ether;
    //
    string  internal _trustedIPNS       = "";
    //
    address internal _upgradeContract   = address(0);
    //
    mapping(address => uint256)                     internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    //
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    //
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    //
    event UpgradeContractChange(
        address owner,
        address indexed _exchangeContractAddress
    );
    //
    event UpgradeBurn(
        address indexed _upgradeContract,
        uint256 _value
    );
    //
    constructor () public Ownable() {
        balances[msg.sender] = totalSupply();
    }
    // Try to prevent sending ETH to SmartContract by mistake.
    function () external payable  {
        revert("This SmartContract is not payable");
    }
    //
    // Getters and Setters
    //
    function name() public view returns (string memory) {
        return _name;
    }
    //
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    //
    function standard() public view returns (string memory) {
        return _standard;
    }
    //
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    //
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    //
    // Contract common functions
    //
    function transfer(address _to, uint256 _value) public returns (bool) {
        //
        require(_to != address(0), "'_to' address has to be set");
        require(_value <= balances[msg.sender], "Insufficient balance");
        //
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        //
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    //
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (_spender != address(0), "_spender address has to be set");
        require (_value > 0, "'_value' parameter has to greater than 0");
        //
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    //
    function safeApprove(address _spender, uint256 _currentValue, uint256 _value)  public returns (bool success) {
        // If current allowance for _spender is equal to _currentValue, then
        // overwrite it with _value and return true, otherwise return false.
        if (allowed[msg.sender][_spender] == _currentValue) return approve(_spender, _value);
        return false;
    }
    //
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        //
        require(_from != address(0), "'_from' address has to be set");
        require(_to != address(0), "'_to' address has to be set");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        //
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        //
        emit Transfer(_from, _to, _value);
        //
        return true;
    }
    //
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    //
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    // Voluntary token upgrade logic
    //
    /**
     * @dev Gets trusted IPNS address
     */
    function trustedIPNS() public view returns(string memory) {
        return  _trustedIPNS;
    }

    function setTrustedIPNS(string memory _trustedIPNSparam) public onlyOwner returns(bool) {
        _trustedIPNS = _trustedIPNSparam;
        return true;
    }
    //
    /** 
     * @dev Gets SmartContract that could upgrade Tokens - empty == no upgrade
     */
    function upgradeContract() public view returns(address) {
        return _upgradeContract;
    }
    //
    /** 
     * @dev Sets SmartContract that could upgrade Tokens to a new version in a future
     */
    function setUpgradeContract(address _upgradeContractAddress) public onlyOwner returns(bool) {
        _upgradeContract = _upgradeContractAddress;
        emit UpgradeContractChange(msg.sender, _upgradeContract);
        //
        return true;
    }
    function burnAfterUpgrade(uint256 _value) public returns (bool success) {
        require(_upgradeContract != address(0), "upgradeContract is not set");
        require(msg.sender == _upgradeContract, "only upgradeContract can execute token burning");
        require(_value <= balances[msg.sender], "Insufficient balance");
        //
        _totalSupply = SafeMath.sub(_totalSupply, _value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender],_value);
        emit UpgradeBurn(msg.sender, _value);
        //
        return true;
    }
    //
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        _totalSupply = SafeMath.sub(_totalSupply, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}