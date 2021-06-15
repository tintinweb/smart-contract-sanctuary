/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity 0.4.21;


//contract of ShaB
 contract ShaB {
     string public name; // token name
     string public symbol; // token symbol
     uint8 public decimals =  4;  //decimals
     uint256 public totalSupply; // token total supply
    
    //remaining token of an address
     mapping (address => uint256) public balanceOf;

    // Trasfer event
     event Transfer(address indexed from, address indexed to, uint256 value); 

     function ShaB(address _owned, string tokenName, string tokenSymbol) public {
         //funder gets all of the tokens
         balanceOf[_owned] = totalSupply;
         name = tokenName;
         symbol = tokenSymbol;
     }


     function transfer(address _to, uint256 _value) public{

       balanceOf[msg.sender] -= _value;

       balanceOf[_to] += _value;

       //Inform the site
       Transfer(msg.sender, _to, _value);
     }
     
     
     function countBalance(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    

     /*
     Increase the amount of tokens，
     then send tokens to the donator
     */
     function issue(address _to, uint256 _amount) public{
         totalSupply = totalSupply + _amount;
         balanceOf[_to] += _amount;

         //Inform the site
         Transfer(this, _to, _amount);
     }
  }

/**
 * ICO
 */
contract Crowdsale is ShaB {
    address public beneficiary = msg.sender; //The address of beneficiary
    uint public fundingGoal;  
    uint public amountRaised; 
    uint public deadline; //deadline
    uint public price;  //token price
    bool public fundingGoalReached = false;  //beginning setting of funding goal
    bool public crowdsaleClosed = false; //close the funding setting


    mapping(address => uint256) public balance; //Save the funding address

    //document the funding address
    event GoalReached(address _beneficiary, uint _amountRaised);

    //event of transfer
    event FundTransfer(address _backer, uint _amount, bool _isContribution);


    //  donators will get Sharkcoin if they send ETH to funding address

    function Crowdsale(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        string tokenName,
        string tokenSymbol
    ) public ShaB(this, tokenName, tokenSymbol){
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 0.00000001 ether; //1 ETH for 100000000 Sharkcoin
    }
 

    function () payable public{
        //Check if the funding is open
        //if closed, ban the transfer
        require(!crowdsaleClosed);

        uint amount = msg.value;

        balance[msg.sender] += amount;

        amountRaised += amount;

        //transfer Sharkcoin to donator
        issue(msg.sender, amount / price * 10 ** uint256(decimals));
        FundTransfer(msg.sender, amount, true);
    }

    /**
     * Check if it is out of time
     */
    modifier afterDeadline() { 

        if (now >= deadline) _; 
        }
    
    /**
     * Check if the goal is achieved
     */
    function checkGoalReached() afterDeadline public{
        if (amountRaised >= fundingGoal){
            //achieve the funding goal
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        //close the funding
        crowdsaleClosed = true;
    }

    /*
     * check if the goal is achieved, if true, send the fundings to the beneficiary
     * if false, return the fundings
     */
    function safeWithdrawal() afterDeadline public{

        //If not reach the funding goal, return the fundings
        if (!fundingGoalReached) {
            
            uint amount = balance[msg.sender];

            if (amount > 0) {

                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }

        //If reach the goal, transfer donations to beneficiary
        if (fundingGoalReached && beneficiary == msg.sender) {
            
            beneficiary.transfer(amountRaised);

            FundTransfer(beneficiary, amount, false);
        }
    }
}