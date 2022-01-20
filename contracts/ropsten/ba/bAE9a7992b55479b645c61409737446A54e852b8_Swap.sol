/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface ERC20{

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

contract Swap {
    ERC20 public token;
    uint percentage = 1;
    address public Owner;
    uint public tokenPerEth;
    uint public EthPerToken;
    
    mapping(address => uint) balances;

    event Bought(uint256 amount);
    event Sold(uint256 amount);
   
    constructor(address _token) {
        token = ERC20(_token);
        Owner = msg.sender;
        tokenPerEth = 1e17;
        EthPerToken = 10e18;
    }

    modifier OnlyOwner{
        require(Owner == msg.sender,"only owner can update");
        _;
    }
  
    receive() external payable { }

    function balanceOf(address owner) public view returns(uint){
        return owner.balance;
    }       

    function updatePercentage(uint _editpercentage) public OnlyOwner returns(bool){
        percentage = _editpercentage;
        return true;
    } 
    
    function updateEthPerToken(uint updateEth) public OnlyOwner returns(bool){
        EthPerToken = updateEth;
        return true;
    }

    function updateTokenPerEath(uint updateToken)public OnlyOwner returns(bool){
        tokenPerEth = updateToken;
        return true;
    }

    function Buy() public payable{
       uint transferfee = (msg.value * 10)/100;
       require(msg.value >= 0.1 ether, "must be atleast 0.1 ether");
       token.transfer(msg.sender,(msg.value  * EthPerToken /1e18)-transferfee);
    }

    function Sell(uint amount) public payable {
        uint transferfee = (amount * percentage)/100;
        token.transferFrom(msg.sender, address(this), amount);
        require(payable(msg.sender).send((amount * tokenPerEth / 1e18) -  transferfee)," error");
    }
}