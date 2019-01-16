pragma solidity^0.4.25; //solidity版本號
contract HelloWorld{ //contract 宣告 + contract 名稱
	string word;
    function saySomething(string _word) public { 
        word = _word;
    }
    function listening() public view returns(string){
        return word;
    }

    int myAge = 333;
    function HowOldAreYou() public view returns(int _respond){
        _respond = myAge;
    }
    
}