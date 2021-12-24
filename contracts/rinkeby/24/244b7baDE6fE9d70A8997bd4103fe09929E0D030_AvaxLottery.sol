pragma solidity >=0.6.0 <0.9.0;
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract AvaxLottery is Ownable {
    uint depositedAvax = 0;
    AggregatorV3Interface internal priceFeed;
    uint AvaxPoolAmount = 0;
    uint256 public  RoundId = 0;
    int256 startedEthPrice =0;
    uint256 public depositedAmount;
    uint256 public  pricePool = 0;
    uint256 public  profitMultiplier = 0;
    uint256 public winnerPool;
    uint256 public payableAvaxAmount;
     string  public  winState;
    uint256 public feeRate; 
    constructor() {
        
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }
    struct GuessedPerson{
        address  userAddress;
        uint depositedAvax;
        uint256 enteredRountId;
        string prediction;
    }
    GuessedPerson[] public guessedPersons;
    struct WinnerList{
        address  winnerAddrres;
        uint256 depositedAmount;


    }
    WinnerList[] public winnerLists;
    struct Round{
        uint256 RoundId;
        uint AvaxPoolAmount;
        bool isFinished;
        int256 StartedPrice;
        int256 EndedPrice;
    }
    Round[] public rounds;
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        return price/100000000;
    }
    
    uint256 public avaxLotteryComissionMultipler = 7500;
    uint256 lotTokenComissionAmount = 0;
    //mapping (address => GuessedPerson[]) public persons;


    
    function depositAvax( string memory _prediction) public payable{
        //require(msg.value>=100000000000000000,"");
        guessedPersons.push(GuessedPerson(
            msg.sender,
            msg.value,
            RoundId,
            _prediction

        ));
        AvaxPoolAmount = AvaxPoolAmount+msg.value;
    }
    function setStartedPrice() public onlyOwner{
        //startedEthPrice = getLatestPrice();
        startedEthPrice = 1000;
        
    }
    
    function ExecuteRound() public onlyOwner{
        
        uint256 _thisRoundId = RoundId+1;
        RoundId = _thisRoundId;
        
        //int256 _endedEthPrice = getLatestPrice();
         int256 _endedEthPrice = 100;
        rounds.push(Round(
            RoundId,
            AvaxPoolAmount,
            true,
            startedEthPrice,
            _endedEthPrice
        ));
        calculateWinners(guessedPersons);
         pricePool = calculateWinAmount(winnerLists);
         profitMultiplier = profitPercantage(pricePool);
        payToWinners(profitMultiplier,winnerLists);
        delete winnerLists;
        delete guessedPersons;


    
        

       

    }
    function calculateWinners(GuessedPerson[] memory _internalPersons)internal {
        for(uint i=0;i<_internalPersons.length; i++ ){
            uint avaxvalue = _internalPersons[i].depositedAvax;
            if(rounds[RoundId-1].StartedPrice>rounds[RoundId-1].EndedPrice){
                winState = "down";
            }
            if(rounds[RoundId-1].StartedPrice<rounds[RoundId-1].EndedPrice){
                winState = "up";
            }
            if (keccak256(abi.encodePacked(_internalPersons[i].prediction)) == keccak256(abi.encodePacked(winState))) {
                winnerLists.push(WinnerList(
                    _internalPersons[i].userAddress,
                    avaxvalue
                ));
             }
            
        }
        
    }
    
    function calculateWinAmount(WinnerList[] memory  _payablewinners)internal   returns (uint prize) {
         uint256 avaxpool = rounds[RoundId-1].AvaxPoolAmount;
         depositedAmount = _payablewinners[0].depositedAmount;
         uint256 _prizePool;
         for(uint i=0;i<_payablewinners.length;i++){
             winnerPool = winnerPool+_payablewinners[i].depositedAmount;
         }
         _prizePool = avaxpool - winnerPool;
         return _prizePool;
    }
    function profitPercantage(uint256 pricePool)internal  returns(uint256 multiplier){
        uint256 avaxpool = rounds[RoundId-1].AvaxPoolAmount;
        uint256 netPool = avaxpool-pricePool;
        uint256 profitMultiplier = avaxpool*10000/netPool-feeRate;
        return profitMultiplier;
    }
    function payToWinners(uint profitMultiplier,WinnerList[] memory _winners) internal {
        for(uint i=0;i<_winners.length;i++){
            payableAvaxAmount = _winners[i].depositedAmount/10000*profitMultiplier;
            address    winnedAddress = _winners[i].winnerAddrres;
           (bool sent, bytes memory data) = winnedAddress.call{value: payableAvaxAmount}("");
           require(sent,"failed eth transfer");
            
         }
    }
    function withdrawBalance(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.7.0 <0.9.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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