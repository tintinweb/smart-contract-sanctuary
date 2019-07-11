/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.0;



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) public pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) public pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract crowdsale{
    using SafeMath for uint256;
    
    uint256 private OpenTime;
    uint256 private CloseTime;
    
    uint256 private  _rate;
    address payable private  _wallet;
    uint256 private weiRaised;
    uint256 private weiAmount;
    
    modifier TimeSpan(){
      require(block.timestamp > OpenTime && block.timestamp < CloseTime);
      _;
    }
  /*  
    constructor(uint256 rate,address payable wallet,uint256 _closeTime) public{
        require(rate > 0,"Rate Should be greater  than zero");
        require(wallet != address(0),"Address Should not be aero address");
        require(_closeTime > block.timestamp,"Should be greater than current time");
        _rate = rate;
        _wallet = wallet;
        OpenTime = now;
        CloseTime = _closeTime;
    }*/
    
      
    constructor() public{
     
        _rate = 4;
        _wallet = msg.sender;
        OpenTime = 1562672544;
        CloseTime = 1562704301;
    }
    
    
    event _buyTokens(uint256 tokens,address beneficiary);
    uint256 public  NumberOftokens;
    address public  beneficiary;
    
    //function to buy tokens
    function buyTokens(address _beneficiary) public payable TimeSpan returns(bool){
        
        weiAmount = msg.value;
        require((weiAmount * _rate).div(1e18 wei) > 0,"Number Of Tokens Cant be Zero or less than one");  
        weiRaised += weiAmount;
        NumberOftokens = 0;
        NumberOftokens = (weiAmount * _rate).div(1e18 wei);
        beneficiary = _beneficiary;
        return true;
    
    }
    
    function GetBeneficiaryInfo() public view returns (uint256,address){
        return (NumberOftokens,beneficiary);
    }
    
    function fundsTransfer() public payable
    {
        _wallet.transfer(weiAmount);
    }
    
    
}