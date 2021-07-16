//SourceUnit: SafeMath.sol

pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

//SourceUnit: SoulToken.sol

pragma solidity ^0.4.23;

import "./SafeMath.sol";

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, uint256 _extraData) external;
}

contract SoulToken
{
    using SafeMath for uint256;

    uint8 public decimals = 6;
    uint256 public totalSupply = 333333333 * (10 ** uint256(decimals));
    string public name = "SOUL";
    string public symbol = "SOUL";

    address addrOwner; 
    address addrMiningPool;
    uint256 transferOpen = 2145888000;              // 2038��1��1��(GMT+8)
    bool burnOn;
    bool approveAndCallOn;

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowed;

    mapping (address => bool) private _fromWhiteList;
    mapping (address => bool) private _toWhiteList;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor() public {
        addrOwner = msg.sender;
        addrMiningPool = msg.sender;
        burnOn = false;
        approveAndCallOn = true;
        _balances[addrOwner] = totalSupply;
    }

    function() external payable {
        revert();
    }

    modifier onlyOwner() {
        require(msg.sender == addrOwner);
        _;
    }

    function setOption(bool _burnOn, bool _acOn, uint256 _transTime) external onlyOwner {
        burnOn = _burnOn;
        approveAndCallOn = _acOn;
        transferOpen = _transTime;
    }

    function getOption() external view returns(bool _burnOn, bool _acOn, uint256 _transTime) {
        _burnOn = burnOn;
        _acOn = approveAndCallOn;
        _transTime = transferOpen;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0) && _newOwner != addrOwner);
        addrOwner = _newOwner;
    }

    function setMiningPool(address _newPool) external onlyOwner {
        require(_newPool != address(0) && _newPool != addrOwner);
        addrMiningPool = _newPool;
    }

    function getRole() external view returns(address _owner, address _miningPool) {
        _owner = addrOwner;
        _miningPool = addrMiningPool;
    }

    function setFromPermission(address _addr, bool _useful) external onlyOwner {
        require(_addr != address(0));
        _fromWhiteList[_addr] = _useful;
    }

    function setToPermission(address _addr, bool _useful) external onlyOwner {
        require(_addr != address(0));
        _toWhiteList[_addr] = _useful;
    }

    function adjustSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply > 0 && _newSupply < 9999999999);
        require(_newSupply != totalSupply);
        if (_newSupply > totalSupply) {
            uint256 addVal = _newSupply - totalSupply;
            _balances[addrMiningPool] = _balances[addrMiningPool].add(addVal);
            emit Transfer(address(0), addrMiningPool, addVal);
        } else {
            uint256 subVal = totalSupply - _newSupply;
            uint256 miningPoolBalance = _balances[addrMiningPool];
            require(miningPoolBalance >= subVal);
            _balances[addrMiningPool] = _balances[addrMiningPool].sub(subVal);
            emit Transfer(addrMiningPool, address(0), subVal);
        }
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_value <= _balances[msg.sender] && _value > 0);
        require(_to != address(0));

        if (block.timestamp < transferOpen) {
            require(_fromWhiteList[msg.sender] || _toWhiteList[_to]);
        }

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;    
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[_from] && _value > 0);
        require(_value <= _allowed[_from][msg.sender]);

        if (block.timestamp < transferOpen) {
            require(_fromWhiteList[_from] || _toWhiteList[_to]);
        }

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) 
        external 
        returns (bool success) 
    {
        require(burnOn == true);
        require(_balances[msg.sender] >= _value && totalSupply > _value);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);                                
        emit Burn(msg.sender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, uint256 _extraData)
        external
        returns (bool success) 
    {
        require(approveAndCallOn == true);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _extraData);
            return true;
        }
    }
}