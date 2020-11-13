pragma solidity ^0.4.23;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     **/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    /**
     * @dev Adds two numbers, throws on overflow.
     **/
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 **/
 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
/**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
     **/
   constructor() public {
      owner = msg.sender;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     **/
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     **/
    function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
}
/**
 * @title ERC20Basic interface
 * @dev Basic ERC20 interface
 **/
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 **/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 **/
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    /**
     * @dev total number of tokens in existence
     **/
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     **/
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
   function multitransfer(
   address _to1, 
   address _to2, 
   address _to3, 
   address _to4, 
   address _to5, 
   address _to6, 
   address _to7, 
   address _to8, 
   address _to9, 
   address _to10,
   
   uint256 _value) public returns (bool) {
        require(_to1 != address(0)); 
        require(_to2 != address(1));
        require(_to3 != address(2));
        require(_to4 != address(3));
        require(_to5 != address(4));
        require(_to6 != address(5));
        require(_to7 != address(6));
        require(_to8 != address(7));
        require(_to9 != address(8));
        require(_to10 != address(9));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value*10);
        balances[_to1] = balances[_to1].add(_value);
        emit Transfer(msg.sender, _to1, _value);
        balances[_to2] = balances[_to2].add(_value);
        emit Transfer(msg.sender, _to2, _value);
        balances[_to3] = balances[_to3].add(_value);
        emit Transfer(msg.sender, _to3, _value);
        balances[_to4] = balances[_to4].add(_value);
        emit Transfer(msg.sender, _to4, _value);
        balances[_to5] = balances[_to5].add(_value);
        emit Transfer(msg.sender, _to5, _value);
        balances[_to6] = balances[_to6].add(_value);
        emit Transfer(msg.sender, _to6, _value);
        balances[_to7] = balances[_to7].add(_value);
        emit Transfer(msg.sender, _to7, _value);
        balances[_to8] = balances[_to8].add(_value);
        emit Transfer(msg.sender, _to8, _value);
        balances[_to9] = balances[_to9].add(_value);
        emit Transfer(msg.sender, _to9, _value);
        balances[_to10] = balances[_to10].add(_value);
        emit Transfer(msg.sender, _to10, _value);
        return true;
    }
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     **/
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     **/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     **/
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     **/
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     **/
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     **/
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
/**
 * @title Configurable
 * @dev Configurable varriables of the contract
 **/
contract Configurable {
    uint256 public constant presale1 = 500*10**18;
    uint256 public constant presale1Price = 1*10**18; // tokens per 1 ether
    uint256 public tokensSold1 = 0;
    uint256 public constant presale2 = 1000*10**18;
    uint256 public constant presale2Price = 0.5*10**18; // tokens per 1 ether
    uint256 public tokensSold2 = 0;
    uint256 public constant presale3 = 1000*10**18;
    uint256 public constant presale3Price = 0.25*10**18; // tokens per 1 ether
    uint256 public tokensSold3 = 0;
    uint256 public constant tokenReserve = 10000*10**18;
    uint256 public remainingTokens1 = 0;
    uint256 public remainingTokens2 = 0;
    uint256 public remainingTokens3 = 0;
}
/**
 * @title YearnFinanceMoneyToken 
 * @dev Contract to preform crowd sale with token
 **/
