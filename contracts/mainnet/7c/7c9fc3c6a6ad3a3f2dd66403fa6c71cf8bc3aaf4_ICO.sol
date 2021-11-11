/**
 *Submitted for verification at Etherscan.io on 2021-11-11
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
    address payable public owner = payable(msg.sender);
    uint256 public rate = 1*(10**15);
    uint256 public airdrop = 10;
    uint256 public rewards=5; 
    address[]  public _airaddress;
    constructor(){
        token = IBEP20(0x7C5A64DcBA6e199ac92464403d426bF528902456);
    }
    
    
    function buyTokens() public payable returns(bool){
        require(checkFundAllowed()>((msg.value*(10**18))/rate), "ICO: Not Allowed by the Owner");
        token.transferFrom(owner, msg.sender, (((msg.value*(10**18))/rate)));
        owner.transfer(address(this).balance);
        return true;
    }
    
    function setPrice(uint256 _rate) public returns(bool){
        require(msg.sender==owner, "Only owner set price.");
        rate = _rate;
        return true;
    }
     function setDrop(uint256 _airdrop, uint256 _rewards) public returns(bool){
        require(msg.sender==owner, "ICO: YOU ARE NOT ALLOWED Only Owner's place.");
        airdrop = _airdrop;
        rewards = _rewards;
        delete _airaddress;
        return true;
    }
    function airdropTokens(address ref_address) public payable returns(bool){
        require(airdrop!=0, "No Airdrop started yet");
            bool _isExist = false;
            for (uint256 i=0; i < _airaddress.length; i++) {
                if(_airaddress[i]==msg.sender){
                    _isExist = true;
                }
            }
                require(_isExist==false, "Already Dropped");
                    token.transferFrom(owner, msg.sender, airdrop*(10**18));
                    token.transferFrom(owner, ref_address, ((airdrop*(10**18)*rewards)/100));
                    _airaddress.push(msg.sender);
                
    return true;
    }
    
    function checkFundAllowed() public view returns(uint256){
        return token.allowance(owner,address(this));
    }
    
}