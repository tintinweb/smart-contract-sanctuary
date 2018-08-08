pragma solidity ^0.4.13;
 
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value)public returns (bool);
    function allowance(address owner, address spender)public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value)public returns (bool);
    function approve(address spender, uint256 value)public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}
 
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20 {
    
    using SafeMath for uint256;
    mapping(address => uint256) balances;
  
    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value)public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
 
    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return balances[_owner];
    }
 
}
 
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken {
 
    mapping (address => mapping (address => uint256)) allowed;
 
    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
        uint _allowance = allowed[_from][msg.sender];
 
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
 
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
 
    /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value)public returns (bool) {
 
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;
 
    /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    function Ownable()public {
        owner = msg.sender;
    }
 
    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner)public onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }
 
}
 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
 
    bool public mintingFinished = false;
 
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
 
    /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount)public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0, _to, _amount);
        return true;
    }
 
    /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
    function finishMinting()public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
    /*function approveAndCall(address spender, uint skolko) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(skolko.mul(1000000000000000000));
        allowed[msg.sender][spender] = skolko;
        Approval(msg.sender, spender, skolko);
        Crowdsale(spender).receiveApproval(msg.sender, skolko, address(this));
        return true;
    }
  */

}
 
contract MultiLevelToken is MintableToken {
    
    string public constant name = "Multi-level token";
    string public constant symbol = "MLT";
    uint32 public constant decimals = 18;
    
}
 
contract Crowdsale is Ownable{
    
    using SafeMath for uint;
    
    address multisig;
    uint multisigPercent;
    address bounty;
    uint bountyPercent;
 
    MultiLevelToken public token = new MultiLevelToken();
    uint rate;
    uint tokens;
    uint value;
    
    uint tier;
    uint i;
    uint a=1;
    uint b=1;
    uint c=1;
    uint d=1;
    uint e=1;
    uint parent;
    uint256 parentMoney;
    address whom;
    mapping (uint => mapping(address => uint))tree;
    mapping (uint => mapping(uint => address)) order;
 
    function Crowdsale()public {
        multisig = 0xB52E296b76e7Da83ADE05C1458AED51D3911603f;
        multisigPercent = 5;
        bounty = 0x1F2D3767D70FA59550f0BC608607c30AAb9fDa06;
        bountyPercent = 5;
        rate = 100000000000000000000;
        
    }
 
    function finishMinting() public onlyOwner returns(bool)  {
        token.finishMinting();
        return true;
    }
    
    function distribute() public{
        
        for (i=1;i<=10;i++){
            while (parent >1){
                if (parent%3==0){
                            parent=parent.div(3);
                            whom = order[tier][parent];
                            token.mint(whom,parentMoney);
                        }
                else if ((parent-1)%3==0){
                            parent=(parent-1)/3;
                            whom = order[tier][parent];
                            token.mint(whom,parentMoney); 
                        }
                else{
                            parent=(parent+1)/3;
                            whom = order[tier][parent];
                            token.mint(whom,parentMoney);
                        }
            }
        }
        
    }    
    
    function createTokens()public  payable {
        
        uint _multisig = msg.value.mul(multisigPercent).div(100);
        uint _bounty = msg.value.mul(bountyPercent).div(100);
        tokens = rate.mul(msg.value).div(1 ether);
        tokens = tokens.mul(55).div(100);
        parentMoney = msg.value.mul(35).div(10);
        
        if (msg.value >= 50000000000000000 && msg.value < 100000000000000000){
            tier=1;
            tree[tier][msg.sender]=a;
            order[tier][a]=msg.sender;
            parent = a;
            a+=1;
            distribute();
        }
        else if (msg.value >= 100000000000000000 && msg.value < 200000000000000000){
            tier=2;
            tree[tier][msg.sender]=b;
            order[tier][b]=msg.sender;
            parent = b;
            b+=1;
            distribute();
        }    
        else if (msg.value >= 200000000000000000 && msg.value < 500000000000000000){
            tier=3;
            tree[tier][msg.sender]=c;
            order[tier][c]=msg.sender;
            parent = c;
            c+=1;
            distribute();
        }
        else if(msg.value >= 500000000000000000 && msg.value < 1000000000000000000){
            tier=4;
            tree[tier][msg.sender]=d;
            order[tier][d]=msg.sender;
            parent = d;
            d+=1;
            distribute();
        }
        else if(msg.value >= 1000000000000000000){
            tier=5;
            tree[tier][msg.sender]=e;
            order[tier][e]=msg.sender;
            parent = e;
            e+=1;
            distribute();
        }
        token.mint(msg.sender, tokens);
        multisig.transfer(_multisig);
        bounty.transfer(_bounty);
    }
    
    /*address _tokenAddress;
    function GetTokenAddress (address Get) public onlyOwner{
        _tokenAddress=Get;
    }*/
    
    function receiveApproval(address from, uint skolko /*, address tokenAddress*/) public payable onlyOwner{
     //   require (tokenAddress == _tokenAddress);
        from.transfer(skolko.mul(1000000000000));
    }
    
    function() external payable {
        createTokens();
    }
}