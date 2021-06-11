/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/**
                                                                                             
                                              ./+o+:.                                               
                                            `ohdddddh/                                              
                                            /ddddddddd-                                             
                                            /ddddddddd-                                             
                                             +hdddddy:                                              
                                              .ydddo`                                               
                                              :ddddh.                                               
                 `.--.`                      .hdddddy`                       `.--.`                 
                :yddddhs.                   `yddddddds                     .ohddddy:                
               /ddddddddh`                  sddddddddd/                   `hdddddddd/               
               oddddddddd-                 /ddddddddddd-                  -dddddddddo               
               .yddddddddo/-.             -ddddddddddddh`            `.:/oyddddddddh.               
                 :oyyyddddddddyo+:.`     `hddddddydddddds``    `-:+syddddddddosyyo:`                
                      /ddddddddddyodys+/-sddhdddo`ydddhhho:/+shddyoddddddddh-                       
                       :dddddd++o.`o+/yhddhho.-/``.:-.ydhdhddh++o.`oo/hdddh.                        
                        -hddddh`     sddddddd+       sddddddddh`     odddy`                         
                         .hddo-.    `-+hdddo-        `:sdddddo-.    `-+hs`                          
                          `ydddy -: +dddddddhh+  `  shhddddddddy -: +ddo`                           
                           `sddysddysddddddddd+-sho.sddddddddddhsddysd+                             
                            `ohhhhhhhhhhhhhhhhyhhhhhyhhhhhhhhhhhhhhhh/                              
                              ```````````````````````````````````````                               
                              --------------------------------------.                               
                             `hdddddddddddddddddddddddddddddddddddddy                               
                             `ddddddddddddddddddddddddddddddddddddddy                               
                             `ddddddddddddddddddddddddddddddddddddddy                               
                             `ddddddddddddddddddddddddddddddddddddddy                               
                              +ooooooooooooooooooooooooooooooooooooo/     
*/


//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

contract DogePrince {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    
    uint256 public totalSupply = 10 * 10**11 * 10**18;
    string public name = "Doge Prince";
    string public symbol = hex"444F4745f09fa4b4";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}