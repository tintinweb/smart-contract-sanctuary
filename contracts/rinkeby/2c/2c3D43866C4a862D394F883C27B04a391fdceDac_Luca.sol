/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "./Token.sol";
contract LucaTokenStorage {
    string  internal _name;
    string  internal _symbol;
    uint8   internal _decimals;
    uint256 internal _fragment;
    uint256 internal _totalSupply;
    address internal _rebaser;
    address internal _minter;
    address internal _receiver;
    uint256 internal constant _internalDecimals = 10**24;
    uint256 internal constant BASE = 10**18;
    uint256 internal _scalingFactor;
    bool    internal _isInitialize;
    mapping (address => uint256) internal _fragmentBalances;
    mapping (address => mapping (address => uint256)) internal _allowedFragments;

}

//import "../common/interface/IERC20.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//import "../common/library/SafeMath.sol";
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

//lucaInterface.sol
interface LucaInterface is IERC20{
    //event
    event Rebase(uint256 epoch, uint256 scalingFactor, uint256 newScalingFactor);
    event Mint(address to, uint256 amount);
    event NewRebaser(address oldRebaser, address newRebaser);
    event NewMinter(address oldMinter, address NewMinter);
    event NewReceiver(address oldReceiver, address NewReceiver);
    
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function fragment() external view returns(uint256);
    function rebaser() external view returns(address);
    function minter() external view returns(address);
    function scalingFactor() external view returns(uint256);
    function maxScalingFactor() external view returns (uint256);
    function lucaToFragment(uint256 value) external view returns (uint256);
    function fragmentToLuca(uint256 value) external view returns (uint256);
    function setReceiver(address user)external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function setMinter(address user) external;
    function rebaseByMilli(uint256 epoch, uint256 milli, bool positive) external returns (uint256);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function setRebaser(address user) external;
}

