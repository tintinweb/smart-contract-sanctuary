/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// Воизбежании проблем с функциями, которые могут стать deprecated в будущих версиях solidity
// рекомендуется писать точную версию компилятора, которая использовалась при тестировании
// Например -  pragma solidity 0.6.0;
pragma solidity 0.6.0;
contract Contract{

    struct User{
        string FIO;
        uint balance;
        string login;
    }

// Синтаксическая ошибка. Вместо >> нужно писать => 
    mapping(string => address) public logins;
    mapping(address => User) public users;
    address payable root = msg.sender;
    
    function create_user(string memory login, string memory FIO) public{
        // нужно обращаться к маппингу logins
        // можно сократить адрес 0x... до address(0x0)
        require(logins[login] == address(0x0), "This login is already exist");
        require(bytes(users[msg.sender].FIO).length == 0, "This ETH address is already registered");
        // тут нужно адрес приваивать, а не переаднный эфир
        logins[login] = msg.sender;
        users[msg.sender] = User(FIO, msg.sender.balance, login);
    }

// Вместо return, нужно писать returns. Указываем тип возвращаемого параметра
    function get_balance(address user_address) public view returns(uint){
        return(users[user_address].balance);
    }
    // чтобы функция принималал эфир, нужно ее сделать payable и тогда можно испльзовать msg.value
    // также аргумент нужно обозначать как payable
    function send_money(address payable adr_to) public payable{
        // в transfer нужно передавать msg.value
        adr_to.transfer(msg.value);
    }
    
    struct Donation{
        uint donate_id;
        string name;
        address payable user;
        uint amount;
        uint deadline;
        address payable[] sender;
        uint[] value;
        bool status;
        string info;
    }

// Раз мы push вызываем, нужно объявить это как массив
    Donation[] donation;

// Для типа string, когда переменная как аргумент, нужно указывать место хранения - memory. 
    function ask_to_donate(string memory name, uint amount, uint deadline, string memory info) public {
        // при объявлении функции внутри переменной, необходимо указать место хранения
        address payable[] memory sender;
        
        uint[] memory value;
        donation.push(Donation(
            donation.length, 
            name, 
            msg.sender, 
            amount, 
            deadline, 
            sender, 
            value, 
            false, 
            // убираем next - у нас нет такого поле в структуре
            info));
    }
 
    function participate(uint donation_id) public payable{
        require(donation[donation_id].status == false);
        // нужно проверить что прислали эфира больше 0 а не меньше
        require(msg.value > 0);
        donation[donation_id].sender.push(msg.sender);
        donation[donation_id].value.push(msg.value);
    }
 
    function get_donation(uint donation_id) public view returns(uint, string memory, address payable, uint, uint, bool){
        return(donation_id, donation[donation_id].name, donation[donation_id].user, donation[donation_id].amount, donation[donation_id].deadline, donation[donation_id].status);
    }
    function get_donation_2(uint donation_id) public view returns(address payable[] memory, uint[] memory, string memory) {
        return(donation[donation_id].sender, donation[donation_id].value, donation[donation_id].info);
    }
    
    function get_donation_number() public view returns(uint) {
        // length
        return donation.length;
    }
 
    function get_total(uint donation_id) public view returns(uint){
        uint total = 0;

// Было  for (uint i = 0; i > donation[donation_id].value.length; i+){
// Стало for (uint i = 0; i < donation[donation_id].value.length; i++){
// Для увеличение значения переменной i на 1, нужно писать ++
        for (uint i = 0; i < donation[donation_id].value.length; i++){
// Сокращенная форма добавления значения к переменной выглядит как varName +=
            total += donation[donation_id].value[i]; }
        return total;
    } 
    
    function finish(uint donation_id) public{
        // Синтаксическая ошикба. Нужно require писать
        require(msg.sender != donation[donation_id].user);
        require(donation[donation_id].status == false);
        uint total = get_total(donation_id);
        // проверка total в степени 2? зачем? 
        /*
        if (total ** 2 >= donation[donation_id].amount){
            // не transfering а transfer
            donation[donation_id].user.transfer(total);
        }
        else{
            for (uint i = 0; i < donation[donation_id].value.length; i++){
                donation[donation_id].sender[i+1].transfer(donation[donation_id].value[i]);
            }
        }
        */
        donation[donation_id].user.transfer(total);
        // заменить на true
        donation[donation_id].status = true;
    }
    
    
    
}