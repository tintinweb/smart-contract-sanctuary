//SourceUnit: BCN.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./ownable.sol";

contract BCNToken is ownable {
    using SafeMath for uint;
//****************************************************************************
//* Variables
//****************************************************************************
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    struct Asset {
        uint amount;
        uint releaseTime;
    }
    struct Balance {
        uint amount;
        uint releasedAmount;
//        uint releaseTime;
        uint assetsCount;
        mapping(uint => Asset) assets;  
    }
    mapping(address => Balance) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint freezeDuration = uint(365).mul(2).mul(1 days); // 2 years
    uint maxTotalSupply = 500e12; // 500,000,000 tokens

//****************************************************************************
//* Modifiers
//****************************************************************************

//****************************************************************************
//* Events
//****************************************************************************
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

//****************************************************************************
//* Main Functions
//****************************************************************************
    constructor() public {
        _name = 'Bem Chain';
        _symbol = 'BCN';
        _decimals = 6;
        _totalSupply = 0;
    }

    function name() public view returns(string memory) {
        return(_name);
    }
    
    function symbol() public view returns(string memory) {
        return(_symbol);
    }
    
    function decimals() public view returns(uint8) {
        return(_decimals);
    }

    function totalSupply() public view returns(uint) {
        return(_totalSupply);
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return(balances[_owner].amount);
    }
    
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_amount <= balanceOf(msg.sender),"Transfer value is out of balance.");
        require(_to != address(0),"Receiver address is not valid.");
        _transferAsset(msg.sender, _amount);
        balances[_to].releasedAmount = balances[_to].releasedAmount.add(_amount);
        balances[_to].amount = balances[_to].amount.add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return(true);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(_amount <= balanceOf(_from),"Transfer value is out of balance.");
        require(_amount <= allowed[_from][msg.sender],"Transfer value is not allowed.");
        _transferAsset(_from, _amount);
        require(_to != address(0),"Receiver value is not valid.");
        balances[_to].releasedAmount = balances[_to].releasedAmount.add(_amount);
        balances[_to].amount = balances[_to].amount.add(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return(true);
    }
    
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return(true);
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseAllowance(address _spender, uint256 _addedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

//****************************************************************************
//* Admin Functions
//****************************************************************************
    function releaseToken(address _owner) public isAdmin returns(bool) {
        require(balances[_owner].amount > 0,"The user balance is zero.");
        Balance storage _balance = balances[_owner];
        uint _sum = 0;
        for (uint i = 0; i < _balance.assetsCount; i = i.inc()) {
            Asset storage _asset = _balance.assets[i];
            _sum = _sum.add(_asset.amount);
            _asset.amount = 0;
        }
        _balance.releasedAmount = _balance.releasedAmount.add(_sum);
        return(true);
    }
    
    function releaseToken(address _owner, uint _amount) public isAdmin returns(bool) {
        require(_amount > 0,"Invalid amount.");
        _releaseExpiredAsset(_owner);
        require(_amount <= balances[_owner].amount,"Not enaugh amount.");
        require(_amount <= balances[_owner].amount.sub(balances[_owner].releasedAmount),"Not enaugh released amount.");
        Balance storage _balance = balances[_owner];
        uint _remainedAmount = _amount;
        for (uint i = 0; i < _balance.assetsCount; i = i.inc()) {
            Asset storage _asset = _balance.assets[i];
            if (_asset.amount < _remainedAmount) {
                _remainedAmount = _remainedAmount.sub(_asset.amount);
                _asset.amount = 0;
            } else {
                _asset.amount = _asset.amount.sub(_remainedAmount);
                _remainedAmount = 0;
                break;
            }
        }
        _balance.releasedAmount = _balance.releasedAmount.add(_amount);
        return(true);
    }
    
    function selfMint(address _to, uint _amount) public isAdmin returns(bool) {
        require(_to != address(0),"Receiver address is not valid.");
        _totalSupply = _totalSupply.add(_amount);
        require(_totalSupply <= maxTotalSupply,"Total supply exceeded than its maximum value.");
        Balance storage _balance = balances[_to];
        _balance.amount = _balance.amount.add(_amount);
        _balance.assets[_balance.assetsCount].amount = _amount;
        _balance.assets[_balance.assetsCount].releaseTime = now.add(freezeDuration);
        _balance.assetsCount = _balance.assetsCount.inc();
        emit Transfer(address(0), _to, _amount);
        return(true);
    }

//****************************************************************************
//* Internal Functions
//****************************************************************************
    function _transferAsset(address _owner, uint _amount) internal {
        _releaseExpiredAsset(_owner);
        Balance storage _balance = balances[_owner];
        require(_amount <= _balance.releasedAmount,"Not enaugh released amount.");
        _balance.releasedAmount = _balance.releasedAmount.sub(_amount);
        _balance.amount = _balance.amount.sub(_amount);
    }
    
    function _releaseExpiredAsset(address _owner) internal {
        Balance storage _balance = balances[_owner];
        for (uint i = 0; i < _balance.assetsCount; i = i.inc()) {
            Asset storage _asset = _balance.assets[i];
            if (now >= _asset.releaseTime) {
                _balance.releasedAmount = _balance.releasedAmount.add(_asset.amount);
                _asset.amount = 0;
            }
        }
    }

//****************************************************************************
//* Setter Functions
//****************************************************************************
    function setFreezeDuration(uint _freezeDuration) public isAdmin {
        require(_freezeDuration != freezeDuration,"Invalid value.");
        freezeDuration = _freezeDuration;
    }
//****************************************************************************
//* Getter Functions
//****************************************************************************
    function getFreezeDuration() public view returns(uint) {
        return(freezeDuration);
    }
    
    function getMaxTotalSupply() public view returns(uint) {
        return(maxTotalSupply);
    }
    
    function getRemainedTotalSupply() public view returns(uint) {
        return(maxTotalSupply.sub(_totalSupply));
    }
    
    function getReleasedBalances(address _owner) public view returns(uint) {
        Balance storage _balance = balances[_owner];
        uint _sum = 0;
        for (uint i = 0; i < _balance.assetsCount; i = i.inc()) {
            if (now > _balance.assets[i].releaseTime)
                _sum = _sum.add(_balance.assets[i].amount);
        }
        return(balances[_owner].releasedAmount.add(_sum));
    }
    
    function getUnreleasedAmount(address _owner) public view returns(uint) {
        return(balances[_owner].amount.sub(getReleasedBalances(_owner)));
    }
    
    function getNextTokenRelease(address _owner) public view returns(uint _amount, uint releaseTime) {
        Balance storage _balance = balances[_owner];
        for (uint i = 0; i < _balance.assetsCount; i = i.inc()) {
            if (_balance.assets[i].amount > 0)
                return(_balance.assets[i].amount, _balance.assets[i].releaseTime);
        }
        return(0,0);
    }
}



//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow error.");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "Subtraction overflow error.");
        uint256 c = a - b;
        return c;
    }
    
    function inc(uint a) internal pure returns(uint) {
        return(add(a, 1));
    }

    function dec(uint a) internal pure returns(uint) {
        return(sub(a, 1));
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns(uint) {
        require(b != 0,"Divide by zero.");
        return(a/b);
    }
    
    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0,"Divide by zero.");
        return(a % b);
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        if (a > b)
            return(b);
        else
            return(a);
    }

    function max(uint a, uint b) internal pure returns (uint) {
        if (a < b)
            return(b);
        else
            return(a);
    }
    
    function addPercent(uint a, uint p, uint r) internal pure returns(uint) {
        return(div(mul(a,add(r,p)),r));
    }
}


//SourceUnit: ownable.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
contract ownable {
    address payable admin;
    modifier isAdmin {
        require(admin == msg.sender,"You should be admin to call this function.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }

    function changeAdmin(address payable _admin) public isAdmin {
        require(admin != _admin,"You must enter a new value.");
        admin = _admin;
    }

    function getAdmin() public view returns(address) {
        return(admin);
    }
    
}