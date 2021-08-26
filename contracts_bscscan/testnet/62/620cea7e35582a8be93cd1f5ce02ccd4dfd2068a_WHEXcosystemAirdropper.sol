// SPDX-License-Identifier: Unlicensed

/*

  _____           _            __   _   _          
 |  __ \         | |          / _| | | | |         
 | |__) |_ _ _ __| |_    ___ | |_  | |_| |__   ___ 
 |  ___/ _` | '__| __|  / _ \|  _| | __| '_ \ / _ \
 | |  | (_| | |  | |_  | (_) | |   | |_| | | |  __/
 |_|   \__,_|_|   \__|  \___/|_|    \__|_| |_|\___|

 __          ___    _ ________   __                       _                 
 \ \        / / |  | |  ____\ \ / /                      | |                
  \ \  /\  / /| |__| | |__   \ V / ___ ___  ___ _   _ ___| |_ ___ _ __ ___  
   \ \/  \/ / |  __  |  __|   > < / __/ _ \/ __| | | / __| __/ _ \ '_ ` _ \ 
    \  /\  /  | |  | | |____ / . \ (_| (_) \__ \ |_| \__ \ ||  __/ | | | | |
     \/  \/   |_|  |_|______/_/ \_\___\___/|___/\__, |___/\__\___|_| |_| |_|
                                                 __/ |                      
                                                |___/                       

*/

pragma solidity ^0.8.6;

// Third-party library imports.
import './Address.sol';
import './Context.sol';
import './Ownable.sol';
import './SafeBEP20.sol';
import './SafeMath.sol';


contract WHEXcosystemAirdropper is Context, Ownable
{
    using Address for address;
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    
    constructor(address contract_owner) payable
    {
        _owner = contract_owner;
    }
    
    // Allows this contract to receive and handle ETH/BNB.
    receive() external payable
    {
        
    }
    
    function get_sum(uint256[] calldata array) private pure returns(uint256)
    {
        uint256 sum = 0;

        for(uint256 i = 0; i < array.length; i++)
        {
            sum = sum + array[i];
        }
        
        return sum;
    }
    
    function recover_BNB() public onlyOwner
    {
        uint256 contract_balance = address(this).balance;
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract BNB balance is zero");
        
        payable(owner()).transfer(contract_balance);
    }
    
    function recover_tokens(address token_address) public onlyOwner
    {
        // Releases a token sent to this contract to the contract owner.
        IBEP20 token = IBEP20(token_address);
        
        uint256 contract_balance = token.balanceOf(address(this));
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract token balance is zero");
        
        token.safeTransfer(owner(), contract_balance);
    }
    
    function airdrop_tokens(
        address token_address,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner
    {
        IBEP20 token = IBEP20(token_address);
        
        // Requires that the contract hold the needed token.
        uint256 contract_balance = token.balanceOf(address(this));
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract token balance is zero");
        
        // Requires that the accounts and amounts given are a 1:1 pairing.
        bool account_balances_paired = accounts.length == amounts.length;
        require(account_balances_paired, "WHEXcosystemAirdropper: lists of accounts and balances must have equal lengths");
        
        // Requires that the contract hold enough of the token for all transfers.
        uint256 airdrop_balance = get_sum(amounts);
        bool sufficient_balance = contract_balance >= airdrop_balance;
        require(sufficient_balance, "WHEXcosystemAirdropper: total amount to airdrop exceeds contract token balance");
        
        // Conducts the airdrop.
        for (uint256 i = 0; i < accounts.length; i++)
        {
            token.safeTransfer(accounts[i], amounts[i]);
        }
    }
    
    function airdrop_tokens_with_conversion(
        address token_address,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner
    {
        IBEP20 token     = IBEP20(token_address);
        uint256 decimals = token.decimals();
        
        // Requires that the contract hold the needed token.
        uint256 contract_balance = token.balanceOf(address(this));
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract token balance is zero");
        
        // Requires that the accounts and amounts given are a 1:1 pairing.
        bool account_balances_paired = accounts.length == amounts.length;
        require(account_balances_paired, "WHEXcosystemAirdropper: lists of accounts and balances must have equal lengths");
        
        // Requires that the contract hold enough of the token for all transfers.
        uint256 airdrop_balance = get_sum(amounts) * 10 ** decimals;
        bool sufficient_balance = contract_balance >= airdrop_balance;
        require(sufficient_balance, "WHEXcosystemAirdropper: total amount to airdrop exceeds contract token balance");
        
        // Conducts the airdrop.
        for (uint256 i = 0; i < accounts.length; i++)
        {
            // Converts the given amount to the correct integer representation
            // based on the number of decimals the token uses.
            token.safeTransfer(accounts[i], amounts[i] * 10 ** decimals);
        }
    }
    
    function airdrop_BNB(
        address payable[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner
    {        
        // Requires that the contract hold the needed BNB.
        uint256 contract_balance = address(this).balance;
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract BNB balance is zero");
        
        // Requires that the accounts and amounts given are a 1:1 pairing.
        bool account_balances_paired = accounts.length == amounts.length;
        require(account_balances_paired, "WHEXcosystemAirdropper: lists of accounts and balances must have equal lengths");
        
        // Requires that the contract hold enough BNB for all transfers.
        uint256 airdrop_balance = get_sum(amounts);
        bool sufficient_balance = contract_balance >= airdrop_balance;
        require(sufficient_balance, "WHEXcosystemAirdropper: total amount to airdrop exceeds contract BNB balance");
        
        // Conducts the airdrop.
        for (uint256 i = 0; i < accounts.length; i++)
        {
            accounts[i].transfer(amounts[i]);
        }
    }
    
    function airdrop_BNB_with_conversion(
        address payable[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyOwner
    {
        // Requires that the contract hold the needed BNB.
        uint256 contract_balance = address(this).balance;
        require(contract_balance > 0, "WHEXcosystemAirdropper: contract BNB balance is zero");
        
        // Requires that the accounts and amounts given are a 1:1 pairing.
        bool account_balances_paired = accounts.length == amounts.length;
        require(account_balances_paired, "WHEXcosystemAirdropper: lists of accounts and balances must have equal lengths");
        
        // Requires that the contract hold enough BNB for all transfers.
        uint256 airdrop_balance = get_sum(amounts) * 10 ** 18;
        bool sufficient_balance = contract_balance >= airdrop_balance;
        require(sufficient_balance, "WHEXcosystemAirdropper: total amount to airdrop exceeds contract BNB balance");
        
        // Conducts the airdrop.
        for (uint256 i = 0; i < accounts.length; i++)
        {
            accounts[i].transfer(amounts[i] * 10 ** 18);
        }
    }
}