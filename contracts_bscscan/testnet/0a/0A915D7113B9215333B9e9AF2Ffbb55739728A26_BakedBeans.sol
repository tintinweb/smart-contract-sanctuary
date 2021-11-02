/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT

/*
    ,---,.                   ,-.                                  ,---,.                                                       
  ,'  .'  \              ,--/ /|                 ,---,          ,'  .'  \                                                      
,---.' .' |            ,--. :/ |               ,---.'|        ,---.' .' |                             ,---,                    
|   |  |: |            :  : ' /                |   | :        |   |  |: |                         ,-+-. /  | .--.--.           
:   :  :  /  ,--.--.   |  '  /      ,---.      |   | |        :   :  :  /   ,---.     ,--.--.    ,--.'|'   |/  /    '          
:   |    ;  /       \  '  |  :     /     \   ,--.__| |        :   |    ;   /     \   /       \  |   |  ,"' |  :  /`./          
|   :     \.--.  .-. | |  |   \   /    /  | /   ,'   |        |   :     \ /    /  | .--.  .-. | |   | /  | |  :  ;_            
|   |   . | \__\/: . . '  : |. \ .    ' / |.   '  /  |        |   |   . |.    ' / |  \__\/: . . |   | |  | |\  \    `.         
'   :  '; | ," .--.; | |  | ' \ \'   ;   /|'   ; |:  |        '   :  '; |'   ;   /|  ," .--.; | |   | |  |/  `----.   \        
|   |  | ; /  /  ,.  | '  : |--' '   |  / ||   | '/  '        |   |  | ; '   |  / | /  /  ,.  | |   | |--'  /  /`--'  /        
|   :   / ;  :   .'   \;  |,'    |   :    ||   :    :|        |   :   /  |   :    |;  :   .'   \|   |/     '--'.     /         
|   | ,'  |  ,     .-./'--'       \   \  /  \   \  /          |   | ,'    \   \  / |  ,     .-./'---'        `--'---'          
`----'     `--`---'                `----'    `----'           `----'       `----'   `--`---'                                   
Baked Beans - BSC BNB Miner
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

contract BakedBeans {
    using SafeMath for uint256;
    
    uint256 public BEANS_IN_1_CAN = 1728000;//for final version should be seconds in a day
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public devFeeVal = 2;
    bool public initialized = false;
    address payable recAdd;
    mapping (address => uint256) public beanCan;
    mapping (address => uint256) public bakedBeans;
    mapping (address => uint256) public lastBake;
    mapping (address => address) public referrals;
    uint256 public marketBeans;
    
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function setBeansInCan(uint256 beans) public {
        BEANS_IN_1_CAN = beans;
    }
    
    function reBakeBeans(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = address(0);
        }
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender){
            referrals[msg.sender] = ref;
        }
        uint256 beansBaked = getMyCans();
        uint256 newCans = SafeMath.div(beansBaked,BEANS_IN_1_CAN);
        beanCan[msg.sender] = SafeMath.add(beanCan[msg.sender],newCans);
        bakedBeans[msg.sender] = 0;
        lastBake[msg.sender] = block.timestamp;
        
        //send referral leaves
        bakedBeans[referrals[msg.sender]] = SafeMath.add(bakedBeans[referrals[msg.sender]],SafeMath.div(beansBaked,12));
        
        //boost market to nerf Trees hoarding
        marketBeans=SafeMath.add(marketBeans,SafeMath.div(beansBaked,5));
    }
    
    function takeBeans() public{
        require(initialized);
        uint256 hasBeans = getMyCans();
        uint256 beanValue = calculateBeanSell(hasBeans);
        uint256 fee = devFee(beanValue);
        bakedBeans[msg.sender] = 0;
        lastBake[msg.sender] = block.timestamp;
        marketBeans=SafeMath.add(marketBeans,hasBeans);
        recAdd.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(beanValue,fee));
    }
    
    function bakeBeans(address ref) public payable{
        require(initialized);
        uint256 beansBought = calculateBeanBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        beansBought = SafeMath.sub(beansBought,devFee(beansBought));
        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        bakedBeans[msg.sender] = SafeMath.add(bakedBeans[msg.sender],beansBought);
        reBakeBeans(ref);
    }

    //balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateBeanSell(uint256 leaves) public view returns(uint256){
        return calculateTrade(leaves,marketBeans,address(this).balance);
    }
    
    function calculateBeanBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketBeans);
    }
    
    function calculateBeanBuySimple(uint256 eth) public view returns(uint256){
        return calculateBeanBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function setDevFee(uint256 fee) public {
        devFeeVal = fee;
    }
    
    function seedMarket() public payable{
        require(marketBeans == 0);
        initialized = true;
        marketBeans = 172800000000;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyCans() public view returns(uint256){
        return beanCan[msg.sender];
    }
    
    function getMyBeans() public view returns(uint256){
        return SafeMath.add(bakedBeans[msg.sender],getBeansSinceLastBake(msg.sender));
    }
    
    function getBeansSinceLastBake(address adr) public view returns(uint256){
        uint256 secondsPassed=min(BEANS_IN_1_CAN,SafeMath.sub(block.timestamp,lastBake[adr]));
        return SafeMath.mul(secondsPassed,beanCan[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}