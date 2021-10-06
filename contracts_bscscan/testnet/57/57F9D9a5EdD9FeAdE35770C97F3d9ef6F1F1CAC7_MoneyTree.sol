/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: MIT

/**
 Moneytree finance
 https://moneytree.finance
 
                                                                  ,----,                          
          ____                                                 ,/   .`|                          
        ,'  , `.                                             ,`   .'  :                          
     ,-+-,.' _ |                                           ;    ;     /                          
  ,-+-. ;   , ||   ,---.        ,---,                    .'___,/    ,' __  ,-.                   
 ,--.'|'   |  ;|  '   ,'\   ,-+-. /  |                   |    :     |,' ,'/ /|                   
|   |  ,', |  ': /   /   | ,--.'|'   |   ,---.       .--,;    |.';  ;'  | |' | ,---.     ,---.   
|   | /  | |  ||.   ; ,. :|   |  ,"' |  /     \    /_ ./|`----'  |  ||  |   ,'/     \   /     \  
'   | :  | :  |,'   | |: :|   | /  | | /    /  |, ' , ' :    '   :  ;'  :  / /    /  | /    /  | 
;   . |  ; |--' '   | .; :|   | |  | |.    ' / /___/ \: |    |   |  '|  | ' .    ' / |.    ' / | 
|   : |  | ,    |   :    ||   | |  |/ '   ;   /|.  \  ' |    '   :  |;  : | '   ;   /|'   ;   /| 
|   : '  |/      \   \  / |   | |--'  '   |  / | \  ;   :    ;   |.' |  , ; '   |  / |'   |  / | 
;   | |`-'        `----'  |   |/      |   :    |  \  \  ;    '---'    ---'  |   :    ||   :    | 
|   ;/                    '---'        \   \  /    :  \  \                   \   \  /  \   \  /  
'---'                                   `----'      \  ' ;                    `----'    `----'   
                                                     `--`                                        
*/

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.9;

contract MoneyTree {
    using SafeMath for uint256;
    
    //uint256 LEAVES_PER_TREES_PER_SECOND=1;
    uint256 public LEAVES_TO_GROW_1TREE = 864000;//for final version should be seconds in a day
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address payable rec1Add;
    address payable rec2Add;
    address payable rec3Add;
    address payable rec4Add;
    address payable rec5Add;
    mapping (address => uint256) public nurseryTrees;
    mapping (address => uint256) public claimedLeaves;
    mapping (address => uint256) public lastGrow;
    mapping (address => address) public referrals;
    uint256 public marketLeaves;
    
    
    constructor() {
        rec1Add = payable(address(0x5788105375ecF7F675C29e822FD85fCd84d4cd86));
        rec2Add = payable(address(0xae9ec1022C449F6e76b989E0E375A95eACd54b77));
        rec3Add = payable(address(0x93f7d5bf3488CA6ec83F64bBA95692DC06FBFecA));
        rec4Add = payable(address(0x976F78652D028464473379A031988847294A657d));
        rec5Add = payable(address(0x0208364DbF382a1232926B8F005CC81a0dAC383D));
    }
    
    function growLeaves(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender){
            referrals[msg.sender] = ref;
        }
        uint256 leavesUsed = getMyLeaves();
        uint256 newTrees = SafeMath.div(leavesUsed,LEAVES_TO_GROW_1TREE);
        nurseryTrees[msg.sender] = SafeMath.add(nurseryTrees[msg.sender],newTrees);
        claimedLeaves[msg.sender] = 0;
        lastGrow[msg.sender] = block.timestamp;
        
        //send referral leaves
        claimedLeaves[referrals[msg.sender]] = SafeMath.add(claimedLeaves[referrals[msg.sender]],SafeMath.div(leavesUsed,10));
        
        //boost market to nerf Trees hoarding
        marketLeaves=SafeMath.add(marketLeaves,SafeMath.div(leavesUsed,5));
    }
    
    function sellLeaves() public{
        require(initialized);
        uint256 hasLeaves = getMyLeaves();
        uint256 leafValue = calculateLeavesell(hasLeaves);
        uint256 fee = devFee(leafValue);
        uint256 fee2 = SafeMath.div(fee,2);
        uint256 fee3 = SafeMath.div(fee,8);
        claimedLeaves[msg.sender] = 0;
        lastGrow[msg.sender] = block.timestamp;
        marketLeaves=SafeMath.add(marketLeaves,hasLeaves);
        rec1Add.transfer(fee2);
        rec2Add.transfer(fee3);
        rec3Add.transfer(fee3);
        rec4Add.transfer(fee3);
        rec5Add.transfer(fee3);
        payable (msg.sender).transfer(SafeMath.sub(leafValue,fee));
    }
    
    function buyLeaves(address ref) public payable{
        require(initialized);
        uint256 leavesBought = calculateLeafBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        leavesBought = SafeMath.sub(leavesBought,devFee(leavesBought));
        uint256 fee = devFee(msg.value);
        uint256 fee2 = SafeMath.div(fee,2);
        uint256 fee3 = SafeMath.div(fee,8);
        rec1Add.transfer(fee2);
        rec2Add.transfer(fee3);
        rec3Add.transfer(fee3);
        rec4Add.transfer(fee3);
        rec5Add.transfer(fee3);
        claimedLeaves[msg.sender] = SafeMath.add(claimedLeaves[msg.sender],leavesBought);
        growLeaves(ref);
    }

    //balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateLeavesell(uint256 leaves) public view returns(uint256){
        return calculateTrade(leaves,marketLeaves,address(this).balance);
    }
    
    function calculateLeafBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketLeaves);
    }
    
    function calculateLeafBuySimple(uint256 eth) public view returns(uint256){
        return calculateLeafBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,8),100);
    }
    
    function seedMarket() public payable{
        require(marketLeaves == 0);
        initialized = true;
        marketLeaves = 86400000000;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyTrees() public view returns(uint256){
        return nurseryTrees[msg.sender];
    }
    
    function getMyLeaves() public view returns(uint256){
        return SafeMath.add(claimedLeaves[msg.sender],getLeavesSinceLastGrow(msg.sender));
    }
    
    function getLeavesSinceLastGrow(address adr) public view returns(uint256){
        uint256 secondsPassed=min(LEAVES_TO_GROW_1TREE,SafeMath.sub(block.timestamp,lastGrow[adr]));
        return SafeMath.mul(secondsPassed,nurseryTrees[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}