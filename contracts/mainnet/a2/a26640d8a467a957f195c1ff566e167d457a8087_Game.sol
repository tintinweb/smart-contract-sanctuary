pragma solidity ^0.4.18;

contract ownerOnly {
    
    function ownerOnly() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Game is ownerOnly {
    
    //Уникальный код коровы
    uint cow_code;
    
    struct cows {
        uint cow;
        uint date_buy;
        bool cow_live;
        uint milk;
        uint date_milk;
    } 
    
    //Маппинг количество коров у пользователя
    mapping (address => uint) users_cows;
    //Маппинг коровы у пользователя
    mapping (bytes32 => cows) user;
    //Маппинг телеги
    mapping (address => bool) telega;
    //Адрес кошелька rico
    address rico;
    
    //сколько корова дает молока за одну дойку
    uint volume_milk;
    //сколько нужно времени между доениями
    uint time_to_milk;
    //времмя жизни коровы
    uint time_to_live;   
        
    //сколько стоит молоко в веях в розницу
    uint milkcost;
    
    //инициируем переменные движка
    function Game() public {
        
        //устанавливаем кошелек движка для управления
    	rico = 0xb5F60D78F15b73DC2D2083571d0EEa70d35b9D28;
    	
    	//Устанавливаем счетчик коров
    	cow_code = 0;
    	
        //сколько литров дает корова на 5 минут
        volume_milk = 1;
        //через сколько секунд можно доить корову
        time_to_milk = 60;
        //сколько секунд живет корова - 30 мин
        time_to_live = 600;  
        
        //Сколько стоит продать молоко в розницу
        milkcost = 0.0013 ether;
    }
    
    function pay() public payable {
        payCow();
    }        
    
    //покупаем коров только от движка
    function payCow() private {
       
        uint time= now;
        uint cows_count = users_cows[msg.sender];
        
        uint index = msg.value/0.01 ether;
        
        for (uint i = 1; i <= index; i++) {
            
            cow_code++;
            cows_count++;
            user[keccak256(msg.sender) & keccak256(i)]=cows(cow_code,time,true,0,time);
        }
        users_cows[msg.sender] = cows_count;
        rico.transfer(0.001 ether);
    }    
    
    //доим корову
    function MilkCow(address gamer) private {
       
        uint time= now;
        uint time_milk;
        
        for (uint i=1; i<=users_cows[gamer]; i++) {
            
            //если корова пока жива тогда доим
            if (user[keccak256(gamer) & keccak256(i)].cow_live==true) {
                
                //получаем время смерти коровы
                uint datedeadcow=user[keccak256(gamer) & keccak256(i)].date_buy+time_to_live;
               
                //если время смерти коровы уже наступило
                if (time>=datedeadcow) {
                    
                    //получаем сколько доек мы пропустили
                    time_milk=(time-user[keccak256(gamer) & keccak256(i)].date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        //кидаем на склад молоко которое мы надоили за пропущенные дойки
                        user[keccak256(gamer) & keccak256(i)].milk+=(volume_milk*time_milk);
                        //убиваем корову
                        user[keccak256(gamer) & keccak256(i)].cow_live=false;
                        //устанавливаем последнее время доения
                        user[keccak256(gamer) & keccak256(i)].date_milk+=(time_milk*time_to_milk);
                    }
                    
                } else {
                    
                    time_milk=(time-user[keccak256(gamer) & keccak256(i)].date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        user[keccak256(gamer) & keccak256(i)].milk+=(volume_milk*time_milk);
                        user[keccak256(gamer) & keccak256(i)].date_milk+=(time_milk*time_to_milk);
                    }
                }
            }
        }
    }    
  
    //продаем молоко, если указано 0 тогда все молоко, иначе сколько сколько указано
    function saleMilk() public {
        
        //сколько будем продовать молока
        uint milk_to_sale;
        
        //отгрузка молока возможно только при наличии телеги у фермера
        if (telega[msg.sender]==true) {
            
            MilkCow(msg.sender);
            
            //Получаем количество коров у пользователя
            uint cows_count = users_cows[msg.sender];            
        
            //обнуляем все молоко на продажу
            milk_to_sale=0;

            for (uint i=1; i<=cows_count; i++) {

                milk_to_sale += user[keccak256(msg.sender) & keccak256(i)].milk;
                //удаляем из анкеты все молоко
                user[keccak256(msg.sender) & keccak256(i)].milk = 0;
            }
            //отсылаем эфир за купленное молоко
            uint a=milkcost*milk_to_sale;
            msg.sender.transfer(milkcost*milk_to_sale);
        }            
    }
            
    //продаем корову от фермера фермеру, историю передачи всегда можно узнать из чтения бд
    function TransferCow(address gamer, uint num_cow) public {
        
        //продавать разрешается только живую корову
        if (user[keccak256(msg.sender) & keccak256(num_cow)].cow_live == true) {
            
            //получаем количество коров у покупателя
            uint cows_count = users_cows[gamer];
            
            //создаем и заполняем анкету коровы для нового фермера, при этом молоко не передается
            user[keccak256(gamer) & keccak256(cows_count)]=cows(user[keccak256(msg.sender) & keccak256(num_cow)].cow,
            user[keccak256(msg.sender) & keccak256(num_cow)].date_buy,
            user[keccak256(msg.sender) & keccak256(num_cow)].cow_live,0,now);
            
            //убиваем корову и прошлого фермера
            user[keccak256(msg.sender) & keccak256(num_cow)].cow_live= false;
            
            users_cows[gamer] ++;
        }
    }
    
    //убиваем корову принудительно из движка
    function DeadCow(address gamer, uint num_cow) public onlyOwner {
       
        //обновляем анкету коровы
        user[keccak256(gamer) & keccak256(num_cow)].cow_live = false;
    }  
    
    //Послать телегу фермеру
    function TelegaSend(address gamer) public onlyOwner {
       
        //Послать телегу
        telega[gamer] = true;
       
    }  
    
    //Вернуть деньги
    function SendOwner() public onlyOwner {
        msg.sender.transfer(this.balance);
    }      
    
    //Послать телегу фермеру
    function TelegaOut(address gamer) public onlyOwner {
       
        //Послать телегу
        telega[gamer] = false;
       
    }  
    
    //Вывести сколько коров у фермера
    function CountCow(address gamer) public view returns (uint) {
        return users_cows[gamer];   
    }

    //Вывести сколько коров у фермера
    function StatusCow(address gamer, uint num_cow) public view returns (uint,uint,bool,uint,uint) {
        return (user[keccak256(gamer) & keccak256(num_cow)].cow,
        user[keccak256(gamer) & keccak256(num_cow)].date_buy,
        user[keccak256(gamer) & keccak256(num_cow)].cow_live,
        user[keccak256(gamer) & keccak256(num_cow)].milk,
        user[keccak256(gamer) & keccak256(num_cow)].date_milk);   
    }
    
    //Вывести наличие телеги у фермера
    function Statustelega(address gamer) public view returns (bool) {
        return telega[gamer];   
    }    
    
}