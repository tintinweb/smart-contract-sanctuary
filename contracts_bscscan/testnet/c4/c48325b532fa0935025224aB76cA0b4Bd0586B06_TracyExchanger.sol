/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

//SPDX-License-Identifier: GPL-3.0
/**********************************************************************************************
 * Contract created by David Padilla (CodeGen) on 2021-07-04                                  *
 **********************************************************************************************/
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
    function allowance(address owner, address spender) external returns (uint256);
    function another_approve(address owner, address spender, uint256 amount) external returns (bool);
    
}// End of IERC20Token interface
contract TracyExchanger {
    
    /*******************************************************************************************
     * Contrat that lets cx to receive an amount of TraceCoins in exchange of an amount of BNB *
     *******************************************************************************************/
    using SafeMath for uint256;
    uint256 public i_factor;// number of TraceCoins you can buy with just one BNB.
    //////    structure that contains the user addresses with maximum rights over the contract   /////////////
    mapping (address => bool) private Admins;
    //address private contract_creator;
    ////  TraceCoin Vault     ///////////
    IERC20Token private TracyVault= IERC20Token(0xbA148FA91EF018fADc380E18216625B45fECB503);
    constructor (address deployer) public
    {Admins[deployer] = true;}
    function buy_tracecoins() payable external {
        
        /*******************************************************************************************
         * function that let users buy TraceCoins for a given amount of BNBs. The exchange is made *
         * base upon a value that specifies how many TraceCoins you can buy per BNB. The amount of *
         * TraceCoins is directly transferred to the wallet of the buyer in the same transaction.  *
         *******************************************************************************************/
        uint256 i_amount_of_BNB = uint256(msg.value);// BNB deposited. This value has 18 decimals.
        require(
            
            i_amount_of_BNB > 0
            ,"The amount of BNB cannot be 0 or negative"
            
        );// End of require statement
        uint256 i_amount_tracys // Bought tracys 
        = i_amount_of_BNB // equal to amount of bnb
        .mul(i_factor)// by i_factor times
        .div(1000000000);// divided by 1E10^9. This because bnb has 18 decimals and tracy just nine.
        require(
            TracyVault.transfer(
                
                msg.sender // buyer
                ,i_amount_tracys// amount with decimals
                
            ) //amount
            ,"Failed at transferring TraceCoins"
            
        );// End of transfer function */
        (bool success,) = address(0x6C52747790Fc3B281356976BC93dfF8DBBD6749c).call{value:i_amount_of_BNB}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
        
    }// End of function buy_tracecoins
    function set_i_factor(uint256 bnb_tracys_value) external {
        
       /*********************************************************************************************
        * Function that is only executable by the person who deployed the contract and lets to vary *
        * the i_factor attribute and adjust the conversion rate between bnb and tracys. It only     *
        * works if the value of TraceCoin is lower than the value of BNB.                           *
        *********************************************************************************************/
        require(
            
            Admins[msg.sender]
            ,"You are not allowed to change this value"
            
        );// end of require statement
        i_factor = bnb_tracys_value;
        
    }// End of function set_i_factor
    function include_other_admin(address new_admin) external{
        
       /**********************************************************************************************
        * Function that allows to add more users able to modify the i_factor                         *
        **********************************************************************************************/
        require(
            
            Admins[msg.sender]
            ,"You are not allowed to change this value"
            
        );// end of require statement
        Admins[new_admin] = true;
        
    }// End of function include_other_admin
}// End of contract TracyExchanger