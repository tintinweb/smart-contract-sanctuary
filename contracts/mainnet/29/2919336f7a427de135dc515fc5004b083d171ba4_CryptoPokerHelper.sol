pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract CryptoPokerBase is Ownable
{
    using SafeMath for uint256;
    enum CardStatus
    {
        Frozen,
        Tradable
    }
    
    struct Card
    {
        uint256 id;
        uint256 sellPrice;
        //card status 
        CardStatus status;
        //card update
        uint256 upTime;
    }
    
    mapping(uint256=>address) cardToOwer;
    mapping(address=>uint256) ownerCardCount;
    mapping(uint256=>uint256) idToCardIndex;
    mapping(address=>bool) workers;
    
    Card[] allCards;
    address[] workerArr;
    
    uint256 upIndex = 0;
   
    bool saleStatus = true;
    uint256 salePrice = 90000000000000000;
    
    
    modifier isWorker()
    {
        require(msg.sender == owner || workers[msg.sender]);
        _;
    }
    
    modifier canSale()
    {
        require(saleStatus);
        _;
    }
    
    
    function setWorkerAdress(address _adress) external onlyOwner
    {
        require(_adress!=address(0));
        workers[_adress] = true;
        workerArr.push(_adress);
    }
    
    function deleteWorkerAdress(address _adress) external onlyOwner
    {
        require(_adress!=address(0));
        workers[_adress] = false;
    }
    
    function getAllWorkers() external view isWorker returns(address[],bool[])
    {
        address[] memory addressArr = new address[](workerArr.length);
        bool[] memory statusArr = new bool[](workerArr.length);
        for(uint256 i=0;i<workerArr.length;i++)
        {
            addressArr[i] = workerArr[i];
            statusArr[i] = workers[workerArr[i]];
        }
        return (addressArr,statusArr);
    }
    

    function setSaleStatus(bool value) external isWorker
    {
        saleStatus = value;
    }
    
    function getSaleStatus() external view returns(bool)
    {
        return saleStatus;
    }
    
    function setSalePrice(uint256 value) external isWorker
    {
        salePrice = value;
    }
    
    function getSalePrice() external view returns(uint256)
    {
        return salePrice;
    }
    
   
    function withdraw() external isWorker
    {
        owner.transfer(this.balance);
    }
    
    function getBalance() external view returns(uint256)
    {
        return this.balance;
    }

    
}
contract CryptoPokerMarket is CryptoPokerBase
{
    
    event fallbackTrigged(bytes data);
    event saleCardEvent(address _address,uint256 price);
    event createSaleCardEvent(address _address);

    function() public payable
    {
        emit fallbackTrigged(msg.data);
    }
    
    function buySaleCardFromSys() external canSale payable
    {
        require(msg.value>=salePrice);
        emit saleCardEvent(msg.sender,msg.value);
    }
    
    function createSaleCardToPlayer(uint256[] ids,address _address) external isWorker
    {
        require(_address != address(0));
        for(uint256 i=0;i<ids.length;i++)
        {
            if(cardToOwer[ids[i]] == address(0))
            {
                allCards.push(Card(ids[i],0,CardStatus.Tradable,upIndex));
                idToCardIndex[ids[i]] = allCards.length - 1;
                cardToOwer[ids[i]] = _address;
                ownerCardCount[_address] = ownerCardCount[_address].add(1);    
            }
            
        }
        emit createSaleCardEvent(_address);
    }

    
    function balanceOf(address _owner) public view returns (uint256 _balance)
    {
        return ownerCardCount[_owner];
    }
      
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return cardToOwer[_tokenId];    
    }
}
contract CryptoPokerHelper is CryptoPokerMarket
{
    
    function getAllCardByAddress(address _address) external isWorker view returns(uint256[],uint256[])
    {
        require(_address!=address(0));
        uint256[] memory result = new uint256[](ownerCardCount[_address]);
        uint256[] memory cardStatus = new uint256[](ownerCardCount[_address]);
        uint counter = 0;
        for (uint i = 0; i < allCards.length; i++)
        {
            uint256 cardId = allCards[i].id;
            if (cardToOwer[cardId] == _address) {
                result[counter] = cardId;
                cardStatus[counter] = allCards[i].sellPrice;
                counter++;
            }
         }
         return (result,cardStatus);
    }
    
    function getSelfCardDatas() external view returns(uint256[],uint256[])
    {
        uint256 count = ownerCardCount[msg.sender];
        uint256[] memory result = new uint256[](count);
        uint256[] memory resultPrice = new uint256[](count);
        if(count > 0)
        {
            uint256 counter = 0;
            for (uint256 i = 0; i < allCards.length; i++)
            {
                uint256 cardId = allCards[i].id;
                if (cardToOwer[cardId] == msg.sender) {
                    result[counter] = cardId;
                    resultPrice[counter] = allCards[i].sellPrice;
                    counter++;
                }
            }
        }
        return (result,resultPrice);
    }
    
    
    function getSelfBalance() external view returns(uint256)
    {
        return(address(msg.sender).balance);
    }
    
    
    function getAllCardDatas() external view isWorker returns(uint256[],uint256[],address[])
    {
        uint256 len = allCards.length;
        uint256[] memory resultIdArr = new uint256[](len);
        uint256[] memory resultPriceArr = new uint256[](len);
        address[] memory addressArr = new address[](len);
        
        for(uint256 i=0;i<len;i++)
        {
            resultIdArr[i] = allCards[i].id;
            resultPriceArr[i] = allCards[i].sellPrice;
            addressArr[i] = cardToOwer[allCards[i].id];
        }
        return(resultIdArr,resultPriceArr,addressArr);
    }
}