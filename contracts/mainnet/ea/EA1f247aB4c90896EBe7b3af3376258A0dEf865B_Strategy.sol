/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity >=0.6.0 <0.8.0;




library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface NFT {
    
    function getUserData(address _who) external view returns (uint256 userPower, uint256 userEnergy, uint256 lastWithdrawDate, uint256 whitelist);
    
    function updateDate(uint256 _newDate, address _who) external;

    function balanceOf(address account) external view returns (uint256);

    
}




/**
 * @title MoonDayPlus Strategy
 * 
 *
 * 
          ,
       _/ \_     *
      <     >
*      /.'.\                    *
             *    ,-----.,_           ,
               .'`         '.       _/ \_
    ,         /              `\    <     >
  _/ \_      |  ,.---.         \    /.'.\
 <     >     \.'    _,'.---.    ;   `   `
  /.'.\           .'  (-(0)-)   ;
  `   `          /     '---'    |  *
                /    )          |             *
     *         |  .-;           ;        ,
               \_/ |___,'      ;       _/ \_ 
          ,  |`---.MOON|_       /     <     >
 *      _/ \_ \         `     /        /.'.\
       <     > '.          _,'         `   `
 MD+    /.'.\    `'------'`     *   
        `   `
 
 
 */


contract Strategy {

    using SafeMath for uint256;


    NFT public nftContract;

  

    constructor(NFT _Nft) {
        
        nftContract = _Nft;

       
    }

    
    //public one for ui
    function returnPercPub(address investor) public view returns (uint256 _perc){
        uint256  balanceOf = nftContract.balanceOf(investor);

        if(balanceOf < 1){
            return 0;
        }


        (uint256 userPower, uint256 userEnergy, uint256 lastWithdrawDate,) = nftContract.getUserData(investor);


        uint256  medianEnergy = userEnergy.div(balanceOf);



        uint256  intervalDiff = (block.timestamp).sub(lastWithdrawDate);


        if (intervalDiff.div(1 days) >= medianEnergy){

            //full userPower

            _perc = userPower;

        }else{
            
          

            _perc = userPower.sub(userPower.mul((medianEnergy.sub(intervalDiff.div(1 days))).div(medianEnergy)));


        }


        if(_perc.mul(5) > 4166){
            
           _perc = 4166; 
        }else{
            
            _perc = _perc.mul(5);
        }


        return _perc;
    }


    //this one update the user last withdraw
    function returnPerc(address investor) external returns (uint256 _perc){
        
        _perc = returnPercPub(investor);
        
         if( _perc > 0 ){
             
             nftContract.updateDate(block.timestamp, investor);
             
         }

       return _perc;


    }





}