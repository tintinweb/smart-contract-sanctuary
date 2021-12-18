// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;


interface Q3TokenInterface{
    
   // function transfer( address from, address to, uint256 amount) external returns(bool);
    function transfer(address sender, address recipient, uint256 amount) external returns(bool);
    function mint(uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    
}

contract Q3Token is Q3TokenInterface{
    
    
    // balance mapping
       mapping(address => uint256) internal _balances;

    function transfer(address sender, address recipient, uint256 amount) override external returns(bool) {
        require(sender != address(0), "Q3Token: transfer from the zero address");
        require(recipient != address(0), "Q3Token: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Q3Token: you have insufficient Q3Tokens in your account");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        return true;
             
    }
 
    function mint(uint256 amount) override public returns(bool){
         _balances[msg.sender] = _balances[msg.sender] + amount;
         return true;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    
}