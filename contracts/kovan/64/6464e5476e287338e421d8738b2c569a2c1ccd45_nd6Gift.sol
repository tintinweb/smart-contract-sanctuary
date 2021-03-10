/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// File: contracts/assets/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/assets/Context.sol
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/assets/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: references/nd6Reward/nd6Reward-improve-03.sol
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/access/Ownable.sol";
// import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";


interface Ind2Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
* @notice contribution handler
*/
contract nd6Gift is Ownable {

    //Use SafeMath from OpenZeppelin Libary.
    using SafeMath for uint256;
    
    //This funding have these possible states
    enum State {
        GIVING,
        PAUSED,
        Completed
    }

    AggregatorV3Interface internal priceFeed;               //Interface for chainlink oracle
    
    //Public variables

    //Time-state Related
    State public state = State.GIVING;                      //Set initial stage
    uint256 public nd2GivingStart = block.timestamp.add(7 days);        //Start in one week. Can be updated!
    uint256 public nd2GivingDeadline = nd2GivingStart.add(120 days); //Set duration to 120 days. Can be updated!
    uint256 public completedAt;                             //Set when funding finish
    
    //Token-eth related
    uint256 public totalRaised;                             //eth collected in wei
    uint256 public totalContractSupply;                     //Whole tokens distributed by this contract. Is != totalSupply
    Ind2Token public nd2Token;                              //The nd2 Token contract

    //Contract details
    address private creator;                                //Creator address
    address payable public nd2holder;                       //Holder address

    //events for log
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _user, uint256 _ethReceived, uint256 _give, uint256 _price, uint80 _round);
    event LogWithdrawToHolder(address indexed _holderAddress, uint256 _amount);
    event LogFundingCompleted(uint256 _totalRaised);
    event LogTimeWindowModified(uint256 _start, uint256 _deadLine);

    //Modifier to prevent execution if state is paused o completed.
    modifier isGiving() {
        require(state == State.GIVING, "Funding has ended or is paused");
        _;
    }

    /**
    * @notice constructor
    */
    constructor() {

        /**
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         */
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        creator = _msgSender();                     //Creator is set from deployer address
        nd2holder = payable(creator);               //nd2holder is set to creator address
        nd2Token = Ind2Token(0x8e371407513df991B6Fb28cb700f249F24b40454);              //Token address is set during deployment
        emit LogFundrisingInitialized(creator);     //Log contract initialization

    }

    /**
    * @notice contribution handler
    */
    function contribute(address _target, uint256 _value)
    internal
    isGiving
    {
        
        require(block.timestamp >= nd2GivingStart, "The contribute window has not started");        //Current time must be equal or greater than the start time
        address user = _target;
        uint256 ethReceived = _value;
        (
            uint256 give,
            uint256 price,
            uint80 round
        ) = tokenGetCalc(ethReceived);                            //get conversion data
        totalRaised = totalRaised.add(ethReceived);               //ether received updated
        totalContractSupply = totalContractSupply.add(give);    //Update tokens distributed by this contract
        nd2Token.mint(user, give);                              //Call token contract to mine 

        emit LogFundingReceived(user, ethReceived, give, price, round);               //Log the donation

    }


    /*
    * This function handle the token rewards amounts
    */
    function tokenGetCalc(uint256 _value)
    internal
    view
    returns
    (
        uint256 give,
        uint256 price,
        uint80 roundID
    )
    {
        
        uint256 rewardByUSD;
        /** USD price from chainlink oracle https://chain.link/
         * @param startedAt, timeStamp & answeredInRound are not used here.
         */
         (
            uint80 _roundID, 
            int _price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint256 curSupply = totalContractSupply;
        uint256 priceUSD = uint(_price);
        uint256 temp1 = 1e7;
        rewardByUSD = temp1.sub(curSupply.div(5e18).mul(2));
        uint256 temp2 = _value.mul(priceUSD);
        give = rewardByUSD.mul(temp2).div(1e14);                    //nd2 Tokens to give

        return (give, uint256(_price), _roundID);

    }

    /**
    * @notice function for move existents ether to nd2holder
    */    
    function withdrawToHolder ()
    public
    onlyOwner
    {
        
        require (address(this).balance > 0, "There are not balance to withdraw");
        uint256 withdrawAmount = address(this).balance;
        nd2holder.transfer(withdrawAmount);                                      //eth is send to nd2holder
        emit LogWithdrawToHolder(nd2holder, withdrawAmount);                            //Log transaction
    }
    

    /**
    * @notice Process to check contract current status
    */
    function checkIfCompleted()
    internal
    {

        require(state != State.Completed);                          //When Completed
        if ( block.timestamp >= nd2GivingDeadline){                 //If Deadline is reached and not yet Completed

        state = State.Completed;                                    //Funding becomes Completed
        completedAt = block.timestamp;                              //Funding is complete
        
        emit LogFundingCompleted(totalRaised);                      //Log the finish

        }

    }

    /**
    * @notice Completed closure handler
    */
    function Completed()
    public
    onlyOwner
    {
        
        require(state != State.Completed);                          //When Completed
        withdrawToHolder();                                         //Remanent eth to nd2holder
        state = State.Completed;                                    //Funding becomes Completed
        completedAt = block.timestamp;                              //Funding is complete
        
        emit LogFundingCompleted(totalRaised);                      //Log the finish
        
    }

    /**
     * @notice Function to set a new hoder for withdraws
     * @param _holder Address of holder
    */
    function setHolder(address _holder)
    public
    onlyOwner
    {

      nd2holder = payable(_holder);

    }
    
    /**
     * @notice Function to update de operation window
     * If you want to move the start of funding.
     * It can only be done by the owner before the scheduled start.
     */
     function moveStart(uint256 _start)
     public
     onlyOwner
     {
         
         require (state != State.Completed && block.timestamp < nd2GivingStart, "It is no longer possible to modify the start time");
         require (_start > block.timestamp, "You must set a future time");
         nd2GivingStart = _start;
         emit LogTimeWindowModified(nd2GivingStart, nd2GivingDeadline);

     }
     
     /**
     * @notice Function to update de operation window
     * If you want to move the closing time.
     * This can only be done by the owner before the scheduled closing time and if the status is other than "Completed"
     */
     function moveDeadline(uint256 _deadLine)
     public
     onlyOwner
     {
         
         require (state != State.Completed && block.timestamp < nd2GivingDeadline, "It is no longer possible to modify the deadline time");
         require (_deadLine > block.timestamp, "You must set a future time");
         nd2GivingDeadline = _deadLine;
         emit LogTimeWindowModified(nd2GivingStart, nd2GivingDeadline);
         
     }


    /**
    * @dev Direct payments handler
    */
    receive ()
    external
    payable
    {

        checkIfCompleted();
        contribute(_msgSender(), msg.value);        //Forward to contribute function

    }
}