//Token.sol
contract Token is LucaInterface, LucaTokenStorage {
    using SafeMath for uint256;
    modifier unInitialized() {
        require(!_isInitialize, "LUCA: Token Already initialized");
        _;
    }
    
    modifier onlyRebaser() {
        require(msg.sender == _rebaser, "LUCA: Caller not rebaser");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter, "LUCA: Caller not minter");
        _;
    }
    
    
    modifier onlyReceiver() {
        require(msg.sender == _receiver, "LUCA: Caller not receiver");
        _;
    }
    
    modifier validRecipient(address to) {
        require(to != address(0x0), "LUCA: The variable 'to' cannot be zero");
        require(to != address(this), "LUCA: The variable 'to' cannot be current contract");
        _;
    }
    
    modifier validBalance(address who, uint256 value) {
        require(value <= _fragmentToLuca(_fragmentBalances[who]), "LUCA: not enough balance");
        _;
    }

    function initializeToken(string memory name_, string memory symbol_, uint8 decimals_, uint256 initTotalSupply) internal unInitialized {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _isInitialize = true;
        _scalingFactor = BASE;
        _fragment = _lucaToFragment(initTotalSupply);
        _totalSupply = initTotalSupply;
        address owner = msg.sender;
        _fragmentBalances[owner] = _fragment;
        _setRebaser(owner);
        _setMinter(owner);
        _setReceiver(owner);
    }
    
    function name() override external view returns(string memory) {
        return _name;
    }
    
    function symbol() override external view returns(string memory) {
        return _symbol;
    }
    
    function decimals() override external view returns(uint8) {
        return _decimals;
    }
    
    function fragment() override external view returns(uint256) {
        return _fragment;
    }
    
    function totalSupply() override external view returns(uint256) {
        return _totalSupply;
    }
    
    function rebaser() override external view returns(address) {
        return _rebaser;
    }
    
    function minter() override external view returns(address) {
        return _minter;
    }
    
    function scalingFactor() override external view returns(uint256) {
        return _scalingFactor;
    }
    

    function mint(address to, uint256 amount) override external onlyMinter {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
            _totalSupply = _totalSupply.add(amount);
            uint256 scaledAmount = _lucaToFragment(amount);
            _fragment = _fragment.add(scaledAmount);
            require(_scalingFactor <= _maxScalingFactor(), "LUCA: max scaling factor too low");
            _fragmentBalances[to] = _fragmentBalances[to].add(scaledAmount);
            emit Mint(to, scaledAmount);
            emit Transfer(address(0), to, scaledAmount);
    }
    
    function burn(uint256 amount) override external {
        _burn(msg.sender, amount);
    }
    
    function _burn(address user, uint256 amount) internal {
            _totalSupply = _totalSupply.sub(amount);
            uint256 scaledAmount = _lucaToFragment(amount);
            _fragment = _fragment.sub(scaledAmount);
            _fragmentBalances[user] = _fragmentBalances[user].sub(scaledAmount);
            emit Transfer(user ,address(0), scaledAmount);
    }
    
   
    function transfer(address to, uint256 value) override external validRecipient(to) validBalance(msg.sender, value) returns (bool) {
        _transferFragment(msg.sender, to, _lucaToFragment(value));
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function _transferFragment(address from, address to, uint256 value ) internal {
        _fragmentBalances[from] = _fragmentBalances[from].sub(value);
        _fragmentBalances[to] = _fragmentBalances[to].add(value);
    }

    function transferFrom(address from, address to, uint256 value) override external validRecipient(to) validBalance(from, value) returns (bool){
        uint256 fragmentValue = _lucaToFragment(value);
        require(fragmentValue <=  _allowedFragments[from][msg.sender], "LUCA: not enough allowed");
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(fragmentValue);
        _transferFragment(from, to, fragmentValue);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) override external view returns (uint256){
        return _fragmentToLuca(_fragmentBalances[who]);
    }

    function allowance(address owner_, address spender) override external view returns (uint256){
        return _fragmentToLuca(_allowedFragments[owner_][spender]);
    }

    function approve(address spender, uint256 value) override external returns (bool){
        uint256 fragmentValue = _lucaToFragment(value);
        _allowedFragments[msg.sender][spender] = fragmentValue;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function rebaseByMilli(uint256 epoch, uint256 milli, bool positive) override external onlyRebaser returns (uint256){
        require(milli <= 1000, "LUCA: milli need less than 1000");
        uint256 indexDelta = milli.mul(BASE.div(1000));
        return _rebase(epoch, indexDelta, positive);
    }
    
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) override external onlyRebaser returns (uint256){
         return _rebase(epoch, indexDelta, positive);
    }
   
    function _rebase(uint256 epoch, uint256 indexDelta, bool positive) internal returns (uint256){
        if (indexDelta == 0) {
            emit Rebase(epoch, _scalingFactor, _scalingFactor);
            return _totalSupply;
        }
        
        uint256 prevScalingFactor = _scalingFactor;

        if (!positive) {
            _scalingFactor = _scalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
        } else {
            uint256 newScalingFactor = _scalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                _scalingFactor = newScalingFactor;
            } else {
                _scalingFactor = _maxScalingFactor();
            }
        }
        _totalSupply = _fragmentToLuca(_fragment);

        emit Rebase(epoch, prevScalingFactor, _scalingFactor);
        return _totalSupply;
    }
    
    function setReceiver(address user) override external onlyReceiver{
        _setReceiver(user);
    }
    
    function _setReceiver(address user) internal{
        address oldReceiver = _receiver;
        _receiver = user;
        emit NewReceiver(oldReceiver, user);
    }
    
    function setMinter(address user) override external onlyMinter{
        _setMinter(user);
    }
    
    function _setMinter(address user) internal{
        address oldMinter = _minter;
        _minter =  user;
        emit NewMinter(oldMinter, user);
    }
    
    
    function setRebaser(address rebaser_) override onlyRebaser external{
        _setRebaser(rebaser_);
    }
    
    function _setRebaser(address user) internal{
        address oldRebaser = _rebaser;
        _rebaser = user;
        emit NewRebaser(oldRebaser, user);
    }

    //utils function 
    function maxScalingFactor() override external view returns (uint256){
        return _maxScalingFactor();
    }
    
    function _maxScalingFactor() internal view returns (uint256){
       return (type(uint256).max).div(_fragment);
    }

    function fragmentToLuca(uint256 value) override external view returns (uint256){
        return _fragmentToLuca(value);
    }
    
    function _fragmentToLuca(uint256 value) internal view returns(uint256){
         return value.mul(_scalingFactor).div(_internalDecimals);
    }

    function lucaToFragment(uint256 value) override external view returns (uint256){
       return _lucaToFragment(value);
    }
    
    function _lucaToFragment(uint value) internal view returns (uint256){
        return value.mul(_internalDecimals).div(_scalingFactor);
    }
}

//support for poxry
contract Luca is Token {
    function initialize(string memory name, string memory symbol, uint256 totalSupply) public {
        initializeToken(name, symbol, 18, totalSupply*10**18);
    }
}