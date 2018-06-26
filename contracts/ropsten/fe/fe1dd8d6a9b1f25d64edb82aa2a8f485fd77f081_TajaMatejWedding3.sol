pragma solidity ^0.4.24;

contract TajaMatejWedding3 {
    string bride = &quot;Taja&quot;;
    string groom = &quot;Matej&quot;;
    string date = &quot;29 July 2017&quot;;
    
    function getWeddingData() returns (string) {
        return string(abi.encodePacked(bride, &quot; & &quot;, groom, &quot;, happily married on &quot;, date, &quot;. :)&quot;));
    }
    
    function myWishes() returns (string) {
        return &quot;I wish you the best marriage ever!&quot;;
    }
}