pragma solidity ^ 0.4.15;
/**
*contract name : GodzSwapGodzEtherCompliance
*purpose : be the smart contract for compliance of the greater than usd5000
*/
contract GodzSwapGodzEtherCompliance{
    //address of the owner of the contract
    address public owner;
    
    /*structure for store the sale*/
    struct GodzBuyAccounts
    {
        uint256 amount;/*amount sent*/
        address account;/*account that sent*/
        uint sendGodz;/*if send the godz back*/
    }

    /*mapping of the acounts that send more than usd5000*/
    mapping(uint=>GodzBuyAccounts) public accountsHolding;
    
    /*index of the account information*/
    uint public indexAccount = 0;

    /*account information*/
    address public swapContract;/*address of the swap contract*/


    /*function name : GodzSwapGodzEtherCompliance*/
    /*purpose : be the constructor and the setter of the owner*/
    /*goal : to set the owner of the contract*/    
    function GodzSwapGodzEtherCompliance()
    {
        /*sets the owner of the contract than compliance with the greater than usd5000 maximiun*/
        owner = msg.sender;
    }

    /*function name : setHolderInformation*/
    /*purpose : be the setter of the swap contract and wallet holder*/
    /*goal : to set de swap contract address and the wallet holder address*/    
    function setHolderInformation(address _swapContract)
    {    
        /*if the owner is setting the information of the holder and the swap*/
        if (msg.sender==owner)
        {
            /*address of the swap contract*/
            swapContract = _swapContract;
        }
    }

    /*function name : SaveAccountBuyingGodz*/
    /*purpose : be the safe function that map the account that send it*/
    /*goal : to store the account information*/
    function SaveAccountBuyingGodz(address account, uint256 amount) public returns (bool success) 
    {
        /*if the sender is the swapContract*/
        if (msg.sender==swapContract)
        {
            /*increment the index*/
            indexAccount += 1;
            /*store the account informacion*/
            accountsHolding[indexAccount].account = account;
            accountsHolding[indexAccount].amount = amount;
            accountsHolding[indexAccount].sendGodz = 0;
            /*transfer the ether to the wallet holder*/
            /*account save was completed*/
            return true;
        }
        else
        {
            return false;
        }
    }

    /*function name : setSendGodz*/
    /*purpose : be the flag update for the compliance account*/
    /*goal : to get the flag on the account*/
    function setSendGodz(uint index) public 
    {
        if (owner == msg.sender)
        {
            accountsHolding[index].sendGodz = 1;
        }
    }

    /*function name : getAccountInformation*/
    /*purpose : be the getter of the information of the account*/
    /*goal : to get the amount and the acount of a compliance account*/
    function getAccountInformation(uint index) public returns (address account, uint256 amount, uint sendGodz)
    {
        /*return the account of a compliance*/
        return (accountsHolding[index].account, accountsHolding[index].amount, accountsHolding[index].sendGodz);
    }
}