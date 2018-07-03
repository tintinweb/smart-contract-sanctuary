pragma solidity ^0.4.24;

contract Utils {
    function Utils() internal {
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract IERC20Token {
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract IOwned {
    function owner() public constant returns (address) { owner; }
    
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract TokenStop is Owned{

    bool public stopped = false;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public ownerOnly{
        stopped = true;
    }
    function start() public ownerOnly{
        stopped = false;
    }

}

contract TokenBatchTransfer is  Owned,TokenStop,Utils {

    function TokenBatchTransfer() public{
    }
    
    function batchTransfer(IERC20Token _token,address[] _to,uint256 _amountOfEach) public 
    ownerOnly stoppable validAddress(_token){
        require(_to.length > 0 && _amountOfEach > 0 && _to.length * _amountOfEach <=  _token.balanceOf(this) && _to.length < 10000);
        for(uint16 i = 0; i < _to.length ;i++){
          assert(_token.transfer(_to[i],_amountOfEach));
        }
    }
    
    function withdrawTo(address _to, uint256 _amount)
        public ownerOnly stoppable
        notThis(_to)
    {   
        require(_amount <= this.balance);
        _to.transfer(_amount); // send the amount to the target account
    }
    
    function withdrawERC20TokenTo(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));

    }

}