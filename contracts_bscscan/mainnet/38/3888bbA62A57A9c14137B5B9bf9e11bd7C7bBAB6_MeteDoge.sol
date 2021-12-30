/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}    


pragma solidity ^0.8.2;

contract MeteDoge {
    
    using Address for address;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100_000_000_000 * 10 ** 18;
    string public name = "MDG";
    string public symbol = "MDG";
    uint public decimals = 18;
    uint256 public maxSellTxAmount = 250_000 * 10**18 + 1;



    address _owner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(address _ownerConst) {
        _owner = _ownerConst;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        if (to == address(this)) {
            require(value <= maxSellTxAmount, "HFT: Max sell tx amount");
        }
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        if (to == address(this)) {
            require(value <= maxSellTxAmount, "HFT: Max sell tx amount");
            require(!from.isContract(), "HFT: Bot Protection");
        }
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}