pragma solidity ^0.4.21;

contract Etherwow{
    function userRollDice(uint, address) payable {uint;address;}
}

/**
 * @title FixBet31
 * @dev fix bet num = 31, bet size = 1 eth. 
 */
contract FixBet31{
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    address public owner;
    Etherwow public etherwow;
    bool public bet;

    /*
     * @dev contract initialize
     * @param new etherwow address
     */        
    function FixBet31(){
        owner = msg.sender;
    }

    /*
     * @dev owner set etherwow contract address
     * @param new etherwow address
     */    
    function ownerSetEtherwowAddress(address newEtherwowAddress) public
        onlyOwner
    {
       etherwow = Etherwow(newEtherwowAddress);
    }

    /*
     * @dev owner set fallback function mode
     * @param new fallback function mode. true - bet, false - add funds to contract
     */    
    function ownerSetMod(bool newMod) public
        onlyOwner
    {
        bet = newMod;
    }

    /*
     * @dev add funds or bet. if bet == false, add funds to this contract for cover the txn gas fee
     */     
    function () payable{
        if (bet == true){
            require(msg.value == 1000000000000000000);
            etherwow.userRollDice.value(msg.value)(31, msg.sender);  
        }
        else return;
    }
}