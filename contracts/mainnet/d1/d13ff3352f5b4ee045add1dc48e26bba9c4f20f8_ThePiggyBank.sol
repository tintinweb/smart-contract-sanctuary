/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

//
//
//    ______  __ __    ___      ____ ____   ____   ____  __ __      ____    ____  ____   __  _ 
//   |      ||  |  |  /  _]    |    \    | /    | /    ||  |  |    |    \  /    ||    \ |  |/ ]
//   |      ||  |  | /  [_     |  o  )  | |   __||   __||  |  |    |  o  )|  o  ||  _  ||  ' / 
//   |_|  |_||  _  ||    _]    |   _/|  | |  |  ||  |  ||  ~  |    |     ||     ||  |  ||    \ 
//     |  |  |  |  ||   [_     |  |  |  | |  |_ ||  |_ ||___, |    |  O  ||  _  ||  |  ||     \
//     |  |  |  |  ||     |    |  |  |  | |     ||     ||     |    |     ||  |  ||  |  ||  .  |
//     |__|  |__|__||_____|    |__| |____||___,_||___,_||____/     |_____||__|__||__|__||__|\_|
//
// The Reflect 3 team ($RFIII) is launching their 2nd project in the Reflect 3 Ecosystem.
// “The Piggy Bank” is all about generating a passive income for token holders of the first project $RFIII and holders of this token.
// The third farming pool is supported with our partner Corlibri. All pools will pair with ETH and mint new RFPIG tokens but can have different and variable APY (returns).
//
//
// Medium: https://thepiggybank.medium.com/
// Website: https://reflect3finance.com/
// Twitter: https://twitter.com/financereflect3
// Telegram: https://t.me/reflectfinance3
//
//

pragma solidity 0.7.4;

// SPDX-License-Identifier: MIT

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;
    address newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function balanceOf(address _owner) view public returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract ThePiggyBank is Owned,ERC20{
    uint256 public maxSupply;

    constructor(address _owner) {
        symbol = "RFPIG";
        name = "ThePiggyBank";
        decimals = 18;                           // 18 Decimals
        totalSupply = 150000e18;                 // 150,000 RFPIG and 18 Decimals
        maxSupply   = 150000e18;                 // 150,000 RFPIG and 18 Decimals
        owner = _owner;
        balances[owner] = totalSupply;
    }
    
    receive() external payable {
        revert();
    }
}