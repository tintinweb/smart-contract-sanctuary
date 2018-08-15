pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    owner = newOwner;
  }

}

contract EventStructContract {
        //структура для хранения события
        struct EventStruct {
          uint64 eventID;    
          uint eventDate;
          uint8 result; // 0 - отрицательный, 1 - положительный, 2 - не выставлен
          uint resultSetTime; // время, когда админ выставил результат события 
          bool isSet;
          uint8 percent; //процент, оставляемый за владельцем контракта
          uint minBet;
          uint maxBet;
          
        }   
}


contract EventsDatabase is Ownable, EventStructContract {
    
    using SafeMath for uint256;


    
    //Событие. Записываем лог
    event createEventLog(string _description, uint _eventDate,  uint64 _eventID );
    event setEventResultLog(string _description,  uint64 _eventID, uint8 _result );
    event editEventResultLog(string _description,  uint64 _eventID, uint8 _result );

    //адресс с которого разрешено заносить события в базу
    address manager;
    
    //Сама база данных ID события => структура
    mapping (uint64 => EventStruct) public eventDatabase;
    
    //конструктор. Вызывается 1 раз при деплое контракта
    constructor() public {
        manager = msg.sender;
    }

    //Модификатор проверяющий, является ли вызвавший метод владельцем контракта или менеджером
    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager));
        _;
    }

    //Смена менеджера. Может быть вызвана только владельцем
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }
    
    //Заносим событие в базу данных
    function createEvent(string _description, uint _eventDate, uint8 _percent, uint _minBet, uint _maxBet , uint64 _eventID ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(eventDatabase[_eventID].isSet){
            revert();
        }
        EventStruct memory eventStruct = EventStruct({eventID:_eventID, eventDate:_eventDate, result:2, resultSetTime:0, isSet:true, percent:_percent, minBet:_minBet, maxBet:_maxBet });
        
        eventDatabase[_eventID] = eventStruct;
        emit createEventLog(_description,  _eventDate,   _eventID);
    }
    
    function setEventResult(string _description, uint64 _eventID, uint8 _result  ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        //проверяем - наступилали дата события
        if(now < eventDatabase[_eventID].eventDate){
            revert();
        }
        //проверяем - выставлен ли результат
        if(eventDatabase[_eventID].result!=2){
            revert();
        }
        
        eventDatabase[_eventID].result = _result;
        eventDatabase[_eventID].resultSetTime = now;
        emit setEventResultLog(_description,  _eventID,   _result);
    }
    
    function editEventResult(string _description, uint64 _eventID, uint8 _result  ) public onlyOwner {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        //проверяем - наступилали дата события
        if(now < eventDatabase[_eventID].eventDate){
            revert();
        }
        //проверяем, не прошлили 24 часа с момента установки результата события админом
        if(now > (eventDatabase[_eventID].resultSetTime + 24*60*60)){
            revert();
        }
        
        
        eventDatabase[_eventID].result = _result;
        emit editEventResultLog(_description,  _eventID,   _result);
    }
    
    function getEventResult( uint64 _eventID ) public constant returns(uint8) {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        
        return eventDatabase[_eventID].result;
    }
    
    
    function readEventFromDatabase (uint64 _eventID) public constant returns (EventStruct) {
        return eventDatabase[_eventID];
    }
    
}



