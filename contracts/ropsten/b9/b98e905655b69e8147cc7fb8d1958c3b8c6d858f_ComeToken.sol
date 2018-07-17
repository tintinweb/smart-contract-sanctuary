pragma solidity ^0.4.24;

contract ComeToken {
    string public name = &quot;Come Token&quot;;
    string public symbol = &quot;CT_1&quot;;
    uint8 public decimals = 18;
    uint256 public increasedSupply = 200000000 * 10 ** uint256(decimals);
    address public owner;
    uint8 saveRelease = 1;
    
    uint public year2020 = 1531453200;//20180713 11:40:00
    uint public year2021 = 1531454400;//20180713 12:00:00
    uint public year2022 = 1531458000;//20180713 13:00:00
    uint public year2023 = 1531461600;//20180713 14:00:00
    
    // uint public year2020 = 1577808000;//2020
    // uint public year2021 = 1609430400;//2021
    // uint public year2022 = 1640966400;//2022
    // uint public year2023 = 1672502400;//2023

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply();
    }
    
    function totalSupply() view public returns (uint256 _total) {
        return _calcRelease() * increasedSupply;
    }
    
    function releaseSupply() public returns (uint256 _total) {
        uint256 total = 0;
        if(msg.sender != owner)
            return total;
        uint8 release = _calcRelease();
        if(release > saveRelease) {   
            total = (release - saveRelease) * increasedSupply;
            balanceOf[owner] += total;
            saveRelease = release;
        }
        return total;
    }
    
    function _calcRelease() view internal returns (uint8 rel){
        uint8 release = 1;
        uint currTime = now;
        if(currTime < year2020)
            release = 1;
        else if(currTime < year2021)
            release = 2;
        else if(currTime < year2022)
            release = 3;
        else if(currTime < year2023)
            release = 4;
        else
            release = 5;
        
        return release;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}