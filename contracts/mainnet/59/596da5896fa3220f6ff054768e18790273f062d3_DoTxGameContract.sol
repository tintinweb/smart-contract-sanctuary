/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IDotTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

interface IDoTxLib{
    function queryChainLinkPrice(string calldata _fsym, string calldata _fsymId, int256 _multiplicator, bytes4 _selector) external;
    function fetchFirstDayPrices(string calldata firstHouseTicker, string calldata secondHouseTicker, string calldata firstHouseId, string calldata secondHouseId, int256 multiplicator, uint256 warIndex) external;
    function fetchLastDayPrices(string calldata firstHouseTicker, string calldata currentSecondHouseTicker, string calldata firstHouseId, string calldata secondHouseId, int256 multiplicator, uint256 warIndex) external;
    function setDoTxGame(address gameAddress) external;
    function calculateHousePerf(int256 open, int256 close, int256 precision) external pure returns(int256);
    function calculatePercentage(uint256 amount, uint256 percentage, uint256 selecteWinnerPrecision) external pure returns(uint256);
    function calculateReward(uint256 dotxUserBalance, uint256 totalDoTxWinningHouse, uint256 totalDoTxLosingHouse) external view returns(uint256);
    function getWarIndex() external view returns(uint256);
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _owner2;
    address public dotxLibAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function owner2() public view returns (address) {
        return _owner2;
    }
    
