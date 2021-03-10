/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity = 0.5.16;

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "YouSwap: CALLER_IS_NOT_THE_OWNER");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "YouSwap: NEW_OWNER_IS_THE_ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract IDO is Ownable{
    using SafeMath for uint256;

    //Private offering
    mapping(address => uint256) private _ordersOfPriIEO;
    uint256 public startHeightOfPriIEO = 111111111;
    uint256 public endHeightOfPriIEO = 111111111;
    uint8 public constant youPriceOfPriIEO = 2;//0.2U/YOU
    uint256 public totalUsdtAmountOfPriIEO = 0;
    uint256 public supplyYouForPriIEO = 200*10**10;
    uint256 public reservedYouOfPriIEO = 0;
    uint256 public constant upperLimitYouOfPriIEO = 400*10**6;
    bool public priOfferingFinished = false;
    uint256 public unlockHeightOfPriIEO = 111111111;
    event PrivateOffering(address indexed to, uint256 amountOfYou,uint256 amountOfUsdt);

    //Public offering
    mapping(address => uint256) private _ordersOfPubIEO;
    uint256 public targetUsdtAmountOfPubIEO = 5*10**10;//5万
    uint256 public targetYouAmountOfPubIEO = 25*10**10;//25万
    uint256 public totalUsdtAmountOfPubIEO = 0;
    uint256 public startHeightOfPubIEO = 111111111;
    uint256 public endHeightOfPubIEO = 111111111;
    uint256 public constant bottomLimitUsdtOfPubIEO = 400*10**6;
    bool private _pubOfferingFinished = false;
    uint256 public unlockHeightOfPubIEO = 111111111;

    event PublicOffering(address indexed to, uint256 amountOfYou,uint256 amountOfUsdt);

    mapping(address => uint8) private _whiteList;
    
    address private _usdtAddress;
    address private _youAddress;

    constructor() public {

        uint256 blocksOfOneDay = 3600/15*24;
        startHeightOfPriIEO = block.number;
        endHeightOfPriIEO = startHeightOfPriIEO + blocksOfOneDay;
        unlockHeightOfPriIEO = endHeightOfPriIEO;

        startHeightOfPubIEO = block.number;
        endHeightOfPubIEO = startHeightOfPubIEO + blocksOfOneDay;

        unlockHeightOfPubIEO = endHeightOfPubIEO;
        
        _usdtAddress = 0xFA8B1212119197eC88Fc768AF1b04aD0519Ad994;
        _youAddress = 0x7C8D25108E588f858c80f3451F32748382851609;
    }
    
    function initEnvForPri(uint256 startH,uint256 endH,uint256 unlockH, uint256 supplyYou,bool finished) inWhiteList external{
        startHeightOfPriIEO = startH;
        endHeightOfPriIEO = endH;
        unlockHeightOfPriIEO = unlockH;
        supplyYouForPriIEO = supplyYou;
        priOfferingFinished = finished;
    }
    
    function initEnvForPub(uint256 startH,uint256 endH,uint256 unlockH, uint256 targetU,uint256 targetYou,bool finished) inWhiteList external{
        startHeightOfPubIEO = startH;
        endHeightOfPubIEO = endH;
        unlockHeightOfPubIEO = unlockH;
        targetUsdtAmountOfPubIEO = targetU;
        targetYouAmountOfPubIEO = targetYou;
        _pubOfferingFinished = finished;
    }

    modifier inWhiteList() {
        require(_whiteList[msg.sender]==1, "YouSwap: NOT_IN_WHITE_LIST");
        _;
    }

    function isInWhiteList(address addr) external view returns (bool) {
        return _whiteList[addr] == 1;
    }

    function addToWhiteList(address addr) external onlyOwner{
        _whiteList[addr] = 1;
    }

    function removeFromWhiteList(address addr) external onlyOwner{
        _whiteList[addr] = 0;
    }

    function claim() inWhiteList external{
        require(block.number>= unlockHeightOfPriIEO || block.number>= unlockHeightOfPubIEO,'YouSwap: BLOCK_HEIGHT_NOT_REACHED');

        if(block.number>= unlockHeightOfPriIEO){
            uint256 youAmountOfPriIEO = _ordersOfPriIEO[msg.sender];
            if(youAmountOfPriIEO > 0){
                _mintYou(_youAddress,youAmountOfPriIEO);
                _ordersOfPriIEO[msg.sender] = 0;
            }
        }

        if(block.number>= unlockHeightOfPubIEO){
            uint256 amountOfUsdtPayed = _ordersOfPubIEO[msg.sender];
            if(amountOfUsdtPayed > 0) {
                uint256 availableAmountOfUsdt = amountOfUsdtPayed / totalUsdtAmountOfPubIEO * targetUsdtAmountOfPubIEO;
                uint256 youAmountOfPubIEO = availableAmountOfUsdt * targetYouAmountOfPubIEO / targetUsdtAmountOfPubIEO;

                uint256 usdtAmountToRefund = amountOfUsdtPayed - availableAmountOfUsdt;

                if(usdtAmountToRefund > 0){
                    _transfer(_usdtAddress,msg.sender,usdtAmountToRefund);
                
                }

                _mintYou(_youAddress,youAmountOfPubIEO);
            }
        }
    }

    function withdraw() onlyOwner external{
        require(block.number>= unlockHeightOfPriIEO,'YouSwap: BLOCK_HEIGHT_NOT_REACHED');

        uint256 value = totalUsdtAmountOfPriIEO + totalUsdtAmountOfPubIEO;

        _transfer(_usdtAddress,msg.sender,value);
    }

    function privateOffering(uint256 amountOfYou) inWhiteList external returns (bool)  {
        require(block.number >= startHeightOfPriIEO,'YouSwap:NOT_STARTED_YET');
        require(!priOfferingFinished && block.number <= endHeightOfPriIEO,'YouSwap:PRIVATE_OFFERING_ALREADY_FINISHED');
        require(_ordersOfPriIEO[msg.sender] == 0,'YouSwap: ATTENDED_ALREADY');
        require(amountOfYou <= upperLimitYouOfPriIEO,'YouSwap: EXCEED_THE_UPPER_LIMIT');

        require( supplyYouForPriIEO - reservedYouOfPriIEO > 0,'YouSwap:YOU_INSUFFICIENT');

        if(amountOfYou + reservedYouOfPriIEO > supplyYouForPriIEO){
            amountOfYou = supplyYouForPriIEO - reservedYouOfPriIEO;
            priOfferingFinished = true;
        }

        uint256 amountOfUsdt = amountOfYou*youPriceOfPriIEO/10;
        
        _transferFrom(_usdtAddress,amountOfUsdt);

        _ordersOfPriIEO[msg.sender] = _ordersOfPriIEO[msg.sender].add(amountOfYou);
        reservedYouOfPriIEO += amountOfYou;
        totalUsdtAmountOfPriIEO += amountOfUsdt;
        emit PrivateOffering(msg.sender,amountOfYou,amountOfUsdt);
        
        return true;
    }
    
    function pubOfferingFinished() public view returns (bool) {
        return block.number > endHeightOfPubIEO;
    }
    
    function publicOffering(uint256 amountOfUsdt) external returns (bool)  {
       require(block.number >= startHeightOfPubIEO,'YouSwap:PUBLIC_OFFERING_NOT_STARTED_YET');
       require(block.number <= endHeightOfPubIEO,'YouSwap:PUBLIC_OFFERING_ALREADY_FINISHED');
       require(amountOfUsdt >= bottomLimitUsdtOfPubIEO,'YouSwap: AMOUNT_TOO_LOW');

       _transferFrom(_usdtAddress,amountOfUsdt);

       _ordersOfPubIEO[msg.sender] = _ordersOfPubIEO[msg.sender].add(amountOfUsdt);
       totalUsdtAmountOfPubIEO += amountOfUsdt;

       _whiteList[msg.sender] = 1;
        
       return true;
    }
    
    function _transferFrom(address token, uint256 amount) private {
       bytes4 methodId = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        
       (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, msg.sender,address(this), amount));
       require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
    
    function _mintYou(address token,uint256 amount) private {
       bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));
        
       (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, msg.sender,amount));
       require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
    
    function _transfer(address token, address recipient, uint amount) private {
        
       bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));
        
       (bool success, bytes memory data) = token.call(abi.encodeWithSelector(methodId, recipient, amount));
       require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
}