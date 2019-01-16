//Hinweis f&#252;r den Compiler. Dieser Quelltext wird nur mit einem Compiler ausgef&#252;hrt, welcher neuer als die Version 0.4.24 ist.
pragma solidity ^0.4.24; 

//Definition eines Smart Contracts mit dem Namen helloWorld.
contract helloWorld { 

    //Definition der Methode (function); die Methode ist &#214;ffentlich (public) aufrufbar und wiedergibt (returns) eine Zeichenkette (string).
    function sayHelloWorld () public pure returns (string) { 
       
        //Dieser Text wird wiedergeben. Kann auch individuell abge&#228;ndert werden.
        return "Hallo Welt!"; 
        
    }
}