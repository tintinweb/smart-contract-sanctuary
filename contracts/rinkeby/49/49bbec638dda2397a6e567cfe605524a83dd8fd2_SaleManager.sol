/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity 0.7.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


contract SaleManager{
    using SafeMath for uint;
    struct User{
        bool claimed;
        uint share; //all addresses shares start as zero
    }

    mapping(address => User) public shareLedger;
    address public owner;
    address public nft;
    uint public balance;
    uint public allocatedShare;
    bool public claimsStarted;

    constructor(address _owner, address _nft){
        owner = _owner;
        nft = _nft;
    }

    receive() external payable{}

    /**
    * @dev biggest point of power for the owner bc they could choose to not call this function, but doing so means they don't get paid
    * if malicous owner sent 1 eth to contract, then called balance, then claimed their share, then everyones share would be based off 1 Eth instead of actual conctract balance
    * ^^^^^ mitigated by making the NFT in charge of calling this function when withdraw is called on the NFT
    **/
    function logEther() external {//could maybe have the nft contract call this to remove owner power to not call it?
        require(msg.sender == nft, 'Only the nft can log ether');
        require(!claimsStarted, 'Users have already started claiming Eth from the contract');
        balance = address(this).balance;
    }

    function resetManager() external{
        require(msg.sender == owner, 'Only the owner can reset the contract');
        require(balance > 0 && address(this).balance == 0, 'Can not reset when users still need to claim');
        balance = 0;
        claimsStarted = false;
        allocatedShare = 0;//Owner must reallocate share once this function is called
    }

    /**
    * @dev only deploy nft contract once shareLedger is finalized, then set the SalesManager in the nft equal to this address
    **/
    function createUser(address _address, uint _share) external{
        require(msg.sender == owner, 'Only the owner can create users');
        require(_share > 0, 'Share must be greater than zero');//makes it so that owner can not zero out shares after allocated shares is equal to 100
        require(allocatedShare.add(_share) <= 100, 'Total share allocation greater than 100');
        shareLedger[_address] = User({
        claimed: false,
        share: _share
        });
        allocatedShare = allocatedShare.add(_share);
    }

    function claimEther() external{
        require(balance > 0, 'Balance has not been set');
        require(shareLedger[msg.sender].share > 0, 'Caller has no share to claim');
        require(!shareLedger[msg.sender].claimed, 'Caller already claimed Ether');
        shareLedger[msg.sender].claimed = true;
        uint etherOwed = shareLedger[msg.sender].share.mul(balance).div(100);
        if(etherOwed > address(this).balance){//safety check for rounding errors
            etherOwed = address(this).balance;
        }
        claimsStarted = true;
        msg.sender.transfer(etherOwed);
    }

    function adminWithdraw() external{
        require(msg.sender == owner, 'Only the owner can use this function');
        msg.sender.transfer(address(this).balance);
    }
}