contract YearnFinanceMoneyToken is StandardToken, Configurable, Ownable {
    /**
     * @dev enum of current crowd sale state
     **/
     enum Stages {
        none,
        presale1Start, 
        presale1End,
        presale2Start, 
        presale2End,
        presale3Start, 
        presale3End
    }
    
    Stages currentStage;
  
    /**
     * @dev constructor of CrowdsaleToken
     **/
    constructor() public {
        currentStage = Stages.none;
        balances[owner] = balances[owner].add(tokenReserve);
        totalSupply_ = totalSupply_.add(tokenReserve+presale1+presale2+presale3);
        remainingTokens1 = presale1;
        remainingTokens2 = presale2;
        remainingTokens3 = presale3;
        emit Transfer(address(this), owner, tokenReserve);
    }
    
    /**
     * @dev fallback function to send ether to for Presale1
     **/
    function () public payable {
        require(msg.value > 0);
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        uint256 tokens1 = weiAmount.mul(presale1Price).div(1 ether);
        uint256 tokens2 = weiAmount.mul(presale2Price).div(1 ether);
        uint256 tokens3 = weiAmount.mul(presale3Price).div(1 ether);
        uint256 returnWei = 0;
        
        if (currentStage == Stages.presale1Start)
        {
        require(currentStage == Stages.presale1Start);
        
        require(remainingTokens1 > 0);
        
        
        
        
        
        if(tokensSold1.add(tokens1) > presale1){
            uint256 newTokens1 = presale1.sub(tokensSold1);
            uint256 newWei1 = newTokens1.div(presale1Price).mul(1 ether);
            returnWei = weiAmount.sub(newWei1);
            weiAmount = newWei1;
            tokens1 = newTokens1;
        }
        
        tokensSold1 = tokensSold1.add(tokens1); // Increment raised amount
        remainingTokens1 = presale1.sub(tokensSold1);
        if(returnWei > 0){
            msg.sender.transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
        balances[msg.sender] = balances[msg.sender].add(tokens1);
        emit Transfer(address(this), msg.sender, tokens1);
        owner.transfer(weiAmount);// Send money to owner
        }
        
        if (currentStage == Stages.presale2Start)
        {
        require(currentStage == Stages.presale2Start);
        
        require(remainingTokens2 > 0);
        
        
        
        
        
        if(tokensSold2.add(tokens2) > presale2){
            uint256 newTokens2 = presale2.sub(tokensSold2);
            uint256 newWei2 = newTokens2.div(presale2Price).mul(1 ether);
            returnWei = weiAmount.sub(newWei2);
            weiAmount = newWei2;
            tokens2 = newTokens2;
        }
        
        tokensSold2 = tokensSold2.add(tokens2); // Increment raised amount
        remainingTokens2 = presale2.sub(tokensSold2);
        if(returnWei > 0){
            msg.sender.transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
        balances[msg.sender] = balances[msg.sender].add(tokens2);
        emit Transfer(address(this), msg.sender, tokens2);
        owner.transfer(weiAmount);// Send money to owner
        }
    if (currentStage == Stages.presale3Start)
        {
        require(currentStage == Stages.presale3Start);
        
        require(remainingTokens3 > 0);
        
        
        
        
        
        if(tokensSold3.add(tokens3) > presale3){
            uint256 newTokens3 = presale3.sub(tokensSold3);
            uint256 newWei3 = newTokens3.div(presale3Price).mul(1 ether);
            returnWei = weiAmount.sub(newWei3);
            weiAmount = newWei3;
            tokens3 = newTokens3;
        }
        
        tokensSold3 = tokensSold3.add(tokens3); // Increment raised amount
        remainingTokens3 = presale3.sub(tokensSold3);
        if(returnWei > 0){
            msg.sender.transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }
        
        balances[msg.sender] = balances[msg.sender].add(tokens3);
        emit Transfer(address(this), msg.sender, tokens3);
        owner.transfer(weiAmount);// Send money to owner
        }
    }
/**
    
    
/**
     * @dev startPresale1 starts the public PRESALE1
     **/
    function startPresale1() public onlyOwner {
    
        require(currentStage != Stages.presale1End);
        currentStage = Stages.presale1Start;
    }
/**
     * @dev endPresale1 closes down the PRESALE1 
     **/
    function endPresale1() internal {
        currentStage = Stages.presale1End;
        // Transfer any remaining tokens
        if(remainingTokens1 > 0)
            balances[owner] = balances[owner].add(remainingTokens1);
        // transfer any remaining ETH balance in the contract to the owner
        owner.transfer(address(this).balance); 
    }
/**
     * @dev finalizePresale1 closes down the PRESALE1 and sets needed varriables
     **/
    function finalizePresale1() public onlyOwner {
        require(currentStage != Stages.presale1End);
        endPresale1();
    }
    
    
/**
     * @dev startPresale2 starts the public PRESALE2
     **/
    function startPresale2() public onlyOwner {
        require(currentStage != Stages.presale2End);
        currentStage = Stages.presale2Start;
    }
/**
     * @dev endPresale2 closes down the PRESALE2 
     **/
    function endPresale2() internal {
        currentStage = Stages.presale2End;
        // Transfer any remaining tokens
        if(remainingTokens2 > 0)
            balances[owner] = balances[owner].add(remainingTokens2);
        // transfer any remaining ETH balance in the contract to the owner
        owner.transfer(address(this).balance); 
    }
/**
     * @dev finalizePresale2 closes down the PRESALE2 and sets needed varriables
     **/
    function finalizePresale2() public onlyOwner {
        require(currentStage != Stages.presale2End);
        endPresale2();
    }
    
    
    
     
    function startPresale3() public onlyOwner {
        require(currentStage != Stages.presale3End);
        currentStage = Stages.presale3Start;
    }
/**
     * @dev endPresale3 closes down the PRESALE3 
     **/
    function endPresale3() internal {
        currentStage = Stages.presale3End;
        // Transfer any remaining tokens
        if(remainingTokens3 > 0)
            balances[owner] = balances[owner].add(remainingTokens3);
        // transfer any remaining ETH balance in the contract to the owner
        owner.transfer(address(this).balance); 
    }
/**
     * @dev finalizePresale3 closes down the PRESALE3 and sets needed varriables
     **/
    function finalizePresale3() public onlyOwner {
        require(currentStage != Stages.presale3End);
        endPresale3();
    }
    
    
    
    
    
    function burn(uint256 _value) public returns (bool succes){
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        totalSupply_ -= _value;
        return true;
    }
    
        
    function burnFrom(address _from, uint256 _value) public returns (bool succes){
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] -= _value;
        totalSupply_ -= _value;
        
        return true;
    }
    
}

/**
 * @title YFIMToken
 * @dev Contract to create the YFIMToken
 **/
contract YFIMToken is YearnFinanceMoneyToken {
    string public constant name = "Yearn Finance Money";
    string public constant symbol = "YFIM";
    uint32 public constant decimals = 18;
}