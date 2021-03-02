/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.5.17;


/**
 * @title SafeMath
 * @dev Removed mul, div, mod
 */
library SafeMath {
        /**
         * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
         */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b <= a, "Subtractionoverflow.");
                uint256 c = a - b;

                return c;
        }

        /**
         * @dev Adds two unsigned integers, reverts on overflow.
         */
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                require(c >= a, "Addition overflow.");

                return c;
        }
}


contract ERC20 {
      function totalSupply() public view returns (uint256);
      function balanceOf(address _who) public view returns (uint256);
      function transfer(address _to, uint256 _value) public returns (bool);
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
      function allowance(address _owner, address _spender) public view returns (uint256);
      function approve(address _spender, uint256 _value) public returns (bool);

      event Transfer(address indexed from, address indexed to, uint256 value);
      event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {
        using SafeMath for uint256;

        uint256 internal _totalSupply;
        mapping(address => uint256) internal _balances;
        mapping(address => mapping (address => uint256)) internal _allowed;
        
        modifier validDestination( address _to )
        {
                require(_to != address(0x0), "Invalid address.");
                require(_to != address(this), "Invalid address.");
                _;
        }

        function totalSupply() public view returns (uint256) {
                return _totalSupply;
        }

        function balanceOf(address _who) public view returns (uint256) {
                return _balances[_who];
        }

        function transfer(address _to, uint256 _value)
                public
                validDestination(_to)
                returns (bool)
        {
                _balances[msg.sender] = _balances[msg.sender].sub(_value);
                _balances[_to] = _balances[_to].add(_value);
                emit Transfer(msg.sender, _to, _value);
                return true;
        }

        function transferFrom(address _from, address _to, uint256 _value)
                public
                validDestination(_to)
                returns (bool)
        {
                require(_value <= _allowed[_from][msg.sender],"Insufficient allowance.");

                _balances[_from] = _balances[_from].sub(_value);
                _balances[_to] = _balances[_to].add(_value);
                _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

                emit Transfer(_from, _to, _value);
                return true;
        }

        function burn(uint _value) public returns (bool)
        {
                _balances[msg.sender] = _balances[msg.sender].sub(_value);
                _totalSupply = _totalSupply.sub(_value);
                emit Transfer(msg.sender, address(0x0), _value);
                return true;
        }

        function burnFrom(address _from, uint256 _value) public validDestination(_from) returns (bool)
        {
                require(_value <= _allowed[_from][msg.sender],"Insufficient allowance.");
                
                _balances[_from] = _balances[_from].sub(_value);
                _totalSupply = _totalSupply.sub(_value);
                _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
                
                emit Transfer(_from, address(0x0), _value);

                return true;
        }
        

        function approve(address _spender, uint256 _value) public validDestination(_spender) returns (bool) {

                _allowed[msg.sender][_spender] = _value;
                emit Approval(msg.sender, _spender, _value);
                return true;
        }

        function allowance(address _owner, address _spender) public view returns (uint256)
        {
                return _allowed[_owner][_spender];
        }
}


contract Ownable {
        address private _owner;

        event OwnershipTransferred(
                address indexed previousOwner,
                address indexed newOwner
        );

        constructor() public {
                _owner = msg.sender;
        }

        modifier validateAddress(address _to) {
                require(_to != address(0x0));
				require(_to != address(this));
                _;
        }

        modifier onlyOwner() {
                require(msg.sender == _owner, "Permission denied.");
                _;
        }
		
		function owner() public view returns (address) {
		        return _owner;
		}
		
        function transferOwnership(address _newOwner) public onlyOwner validateAddress(_newOwner) returns (bool) {
                _owner = _newOwner;
                emit OwnershipTransferred(_owner, _newOwner);
                return true;
        }
}


contract Pausable is Ownable {
        event Pause();
        event Unpause();

        bool public paused = false;

        modifier whenNotPaused() {
                require(!paused, "Paused by owner.");
                _;
        }

        modifier whenPaused() {
                require(paused, "Paused requied.");
                _;
        }

        function pause() public onlyOwner whenNotPaused {
                paused = true;
                emit Pause();
        }

        function unpause() public onlyOwner whenPaused {
                paused = false;
                emit Unpause();
        }
}


contract Freezable is Ownable {
        mapping (address => bool) public frozenAccount;

        event Freezed(address indexed target);
        event Unfreezed(address indexed target);

        modifier isNotFrozen(address _target) {
                require(!frozenAccount[_target], "Frozen account.");
                _;
        }

        modifier isFrozen(address _target) {
                require(frozenAccount[_target], "Not a frozen account.");
                _;
        }

        function freeze(address _target) public onlyOwner isNotFrozen(_target) validateAddress(_target) returns (bool) {
                frozenAccount[_target] = true;
                emit Freezed(_target);
                return true;
        }

        function unfreeze(address _target) public onlyOwner isFrozen(_target) validateAddress(_target) returns (bool) {
                frozenAccount[_target] = false;
                emit Unfreezed(_target);
                return true;
        }

}

contract MTCT06 is StandardToken, Pausable, Freezable {
        using SafeMath for uint256;

        string  public  name = "MTCT06";
        string  public  symbol = "MTCT06";
        uint256 public  constant decimals = 12;
        
        event MultiTransfer(address[] recipients, uint256[] values, uint256 sumOfTransfer, bool[] result);
        
        constructor(
                uint256 _initialSupply
        )
                public
        {
                _totalSupply = _initialSupply * 10 ** uint256(decimals);
                _balances[msg.sender] = _totalSupply;     
                emit Transfer(address(0x0), msg.sender, _totalSupply);
        }
		
        function transfer(address _to, uint256 _value)
                public
                whenNotPaused
                isNotFrozen(msg.sender)
                returns (bool)
        {
                return super.transfer(_to, _value);
        }

        function multiTransfer(address[] memory _recipients, uint256[] memory _values)
                public
                whenNotPaused
                isNotFrozen(msg.sender)
                returns (bool[] memory)
        {
                uint256 sumOfRequest = 0;
                for (uint256 i = 0; i < _recipients.length; i++) {
                    sumOfRequest += _values[i];
                }
                require(balanceOf(msg.sender) >= sumOfRequest, "Insufficient balance.");
                bool[] memory result = new bool[](_recipients.length);
                for (uint256 i = 0; i < _recipients.length; i++) {
                    result[i] = super.transfer(_recipients[i], _values[i]);
                }
                emit MultiTransfer(_recipients, _values, sumOfRequest, result);
                return result;
        }

        function multiFreeze(address[] memory _recipients)
                public
                onlyOwner
                returns (bool[] memory)
        {
                bool[] memory result = new bool[](_recipients.length);
                for (uint256 i = 0; i < _recipients.length; i++) {
                    if (!frozenAccount[_recipients[i]]) {
                        result[i] = super.freeze(_recipients[i]);
                    }
                }
                return result;
        }

        function multiUnfreeze(address[] memory _recipients)
                public
                onlyOwner
                returns (bool[] memory)
        {
                bool[] memory result = new bool[](_recipients.length);
                for (uint256 i = 0; i < _recipients.length; i++) {
                    if (frozenAccount[_recipients[i]]) {
                        result[i] = super.unfreeze(_recipients[i]);
                    }
                }
                return result;
        }

        function transferFrom(address _from, address _to, uint256 _value)
                public
                whenNotPaused
                isNotFrozen(_from)
                returns (bool)
        {
                return super.transferFrom(_from, _to, _value);
        }

        function burn(uint256 _value)
                public
                whenNotPaused
                isNotFrozen(msg.sender)
                returns (bool)
        {
                return super.burn(_value);
        }

        function burnFrom(address _from, uint256 _value)
                public
                whenNotPaused
                isNotFrozen(_from)
                returns (bool)
        {
                return super.burnFrom(_from, _value);
        }

        function approve(
                address _spender,
                uint256 _value
        )
                public
                whenNotPaused
                isNotFrozen(msg.sender)
                isNotFrozen(_spender)
                returns (bool)
        {
                return super.approve(_spender, _value);
        }
        
}