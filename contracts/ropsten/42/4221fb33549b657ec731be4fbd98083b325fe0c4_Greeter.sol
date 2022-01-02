/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.4.18;

contract Greeter {
	string helloKorean = "안녕?";
	string goodbyeKorean = "잘가!";
	string helloEnglish = "Hello";
	string goodbyeEnglish = "Goodbye!";

    function sayHello(uint8 lang) public view returns (string) {
        if (lang == 0)
            return helloKorean;
        if (lang == 1)
            return helloEnglish;
        
        return "";
    }

    function changeHello(uint8 lang, string _hello) public {
        if (lang == 0)
            helloKorean = _hello;
        if (lang == 1)
            helloEnglish = _hello;
    }

    function sayGoodbye(uint8 lang) public view returns (string) {
        if (lang == 0)
            return goodbyeKorean;
        if (lang == 1)
            return goodbyeEnglish;
        return "";
    }

    function changeGoodbye(uint8 lang,string _goodbye) public {
		if ( lang == 0 )
			goodbyeKorean = _goodbye;
		if ( lang == 1 )
			goodbyeEnglish = _goodbye;
	}
}