pragma solidity ^0.4.25;

// donation: 0xc2bf86970a677C018bD246ad9a30E0Fe258dEee0

contract GorgonaKiller {
    // адрес горгоны
    address public GorgonaAddr; 
    
    // минимальный депозит
    uint constant public MIN_DEP = 0.01 ether; 
    
    // максимальное число транзакций при выплате дивидендов
    uint constant public TRANSACTION_LIMIT = 2;
    
    // баланс дивидендов
    uint public dividends;
    
    // id последнего инвестора, которому прошла оплата
    uint public last_payed_id;
    
    // общая сумма депозитов от инвесторов
    uint public deposits; 
    
    // адреса инвесторов
    address[] public addresses;

    // мапинг адрес инвестора - структура инвестора
    mapping(address => Investor) public members;
    
    // id адреса в addresses, deposit - сумма депозитов
    struct Investor {
        uint id;
        uint deposit;
    }
    
    constructor() public {
        GorgonaAddr = 0x32686424Ad115dDA92AED81a9775172e93C9d76A; 
    }

    // обработка поступлений
    function () external payable {

        // если пришло с горгоны выходим
        if (msg.sender == GorgonaAddr) {
            return;
        }
        
        // если баланс без текущего поступления > 0 и не начинали выплаты, пишем в дивиденды
        if ( last_payed_id == 0 && address(this).balance - msg.value > 0 ) {
            dividends = address(this).balance - msg.value;
        }
        
        // выплачиваем дивиденды
        if ( dividends > 0 ) {
            payDividends();
        }
        
        // инвестируем текущее поступление
        if (msg.value >= MIN_DEP) {
            Investor storage investor = members[msg.sender];

            // добавляем инвестора, если еще нет
            if (investor.id == 0) {
                investor.id = addresses.push(msg.sender);
            }
            
            // отправляем в горгону
            payToGorgona();
            
            // пополняем депозит инвестора и общий депозит
            investor.deposit += msg.value;
            deposits += msg.value;

        }
        
    }

    // отправляем текущее поступление в горгону
    function payToGorgona() private {
        if ( ! GorgonaAddr.call.value( msg.value )() ) {
            revert();
        }
    }

    // выплата дивидендов
    function payDividends() private {
        address[] memory _addresses = addresses;
        
        uint _dividends = dividends;

        if ( _dividends > 0) {
            uint num_payed = 0;
            
            for (uint i = last_payed_id; i < _addresses.length; i++) {
                
                // считаем для каждого инвестора долю дивидендов
                uint amount = _dividends * members[ _addresses[i] ].deposit / deposits;
                
                // отправляем дивиденды
                if ( _addresses[i].send( amount ) ) {
                    last_payed_id = i+1;
                    num_payed += 1;
                }
                
                // если достигли лимита выплат выходим из цикла
                if ( num_payed == TRANSACTION_LIMIT ) break;
                
            }
            
            // обнуляем id последней выплаты, если выплатили всем
            if ( last_payed_id >= _addresses.length) {
                last_payed_id = 0;
                dividends = 0;
            }
            
        }
        
    }
    
    // смотрим баланс на контракте
    function getBalance() public view returns(uint) {
        return address(this).balance / 10 ** 18;
    }

    // смотрим число инвесторов
    function getInvestorsCount() public view returns(uint) {
        return addresses.length;
    }

}