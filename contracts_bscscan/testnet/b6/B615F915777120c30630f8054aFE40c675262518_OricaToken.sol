pragma solidity ^0.5.16;
import "./BEP20Token.sol";

contract OricaToken is BEP20Token{

    // Здесь нет комментария
    mapping (address => bool) public whitelist;

    /*
        1 - Owner
        2 - SuperAdmin
        3 - Admin Seed
        4 - Admin Presale
        5 - Admin Team
        6 - Admin Advisors
        7 - Pool - only admin presale
    */
    mapping (address => uint) public roles;

    // аварийная кнопка
    bool public extra_condition;

    // история кому сколько в сид фазе зачислено, не меняется
    mapping (address => uint) public seed_group;
    uint public seed_amount;

    // список купивших в пресейле и их доступный баланс в фазе
    mapping (address => frozen_token) public presale_group;
    // uint public presale_amount;

    // список купивших в тиме и их доступный баланс в фазе
    mapping (address => frozen_token) public team_group;
    uint public team_amount;

    // баланс партнеров и выделенная сумма из Total_supply под них
    mapping (address => uint) public advisors_group;
    uint public advisors_amount;

    // списки пользователей, купившие в фазы
    address[] seed_users;
    address[] presale_users;
    address[] team_users;
    address[] advisor_users;

    // Стадии распределения токенов (Seed, Presale, Team, Advisers)

    struct frozen_token{
        uint all_token;
        uint free_token;    // -> all_token
    }

    // Сколько процентов разблокировано для группы Presale
    uint public allowed_presale;

    // Сколько процентов разблокировано для группы Team
    uint public allowed_team;

    uint public deadline_for_whitelist;

    uint constant private Aug142021 = 1628899200;
    uint constant private Aug282021 = 1630108800;
    uint constant private Sep12021 = 1630454400;
    uint constant private Oct12021 = 1633046400;
    uint constant private Nov12021 = 1635724800;
    uint constant private Dec12021 = 1638316800;
    uint constant private Jan12022 = 1640995200;
    uint constant private Feb12022 = 1643673600;
    uint constant private Mar12022 = 1646092800;
    uint constant private Sep12022 = 1661990400;
    uint constant private Oct12022 = 1664582400;
    uint constant private Nov12022 = 1667260800;
    uint constant private Dec12022 = 1669852800;
    uint constant private Jan12023 = 1672531200;
    uint constant private Feb12023 = 1675209600;
    uint constant private Mar12023 = 1677628800;

    // Запоминает время прошлой транзакции (блока)
    uint private _timetamp_last_block;

    // Проверяет время проведения транзакции на подлинность
    // Новая транзакция не может быть проведена раньше предыдущей
    modifier checkTimestamp(){
        require(_timetamp_last_block < now, "Invalid block timestamp");
        _timetamp_last_block = now;
        _;
    }

    modifier onlySuperAdmin(){
        require(roles[msg.sender] == 2 || roles[msg.sender] == 1, "You are not SuperAdmin");
        _;
    }

    modifier onlyAdminSeed(){
        require(roles[msg.sender] == 3 || roles[msg.sender] == 2 || roles[msg.sender] == 1, "You are not Seed Admin");
        _;
    }

    modifier onlyAdminPresale(){
        require(_isAdminPresale(msg.sender), "You are not Presale Admin");
        _;
    }

    modifier onlyAdminTeam(){
        require(roles[msg.sender] == 5 || roles[msg.sender] == 2 || roles[msg.sender] == 1, "You are not Team Admin");
        _;
    }

    modifier onlyAdminAdvisors(){
        require(roles[msg.sender] == 6 || roles[msg.sender] == 2 || roles[msg.sender] == 1, "You are not Advisors Admin");
        _;
    }
    
    uint public start_presale_date;
    uint public end_presale_date;
    
    constructor() public{
        // Total_supply для Seed стадии
        seed_amount = 500000000000000000000000;

        // Total_supply для Presale стадии
        //presale_amount = 15000000;

        // Total_supply для Team группы
        team_amount = 15000000000000000000000000;

        // Total_supply для Advisors группы
        advisors_amount = 10000000000000000000000000;

        // Sun Aug 15 2021 00:00:00 GMT+0
        deadline_for_whitelist = start_presale_date + 2 minutes;

        _timetamp_last_block = now;

        roles[msg.sender] = 1;
        
        start_presale_date = now + 2 minutes;
        end_presale_date = start_presale_date + 10 minutes;
        
    }

    function _isAdminPresale(address addr) internal view returns (bool) {
        return roles[addr] == 4 || roles[addr] == 2 || roles[addr] == 1 || roles[addr] == 7;
    }

    // Возвращает пользователей Seed стадии -> address array
    function getSeedUsers() public view returns(address[] memory){
        return seed_users;
    }

    // Возвращает пользователей Presale стадии -> address array
    function getPresaleUsers() public view returns(address[] memory){
        return presale_users;
    }

    // Возвращает пользователей Team группы -> address array
    function getTeamUsers() public view returns(address[] memory){
        return team_users;
    }

    // Возвращает пользователей Advisors группы -> address array
    function getAdvisorsUsers() public view returns(address[] memory){
        return advisor_users;
    }

    // Раздать деньги в Seed этапе
    function addMoneySeed(address recipient, uint amount) public onlyAdminSeed checkTimestamp returns(bool){
        require(amount > 0, "Amount must be non zero.");
        require(amount <= seed_amount, "Exceeding the available number of tokens");

        bool already_user;
        for (uint32 i = 0; i < seed_users.length; i++){
            if (seed_users[i] == recipient){
                already_user = true;
                break;
            }
        }

        if (already_user == true){
            seed_users.push(recipient);
        }


        seed_users.push(recipient);
        super._transfer(owner(), recipient, amount);
        seed_group[recipient] += amount;
        seed_amount -= amount; // Уменьшили общее количество доступных токенов для Seed

        return true;
    }

    // продажа токенов на стадии presale
    function addMoneyPresale(address recipient, uint amount) public onlyAdminPresale checkTimestamp returns(bool){
        require(amount > 0, "Amount must be non zero.");

        // аварийное отключение продажи токенов
        require(extra_condition, "The sale was forcibly terminated");

        // покупка недоступна до Sat Aug 14 2021 00:00:00 GMT+0 
        require(now >= start_presale_date, "The purchase of a token for the Presale stage is not available. Too early.");

        // покупка невозможна после Wed Sep 01 2021 00:00:00 GMT+0
        require(now < end_presale_date, "The purchase of a token for the Presale stage is not available. Too late.");

        // покупка доступна только пользователям из whitelist до момента deadline_for_whitelist
        if (now < deadline_for_whitelist){
            require(whitelist[recipient], "Free presale not yet authorized");
        }

        // добавление пользователя в реестр presale
        bool already_user = false;
        for (uint i = 0; i < presale_users.length; i++){
            if (presale_users[i] == recipient){
                already_user = true;
                break;
            }
        }
        if (already_user == false){
            presale_users.push(recipient);
        }

        // добавления токена на presale счет
        presale_group[recipient].all_token += amount;
        super._transfer(msg.sender, owner(), amount);

        return true;
    }

    // Разрешают трату для presale этапа (каждой из 7 итераций отдельно) (метод может быть один, с необходимыми параметрами)
    // оставляем возможность ввести процент в любой момент времени
    function openNextPresaleStage(uint increase_percentage) public onlyAdminPresale checkTimestamp returns(bool){
        // Right time is September 1, 2021
        require(now >= end_presale_date, "Not available for spending. It's too early.");
        require(allowed_presale + increase_percentage <= 100, "More then 100 percent");
        uint new_percentage = increase_percentage + allowed_presale;
        //25 = 15 + 10
        for (uint i=0; i < presale_users.length; i++) {
            int256 new_token = int256(presale_group[presale_users[i]].all_token * new_percentage / 100 - presale_group[presale_users[i]].free_token);
            //15 = 24 - 9
            if (new_token <= 0){
                continue;
            }
            presale_group[presale_users[i]].free_token += uint(new_token);
            super._transfer(owner(), presale_users[i], uint(new_token));
        }
        allowed_presale += increase_percentage;
        return true;
    }

     // Запускает стадию пресейла
    function startPresale() public onlyAdminPresale checkTimestamp returns(bool) {
        extra_condition = true;
        return true;
    }

    // Останавливает стадию пресейла
    function stopPresale() public onlyAdminPresale checkTimestamp returns(bool) {
        extra_condition = false;
        return true;
    }

    // Добавление адресов для whitelist (желательно пачкой, а не по одному)
    function add_to_whitelist(address[] memory u_addr) public onlyAdminPresale checkTimestamp {
        for (uint i = 0; i < u_addr.length; i++){
            whitelist[u_addr[i]] = true;
        }
    }

    // Удаление адресов для whitelist (желательно пачкой, а не по одному)
    function delFromWhitelist(address[] memory u_addr) public onlyAdminPresale checkTimestamp{
        for (uint i = 0; i < u_addr.length; i++){
            whitelist[u_addr[i]] = false;
        }
    }

    // Продление продажи только для whitelist'а, может вызываться несколько раз, но максимальная дата Fri Aug 27 2021 23:59:59 GMT+03
    function extendWhitelistDeadline(uint extended_seconds) public onlyAdminPresale checkTimestamp returns(bool){
        //require(deadline_for_whitelist != start_presale_date, "Re-launching the whitelist is not available");
        // new_deadline must be less than 2 weeks from the start 
        // 14 Aug (Start Presale) + new_deadline <= 28 Aug GMT+0 
        require(deadline_for_whitelist +  extended_seconds <= end_presale_date - 5 minutes, "The maximum period will be exceeded");
        deadline_for_whitelist += extended_seconds;
        return true;
    }

    // Разрешают продажи для всех
    function allowForAll() public onlyAdminPresale checkTimestamp returns(bool){
        // сбросить дедлайн в Sat Aug 14 2021 00:00:00 GMT+0
        deadline_for_whitelist = start_presale_date;
        return true;
    }

    // раздача токенов для группы Team
    function addMoneyTeam(address recipient, uint amount) public onlyAdminTeam checkTimestamp returns(bool){
        // Sep 1 2022 GMT0  
        require(now < Sep12022, "Too late to add money for the team.");
        require(amount > 0, "Amount must be non zero.");

        // проверить что TeamTokens еще не распроданы
        require(amount <= team_amount, "Exceeding the available number of tokens");

        // добавление пользователя в реестр Team
        bool already_user = false;
        for (uint i = 0; i < team_users.length; i++){
            if (team_users[i] == recipient){
                already_user = true;
                break;
            }
        }
        if (already_user == false){
            team_users.push(recipient);
        }

        // добавления токена на Team счет
        team_amount -= amount;
        team_group[recipient].all_token += amount;

        return true;
    }

    // Разрешают трату для team этапа (каждой из 7 итераций отдельно) (метод может быть один, с необходимыми параметрами)
    // оставляем возможность ввести процент в любой момент времени
    function openNextTeamStage(uint increase_percentage) public onlyAdminTeam checkTimestamp returns(bool){
        // токены недоступны до Sep 1 2022 00:00:00 GMT+0
        require(now >= Sep12022, "Not available for spending. It's too early.");
        require(allowed_team + increase_percentage <= 100, "More then 100 percent");
        uint new_percentage = increase_percentage + allowed_team;
        //25 = 15 + 10
        for (uint i = 0; i < team_users.length; i++) {
            int256 new_token = int256(team_group[team_users[i]].all_token * new_percentage / 100 - team_group[team_users[i]].free_token);
            if (new_token <= 0){
                continue;
            }
            team_group[team_users[i]].free_token += uint(new_token);
            super._transfer(owner(), team_users[i], uint(new_token));
        }
        allowed_team += increase_percentage;
        return true;
    }

    // Вознаграждение партнеров
    function awardAdvisors(address recipient, uint amount) public onlyAdminAdvisors checkTimestamp returns(bool){
        require(amount > 0, "Amount must be non zero.");
        require(advisors_amount >= amount, "Exceeding the available number of tokens");

        advisor_users.push(recipient);
        advisors_amount -= amount;
        advisors_group[recipient] += amount;
        super._transfer(owner(), recipient, amount);
        return true;
    }

    function burn(uint amount) public onlySuperAdmin {
        _burn(msg.sender, amount);
    }

    function unlockPresaleTokens() public checkTimestamp {
        require(presale_group[msg.sender].all_token > 0, "You have no presale tokens");
        require(now >= Sep12021, "Too early");
        uint new_percent;
        if (now >= Sep12021){
            new_percent += 10;
        }
        if (now >= Oct12021){
            new_percent += 15;
        }
        if (now >= Nov12021){
            new_percent += 15;
        }
        if (now >= Dec12021){
            new_percent += 15;
        } 
        if (now >= Jan12022){
            new_percent += 15;
        }
        if (now >= Feb12022){
            new_percent += 15;
        }
        if (now >= Mar12022){
            new_percent += 15;
        }

        int256 new_token = int256(presale_group[msg.sender].all_token * new_percent / 100 - presale_group[msg.sender].free_token);
        require(new_token > 0, "You have already received your tokens");
        presale_group[msg.sender].free_token += uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }

    function unlockTeamTokens() public checkTimestamp {
        require(team_group[msg.sender].all_token > 0, "You have no presale tokens");
        require(now >= Sep12022, "Too early");
        uint new_percent;
        if (now >= Sep12022){
            new_percent += 10;
        }
        if (now >= Oct12022){
            new_percent += 15;
        }
        if (now >= Nov12022){
            new_percent += 15;
        }
        if (now >= Dec12022){
            new_percent += 15;
        }
        if (now >= Jan12023){
            new_percent += 15;
        }
        if (now >= Feb12023){
            new_percent += 15;
        }
        if (now >= Mar12023){
            new_percent += 15;
        }

        int256 new_token = int256(team_group[msg.sender].all_token * new_percent / 100 - team_group[msg.sender].free_token);
        require(new_token > 0, "You have already received your tokens");
        team_group[msg.sender].free_token += uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }

    function setRole(address u_addr, uint role) public onlyOwner{
        roles[u_addr] = role;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        if(roles[sender] == 7 && !_isAdminPresale(recipient)) {
            addMoneyPresale(recipient, amount);
        }
        else {
            super._transfer(sender, recipient, amount);
        }
    }
    
    function balanceOf(address account) public view returns (uint){
        return super.balanceOf(account) + presale_group[account].all_token + team_group[account].all_token;
    }
    
    function setStartPresaleDate(uint new_date) public{
        start_presale_date = new_date;
    }
    
    function setStopPresaleDate(uint new_date) public{
        end_presale_date = new_date;
    }
}