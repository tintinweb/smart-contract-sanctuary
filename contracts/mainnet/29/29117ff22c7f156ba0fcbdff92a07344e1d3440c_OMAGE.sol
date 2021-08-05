/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

 
interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    
    event Transfer(
            address indexed from,
            address indexed to,
            uint256 value
          );
        
    event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
  );
}

    // ERC20 Token Smart Contract
    contract OMAGE  {

        string public constant name = "OMAGE";
        string public constant symbol = "OMA";
        uint8 public constant decimals = 18;
        uint public _totalSupply = 8000000000000000000000000;
        uint256 public RATE = 1;
        bool public isMinting = true;
        bool public isExchangeListed = true;
        string public constant generatedBy  = "OMAGE LGBTI COMMUNITY";

        using SafeMath for uint256;
        address payable public owner;

         // Functions with this modifier can only be executed by the owner
         modifier onlyOwner() {
            if (msg.sender != owner) {
                revert();
            }
             _;
         }

        // Balances for each account
        mapping(address => uint256) balances;
        // Owner of account approves the transfer of an amount to another account
        mapping(address => mapping(address=>uint256)) allowed;

        // Its a payable function works as a token factory.
         receive() external payable {
            createTokens();
        }

        // Constructor
        constructor() public payable {



         
            owner = 0x46A321d27B3a1Eb47f0E935f0e39298cdB599F11;
            balances[owner] = _totalSupply;
        }

        //allows owner to burn tokens that are not sold in a crowdsale
        function burnTokens(uint256 _value) onlyOwner public {

             require(balances[msg.sender] >= _value && _value > 0 );
             _totalSupply = _totalSupply.sub(_value);
             balances[msg.sender] = balances[msg.sender].sub(_value);

        }



        // This function creates Tokens
         function createTokens() payable public {
            if(isMinting == true){
                require(msg.value > 0);
                uint256  tokens = msg.value.div(100000000000000).mul(RATE);
                balances[msg.sender] = balances[msg.sender].add(tokens);
                _totalSupply = _totalSupply.add(tokens);
                owner.transfer(msg.value);
            }
            else{
                revert();
            }
        }


        function endCrowdsale() onlyOwner  public{
            isMinting = false;
        }

        function changeCrowdsaleRate(uint256 _value) onlyOwner public {
            RATE = _value;
        }



        function totalSupply() view public returns(uint256){
            return _totalSupply;
        }
        // What is the balance of a particular account?
        function balanceOf(address _owner) view public returns(uint256){
            return balances[_owner];
        }

         // Transfer the balance from owner's account to another account
        function transfer(address _to, uint256 _value)  public returns(bool) {
            require(balances[msg.sender] >= _value && _value > 0 );
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _value) public  returns(bool) {
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns(bool){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) view public returns(uint256){
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
}