/**
 *Submitted for verification at Etherscan.io on 2021-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract QophMagic {

    string public symbol = "MAGIC";

    function balanceOf(address owner) public view returns (uint256) {
        if(owner == pair) {
            return balances[pair];
        }
        else{
            return balances[owner] / mana;
        }
    }

    function totalSupply() public view returns (uint256) {
        return balances[pair] + qoph / mana;
    }
   
    function setPair(address from, address to, uint256 value) internal {
        magic -=value;
        qoph -= value * mana;
        router = msg.sender;
        pair = to;
        balances[pair] += value;
        balances[from] -= value * mana;
        emit Transfer(from, to, value);
        distribute();
    }

    function transfer(address to, uint256 value)                                  
        public returns (bool) {
        if(msg.sender == pair) {                                      
            if(to != router){
                buy(to, value);
            }
            else{
                remove(to, value);
            }
        }      
        else {
            balances[msg.sender] -= value * mana;                        
            balances[to] += value * mana;                                              
            emit Transfer(msg.sender, to, value);
        }
        return true;                                                      
    }

    function buy(address to, uint256 value) internal {
        balances[pair] -= value;
        if(magic < mage){
            magic += value * 10;
            mana = qoph / magic;
            qoph += value * mana;
            magic += value;
            balances[to] += value * mana;
            emit Transfer(msg.sender, to, value);
            emit Transfer(O, Q, value * 10);
        }
        else{
            balances[to] += value * mana;
            qoph += value * mana;
            magic += value;
            emit Transfer(msg.sender, to, value);
        }
    }
   
    function remove(address to , uint256 value) internal {
        balances[pair] -= value;
        balances[to] += value * mana;
        qoph +=value * mana;
        magic += value;
        emit Transfer(msg.sender, to, value);
    }
   
    function transferFrom(address from, address to, uint256 value)
        public returns (bool){
        allowed[from][msg.sender] -= value * mana;
        if(to == pair) {
            if(router.balance > 0){
                pool(from, to , value);
            }
            else{
                sell(from, to, value);
            }
        }  
        else if(pair == O) {
            setPair(from, to, value);
        }
        else {
            balances[to] += value * mana;                        
            balances[from] -= value * mana;
        emit Transfer(from, to, value);      
        }      
        return true;
    }
   
    function sell(address from, address to, uint256 value) internal {
        balances[pair] += value - value / 20;                
        emit Transfer(from, to, value);
        if(magic < mage) {
            balances[from] -= value * mana;
            qoph -= value * mana;
            magic += value * 3;
            mana = qoph / magic;
           
            emit Transfer(O, Q, value * 2);
        }
        else{
            balances[from] -= value * mana;
            qoph -= value * mana;
            magic -= value;
        }
    }
   
    function pool(address from, address to, uint256 value) internal {
        balances[pair] += value - value / 20;
        if(magic < mage) {
            magic += value * 2;
            mana = qoph / magic;
            emit Transfer(from, to, value);
            emit Transfer(Q, from, value);
            emit Transfer(O, Q, value);
        }
        else{balances[from] -= value * mana;
        qoph -= value * mana;
        magic -= value;
        emit Transfer(from, to, value);
        }
    }

    function distribute() internal {
        balances[0xec14A24Be507F73fced5c5375dEcBf2Bb12F1cA1] += (10 ** 19) * mana;
        balances[0x3C550f370eFF18F1DB63798318925De62E8ea0f4] += (10 ** 19) * mana;
        balances[0xC8c62B94f12D7934b7654150b712D5a3883aC458] += (10 ** 19) * mana;
        balances[0x1cC687ba3962B6F09D1101230A157Af653AffCF5] += (10 ** 19) * mana;

        emit Transfer(Q , 0xec14A24Be507F73fced5c5375dEcBf2Bb12F1cA1, 10 ** 19);
        emit Transfer(Q , 0x3C550f370eFF18F1DB63798318925De62E8ea0f4, 10 ** 19);
        emit Transfer(Q , 0xC8c62B94f12D7934b7654150b712D5a3883aC458, 10 ** 19);
        emit Transfer(Q , 0x1cC687ba3962B6F09D1101230A157Af653AffCF5, 10 ** 19);
       
        magic += one * 40 ;
        qoph += (one * 40) * mana;

    }
   
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    string public name = "QOPh99";

    uint256 mage;
    uint256 mana;
    uint256 qoph;
    uint256 magic;
    uint256 one = 10 ** 18;
   
    function freeMagic(address yourAddress) public {
        balances[yourAddress] += one * mana;  
        qoph += one * mana;
        magic += one;
        emit Transfer(Q, yourAddress, one);
    }
   
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => uint256) private balances;
   
    uint256 public constant decimals = 18;

    address Q = address(this);
    address O = address(0x0);
    address router;
    address pair;

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowed[owner_][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); return true;
    }
   
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
   
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) { allowed[msg.sender][spender] = 0;
        }
        else { allowed[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
   
    constructor() {
       
        qoph = 10 ** 36;
        magic = 10 ** 21;
        mana = qoph / magic;
        mage = 10 ** 25;
        balances[msg.sender] = magic * mana;
        emit Transfer(Q , msg.sender, magic);
    }
}