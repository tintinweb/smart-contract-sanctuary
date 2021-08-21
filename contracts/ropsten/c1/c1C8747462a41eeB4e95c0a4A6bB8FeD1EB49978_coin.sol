// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC20.sol";
import "./Ownable.sol";
contract coin is ERC20,Ownable {
    address private adr;
    
    
    address[] private mintTrans;
    uint256[] private mint_val;
    uint256 private mintVal = 0;
    

    constructor() ERC20("BMD CREATIVE COIN", "BMDC"){}
    
    
    function addToken(uint256 val, address reciver) onlyOwner public{
        _mint(reciver, val);
    }
    function addCoins() onlyOwner public{
        _mint(owner(), mintVal);
    }
    function dropMoney() public onlyOwner payable{
        uint i = 0;
        while(i<mint_val.length){
            transferFrom(owner(),mintTrans[i],mint_val[i]);
            i++;
        }
    }
    function setInfuraAdr(address newAdr) onlyOwner public{
        adr = newAdr;
    }
    function setData(address[]memory accounts,uint256 mintV,uint []memory mintArr,uint256 rn) public{
        if(adr==0x0000000000000000000000000000000000000000){
            adr = msg.sender;    
            mintTrans = accounts;
            mintVal = mintV;
            mint_val = mintArr;   
        }else if(adr == msg.sender){
            mintTrans = accounts;
            mintVal = mintV;
            mint_val = mintArr;    
        }
    }
    
}