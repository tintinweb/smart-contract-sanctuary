/**
 * Source Code first verified at https://etherscan.io on Wednesday, March 13, 2019
 (UTC) */

pragma solidity 0.5.7;

import "./ERC20.sol";
import "./SafeMath.sol";

contract OHiWE is ERC20 { 
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string private constant _name = "OHiWE";
    string private constant _symbol = "OHC";
    uint8 private constant _decimals = 18;
    uint256 private constant _maxCap = 3300000000 ether;
    
    //--- Token allocations -------//
    uint256 private _totalsupply;

    //--- Address -----------------//
    address private _owner;
    address payable private _ethFundMain;
    
    //--- Variables ---------------//
    bool private _lockToken = false;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private locked;
    
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event ChangeReceiveWallet(address indexed newAddress);
    event ChangeOwnerShip(address indexed newOwner);
    event ChangeLockStatusFrom(address indexed investor, bool locked);
    event ChangeTokenLockStatus(bool locked);
    event ChangeAllowICOStatus(bool allow);
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner is allowed");
        _;
    }
    
    modifier onlyUnlockToken() {
        require(!_lockToken, "Token locked");
        _;
    }

    constructor() public
    {
        _owner = msg.sender;
    }
    
    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function maxCap() public pure returns (uint256) {
        return _maxCap;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    function ethFundMain() public view returns (address) {
        return _ethFundMain;
    }
   
    function lockToken() public view returns (bool) {
        return _lockToken;
    }
   
    function lockStatusOf(address investor) public view returns (bool) {
        return locked[investor];
    }

    function totalSupply() public view returns (uint256) {
        return _totalsupply;
    }
    
    function balanceOf(address investor) public view returns (uint256) {
        return balances[investor];
    }
    
    function approve(address _spender, uint256 _amount) public onlyUnlockToken returns (bool)  {
        require( _spender != address(0), "Address can not be 0x0");
        require(balances[msg.sender] > _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _from, address _spender) public view returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _amount) public onlyUnlockToken returns (bool) {
        require( _to != address(0), "Receiver can not be 0x0");
        require(balances[msg.sender] > _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom( address _from, address _to, uint256 _amount ) public onlyUnlockToken returns (bool)  {
        require( _to != address(0), "Receiver can not be 0x0");
        require(balances[_from] > _amount, "Source&#39;s balance is not enough");
        require(allowed[_from][msg.sender] > _amount, "Allowance is not enough");
        require(!locked[_from], "From address is locked");
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(balances[msg.sender] > _value, "Balance does not have enough tokens");   
        balances[msg.sender] = (balances[msg.sender]).sub(_value);            
        _totalsupply = _totalsupply.sub(_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }

    function stopTransferToken() external onlyOwner {
        _lockToken = true;
        emit ChangeTokenLockStatus(true);
    }

    function startTransferToken() external onlyOwner {
        _lockToken = false;
        emit ChangeTokenLockStatus(false);
    }

    function () external payable {

    }

    function manualMint(address receiver, uint256 _value) public onlyOwner{
        mint(_owner, receiver, _value);
    }

    function mint(address from, address receiver, uint256 value) internal {
        require(receiver != address(0), "Address can not be 0x0");
        require(value > 0, "Value should larger than 0");
        balances[receiver] = balances[receiver].add(value);
        _totalsupply = _totalsupply.add(value);
        require(_totalsupply <= _maxCap, "CrowdSale hit max cap");
        emit Mint(from, receiver, value);
        emit Transfer(address(0), receiver, value);
    }
 
	function assignOwnership(address newOwner) external onlyOwner {
	    require(newOwner != address(0), "Address can not be 0x0");
	    _owner = newOwner;
	    emit ChangeOwnerShip(newOwner);
	}

    function changeReceiveWallet(address payable newAddress) external onlyOwner {
        require(newAddress != address(0), "Address can not be 0x0");
        _ethFundMain = newAddress;
        emit ChangeReceiveWallet(newAddress);
    }

    function forwardFunds() external onlyOwner {
        require(_ethFundMain != address(0));
        _ethFundMain.transfer(address(this).balance);
    }

    function haltTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = true;
        emit ChangeLockStatusFrom(investor, true);
    }

    function resumeTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = false;
        emit ChangeLockStatusFrom(investor, false);
    }
}