contract BetContract is Ownable, EventStructContract {
    
    using SafeMath for uint256;
    
    //адресс с которого разрешено заносить букмекеров в белый лист
    address manager;    

    //Контракт со списком событий
    EventsDatabase public eventsDatabase;
    //uint public bettorTakeRewardsPeriod = 60*60; // период, в течении которого Беттор может забрать выигрыш
    //uint public bookmakerTakeRewardsPeriod = 60*60; // период, в течении которого Букмэйкер может забрать выигрыш
    uint public takeRewardsPeriod = 12*60*60; // период, в течении которого может забрать выигрыш
    uint public returnBetsAfterPeriod = 30*60; // Если не был выставлен результат события, то по истечению этого периода Беттор и Букмейкер могут вернуть свои ставки    
    uint64 public currBetID = 0;
    address public bonusWallet;
    

    //структура ставкт
    struct BetStruct {
      uint64 betID;
      uint64 eventID; 
      address bettor;
      address bookmaker;
      uint rate; // 1000000000000000000 - это 1
      uint bettorValue;
      uint bookmakerValue;
      //uint bettorTakeRewardsPeriod; // период, в течении которого Беттор может забрать выигрыш
      //uint bookmakerTakeRewardsPeriod; // период, в течении которого Букмэйкер может забрать выигрыш
      uint takeRewardsPeriod;
      bool isSet;
      bool isPaid;
    }
    
    // База данных ID - ставка 
    mapping (uint64 => BetStruct) public betsDatabase;
    mapping (address => bool) public bookmakerWhiteList;
    
    
    // события
    event createBetLog(uint64 _eventID, uint _rate, uint _value, uint betID, address _bettor  );
    event createOfferLog(uint64 _eventID, uint _rate, uint _value, uint betID, address _bookmaker  );

    event acceptBetLog(uint64 _eventID, uint _betID, address _bookmaker  );
    event acceptOfferLog(uint64 _eventID, uint _betID, address _bettor  );

    //Модификатор проверяющий, является ли вызвавший метод владельцем контракта или менеджером
    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager));
        _;
    }


  constructor(address initAddr) public {
    //инициализируем контракт со списком событий
    eventsDatabase = EventsDatabase(0x2f38374fB61E135e684A8e9BCe3c4A37C3CfeA72);//initAddr);
    //eventsDatabase = EventsDatabase(initAddr);
    bonusWallet = msg.sender;
    bookmakerWhiteList[msg.sender] = true;
    manager = msg.sender;
  }
  
  
  function createBet(uint64 _eventID, uint _rate ) public payable {
      
      EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(_eventID);
      
       // проверяем - правильно ли указано значение _rate
        if(_rate<=100){
            revert("Rate incorrect");
        }  
      
       // проверяем - есть ли такое событие
        if(!eventStruct.isSet){
            revert("Event not found");
        }
        
        //проверяем - не прошло ли время наступления события
        if(eventStruct.eventDate <= now){
            revert("The event has already occurred");
        }
        
        //проверяем - удовлетворяет ли присланная сумма условиям минимальной и максимальной ставки
        if( (msg.value < eventStruct.minBet)||(msg.value > eventStruct.maxBet) ){
            revert("Amount beyond acceptable limits");
        }
        
        currBetID++;
        
        BetStruct memory betStruct = BetStruct({ 
               betID:currBetID,
               eventID: _eventID, 
               bettor: msg.sender,
               bookmaker: 0,
               rate: _rate,  
               bettorValue: msg.value,
               bookmakerValue: msg.value.mul(_rate).div(100).sub(msg.value) , 
               //bettorTakeRewardsPeriod: bettorTakeRewardsPeriod, // период, в течении которого Беттор может забрать выигрыш
               //bookmakerTakeRewardsPeriod: bookmakerTakeRewardsPeriod, // период, в течении которого Букмэйкер может забрать выигрыш
               takeRewardsPeriod: takeRewardsPeriod,
               isSet: true,
               isPaid: false
        });
        
        betsDatabase[currBetID] = betStruct;
      
        emit createBetLog( _eventID, _rate, msg.value, currBetID, msg.sender);
  }
  
    function createOffer(uint64 _eventID, uint _rate ) public payable {
        //проверка на наличие bookmaker-а в белом списке
        if(!bookmakerWhiteList[msg.sender]){
            revert("You are not in whitelist");
        }
        
       // проверяем - правильно ли указано значение _rate
        if(_rate<=100){
            revert("Rate incorrect");
        }        
      
      EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(_eventID);
      uint bettorValue = msg.value.mul(100).div(_rate.sub(100));
      
       // проверяем - есть ли такое событие
        if(!eventStruct.isSet){
            revert("Event not found");
        }
        
        //проверяем - не прошло ли время наступления события
        if(eventStruct.eventDate <= now){
            revert("The event has already occurred");
        }
        
        //проверяем - удовлетворяет ли присланная сумма условиям минимальной и максимальной ставки
        if( (bettorValue < eventStruct.minBet)||(bettorValue > eventStruct.maxBet) ){
            revert("Amount beyond acceptable limits");
        }
        
        currBetID++;
        
        BetStruct memory betStruct = BetStruct({ 
               betID:currBetID,
               eventID: _eventID, 
               bettor: 0,
               bookmaker: msg.sender,
               rate: _rate,  
               bettorValue: bettorValue,
               bookmakerValue: msg.value, 
               //bettorTakeRewardsPeriod: bettorTakeRewardsPeriod, // период, в течении которого Беттор может забрать выигрыш
               //bookmakerTakeRewardsPeriod: bookmakerTakeRewardsPeriod, // период, в течении которого Букмэйкер может забрать выигрыш
               takeRewardsPeriod: takeRewardsPeriod,
               isSet: true,
               isPaid: false
        });
        
        betsDatabase[currBetID] = betStruct;
      
        emit createOfferLog( _eventID, _rate, msg.value, currBetID, msg.sender);
  }   
  
  
  function acceptBet(uint64 _betID ) public payable {

    //проверка на наличие bookmaker-а в белом списке
    if(!bookmakerWhiteList[msg.sender]){
        revert("You are not in whitelist");
    }
    
    
    BetStruct memory betStruct = betsDatabase[_betID];
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert("Bet not found");
    }
    
    //проверяем - не приняли ли ее раньше
    if(betStruct.bookmaker!=0){
        revert("The bet has already been accepted");
    }
    
    //проверяем - не прошло ли время наступления события
    if(eventStruct.eventDate <= now){
        revert("The event has already occurred");
    }
    
    //проверяем - достаточно ли средств переведено
    if(msg.value < betStruct.bookmakerValue){
        revert("Insufficient funds");
    }
    
    //возвращаем сдачу 
    msg.sender.transfer(msg.value.sub(betStruct.bookmakerValue));
     
    betStruct.bookmaker =  msg.sender;
    
    betsDatabase[_betID] = betStruct;
    
    emit acceptBetLog(eventStruct.eventID, _betID, msg.sender);
      
  }
  
  function acceptOffer(uint64 _betID ) public payable {

    BetStruct memory betStruct = betsDatabase[_betID];
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert("Bet not found");
    }
    
    //проверяем - не приняли ли ее раньше
    if(betStruct.bettor!=0){
        revert("The bet has already been accepted");
    }
    
    //проверяем - не прошло ли время наступления события
    if(eventStruct.eventDate <= now){
        revert("The event has already occurred");
    }
    
    //проверяем - достаточно ли средств переведено
    if(msg.value < betStruct.bettorValue){
        revert("Insufficient funds");
    }
    
    //возвращаем сдачу 
    msg.sender.transfer(msg.value.sub(betStruct.bettorValue));
     
    betStruct.bettor =  msg.sender;
    
    betsDatabase[_betID] = betStruct;
    
    emit acceptOfferLog(eventStruct.eventID, _betID, msg.sender);
      
  }
  
  
  function getReward(uint64 _betID ) public  {
      
    BetStruct memory betStruct = betsDatabase[_betID];
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert("Bet not found");
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert("The event has not yet come");
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert("The payment has already been made");
    }
    
    //проверяем - была ли принята ставка
    if(betStruct.bookmaker==0){
        revert("The bet was not accepted. Call the function returnBet()");
    }
    
    //проверяем - был ли выставлен результат события
    if(eventStruct.result==2){
        revert("The result of the event is not set");
    }
    
    betStruct.isPaid = true;
    betsDatabase[_betID] = betStruct;
    
    
    // если прошло время на получение выигрыша - то эфир отправляется владельцу контракта
    if(now > (eventStruct.resultSetTime.add(betStruct.takeRewardsPeriod))){
        
        owner.transfer(betStruct.bettorValue.add(betStruct.bookmakerValue));
    } else{
        //считаем бонус владельца контракта
        uint bonus = (betStruct.bettorValue.add(betStruct.bookmakerValue)).mul(eventStruct.percent).div(100);
        owner.transfer(bonus);
        
        if (eventStruct.result==1){
            betStruct.bettor.transfer(betStruct.bettorValue.add(betStruct.bookmakerValue).sub(bonus));
        } else if (eventStruct.result==0){
            betStruct.bookmaker.transfer(betStruct.bettorValue.add(betStruct.bookmakerValue).sub(bonus));
        } else {
            revert("Something went wrong");    
        }
        
    }
    
      
  }
  
  
 /** 
  * Возврат ставок для случаев - когда ставка или оффер не были приняты
  * а так же для случая, когда результат события не был выставлен за отведенное
  * в переменной returnBetsAfterPeriod время.
 */
 function returnBetAndOffer(uint64 _betID ) public  {
    
    BetStruct memory betStruct = betsDatabase[_betID];
    
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert("Bet not found");
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert("The event has not yet come");
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert("The payment has already been made");
    }
    
    //Если ставка не была принята или результат события не был выставлен за указанный период - возвращаем средства
    if(betStruct.bookmaker==0 || betStruct.bettor==0 || (now > eventStruct.eventDate.add(returnBetsAfterPeriod) && eventStruct.result==2) ){
        betStruct.isPaid = true;
        betsDatabase[_betID] = betStruct;
        if(betStruct.bettor!=0)
            betStruct.bettor.transfer(betStruct.bettorValue);
        if(betStruct.bookmaker!=0)    
            betStruct.bookmaker.transfer(betStruct.bookmakerValue);  
    } else{
        revert("The bet was accepted");
    }
 }  
  
 function returnBet(uint64 _betID ) public  {
    BetStruct memory betStruct = betsDatabase[_betID];
    //проверяем - есть ли такая ставка 
    if(!betStruct.isSet){
        revert("Bet not found");
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert("The event has not yet come");
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert("The payment has already been made");
    }
    
    // проверяем - не была ли принята ставка букмейкером
    if(betStruct.bookmaker!=0){
        revert("The bet was accepted");
    }
    
    betStruct.isPaid = true;
    betsDatabase[_betID] = betStruct;
    betStruct.bettor.transfer(betStruct.bettorValue);
     
     
 }
 
  function returnOffer(uint64 _betID ) public  {
    BetStruct memory betStruct = betsDatabase[_betID];
    //проверяем - есть ли такой оффер 
    if(!betStruct.isSet){
        revert("Offer not found");
    }
    
    EventStruct memory eventStruct = eventsDatabase.readEventFromDatabase(betStruct.eventID);
    
    //проверяем - настало ли событие
    if(now < eventStruct.eventDate ){
        revert("The event has not yet come");
    }
    
    // проверяем - не было ли выплаты ранее 
    if(betStruct.isPaid){
        revert("The payment has already been made");
    }
    
    // проверяем - не была ли принята ставка букмейкером
    if(betStruct.bettor!=0){
        revert("The offer was accepted");
    }
    
    betStruct.isPaid = true;
    betsDatabase[_betID] = betStruct;
    betStruct.bookmaker.transfer(betStruct.bookmakerValue);
 }
 
 
 function setTakeRewardsPeriod(uint _takeRewardsPeriod) public onlyOwner {
    takeRewardsPeriod = _takeRewardsPeriod;
 }
    
 function setBonusWallet(address _bonusWallet) public onlyOwner {
    bonusWallet = _bonusWallet;
 }  
 
 function addInWhiteList(address _bookmaker) public onlyOwnerOrManager {
    bookmakerWhiteList[_bookmaker] = true;
 }   
 
 function removeInWhiteList(address _bookmaker) public onlyOwnerOrManager {
    bookmakerWhiteList[_bookmaker] = false;
 }  

    //Смена менеджера. Может быть вызвана только владельцем
 function setManager(address _manager) public onlyOwner {
    manager = _manager;
 }

}