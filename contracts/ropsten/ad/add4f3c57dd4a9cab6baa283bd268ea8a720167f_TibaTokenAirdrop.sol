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
//0xBD1C6F6cDc89d03798E85983EEFA4536c558d7fE,1000000000000,0xbb12E4969277EBBC4B08ab6eaaC6f7207d5C0479
contract TibaTokenAirdrop is Owned{
    address public beneficiary;
    uint public amountRaised;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public airdropClosed = false;
    uint256 distributedTotal;
    uint256 tokenQuantity;
    uint256 ReductionRate;
    

    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event ChangeAirdropState(address backer, uint amount, bool _airdropClosed,uint256 _tokenQuantity);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor (
        address ifSuccessfulSendTo,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        price = etherCostOfEachToken ;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    
    
    function ChangeDeadLine( uint newPrice, bool _airdropClosed, uint256 _tokenQuantity) onlyOwner public {
        
        price = newPrice ;
        airdropClosed = _airdropClosed;
        tokenQuantity = _tokenQuantity;
        
        emit ChangeAirdropState(msg.sender, price, _airdropClosed,_tokenQuantity);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!airdropClosed);
        uint amount = msg.value;
         uint256 tokenBalance = tokenReward.getTokenBalance(this);
        
        if (amount > 0){
             uint256 tokenForSale = amount / price;
            
             
            
            require(tokenBalance >= tokenForSale );
            
            tokenReward.transfer(msg.sender, tokenForSale);
            balanceOf[msg.sender] += amount;
            amountRaised += amount;
            tokenQuantity = tokenQuantity -tokenForSale;
            emit FundTransfer(msg.sender, amount, true);
            
      }else{
            
            require(tokenBalance >= tokenQuantity );
            
            tokenReward.transfer(msg.sender, tokenQuantity);
            
            tokenQuantity = tokenQuantity- ReductionRate;
            emit FundTransfer(msg.sender, amount, false);
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
    

    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public  {
       

        if ( beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
            
            }
        }
    }
}