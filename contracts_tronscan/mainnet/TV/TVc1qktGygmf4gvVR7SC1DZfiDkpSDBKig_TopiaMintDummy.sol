//SourceUnit: topiaMintingDummy.sol

pragma solidity 0.4.25; /*

___________________________________________________________________


THIS CONTRACT ALLOWS TOPIA NETWROK TO MINT ANY AMOUNT OF TOPIA. IT WILL NOT EXCEED THE MAX SUPPLY.


-------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
*/ 



interface InterfaceTOPIA {
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
}  


contract TopiaMintDummy {
    
    address public topiaContractAddress;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function callMintToken(address user, uint256 wagerAmountSUN) public returns(string){
        
        require(msg.sender == owner, 'Invalid caller');
        require(topiaContractAddress != address(0), 'Invalid topiaContractAddress');
        
        InterfaceTOPIA(topiaContractAddress).mintToken(user, wagerAmountSUN);
        
        return "Topia minted successfully";
    }
    
    function updateContractAddress(address topiaContract) public returns (string){
        
        require(msg.sender == owner, 'Invalid caller');
        topiaContractAddress = topiaContract;
        
        return "Address updated successfully";
    }

    
}