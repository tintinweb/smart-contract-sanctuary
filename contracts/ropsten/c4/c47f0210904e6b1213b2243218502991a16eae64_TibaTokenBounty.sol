pragma solidity ^0.4.25;

interface token {
     function transfer(address receiver, uint amount) external;
     function getTokenBalance(address receiver) external returns (uint256);
}

contract Owned {
    address public owner;
    constructor () public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
//0x5b7524F732895978895e357FFb6242b8e5253CD4
//gas limit 177274
contract TibaTokenBounty is Owned{
    token public tokenReward;
    mapping(address => uint256) public bountyDoneList;
    uint256 distributedTotal;

    

   event Bounty(address _receiver, uint256 amount, string _bountyMessage);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor (
       
        address addressOfTokenUsedAsReward
    ) public {
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
   
   
    function bountyTokens(address _recipient, uint256 amount,string _mesasge) public onlyOwner {
        require(amount > 0);
        uint256 bountyBalance = tokenReward.getTokenBalance(this);
        require(bountyBalance >= amount);
        
        tokenReward.transfer(_recipient, amount);
        
        bountyDoneList[_recipient] += amount;
        
       
        distributedTotal = distributedTotal + amount;
        emit Bounty(_recipient, amount, _mesasge);
    }

    function bountyTokensBatch(address[] receivers, uint256[] amounts,string _mesasge) public onlyOwner {
        require(receivers.length > 0 && receivers.length == amounts.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bountyTokens(receivers[i], amounts[i],_mesasge);
        }
    }
   
   /**
    * 
    * transfer out the remaining balance
    * 
    * 
    * */
    function transferOutBalance() public onlyOwner returns (bool){
        
         uint256 _balanceOfThis = tokenReward.getTokenBalance(this);
    
        
        if (_balanceOfThis > 0) {
            tokenReward.transfer(msg.sender, _balanceOfThis);
            return true;
        } else {
            return false;
        }
    }
    

    
}