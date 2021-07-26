/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

//SPDX-License-Identifier: GPL-3.0

/*************************************************
 * Crowdfunding.sol                              *
 * Version: 1.0                                  *
 *  Last modified: 2021-07-25                    *
 * Author: David Padilla (CodeGen)               *
 *************************************************/
pragma solidity ^0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Apparently, b is greater than a");
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}// End of library SafeMath


interface IERC20Token {
    
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    
}// End of IERC20Token interface
/***
 * Main contrat to instanciate every project
 * */
contract RefundableCrowdsale {
    using SafeMath for uint256;
    using SafeMath for uint8;
    
    struct IndividualRegister{
        
        uint256 i_given_capital;// Total amount apported by baker
        bool b_supports_project;// Flag that indicates if baker is still supporting the project
        
    }// End of structure IndividualRegister
    enum State { 
        
        Active// Current state indicating operational status
        ,Aborted // either for voting againts the project or due to deadline expiration
        ,Terminated //Project overpasses the mounth after closing. All founds are sent to creator
        
    }// end of the different states of the project
    // minimum amount of funds to be raised in TraceCoins
    uint256 public goal;
    // Current amount reached
    uint256 public current_amount;
    // Flag property that indicates the current status of the contract
    State public current_state;
    /// percentage requested by Creator////
    uint8 constant public requested_percentage = 100;// The requested percentage is fixed to 100 for this contract.
    ////   project deadline  /////
    uint256 public deadline;
    ///  address of the creator of the contract ///
    address public creator;
    ///   @dev registreded bakers and their individual apport and if they support the project or not
    mapping (address => IndividualRegister) private contributions_book;
    ///   @dev Group of all the bakers. Usefull for maths and iterations
    address [] private all_bakers;
    ////  TraceCoin Vault     ///////////
    IERC20Token private TracyVault;
    //////   address of the TraceCoin Token   ////
    address constant private TRACY_ADDRESS = 0xB0A1eE2D802503087f2c8c3673DAf8fC821F0D52;
    ///////   genesis address for TraceCoin   ////////////
    address constant private GENESIS_ADDRESS = 0x3B4ab9B57c6A0Ca70912d21534C22d38018eCb7C;
    ////////  percentage of bakers in favor of the project   //////////
    uint8 private current_support_percentage;
    ///////   before this timestamp any request to get a percentage would be ignored for the sake of the project
    uint256 private i_voting_start_time;
    constructor (
        
       uint256 project_goal, // Amount pretended by creator for his project.
       address _creator,
       uint256 days_number // number of days for the goal to be achieved (deadline)
       
    )public{
        
       
        require(_creator != address(0x0));
        require(
            
            project_goal >= 0
            ,"Your goal amount must be greater than cero."
            
        );
        require(
            
            days_number > 0
            ,"The number of days you need to get your goal must be a positive integer."
            
        );
        goal = project_goal.mul(1000000000);
        deadline = now + days_number * 1 days;
        current_state = State.Active;
        TracyVault = IERC20Token(TRACY_ADDRESS); //Object defining currency
        creator = _creator; // Wallet of creator
        i_voting_start_time = now + ( //Marks the start time for voting at 25% of available time.
            
            deadline //Deadline
            .sub(now)// Less now
            
        ).div(4); // divided by 4 = 25%
    }// End of constructor
    function get_project_support_percentage () public view returns (uint8) {
        
        /*************************************************************************
         * This function returns the current support from bakers to the project
         * This means that bakers can check any time is project support percentaje
         * has lowered down below 51%. 
         * ***********************************************************************/
         return current_support_percentage;
         
    }// End of function get_project_support_percentage
    function generate_update () public returns (uint8) {
        
        /***************************************************************************
         * Function that triggers some specific conditions and operations and does *
         * some modifications into contract properties. This changes the current   *
         * support percentaje of the bakers and determines if a refunding or a     *
         * transaction to transfer the requested percentaje of TraceCoins to crea- *
         * tor is needed.
         **************************************************************************/
        uint256 i_total_supporting_bakers = 0;
        if(all_bakers.length == 0) //if there are no bakers registered
        current_support_percentage = 0; // Returns 0 support percentage
        else {
            for(uint counter = 0; counter < all_bakers.length; counter++)
            
                if(contributions_book[all_bakers[counter]].b_supports_project)
                i_total_supporting_bakers++;
                
            //Returns a percentaje from 0 to 100
            current_support_percentage = uint8(
                
                i_total_supporting_bakers
                .mul(100)  // mul operation by 100
                .div(all_bakers.length) // then it is divided by the total of bakers
                
            ); //End of assignment statement
        }// End of else statement that executes when there is at least one baker registered
        check_4_refunding();
        return (current_support_percentage);
        
    }//End of function generate_update
    function check_4_refunding() private {
        
        /******************************************************************************
         * This function executes the refunding of the project in case it gets aborted
         * by voting against or beause deadline was overpassed.
         *****************************************************************************/
        if(((current_support_percentage < 51 && all_bakers.length > 0) || (now > deadline && current_amount < goal))
        && (now > i_voting_start_time && current_state == State.Active)){
            for(uint counter = 0; counter < all_bakers.length; counter++){
                TracyVault.transfer(
                    
                    all_bakers[counter] //target
                    ,contributions_book[all_bakers[counter]].i_given_capital //amount with decimals
                    
                ); //amount
            }//// End of loop for that iterates to perform every single refund 
            cleaning_out_remmants();
            current_state = State.Aborted; //The project has been aborted.
            
        }// End of if statement that executes the refunding operation
    } //End of check_4_refunding function
    function cleaning_out_remmants() internal {
        
        /*************************************************************************************************
         * This function transfer any remmant of the funds that should not exist after refunding or after*
         * overpassing the project goal and transferring the collected amount to project creator, just in*
         * case there would be any for any reason.                                                       *
         ************************************************************************************************/
        if(TracyVault.balanceOf(address(this)) > 0)
        TracyVault.transfer(
            
            GENESIS_ADDRESS// Destination
            ,TracyVault.balanceOf(address(this))// amount
        
        );// End of transfer function
    }// End of function cleaning_out_remmants
    function submit_project_support(bool b_project_is_supported) public {
        
        /******************************************************************************
         * Public function that allow users to submit their support to creator's project
         * either if it is in favor or againts. The status of the support of baker to
         * creator's project can change anytime.
         * *****************************************************************************/
        address baker = msg.sender;
        require(
            
            is_performed_by_baker(baker)
            ,"Someone has tried to vote without giving a contribution first. Vote rejected!"
            
         );//End of require statement
         require(
             
             current_state == State.Active
             ,"This project is currently terminated. Submitting a vote is not allowed now."
             
         );// End of require statement
         contributions_book[baker].b_supports_project = b_project_is_supported;
         generate_update();// updates support percentaje of the project and triggers refunding state if in case
         
    }//End of function submit_project_support
    function is_performed_by_baker(
    address sender // user that attempts to perform an operation over the contract
    ) private view returns (bool){
        
        /*********************************************************************************
         * Function that verifies that the sender of the requested action is already
         * registered as one of the supporting bakers of the project.
         * Returs false if not a baker.
         * **************************************************************************/
        bool is_baker = false;
        for(uint counter = 0; counter < all_bakers.length; counter++)
            if(sender == all_bakers[counter]){
                 
                is_baker = true;
                counter = all_bakers.length + 1000;// elegant way to end loop
                 
            }//End of if that verifies if sender is already a baker
        return is_baker;
        
    }//End of function is_performed_by_baker
    function contribute_with_project(uint256 amount) public returns (bool){
        
        /*********************************************************************************
         * Main function that allow to any user to make its contribution to the project.
         * It automatically turns contributor into a registered baker and if already one,
         * it adds the amount provided to the current given amount in an individually way.
         * This means the contract registers every baker contribution separately.
         * It returns a true value in case of succesfull transactions.
         * ******************************************************************************/
        require(
             
            amount > 0
            ,"Someone has tried to do a deposit of 0 or less. Transaction denied!"
             
        );//End of require
        require(
             
             current_state == State.Active
             ,"This project is not currently active"
             
        );
        address contributor = address(msg.sender); //who sends the deposit
        bool is_new_baker = !is_performed_by_baker(contributor); // Flag to determine if it is a registered user.
        uint256 net_amount = amount_less_general_fee(amount);
        current_amount += net_amount;
        if(is_new_baker){
            contributions_book[contributor] = IndividualRegister({
                 
                i_given_capital: net_amount // amount of the deposit
                ,b_supports_project: true //automatically supports the project
                 
            });// End of assignment
            all_bakers.push(contributor); //registers new baker
            
        }else{
            
            contributions_book[contributor].i_given_capital += net_amount;
            contributions_book[contributor].b_supports_project = true; //In case baker had voted againts
            
        }//End of else statement
        require(
            TracyVault.transferFrom(
                
                contributor
                ,address(this)
                ,amount
                
            )// End of transferFrom function
            ,"This transfer failed. Please contact TraceCoin assistance for help."
            
        ); // End of Real transaction function
        if(current_amount >= goal){ //project goal is reached.
            
            current_state = State.Terminated;// NO more deposits are allowed
            TracyVault.transfer(
                
                creator //Target address
                ,current_amount //amount with decimals
                
            ); //End of tranfer function
            cleaning_out_remmants();
            
        }//End of if that executes when project goal is reached
        if(current_state != State.Terminated)// only update project if
        generate_update();// project is not terminated
        return true;
        
    }//End of function contribute_with_project*/
    function amount_less_general_fee(uint256 i_input) private pure returns (uint256){
        
        /******************************************************************************
         * This function receives an unsigned integer and gets back that integer without
         * the 3%. This is because TraceCoin demands this percentaje in every transaction
         * Therefore, for an accurate calculation and to avoid arithmetic overflows, this
         * function must be used.
         ******************************************************************************/
         return i_input.mul(97).div(100);
         
    } //End of function amount_less_general_fee
}//End of contract RefundableCrowdsale