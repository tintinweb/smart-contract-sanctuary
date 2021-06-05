pragma solidity ^0.6.2;

import "./ERC20.sol";

/*
    Name:           MilitaryCoin
    Symbol:         MLTC
    Website:        http://www.militarycoin.com.au
    Author/Minter:  (Admiral) Tom Webb
    Email:          [email protected]
*/
contract MilitaryCoin is ERC20 {
    
    /* Stores the address for the Admiral (the owner) */
    address public admiral;
    //string public constant symbol = "http://militarycoin.com.au/icon-militarycoin.png";
    
    /* Set the admiral's address at startup */    
    constructor () public ERC20("MilitaryCoin", "MLTC") {
        admiral = msg.sender;
    }

    /* 
    - modifier's always require -; at the end of the function
    - only the admiral can call this function
    */
    modifier onlyAdmiral {
        require(msg.sender == admiral, "Only the Admiral can call this function");
        _;
    }
    
    /* Only the Admiral can mint coins */
    function mint(address receiver, uint amount) public onlyAdmiral {
         _mint(receiver, amount * (10 ** uint256(decimals())));
    }
}