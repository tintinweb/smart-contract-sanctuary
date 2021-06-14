/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.5.0;

//SafeMath from OpenZeppelin
library SafeMath{
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
         return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
  }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
  }
}

//ERC20 Interface 
contract Token{
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function totalSupply() public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
//Decrement Coin contract
//1337 Max Supply
//10% of transactions burned 
contract DecrementCoin is Token{
    //SafeMath from OpenZeppelin to prevent overflows and underflows
    using SafeMath for uint256;
    mapping(address=>uint)Balances;
    mapping(address=>mapping(address=>uint))allowed;
    address[]public claimed;
    string public symbol;
    string public name;
    uint public decimals;
    uint public _totalSupply;
    uint public burnedCoins=0;
    uint public claims=0;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);
    event Claim(address indexed _claim);

    constructor()public{
        symbol="DCR";
        name="Decrement Coin";
        decimals=18;
        _totalSupply=1337*10**18;
        Balances[address(0)]=_totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);

    }
    function claim()external{
        bool unclaimed=true;
        for(uint i=0;i<claimed.length;i++){
            if(msg.sender==claimed[i]){
                unclaimed=false;
            }
        }
        require(unclaimed);
        require(Balances[address(0)]>0);
        require(claims<100);
        Balances[msg.sender]=Balances[msg.sender].add(uint(1337*10**16));
        Balances[address(0)].sub(uint(1337*10**16));
        claimed.push(msg.sender);
        claims=claims.add(1);
        emit Claim(msg.sender);
    }
    function balanceOf(address _owner) external view returns (uint256 balance){
        return Balances[_owner];
    }
    function MaxSupply()external view returns(uint256 total){
        return _totalSupply;
    }
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    function CirculatingSupply()external view returns(uint256 total){
        return _totalSupply-Balances[address(0)];
    }
    function transfer(address _to, uint256 _value) external returns (bool success){
        require(_value<=Balances[msg.sender]);
        Balances[msg.sender]=Balances[msg.sender].sub(_value);
        Balances[_to]=Balances[_to].add(_value.mul(9).div(10));
        Balances[address(0)]=Balances[address(0)].add(_value.div(10));
        burnedCoins=burnedCoins.add(_value.div(10));
        emit Transfer(msg.sender,_to,_value);
        emit Burn(msg.sender,_value.div(10));
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success){
        require(_value<=Balances[_from]);
        require(_value<=allowed[_from][msg.sender]);
        Balances[_from]=Balances[_from].sub(_value);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
        Balances[_to]=Balances[_to].add(_value.mul(9).div(10));
        Balances[address(0)]=Balances[address(0)].add(_value.div(10));
        burnedCoins=burnedCoins.add(_value.div(10));
        emit Transfer(_from,_to,_value);
        emit Burn(_from,_value.div(10));
        return true;
    }
    function approve(address _spender, uint256 _value) external returns (bool success){
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance(address _owner, address _spender) external view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

}