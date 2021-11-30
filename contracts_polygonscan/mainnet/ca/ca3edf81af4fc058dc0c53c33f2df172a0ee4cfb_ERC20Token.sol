/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity ^0.4.18;

/* taking ideas from FirstBlood token */
contract SafeMath {

    function SafeMath() public {
    }

    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }

}


/**
    ERC20Token Standard Token implementation
*/
contract ERC20Token is SafeMath {
    uint8 public constant decimals = 8; 

    string public constant name = 'OilX';
    string public constant symbol = 'OILX';
    //Default assumes totalSupply can't be over max (2^256 - 1).
    //you need multiply 10^decimals by your real total supply.
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ERC20Token() public {
        balanceOf[msg.sender] = totalSupply;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function transfer(address _to, uint256 _value)
    public
    validAddress(_to)
    returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    validAddress(_from)
    validAddress(_to)
    returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    public
    validAddress(_spender)
    returns (bool success)
    {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // disable pay Eureka to this contract
    function () public payable {
        revert();
    }
}