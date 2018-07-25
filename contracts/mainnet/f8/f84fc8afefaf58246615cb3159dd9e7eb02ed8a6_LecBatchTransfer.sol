pragma solidity ^0.4.18;

contract ERC223Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223 is ERC223Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IOwned {
    function owner() public pure returns (address) { owner; }
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

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract LecStop is Owned{

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


contract LecBatchTransfer is  Owned,LecStop{
    
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
    
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }
    
    event LOG_Transfer_Contract(address indexed _from, uint256 _value, bytes indexed _data);

    function LecBatchTransfer() public{
    }
    
    function tokenFallback(address _from, uint _value, bytes _data) public{
        LOG_Transfer_Contract(_from, _value, _data);
    }
    
    function batchTransfer(ERC223 _token,address[] _to,uint256 _amountOfEach) public 
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
    
    function withdrawERC20TokenTo(ERC223 _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));

    }

}