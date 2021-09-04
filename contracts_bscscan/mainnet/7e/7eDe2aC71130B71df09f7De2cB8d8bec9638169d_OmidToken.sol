/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.8.2;

contract OmidToken{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000 * 10 ** 18;
    string public name = "Toman";
    string public symbol= "TMN";
    uint public decimals = 18;
    
    event Transfer(address indexed from , address indexed to , uint value);
    event Approval(address indexed owner, address indexed spender , uint value);
    
    constructor() {
        
        balances[msg.sender] = totalSupply;
        address own=msg.sender;

        
        

    }
    
    function balanceOf(address owner) public view returns (uint) {
        
        return balances[owner];
    }
    
    function transfer(address to , uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value , "balance is not enough");
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender,to,value);
        return true;
        
    }
    
    function transferFrom(address from,address to, uint value) public returns(bool){
        require(balanceOf(from) >= value , "balance is not enough");
        require(allowance[from][msg.sender] >= value ,"allowance is not enough");
        balances[to]+=value;
        balances[from]-=value;
        emit Transfer(from,to,value);
        return true;
        
    }
    
    function approve(address spender , uint value) public returns(bool){
        allowance[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        return true;
        
    }
    

    function _mint(address account, uint256 amount) public returns(bool){
        require(account != address(0), "ERC20: mint to the zero address");
        


        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;

    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint amount) public returns(bool){
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        //unchecked {
        balances[account] = accountBalance - amount;
        //}
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        return true;

    }
    

}