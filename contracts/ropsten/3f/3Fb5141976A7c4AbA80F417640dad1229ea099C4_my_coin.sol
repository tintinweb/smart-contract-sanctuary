/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.5.0;

contract my_coin{
    string public name;
    string  public symbol;
    uint256 public totalSupply;//6 billion coins
    uint8   public decimals;
    address public charity_wallet=0x5b59cA3ca4121E42e5550F76546E22a712491cBc;
    address public tax_wallet=0xe5a014d8c62213830F2dbE5660D5B22912D6a21e;
    address public owner_wallet=0x04e8Bbe7159b9637505A6e408BD6Ae24b920Fc16;
    
    address[] public users;
    mapping(address => bool) public isUser;
    uint256 public redistribution=0;
    uint256 public andel=0;
    uint256 public allAccounts=0;
    uint256 public difference=0;
    
    event Transfer(
        address indexed _from,
        address indexed _to, 
        uint _value
    );
    
    event Approval(
        address indexed _owner,
        address indexed _spender, 
        uint _value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() public {
        name="my coins";
        symbol="mCOINs";
        totalSupply = 6000000000000000000000000000;
        decimals = 18;
        balanceOf[tax_wallet] = totalSupply;
        users.push(charity_wallet);
        users.push(tax_wallet);
        isUser[charity_wallet]=true;
        isUser[tax_wallet]=true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= (_value/1000)*1015);
        // add the balance
        balanceOf[_to] += _value;
        // transfer the amount and subtract the balance
        balanceOf[msg.sender] -= _value;
        
        if(!isUser[_to]) {
            users.push(_to);
            isUser[_to]=true;
        }
        redistribution=(_value/1000)*15/100*40;//It works now
        for (uint i=0; i<users.length; i++) {
            andel=100000000000000000000*balanceOf[users[i]]/totalSupply;
            balanceOf[users[i]]+=andel*redistribution/100000000000000000000;
        }
        balanceOf[msg.sender] -= (_value/1000)*15;
        
        emit Transfer(msg.sender, _to, _value);
        
        balanceOf[charity_wallet]+=(_value/1000)*15/100*10;//This is charity
        balanceOf[tax_wallet]+=(_value/1000)*15/100*35;//This is tax
        totalSupply-=(_value/1000)*15/100*15;//This is burn
        allAccounts=0;
        difference=0;
        for (uint i=0; i<users.length; i++) {
            allAccounts+=balanceOf[users[i]];
        }
        difference=totalSupply-allAccounts;
        balanceOf[tax_wallet]+=difference;
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        require(msg.sender==tax_wallet);
        balanceOf[tax_wallet]-=_value;
        totalSupply-=_value;
        return true;
    }
    
    function distribute(address _to, uint256 _value) public returns (bool success){//I don't know if distribute will work with metamask
        require(balanceOf[msg.sender] >= _value);
        require(msg.sender==tax_wallet);
        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;
        if(!isUser[_to]) {
            users.push(_to);
            isUser[_to]=true;
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function supply() public returns (uint256 _amount){
        return totalSupply;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require((_value/1000)*1015 <= balanceOf[_from]);
        require((_value/1000)*1015 <= allowance[_from][msg.sender]);
        // add the balance for transferFrom
        balanceOf[_to] += _value;
        
        // subtract the balance for transferFrom
        balanceOf[_from] -= _value;
        allowance[msg.sender][_from] -= _value;
        
        if(!isUser[_to]) {
            users.push(_to);
            isUser[_to]=true;
        }
        
        redistribution=(_value/1000)*15/100*40;//Redistribution works and disappearance of coins has been solved by tranferring them to tax wallet
        for (uint i=0; i<users.length; i++) {
            andel=100000000000000000000*balanceOf[users[i]]/totalSupply;
            balanceOf[users[i]]+=andel*redistribution/100000000000000000000;
        }
        
        // subtract the balance for transferFrom
        balanceOf[_from] -= (_value/1000)*15;
        allowance[msg.sender][_from] -= (_value/1000)*15;
        
        emit Transfer(_from, _to, _value);
        
        balanceOf[charity_wallet]+=(_value/1000)*15/100*10;//this is charity
        balanceOf[tax_wallet]+=(_value/1000)*15/100*35;//This is tax
        totalSupply-=(_value/1000)*15/100*15;//This is burn
        
        allAccounts=0;
        difference=0;
        for (uint i=0; i<users.length; i++) {
            allAccounts+=balanceOf[users[i]];
        }
        difference=totalSupply-allAccounts;
        balanceOf[tax_wallet]+=difference;
        return true;
    }
}