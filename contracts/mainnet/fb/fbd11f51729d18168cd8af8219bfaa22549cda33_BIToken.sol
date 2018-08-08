pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        require(a == b * c + a % b); // There is no case in which this doesn’t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a-b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract BIToken {

    ///Public variables of the token
    string public constant name = "Basic Integration Token";
    uint8 public constant decimals = 18;
    string public constant symbol="BINTO";
    string public constant version = "1.0";
    using SafeMath for uint256;
    address public ownerAccount;
    uint256 public totalSupply;
    
    //initialSupply of token without decimals
    uint256 public constant initialSupply = 1000 * (10**6); //total tokens without decimals
    
    //initial rate
    uint256 public purchaseRate = 10000;
    
    //to finish the sale
    bool public isSaleEnded = false;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);

    constructor () public {
        ownerAccount = msg.sender;
        totalSupply = initialSupply*(10**uint256(decimals));
        balances[msg.sender] = totalSupply; 
    }
    
    //setting Modifier
    modifier onlyOwner() {
        require (msg.sender == ownerAccount);
        _;
    }
    
    //purchase rate is changed by  owner in ico and post ico phases
    function setPurchaseRate(uint newRate) public onlyOwner {
        require(purchaseRate != newRate);
        purchaseRate = newRate;
    }
    
    //burn token held by  owner only in case he decides so to destroy
    //any extra tokens in far future.
    function burnToken(uint numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0);
        require(balances[msg.sender] >= numberOfTokens);
        balances[msg.sender] = balances[msg.sender].sub(numberOfTokens);
        totalSupply = totalSupply.sub(numberOfTokens);
        emit Burn(msg.sender,numberOfTokens);
        emit Transfer(msg.sender, address(0), numberOfTokens);
    }

    function endSale() public onlyOwner {
        isSaleEnded = true;
    }

    //sending Eather to Owner
    function sendEtherToOwner() payable public {
        uint256 owneramount = msg.value;
        require(isSaleEnded == false);
        require(owneramount > 0);
        uint256 tokens = purchaseRate.mul(owneramount);
        require(tokens > 0);
        //increse allowances , those will be reduced in transferFrom method again
        allowed[ownerAccount][msg.sender] = allowed[ownerAccount][msg.sender].add(tokens);
        transferFrom(ownerAccount,msg.sender, tokens);
        ownerAccount.transfer(owneramount);
    }
        
    
    //Transfer Token directly to Owner 
    function () payable public {
        sendEtherToOwner();
    }
    
    
    function transfer(address _to, uint256 _value) public  returns (bool){
        
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        //check condition to avoid Overflows
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      
        require(_value > 0);
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender,uint _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender,uint _subtractedValue) public returns (bool){
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }    
    
}