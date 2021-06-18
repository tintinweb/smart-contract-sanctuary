// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./LucaStorage.sol";
import "./LucaInterface.sol";
import "./SafeMath.sol";

contract Token is LucaInterface, LucaTokenStorage {
    using SafeMath for uint256;
    
    modifier unInitialized() {
        require(!isInitialize, "LUCA: Token Already initialized");
        _;
    }
    
    modifier onlyRebaser() {
        require(msg.sender == rebaser, "LUCA: Caller not rebaser");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "LUCA: Caller not minter");
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
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        isInitialize = true;
        scalingFactor = BASE;
        fragment = _lucaToFragment(initTotalSupply);
        totalSupply = initTotalSupply;
        address owner = msg.sender;
        _fragmentBalances[owner] = fragment;
        _setRebaser(owner);
        _setMinter(owner);
    }

    function mint(address to, uint256 amount) override external onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
            totalSupply = totalSupply.add(amount);
            uint256 scaledAmount = _lucaToFragment(amount);
            fragment = fragment.add(scaledAmount);
            require(scalingFactor <= _maxScalingFactor(), "LUCA: max scaling factor too low");
            _fragmentBalances[to] = _fragmentBalances[to].add(scaledAmount);
            emit Mint(to, scaledAmount);
            emit Transfer(address(0), to, scaledAmount);
    }
    

    function transfer(address to, uint256 value) override external validRecipient(to) validBalance(msg.sender, value) returns (bool) {
        uint256 fragmentValue = _lucaToFragment(value);
        _fragmentBalances[msg.sender] = _fragmentBalances[msg.sender].sub(fragmentValue);
        _fragmentBalances[to] = _fragmentBalances[to].add(fragmentValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

 
    function transferFrom(address from, address to, uint256 value) override external validRecipient(to) validBalance(from, value) returns (bool){
        uint256 fragmentValue = _lucaToFragment(value);
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);
        _fragmentBalances[from] = _fragmentBalances[from].sub(fragmentValue);
        _fragmentBalances[to] = _fragmentBalances[to].add(fragmentValue);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) override external view returns (uint256){
        return _fragmentToLuca(_fragmentBalances[who]);
    }

    // function balanceOfUnderlying(address who) external view returns (uint256){
    //     return _fragmentBalances[who];
    // }

    function allowance(address owner_, address spender) override external view returns (uint256){
        return _allowedFragments[owner_][spender];
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
            emit Rebase(epoch, scalingFactor, scalingFactor);
            return totalSupply;
        }
        
        uint256 prevScalingFactor = scalingFactor;

        if (!positive) {
            scalingFactor = scalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
        } else {
            uint256 newScalingFactor = scalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                scalingFactor = newScalingFactor;
            } else {
                scalingFactor = _maxScalingFactor();
            }
        }
        totalSupply = _fragmentToLuca(fragment);

        emit Rebase(epoch, prevScalingFactor, scalingFactor);
        return totalSupply;
    }
    
    
    function setMinter(address minter_) override external onlyMinter returns(bool){
        _setMinter(minter_);
        return true;
    }
    
    function _setMinter(address minter_) internal{
        address oldMinter = minter;
        minter =  minter_;
        emit NewMinter(oldMinter, minter_);
    }
    
    
    function setRebaser(address rebaser_) override onlyRebaser external returns(bool) {
        _setRebaser(rebaser_);
        return true;
    }
    
    function _setRebaser(address rebaser_) internal{
        address oldRebaser = rebaser;
        rebaser = rebaser_;
        emit NewRebaser(oldRebaser, rebaser_);
    }

    
    //utils function 
    function maxScalingFactor() override external view returns (uint256){
        return _maxScalingFactor();
    }
    
    function _maxScalingFactor() internal view returns (uint256){
       return type(uint256).max / fragment;
    }

    function fragmentToLuca(uint256 luca) override external view returns (uint256){
        return _fragmentToLuca(luca);
    }
    
    function _fragmentToLuca(uint256 luca) internal view returns(uint256){
         return luca.mul(scalingFactor).div(internalDecimals);
    }

    function lucaToFragment(uint256 value) override external view returns (uint256){
       return _lucaToFragment(value);
    }
    
    function _lucaToFragment(uint value) internal view returns (uint256){
        return value.mul(internalDecimals).div(scalingFactor);
    }
    
}



contract Luca is Token {
   // function initialize() public {
      constructor() {
        string memory _name = "Luca token";
        string memory _symbol =  "LUCA";
        uint8   _decimals = 18;
        uint256  _totalSupply = 100000*10**18;
        initializeToken(_name, _symbol, _decimals, _totalSupply);
        }
}