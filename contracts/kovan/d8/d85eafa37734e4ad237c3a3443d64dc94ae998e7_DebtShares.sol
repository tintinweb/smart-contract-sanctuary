/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

contract DebtShares {

    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    function importAddresses(address[] calldata accounts, uint256[] calldata amounts) public virtual { 
        for (uint i = 0; i < accounts.length; i++) {
            mint(accounts[i], amounts[i]);
        }     
    }
    
    function mint(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
}

    event Transfer(address indexed from, address indexed to, uint256 value);
}