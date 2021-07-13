/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

contract NerdsToken{
   
    mapping(address=>uint) public balances;
    mapping(address=> mapping(address=>uint)) public allowance;
   
    uint public totalSupply = 1000000000000 * 10 ** 9;
    string public name = "NerdsToken";
    string public symbol = "NRDS";
    uint public decimals =9;
   
   
   
    uint256 public RATE = 1;
    bool public isMinting = true;
    bool public isExchangeListed = true;
    string public constant generatedBy  = "DeFi Token for ETP" ;

    using SafeMath for uint256;
   
    address public   owner;

         // Functions with this modifier can only be executed by the owner
         modifier onlyOwner() {
            if (msg.sender != owner) {
                revert();
            }
             _;
         }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed, address indexed spender, uint value );

    receive() external payable {
            createTokens();
        }
   
    constructor() {

        owner = 0x5ace702B81fffC4e528b2f2968BB7980bbf468CF; //payable(msg.sender);
        balances[msg.sender] = totalSupply;
    }

    function burnTokens(uint256 _value) onlyOwner public {

             require(balances[msg.sender] >= _value && _value > 0 );
             totalSupply = totalSupply.sub(_value);
             balances[msg.sender] = balances[msg.sender].sub(_value);

        }


        // This function creates Tokens
         function createTokens() payable public {
            if(isMinting == true){
               // require(msg.value > 0);
              //  uint256  tokens = msg.value.div(100000000000000).mul(RATE);
              uint256  tokens = 3000000000;
                balances[msg.sender] = balances[msg.sender].add(tokens);
                totalSupply = totalSupply.add(tokens);
               
                payable(owner).transfer(msg.value);
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

    function balanceOf(address _owner) public view returns (uint256) {  return balances[_owner];}

    function transfer(address to, uint value) public returns(bool) {

        require (balanceOf(msg.sender)>= value, 'balance too low');
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender, to, value);
        return true;

    }

    function transferFrom(address from, address to, uint value) public returns(bool){

        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender]>= value, 'balance too low');
        balances[to]+= value;
        balances[from] -=value;
        emit Transfer(from, to, value);
        return true;
  }

    function approve(address spender, uint value) public returns(bool) {

        allowance[msg.sender][spender] =  value;

        emit Approval(msg.sender, spender, value);
        return true;


    }



}