/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.4.18;

//Token contract
 contract token {
     string public name; //Token name
     string public symbol; //Token symbol
     uint8 public decimals = 2;  //Token unit
     uint256 public totalSupply; //Total tokens
    
    //The balance corresponding to the address
     mapping (address => uint256) public balanceOf;

     event Transfer(address indexed from, address indexed to, uint256 value);  
//Transfer notification event

     /* Initialize the contract
      * @param _owned //Contract manager
      * @param tokenName //Token name
      * @param tokenSymbol //Token symbol
      */

     function token(address _owned, string tokenName, string tokenSymbol) public {
         //All tokens obtained by the creator of the contract
         balanceOf[_owned] = totalSupply;
         name = tokenName;
         symbol = tokenSymbol;
     }

     /**
      * Transfer
      * @param  _to address  //The address that accepts the token
      * @param  _value uint256  //Number of accepted tokens
      */
     function transfer(address _to, uint256 _value) public{
       //Subtract the amount sent from the sender
       balanceOf[msg.sender] -= _value;

       //Add the same amount to the recipient
       balanceOf[_to] += _value;

       //Notify any clients that are monitoring the transaction
       Transfer(msg.sender, _to, _value);
     }

     /**
      * Increase tokens and send tokens to new users who donate
      * @param  _to address //The address that accepts the token
      * @param  _amount uint256 //Number of accepted tokens
      */
     function issue(address _to, uint256 _amount) public{
         totalSupply = totalSupply + _amount;
         balanceOf[_to] += _amount;

         //Notify any clients that are monitoring the transaction
         Transfer(this, _to, _amount);
     }
  }

/**
 * Crowdfunding contract
 */
contract Crowdsale is token {
    address public beneficiary = msg.sender; //Beneficiary address
    uint public fundingGoal;  //Crowdfunding goal
    uint public amountRaised; //Amount raised
    uint public deadline; //deadline
    uint public price;  //Token price
    bool public fundingGoalReached = false;  //Achieve the crowdfunding goal, not completed by default
    bool public crowdsaleClosed = false; //Crowdfunding is closed, not closed by default


    mapping(address => uint256) public balance; //Save the crowdfunding address

    //Record received eth notifications
    event GoalReached(address _beneficiary, uint _amountRaised);

    //Event during transfer
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    /**
     * Initialize constructor
     * @param fundingGoalInEthers //Total amount of crowdfunding ether
     * @param durationInMinutes //Crowdfunding deadline
     * @param tokenName //Token name
     * @param tokenSymbol //Token symbol
     */

    function Crowdsale(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        string tokenName,
        string tokenSymbol
    ) public token(this, tokenName, tokenSymbol){
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 1 ether; //1 Ether can buy 1 token
    }


    /**
     * Default function
     *
     * Default function, send money directly to the contract
     */
    function () payable public{
        //Determine whether to close crowdfunding
        //If closed, payment is prohibited
        require(!crowdsaleClosed);
        uint amount = msg.value;

        //Donor’s amount accumulates
        balance[msg.sender] += amount;

        //Cumulative total donations
        amountRaised += amount;

        //Transfer operation, how many tokens to transfer to the donor
        issue(msg.sender, amount / price * 10 ** uint256(decimals));
        FundTransfer(msg.sender, amount, true);
    }

    /**
     * Determine whether the crowdfunding deadline has passed
     */
    modifier afterDeadline() { 
        if (now >= deadline) _; 
        }
    
    /**
     * Check whether the crowdfunding goal is completed
     */
    function checkGoalReached() afterDeadline public{
        if (amountRaised >= fundingGoal){
            //Achieve crowdfunding goals
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        //Close crowdfunding and prohibit fundraising
        crowdsaleClosed = true;
    }

    /**
     * Recover funds
     * Check whether the goal or time limit has been reached
     * Send the full amount to the beneficiary
     */
    function safeWithdrawal() afterDeadline public{

        //If the crowdfunding goal is not reached, empty the tokens
        if (!fundingGoalReached) {
            //Get the donated balance of the contract caller
            uint amount = balance[msg.sender];

            if (amount > 0) {
                //Return all balances of the contract initiator
                msg.sender.transfer(amount);
                FundTransfer(msg.sender, amount, false);
                balance[msg.sender] = 0;
            }
        }

        //If the crowdfunding goal is reached and the contract caller is the beneficiary
        if (fundingGoalReached && beneficiary == msg.sender) {

            //Give all donations from the contract to the beneficiary
            beneficiary.transfer(amountRaised);

            FundTransfer(beneficiary, amount, false);
        }
    }
}