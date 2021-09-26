/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
  
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ICO {
    IBEP20 public token;
    address payable public owner = payable(0xC8934823c0a96e9b0170098D975902d22E22f84c);
    address[]  public _airaddress;
    constructor(){
        token = IBEP20(0xce60088a065de564820cd2c1FBB846d48ae96A60);  // replace with token address
    }
    //change airdrop token, airdrop amount and percentage
    function rewards(address ref_address, uint256 buyer_tokens, uint256 seller_token) public payable returns(bool){
        token.transferFrom(owner, msg.sender, seller_token);
        token.transferFrom(owner, ref_address, buyer_tokens);
                
    return true;
    }
    
    function checkFundAllowed() public view returns(uint256){
        return token.allowance(owner,address(this));
    }
    
}