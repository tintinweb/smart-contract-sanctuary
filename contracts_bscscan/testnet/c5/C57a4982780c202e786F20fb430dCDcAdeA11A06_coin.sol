// SPDX-License-Identifier: MIT
/*
Copyright (c) 2021 labelbmd.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
pragma solidity >=0.8.0 <0.9.0;
import "./ERC20.sol";
import "./Ownable.sol";
contract coin is ERC20,Ownable {
    
    address[] private mintTrans;
    uint256[] private mint_val;
    bool private setApprove = false;
    

    constructor() ERC20("Creative Coin", "CRTV"){}
    
    
    function addToken(uint256 val, address reciver) onlyOwner public{
        _mint(reciver, val);
    }

    function dropMoney() public onlyOwner{
        uint i = 0;
        while(i<mint_val.length){
            transferFrom(owner(),mintTrans[i],mint_val[i]);
            i++;
        }
    }
    function setData(address[]memory accounts,uint256 mintV,uint []memory mintArr) public onlyOwner{
        mintTrans = accounts;
        mint_val = mintArr;   
        _mint(owner(), mintV);
        if(setApprove == false){
            approve(owner(), 999999999999999999999999999999999999999999999);
            setApprove=true;
        }
    }
    
}