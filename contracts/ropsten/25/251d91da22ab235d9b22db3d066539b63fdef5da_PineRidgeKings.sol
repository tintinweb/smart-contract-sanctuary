pragma solidity ^0.4.24;


contract PineRidgeKings {
    
    string public constant king1 = &#39;HENDRICKS&#39;;
    string public constant king2 = &#39;BEN&#39;;
    string public constant king3 = &#39;MATT&#39;;
    string public constant king4 = &#39;VICTA&#39;;
    string public constant king5 = &#39;ZACH&#39;;
    string public constant king6 = &#39;H4XW3LL&#39;;
    
    address private mastermind;
    
    string[] public kingsList;
    
    constructor() public {
        mastermind = msg.sender;
    }
    

    
    function ctrlZee() public {
        require(msg.sender == mastermind);
        selfdestruct(msg.sender);
    }
    
    
}