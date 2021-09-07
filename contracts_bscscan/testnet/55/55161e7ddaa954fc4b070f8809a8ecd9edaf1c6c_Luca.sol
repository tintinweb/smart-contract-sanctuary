/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract Initialized {
    bool internal initialized;
    
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Storage is Initialized{
    //ERC20 pubilc variables
    string  public name;
    string  public symbol;
    uint8   public decimals;
    
    //manager 
    address public owner;
    address public rebaser;
    address public minter;
    address public receiver;
    
    //Factor
    uint256 public scalingFactor;
    uint256 internal fragment;
    uint256 internal _totalSupply;
    uint256 constant Decimals = 10**24;
    uint256 constant BASE = 10**18;
    
    mapping (address => uint256) internal fragmentBalances;
    mapping (address => mapping (address => uint256)) internal allowedFragments;
    
    
    //modifier
    modifier onlyRebaser() {
        require(msg.sender == rebaser, "LUCA: only rebaser");
        _;
    }
    
    modifier onlyOwner(){
         require(msg.sender == owner, "LUCA: only owner");
        _;
    }
    
    modifier onlyMinter() {
        require(msg.sender == minter, "LUCA: only minter");
        _;
    }
    
    modifier onlyReceiver() {
        require(msg.sender == receiver, "LUCA: only receiver");
        _;
    }
}

interface ILuca is IERC20{
    //event
    event Rebase(uint256 epoch, uint256 indexDelta, bool positive);
    
    //luca core
    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function rebaseByMilli(uint256 epoch, uint256 milli, bool positive) external returns (uint256);
    
    //query
    function lucaToFragment(uint256 value) external view returns (uint256);
    function fragmentToLuca(uint256 value) external view returns (uint256);
    
    //manager
    function setMinter(address user) external;
    function setReceiver(address user) external;
    function setRebaser(address user) external;
}

contract Token is Storage, IERC20{
    using SafeMath for uint256;
    
    //IERC20 
    function totalSupply() override external view returns (uint256){
        return _totalSupply;
    }

    function transfer(address to, uint256 value) override external returns (bool) {
        _transferFragment(msg.sender, to, _lucaToFragment(value));
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) override external returns (bool){
        uint256 fragmentValue = _lucaToFragment(value);
        allowedFragments[from][msg.sender] = allowedFragments[from][msg.sender].sub(fragmentValue);
        _transferFragment(from, to, fragmentValue);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) override external view returns (uint256){
        return _fragmentToLuca(fragmentBalances[who]);
    }

    function allowance(address owner_, address spender) override external view returns (uint256){
        return _fragmentToLuca(allowedFragments[owner_][spender]);
    }

    function approve(address spender, uint256 value) override external returns (bool){
        uint256 fragmentValue = _lucaToFragment(value);
        allowedFragments[msg.sender][spender] = fragmentValue;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    //internal 
    function _mint(address to, uint256 amount) internal {
            _totalSupply = _totalSupply.add(amount);
            uint256 scaledAmount = _lucaToFragment(amount);
            fragment = fragment.add(scaledAmount);
            require(scalingFactor <= _maxScalingFactor(), "LUCA: max scaling factor too low");
            fragmentBalances[to] = fragmentBalances[to].add(scaledAmount);
            emit Transfer(address(0), to, amount);
    }

    function _burn(address user, uint256 amount) internal {
            _totalSupply = _totalSupply.sub(amount);
            uint256 scaledAmount = _lucaToFragment(amount);
            fragment = fragment.sub(scaledAmount);
            fragmentBalances[user] = fragmentBalances[user].sub(scaledAmount);
            emit Transfer(user ,address(0), amount);
    }
    
    function _transferFragment(address from, address to, uint256 value ) internal {
        fragmentBalances[from] = fragmentBalances[from].sub(value);
        fragmentBalances[to] = fragmentBalances[to].add(value);
    }
    
    function _maxScalingFactor() internal view returns (uint256){
       return (type(uint256).max).div(fragment);
    }

    function _fragmentToLuca(uint256 value) internal view returns(uint256){ 
         return value.mul(scalingFactor).div(Decimals);
    }

    function _lucaToFragment(uint value) internal view returns (uint256){
        return value.mul(Decimals).div(scalingFactor);
    }
}

contract Luca is Token, ILuca{
    using SafeMath for uint256;
    
    function initialize(string memory name, string memory symbol, uint256 totalSupply) public {
        _initialize(name, symbol, 18, totalSupply*10**18);
    }
    
    function setReceiver(address user) override external onlyOwner{
        receiver = user;
    }
    
    function setMinter(address user) override external onlyOwner{
        minter =  user;
    }
    
    function setRebaser(address user) override external onlyOwner{
        rebaser = user;
    }
    
    function rebaseByMilli(uint256 epoch, uint256 milli, bool positive) override external onlyRebaser returns (uint256){
        require(milli <= 1000, "LUCA: milli need less than 1000");
        return _rebase(epoch, milli.mul(BASE.div(1000)), positive);
    }
    
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) override external onlyRebaser returns (uint256){
         return _rebase(epoch, indexDelta, positive);
    }
    
    function mint(uint256 amount) override external onlyMinter {
        _mint(receiver, amount);
    }
    
    function burn(uint256 amount) override external {
        _burn(msg.sender, amount);
    }
    
    function fragmentToLuca(uint256 value) override external view returns (uint256){
        return _fragmentToLuca(value);
    }
    
    function lucaToFragment(uint256 value) override external view returns (uint256){
      return _lucaToFragment(value);
    }
    
    function _rebase(uint256 epoch, uint256 indexDelta, bool positive) internal returns (uint256){
        emit Rebase(epoch, indexDelta, positive);
        if (indexDelta == 0)  return _totalSupply;
        
        if (!positive) {
            require(indexDelta < BASE);
            scalingFactor = scalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
        } else {
            uint256 newScalingFactor = scalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                scalingFactor = newScalingFactor;
            } else {
                scalingFactor = _maxScalingFactor();
            }
        }
        
        _totalSupply = _fragmentToLuca(fragment);
        return _totalSupply;
    }
    
    function _initialize(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initTotalSupply) internal noInit {
        scalingFactor = BASE;
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _initTotalSupply;
        fragment = _lucaToFragment(_initTotalSupply);
        fragmentBalances[msg.sender] = fragment;
        rebaser = owner;
        minter = owner;
        receiver = owner;
    }
}