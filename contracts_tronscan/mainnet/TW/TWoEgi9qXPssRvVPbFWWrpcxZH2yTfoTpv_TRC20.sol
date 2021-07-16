//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "XXAddition overflow error.XX");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "XXSubtruction overflow error.XX");
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
        require(b != 0,"XXDivide by zero.XX");
        return(a/b);
    }
    
    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0,"XXDivide by zero.XX");
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


//SourceUnit: TRC20.sol

pragma solidity ^0.5.10;
// SPDX-License-Identifier: MIT
import "./SafeMath.sol";

contract TRC20base {
    using SafeMath for uint;
    string internal _name = '';
    string internal _symbol = '';
    uint256 internal _decimals = 0;
    uint256 internal _totalSupply = 0;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns(string memory) {
        return(_name);
    }
    
    function symbol() public view returns(string memory) {
        return(_symbol);
    }
    
    function decimals() public view returns(uint256) {
        return(_decimals);
    }
    
    function totalSupply() public view returns(uint256) {
        return(_totalSupply);
    }
    
    function balanceOf(address _owner) public view returns(uint256) {
        return(_balances[_owner]);
    }
    
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_value <= _balances[msg.sender],"XXTransfer value is out of balance.XX");
        require(_to != address(0),"XXReceiver address is not valid.XX");
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_value <= _balances[_from],"XXTransfer value is out of balance.XX");
        require(_value <= _allowed[_from][msg.sender],"XXTransfer value is not allowed.XX");
        require(_to != address(0),"XXReceiver value is not valid.XX");
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool) {
        require(_spender != address(0),"XXSpender address is not valid.XX");
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return _allowed[_owner][_spender];
    }
    
    function increaseAllowance(address _spender, uint256 _addedValue) public returns(bool) {
        require(_spender != address(0),"XXSpender address is not valid.XX");
        _allowed[msg.sender][_spender] = (_allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns(bool) {
        require(_spender != address(0),"XXSpender address is not valid.XX");
        _allowed[msg.sender][_spender] = (_allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0),"XXAccount is not valid.XX");
        _totalSupply = _totalSupply.add(_amount);
        _balances[_account] = _balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0),"XXAccount is not valid.XX");
        require(_amount <= _balances[_account],"XXValue is out of balance.XX");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[_account] = _balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= _allowed[_account][msg.sender],"XXValue is not allowed.XX");
        _allowed[_account][msg.sender] = _allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }
    
}

contract TRC20 is TRC20base {
    address _owner;
    address mlmAddress;
    modifier isOwner {
        require(msg.sender == _owner,"XXYou are not owner.XX");
        _;
    }
    
    constructor() public {
        _owner = msg.sender;
        _name = 'My Business Token';
        _symbol = 'MBT';
        _decimals = 6;
        _totalSupply = 0;
        //_balances[address(this)] = __totalSupply;
    }

/*    
    function selfApprove(address _spender, uint _value) private {
        require(_spender != address(0));
        _allowed[address(this)][_spender] = _value;
        emit Approval(address(this), _spender, _value);
    }
*/    

    function setMlmAddress(address _mlmAddress) external isOwner {
        require(mlmAddress != _mlmAddress,"XXNew value required.XX");
        mlmAddress = _mlmAddress;
        //selfApprove(mlmAddress, balanceOf(address(this)));
    }
    
    function getMlmAddress() external isOwner view returns(address) {
        return(mlmAddress);
    }
    
    function burn(uint256 _amount) external isOwner {
        _burn(address(this), _amount);
    }
    
    function mint(uint256 _amount) external isOwner {
        _mint(address(this), _amount);
    }
    
    function setApprove(address _to, uint256 _amount) external {
        require(_amount <= balanceOf(address(this)),"XXValue is out of balance.XX");
        require(msg.sender == mlmAddress,"XXNew value required.XX");
        approve(_to, _amount);
    }
    
    function setPay(address _to, uint256 _amount) external {
        require(_amount <= balanceOf(address(this)),"XXValue is outof balance.XX");
        require(msg.sender == mlmAddress,"XXWrong caller address.XX");
        transferFrom(address(this), _to, _amount);
    }
    
    function setMint(address _to, uint256 _amount) external {
        require(msg.sender == mlmAddress,"XXWrong caller.XX");
        _mint(_to, _amount);
    }
    
}