/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity ^0.8.2;

contract Restricted {

    struct Record {
        uint value;
        uint256 timestamp;
    }

    mapping(uint256 => Record) deque;
    uint256 first = 2**255;
    uint256 last = first - 1;

    function updateRestricted() public returns(uint) {
        uint sum = 0;
        Record memory left = _peekLeft();
        while (!((left.value == 0 && left.timestamp == 0) || left.timestamp > (block.timestamp - 60))) { 
            sum += left.value;
            _popLeft();
            left = _peekLeft();
        }
        return sum;
    }

    function _peekLeft() public view returns (Record memory record) {

        if (last < first) {
            record = Record(0, 0);
        } else {
            record = deque[first];
        }
        return record;
    }

    function _popLeft() public{
        require(last >= first, "no restricted tokens");  // non-empty deque

        delete deque[first];
        first += 1;
    }

    function push(uint value) public {
        Record memory record = Record(value, block.timestamp);
        _pushRight(record);
    }

    function _pushRight(Record memory record) public {
        last += 1;
        deque[last] = record;
    }
}

contract TestToken {

    mapping(address => uint) public balances;
    mapping(address => Restricted) public restricted;
    mapping(address => uint) public tradable;

    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 8000000000 * 10 ** 18;
    string public name = "Omicron Token";
    string public symbol = "OMI";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        tradable[msg.sender] = totalSupply;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function tradableValueOf(address owner) public returns(uint) {

        if (address(restricted[owner]) == address(0)){
            restricted[owner] = new Restricted();
        } 

        _updateTradable(owner);
        return tradable[owner];
    }
    
    function _updateTradable(address owner) public {
        tradable[owner] += restricted[owner].updateRestricted();
    } 

    
    function transfer(address to, uint value) public returns(bool) {

        if (address(restricted[to]) == address(0)){
            restricted[to] = new Restricted();
        } 

        if (address(restricted[msg.sender]) == address(0)){
            restricted[msg.sender] = new Restricted();
        } 

        _updateTradable(msg.sender);
        require(tradableValueOf(msg.sender) >= value, string(abi.encodePacked('Balance too low. ', 'Total balance: ',  uint2str(balances[msg.sender]), ' Tradable Token: ', uint2str(tradableValueOf(msg.sender)))));
        balances[to] += value;
        restricted[to].push(value);
        balances[msg.sender] -= value;
        tradable[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        if (address(restricted[to]) == address(0)){
            restricted[to] = new Restricted();
        } 

        if (address(restricted[msg.sender]) == address(0)){
            restricted[msg.sender] = new Restricted();
        } 

        _updateTradable(from);
        require(tradableValueOf(from) >= value, string(abi.encodePacked('Balance too low. ', 'Total balance: ',  uint2str(balances[msg.sender]), ' Tradable Token: ', uint2str(tradableValueOf(msg.sender)))));
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        restricted[to].push(value);
        balances[from] -= value;
        tradable[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}