    function setOwner2(address ownerAddress) public onlyOwner {
        _owner2 = ownerAddress;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyOwnerOrDoTxLib() {
        require(_owner == _msgSender() || dotxLibAddress == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner or the lib");
        _;
    }
    
    modifier onlyDoTxLib() {
        require(dotxLibAddress == _msgSender(), "Ownable: caller is not the owner or the lib");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title DeFi Of Thrones Game Contract
 * @author Maxime Reynders - DefiOfThrones (https://github.com/DefiOfThrones/DOTTokenContract)
 */
contract DoTxGameContract is Ownable {
    using SafeMath for uint256;
    //Burn x% of the losing house tickets to Vitalik Address
    address constant public BURN_ADDRESS = 0x0000000000000000000000000000000000000001;

    //War struct, for each war a War variable will be created 
    struct War {
        uint256 startTime;
        uint256 duration;
        uint256 ticketPrice;
        uint256 purchasePeriod;
        bytes32 winningHouse;
        uint256 warFeesPercent;
        int256 multiplicator;
        uint256 burnPercentage;
        uint256 stakingPercentage;
        House firstHouse;
        House secondHouse;
        mapping(address => User) users;
    }
    //House struct, each war contains an map of 2 houses
    struct House {
        bytes32 houseTicker;
        bytes32 houseId;
        uint256 openPrice;
        uint256 closePrice;
        uint256 ticketsBought;
    }
    //User struct, each war contains a map of users
    //Each user can pledge allegiance to a house, buy tickets and switch house by paying fees (x% of its bought tickets)
    struct User {
        bytes32 houseTicker;
        uint256 ticketsBought;
        bool rewardClaimed;
    }
    
    //BURN STAKING INFORMATION
    struct BurnStake {
        uint256 firstHouseBurnDoTx;
        uint256 firstHouseStakingDoTx;
        uint256 secondHouseBurnDoTx;
        uint256 secondHouseStakingDoTx;
    }
    
    struct WarHouses {
        uint256 index;
        bytes32 firstHouse;
        bytes32 secondHouse;
        uint256 startTime;
        uint256 duration;
    }
    
    //DOTX Token Contract Address
    IDotTokenContract private dotxToken;
    //DOTX Game lib
    IDoTxLib private dotxLib;
    //x% of the losing house tickets are sent to the throne vault
    address stakingAddress = address(0x1c2206f3115CaC3750acCb899d18d50b774C2f21);
    
    //Map of Wars 
    mapping(uint256 => War) public wars;
    
    //GENERAL VARS
    //Total fees paid by users
    uint256 public totalFees;
    //Precision for the select winner calculation
    uint256 public selecteWinnerPrecision = 100000;
    
    uint256 public burnPercentage = 5;
    uint256 public stakingPercentage = 5;
    int256 public multiplicator = 10000;
    
    //EVENTS
    event WarStarted(uint256 warIndex);
    event TicketBought(uint256 warIndex, string house, uint256 valueInDoTx, address sender, string txType);
    event ClaimReward(uint256 warIndex, uint256 reward, uint256 balance, address sender, string txType);
    event SwitchHouse(uint256 warIndex, string from, string to, address sender, uint256 valueInDoTx);
    event openPriceFetched(uint256 warIndex);
    event closePriceFetched(uint256 warIndex);
    event StakeBurn(uint256 warIndex, uint256 burnValue, uint256 stakeValue);

    //MODIFIERS
    modifier onlyIfCurrentWarFinished(uint256 warIndex) {
        require(wars[warIndex].startTime.add(wars[warIndex].duration) <= now || warIndex == 0, "Current war not finished");
        _;
    }
    
    modifier onlyIfCurrentWarNotFinished(uint256 warIndex) {
        require(wars[warIndex].startTime.add(wars[warIndex].duration) > now, "Current war finished");
        _;
    }
    
    modifier onlyIfTicketsPurchasable(uint256 warIndex) {
        require(now.sub(wars[warIndex].startTime) < wars[warIndex].purchasePeriod,
        "Purchase tickets period ended");
        _;
    }
    
    modifier onlyIfPricesFetched(uint256 warIndex){
        require(wars[warIndex].firstHouse.openPrice != 0 && wars[warIndex].secondHouse.openPrice != 0, "Open prices not fetched");
        require(wars[warIndex].firstHouse.closePrice != 0 && wars[warIndex].secondHouse.closePrice != 0, "Close prices not fetched");
        _;
    }
    
    /**
     * Game contract constructor
     * Just pass the DoTx token contract address in parameter
     **/
    constructor(address dotxTokenAddress, address dotxLibAddr, bool setupAddressInLib) public {
        //Implement DoTx contract interface by providing address
        dotxToken = IDotTokenContract(dotxTokenAddress);
        
        setDoTxLib(dotxLibAddr, setupAddressInLib);
    }
    
    /**************************
            WAR METHODS
    ***************************/
    
    /**
     * Start a war only if the previous is finished
     * Parameters :
     * _firstHouseTicker First house ticker 
     * _secondHouseTicker Second house ticker 
     * _duration Duration of the war in seconds 
     * _ticketPrice Ticket price : Number of DoTx needed to buy a ticket (in wei precision)
     * purchasePeriod Number of seconds where the users can buy tickets from the starting date
     * _warFeesPercent How many % fees it will cost to user to switch house 
     * _warIndex Index of the war in mapping
     **/
    function startWar(string memory _firstHouseTicker, string memory _secondHouseTicker, string memory _firstHouseId, string memory _secondHouseId, 
    uint256 _duration, uint256 _ticketPrice, uint256 _purchasePeriod, uint256 _warFeesPercent, uint256 _warIndex) 
    public onlyOwner returns(bool) {
        //Just prevent to replace a war
        require(_warIndex > dotxLib.getWarIndex(), "War index already exists");
        
        //Create war  
        wars[_warIndex] = War(now, _duration, _ticketPrice, _purchasePeriod, 0, _warFeesPercent, multiplicator, burnPercentage, stakingPercentage, 
        House(stringToBytes32(_firstHouseTicker), stringToBytes32(_firstHouseId), 0, 0, 0),
        House(stringToBytes32(_secondHouseTicker), stringToBytes32(_secondHouseId), 0, 0, 0));
        
        emit WarStarted(_warIndex);
        
        fetchFirstDayPrices(_warIndex);
        
        return true;
    }
    
     /**
     * Buy ticket(s) for the current war - only if tickets are purchasable -> purchasePeriod
     * Parameters :
     * _houseTicker House ticker 
     * _numberOfTicket The number of tickets the user wants to buy
     **/
    function buyTickets(string memory _houseTicker, uint _numberOfTicket, uint256 warIndex) public onlyIfTicketsPurchasable(warIndex) {
        bytes32 houseTicker = stringToBytes32(_houseTicker);
        //Get house storage
        House storage userHouse = getHouseStg(houseTicker, warIndex);
        
        //Allow user to only buy tickets for one single House and the one passed in parameter
        bytes32 userHouseTicker = wars[warIndex].users[msg.sender].houseTicker;
        require(userHouse.houseTicker == houseTicker && (userHouseTicker == houseTicker || userHouseTicker == 0), "You can not buy tickets for the other house");

        wars[warIndex].users[msg.sender].houseTicker = userHouse.houseTicker;

        //Update user tickets
        wars[warIndex].users[msg.sender].ticketsBought = wars[warIndex].users[msg.sender].ticketsBought.add(_numberOfTicket);
        
        //Increase tickets bought for the house
        userHouse.ticketsBought = userHouse.ticketsBought.add(_numberOfTicket);
        
        uint256 valueInDoTx = wars[warIndex].ticketPrice.mul(_numberOfTicket);
        
        //Propagate TicketBought event
        emit TicketBought(warIndex, _houseTicker, valueInDoTx, msg.sender, "BOUGHT");
        
        //Transfer DoTx
        dotxToken.transferFrom(msg.sender, address(this), valueInDoTx);
    }
    
    /**
     * Switch house for the user - only if tickets are purchasable -> purchasePeriod
     * Parameters :
     * _fromHouseTicker Current house user pledged allegiance 
     * _toHouseTicker the house user wants to join
     **/
    function switchHouse(string memory _fromHouseTicker, string memory _toHouseTicker, uint256 warIndex) public onlyIfTicketsPurchasable(warIndex) {

        bytes32 fromHouseTicker = stringToBytes32(_fromHouseTicker);
        bytes32 toHouseTicker = stringToBytes32(_toHouseTicker);
        
        //Check if toHouse is in competition && different of fromHouse
        require(checkIfHouseInCompetition(toHouseTicker, warIndex) && fromHouseTicker != toHouseTicker, "House not in competition");
        //Check if user belongs to _fromHouse 
        require(wars[warIndex].users[msg.sender].houseTicker == fromHouseTicker, "User doesn't belong to fromHouse");
        
        House storage fromHouse = getHouseStg(fromHouseTicker, warIndex);
        House storage toHouse = getHouseStg(toHouseTicker, warIndex);
        
        //Switch house for user
        wars[warIndex].users[msg.sender].houseTicker = toHouseTicker;
        
        //Update fromHouse tickets
        uint256 ticketsBoughtByUser = wars[warIndex].users[msg.sender].ticketsBought;
        fromHouse.ticketsBought = fromHouse.ticketsBought.sub(ticketsBoughtByUser);
        
        //Update toHouse tickets
        toHouse.ticketsBought = toHouse.ticketsBought.add(ticketsBoughtByUser);
        
        //Get fees
        uint256 feesToBePaid = getFeesForSwitchHouse(msg.sender, warIndex);
        //Update total fees
        totalFees = totalFees.add(feesToBePaid);
        
        emit SwitchHouse(warIndex, _fromHouseTicker, _toHouseTicker, msg.sender, feesToBePaid);
        
        //Get fees from user wallet
        dotxToken.transferFrom(msg.sender, address(this), feesToBePaid);
    }
    
    /**
     * Allow users who pledged allegiance to the winning house to claim bought tickets + reward
     * Parameters :
     **/
    function claimRewardAndTickets(uint256 warIndex) public onlyIfCurrentWarFinished(warIndex) returns(bool) {
        //Only claim reward one times
        require(wars[warIndex].users[msg.sender].rewardClaimed == false, "You already claimed your reward");
        
        //Check if user belongs to winning house
        require(wars[warIndex].users[msg.sender].ticketsBought > 0 && wars[warIndex].users[msg.sender].houseTicker == wars[warIndex].winningHouse, "User doesn't belong to winning house");
        
        //Set rewardClaimed to true
        wars[warIndex].users[msg.sender].rewardClaimed = true;
        
        //DoTx in user balance (tickets bought) & reward
        uint256 reward = getCurrentReward(wars[warIndex].winningHouse, msg.sender, warIndex);
        uint256 balance = getUserDoTxInBalance(warIndex, msg.sender);
        
        dotxToken.transfer(msg.sender, reward.add(balance));
        
        emit ClaimReward(warIndex, reward, balance, msg.sender, "CLAIM");
    }

    
    /*****************************
            PRICES METHODS
    ******************************/
    
    /**
     * Fetch the prices for the 2 houses the first day for the current war
     **/
    function fetchFirstDayPrices(uint256 warIndex) public onlyOwner {
        require(wars[warIndex].firstHouse.openPrice == 0 && wars[warIndex].secondHouse.openPrice == 0, "Open prices already fetched");
        
        string memory firstHouse = bytes32ToString(wars[warIndex].firstHouse.houseTicker);
        string memory secondHouse = bytes32ToString(wars[warIndex].secondHouse.houseTicker);
        
        dotxLib.fetchFirstDayPrices(firstHouse, secondHouse, bytes32ToString(wars[warIndex].firstHouse.houseId), bytes32ToString(wars[warIndex].secondHouse.houseId), wars[warIndex].multiplicator, warIndex);
    }

    /**
     * Fetch the prices for the 2 houses the last day for the current war
     **/
    function fetchLastDayPrices(uint256 warIndex) public onlyOwner onlyIfCurrentWarFinished(warIndex) {
        require(wars[warIndex].firstHouse.closePrice == 0 && wars[warIndex].secondHouse.closePrice == 0, "Close prices already fetched");
        
        string memory firstHouse = bytes32ToString(wars[warIndex].firstHouse.houseTicker);
        string memory secondHouse = bytes32ToString(wars[warIndex].secondHouse.houseTicker);
        
        dotxLib.fetchLastDayPrices(firstHouse, secondHouse, bytes32ToString(wars[warIndex].firstHouse.houseId), bytes32ToString(wars[warIndex].secondHouse.houseId), wars[warIndex].multiplicator, warIndex);
    }
    
    /**
     * Elect the winner based on open prices & close prices
     **/
    function selectWinner(uint256 warIndex) public onlyOwner onlyIfCurrentWarFinished(warIndex) onlyIfPricesFetched(warIndex) {
        require(wars[warIndex].winningHouse == 0, "Winner already selected");
        
        int256 precision = int256(selecteWinnerPrecision);
        
        int256 firstHousePerf =  dotxLib.calculateHousePerf(int256(wars[warIndex].firstHouse.openPrice), int256(wars[warIndex].firstHouse.closePrice), precision);
        int256 secondHousePerf = dotxLib.calculateHousePerf(int256(wars[warIndex].secondHouse.openPrice), int256(wars[warIndex].secondHouse.closePrice), precision);
        
        //Set winner house
        wars[warIndex].winningHouse = (firstHousePerf > secondHousePerf ? wars[warIndex].firstHouse : wars[warIndex].secondHouse).houseTicker;
        House memory losingHouse = (firstHousePerf > secondHousePerf ? wars[warIndex].secondHouse : wars[warIndex].firstHouse);
        
        /*
        BURN X% OF LOSING HOUSE'S DOTX
        */
        uint256 burnValue = calculateBurnStaking(losingHouse, true, warIndex);
        dotxToken.transfer(BURN_ADDRESS, burnValue);
        
        /*
        SEND X% OF LOSING HOUSE'S DOTX TO STAKING ADDRESS
        */
        uint256 stakingValue = calculateBurnStaking(losingHouse, true, warIndex);
        dotxToken.transfer(stakingAddress, stakingValue);
        
        emit StakeBurn(warIndex, burnValue, stakingValue);
    }

    
    /*******************************
            CHAINLINK METHODS
    ********************************/
    
    /**
     * Handler method called by Chainlink for the first house open price 
     **/
    function firstHouseOpen(uint256 _price, uint256 warIndex) external onlyDoTxLib {
        wars[warIndex].firstHouse.openPrice = _price;
        openPriceEvent(warIndex);
    }
    /**
     * Handler method called by Chainlink for the second house open price 
     **/
    function secondHouseOpen(uint256 _price, uint256 warIndex) external onlyDoTxLib {
        wars[warIndex].secondHouse.openPrice = _price;
        openPriceEvent(warIndex);
    }
    /**
     * Handler method called by Chainlink for the first house close price 
     **/
    function firstHouseClose(uint256 _price, uint256 warIndex) external onlyDoTxLib {
        wars[warIndex].firstHouse.closePrice = _price;
        closePriceEvent(warIndex);
    }
    /**
     * Handler method called by Chainlink for the second house close price 
     **/
    function secondHouseClose(uint256 _price, uint256 warIndex) external onlyDoTxLib {
        wars[warIndex].secondHouse.closePrice = _price;
        closePriceEvent(warIndex);
    }
    /**
     * Emit openPriceFetched event if needed
     **/
    function openPriceEvent(uint256 warIndex) private {
        if(wars[warIndex].firstHouse.openPrice != 0 && wars[warIndex].secondHouse.openPrice != 0){
            emit openPriceFetched(warIndex);
        }
    }
    /**
     * Emit closePriceFetched event if needed
     **/
    function closePriceEvent(uint256 warIndex) private {
        if(wars[warIndex].firstHouse.closePrice != 0 && wars[warIndex].secondHouse.closePrice != 0){
            emit closePriceFetched(warIndex);
        }
    }
    
    /*****************************
            GETTER METHODS
    ******************************/
    
    /**
     * Get user (ticketsBought * ticketPrice) - user fees
     **/
    function getUserDoTxInBalance(uint256 _warIndex, address userAddress) public view returns(uint256){
        return wars[_warIndex].users[userAddress].ticketsBought.mul(wars[_warIndex].ticketPrice);
    }
    
    
    function getFeesForSwitchHouse(address userAddress, uint256 warIndex) public view returns(uint256){
        return (getUserDoTxInBalance(warIndex, userAddress).mul(wars[warIndex].warFeesPercent)).div(100);
    }
    
    /**
     * Returns the current user
     **/
    function getUser(uint256 _warIndex, address userAddress) public view returns(User memory){
        return wars[_warIndex].users[userAddress];
    }
    
    /**
     * Return house for a specific war
     **/
    function getHouse(uint256 _warIndex, string memory houseTicker) public view returns(House memory){
        bytes32 ticker = stringToBytes32(houseTicker);
        return wars[_warIndex].firstHouse.houseTicker == ticker ? wars[_warIndex].firstHouse : wars[_warIndex].secondHouse;
    }
    /**
     * Return burn stake information
     **/
    function getBurnStake(uint256 warIndex) public view returns(BurnStake memory){
        return BurnStake(calculateBurnStaking(wars[warIndex].firstHouse, true, warIndex), calculateBurnStaking(wars[warIndex].firstHouse, false, warIndex),
        calculateBurnStaking(wars[warIndex].secondHouse, true, warIndex), calculateBurnStaking(wars[warIndex].secondHouse, false, warIndex));
    }
    
    function getWarsHouses(uint256 min, uint256 max) public view returns (WarHouses[20] memory){
        WarHouses[20] memory houses;
        uint256 i = min;
        uint256 index = 0;
        while(index < 20 && i <= (max - min) + 1){
            houses[index] = (WarHouses(i, wars[i].firstHouse.houseTicker, wars[i].secondHouse.houseTicker, wars[i].startTime, wars[i].duration));
            i++;
            index++;
        }
        return houses;
    }
    /*****************************
            ADMIN METHODS
    ******************************/
    
    /**
     * Set the select winner precision used for calculate the best house's performance
     **/
    function setSelectWinnerPrecision(uint256 _precision) public onlyOwner{
        selecteWinnerPrecision = _precision;
    }

     /**
     * Set staking % of the losing house's DoTx to send for the currentWar
     **/
    function setStakingBurnPercentageWar(uint256 _burnPercentage, uint256 _stakingPercentage, uint256 warIndex) public onlyOwner{
        wars[warIndex].burnPercentage = _burnPercentage;
        wars[warIndex].stakingPercentage = _stakingPercentage;
    }
    
    /**
     * Set staking % of the losing house's DoTx to send
     **/
    function setStakingBurnPercentage(uint256 _burnPercentage, uint256 _stakingPercentage) public onlyOwner{
        burnPercentage = _burnPercentage;
        stakingPercentage = _stakingPercentage;
    }
    
    /**
     * Precision of the prices receive from WS
     **/
    function setMultiplicatorWar(int256 _multiplicator, uint256 warIndex) public onlyOwner{
        wars[warIndex].multiplicator = _multiplicator;
    }
    
    /**
     * Precision of the prices receive from WS
     **/
    function setMultiplicator(int256 _multiplicator) public onlyOwner{
        multiplicator = _multiplicator;
    }
    
    /**
     * Let owner withdraw DoTx fees (in particular to pay the costs generated by Chainlink)
     **/
    function withdrawFees() public onlyOwner {
        //Fees from switch house
        dotxToken.transfer(owner(), totalFees);
        
        totalFees = 0;
    }
    
    /**
     * Let owner set the DoTxLib address
     **/
    function setDoTxLib(address dotxLibAddr, bool setupAddressInLib) public onlyOwner {
        //DOTX lib mainly uses for Chainlink
        dotxLibAddress = dotxLibAddr;
        dotxLib = IDoTxLib(dotxLibAddress);
        if(setupAddressInLib){
            dotxLib.setDoTxGame(address(this));
        }
    }
    
    /**
     * Let owner update stakingAddress
     **/
    function setStakingAddress(address stakingAdr) public onlyOwner {
        stakingAddress = stakingAdr;
    }

    /****************************
            UTILS METHODS
    *****************************/
    
    function getHouseStg(bytes32 ticker, uint256 warIndex) private view returns(House storage){
        return wars[warIndex].firstHouse.houseTicker == ticker ? wars[warIndex].firstHouse : wars[warIndex].secondHouse;
    }
    
    /**
     * Check if the house passed in parameter is in the current war
     **/
    function checkIfHouseInCompetition(bytes32 _houseTicker, uint256 warIndex) private view returns(bool){
        return wars[warIndex].firstHouse.houseTicker == _houseTicker || wars[warIndex].secondHouse.houseTicker == _houseTicker;
    }
    
    /**
     * Calculate the reward for the current user
     **/
    function getCurrentRewardString(string memory _winningHouse, address userAddress, uint256 warIndex) public view returns(uint256){
        bytes32 winningHouseTicker = stringToBytes32(_winningHouse);
        return getCurrentReward(winningHouseTicker, userAddress, warIndex);
    } 
    
    function getCurrentReward(bytes32 _winningHouse, address userAddress, uint256 warIndex) public view returns(uint256){
        //Losing house
        House memory losingHouse = wars[warIndex].firstHouse.houseTicker == _winningHouse ? wars[warIndex].secondHouse : wars[warIndex].firstHouse;
        
        //Total DoTx in house's balance
        uint256 totalDoTxWinningHouse = getHouseStg(_winningHouse, warIndex).ticketsBought.mul(wars[warIndex].ticketPrice);
        uint256 totalDoTxLosingHouse = losingHouse.ticketsBought.mul(wars[warIndex].ticketPrice).sub(calculateBurnStaking(losingHouse, true, warIndex)).sub(calculateBurnStaking(losingHouse, false, warIndex));
        
        return dotxLib.calculateReward(getUserDoTxInBalance(warIndex, userAddress), totalDoTxWinningHouse, totalDoTxLosingHouse);
    }
    
    function calculateBurnStaking(House memory house, bool isBurn, uint256 warIndex) public view returns(uint256){
        uint256 ticketsBoughtValueDoTx = house.ticketsBought.mul(wars[warIndex].ticketPrice);
        uint256 percentage =  isBurn ? wars[warIndex].burnPercentage : wars[warIndex].stakingPercentage;
        //Calculate tickets remaining after burn
        return dotxLib.calculatePercentage(ticketsBoughtValueDoTx, percentage, selecteWinnerPrecision);
    }
    
    /**
     * Convert string to bytes32
     **/
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * Convert bytes32 to string
     **/
    function bytes32ToString(bytes32 x) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}