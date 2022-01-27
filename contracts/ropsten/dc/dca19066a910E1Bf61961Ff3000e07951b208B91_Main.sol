/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
//Библиотека для безопаснх расчетов 
library SafeMath 
{

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b > 0);
        uint256 c = a / b;
        
	return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b != 0);
        return a % b;
    }
}

contract Main 
{

using SafeMath for uint;


    constructor () public 
    {
        period1 = block.timestamp.add(259200);//переменная кторая хранить дату конца 1 периода
        period2 = period1.add(2629743);//переменная кторая хранить дату конца 2 периода
        period3 = period2.add(1209600);//переменная кторая хранить дату конца 3 периода
        owner = msg.sender; //запись адреса владельца контракта 
        whitelist[msg.sender] = true;
	    totalSupply = 10000;
		name = "Test Token T";
		symbol = "TTT";
        decimals = 0;
		version = "1.0";
    }

    modifier onlyOwner ()
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhiteList ()
    {
        require(whitelist[msg.sender]);
        _;

    }

    

    uint private totalSupply;
    string private name;
    uint8 private decimals;
    string private symbol;
    string private version;
    uint private totalreal; 
    address private owner;

    uint private period1;
    uint private period2;
    uint private period3;
        
    uint private rate1 = 42;//вспомагательная переменная курса токена к эфиру в разные периоды 
    uint private rate2 = 21;//вспомагательная переменная курса токена к эфиру в разные периоды 
    uint private rate3 = 8;//вспомагательная переменная курса токена к эфиру в разные периоды 


    mapping(address=> uint)balance;
    mapping(address => bool)whitelist;
    mapping(address => mapping(address =>uint ))allowed;
    

    function addWhiteList (address add) public onlyOwner
    {
        whitelist[add] = true;  
    }
    
    function deliteWhiteList (address add) public onlyOwner
    {
        whitelist[add] = false;  
    }
  // функция покупки токенов 
    function buyTokens(uint _value) public payable onlyWhiteList returns(string memory)
    {
        require(_value >0);
        require(totalreal.add(_value) <= totalSupply);
        address payable addpayble = msg.sender;
       
        if(block.timestamp <= period1)
        {
            require(msg.value >= _value.mul((1 ether/rate1)),"ошибка");//проверка на корректное введение количесва эфира
            balance[addpayble] = balance[addpayble].add(_value);//добавление токенов на баланс пользователя 
            totalreal = totalreal.add(_value);//увелечение общего числа выпущеных токенов 
        }

        else if(block.timestamp > period1 && block.timestamp <= period2)
        {
            require(msg.value >= _value.mul((1 ether/rate2)),"ошибка");//проверка на корректное введение количесва эфира
            balance[addpayble] = balance[addpayble].add(_value);//добавление токенов на баланс пользователя
            totalreal = totalreal.add(_value);//увелечение общего числа выпущеных токенов 
        }

        else if(block.timestamp > period2 && block.timestamp <= period3)
        {
            require(msg.value == _value.mul((1 ether/rate3)),"ошибка");//проверка на корректное введение количесва эфира
            balance[addpayble] = balance[addpayble].add(_value);//добавление токенов на баланс пользователя
            totalreal = totalreal.add(_value);//увелечение общего числа выпущеных токенов
        }
        
        else return("Продажи прекращены");
      


    }
    
    function balanceOf (address add) public view returns (uint)
    {
        return(balance[add]);
    }

    function allowance (address _owner, address _spender) public view returns(uint) 
    {
        return(allowed[_owner][_spender]);
    }

    function transfer(address _to, uint _value) public onlyWhiteList
    {
        require( balance[msg.sender] >= _value);
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to]  = balance[_to].add(_value);   
        emit Transfer (msg.sender,_to,_value);
    }

    function transferFrom (address _from, address _to, uint _value) public
    {
        require( balance[_from] >= _value && allowed[_from][_to] >= _value);
        balance[_from] = balance[_from].sub(_value);
        balance[_to]  = balance[_to].add(_value); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer (msg.sender, _to, _value);

    }
    function approve (address spender, uint _value) public 
     {
         allowed[msg.sender][spender] = _value;
         emit Approve (msg.sender, spender, _value);
         
    }

    event Transfer( address _from,address _to ,uint _value);
    event Approve( address _from,address _to ,uint _value);



}