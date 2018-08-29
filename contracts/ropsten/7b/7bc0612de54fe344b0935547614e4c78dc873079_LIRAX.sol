pragma solidity ^0.4.18;

//https://github.com/ethereum/EIPs/issues/223 - ok
contract LIRAX {
    string public name = "LIRAX";
    uint8 public decimals = 18;
    string public symbol = "LRX";
    //string public version = "GBC 1.0";
    uint256 public totalSupply;
    mapping(address => uint) balancesOf;
    event LogAddTokenEvent(address indexed to, uint value);
    event LogDestroyEvent(address indexed from, uint value);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

    function LIRAX(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balancesOf[msg.sender] = _totalSupply;
    }

    // Get the total token supply
    function totalSupply() public constant returns (uint256 _supply){
        return totalSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool ok){
        require(balancesOf[msg.sender] >= _value);
        balancesOf[msg.sender] -= _value;
        balancesOf[_to] += _value;
        return true;
    }

    function balanceOf(address who) public view returns (uint balance) {
        return balancesOf[who];
    }

    function add(address _to, uint256 _value) public {
        totalSupply += _value;
        balancesOf[_to] += _value;

        LogAddTokenEvent(_to, _value);
    }

    function destroy(address _from, uint256 _value) public {
        totalSupply -= _value;
        balancesOf[_from] -= _value;
        LogDestroyEvent(_from, _value);
    }
}