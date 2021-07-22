pragma solidity ^0.5.16;
import"./OricaToken.sol";

contract TestOricaToken is OricaToken{
    
    uint public start_presale_stage;
    uint public stop_presale_stage;
    uint public stop_team_stage;
    
    constructor() public{
        start_presale_stage = now + 2 minutes;
        stop_presale_stage = now + 10 minutes;
        stop_team_stage = now + 5 minutes;
        deadline_for_whitelist = start_presale_stage + 2 minutes;
    }
    
    function addMoneyPresale(address recipient, uint amount) public onlyAdminPresale checkTimestamp returns(bool){
        require(amount > 0, "Amount must be non zero.");

        // аварийное отключение продажи токенов
        require(extra_condition, "The sale was forcibly terminated");

        // покупка недоступна до Sat Aug 14 2021 00:00:00 GMT+0 
        require(now >= start_presale_stage, "The purchase of a token for the Presale stage is not available. Too early.");

        // покупка невозможна после Wed Sep 01 2021 00:00:00 GMT+0
        require(now < stop_presale_stage, "The purchase of a token for the Presale stage is not available. Too late.");

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
    
    function openNextPresaleStage(uint increase_percentage) public onlyAdminPresale checkTimestamp returns(bool){
        // Right time is September 1, 2021
        require(now >= stop_presale_stage, "Not available for spending. It's too early.");
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
    
    function extendWhitelistDeadline(uint extended_seconds) public onlyAdminPresale checkTimestamp returns(bool){
        require(deadline_for_whitelist != stop_presale_stage, "Re-launching the whitelist is not available");
        // new_deadline must be less than 2 weeks from the start 
        // 14 Aug (Start Presale) + new_deadline <= 28 Aug GMT+0 
        require(deadline_for_whitelist + extended_seconds <= stop_presale_stage - 5 minutes, "The maximum period will be exceeded");
        deadline_for_whitelist += extended_seconds;
        return true;
    }
    
    function allowForAll() public onlyAdminPresale checkTimestamp returns(bool){
        // сбросить дедлайн в Sat Aug 14 2021 00:00:00 GMT+0
        deadline_for_whitelist = start_presale_stage;
        return true;
    }
    
    function addMoneyTeam(address recipient, uint amount) public onlyAdminTeam checkTimestamp returns(bool){
        // Sep 1 2022 GMT0  
        require(now < stop_team_stage, "Too late to add money for the team.");
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
    
    function openNextTeamStage(uint increase_percentage) public onlyAdminTeam checkTimestamp returns(bool){
        // токены недоступны до Sep 1 2022 00:00:00 GMT+0
        require(now >= stop_team_stage, "Not available for spending. It's too early.");
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
    
    function unlockPresaleTokens() public checkTimestamp {
        require(presale_group[msg.sender].all_token > 0, "You have no presale tokens");
        require(now >= stop_presale_stage, "Too early");
        uint new_percent;
        if (now >= stop_presale_stage){
            new_percent += 10;
        }
        if (now >= stop_presale_stage + 30 seconds){
            new_percent += 15;
        }
        if (now >= stop_presale_stage + 60 seconds){
            new_percent += 15;
        }
        if (now >= stop_presale_stage + 90 seconds){
            new_percent += 15;
        } 
        if (now >= stop_presale_stage + 120 seconds){
            new_percent += 15;
        }
        if (now >= stop_presale_stage + 150 seconds){
            new_percent += 15;
        }
        if (now >= stop_presale_stage + 180 seconds){
            new_percent += 15;
        }

        int256 new_token = int256(presale_group[msg.sender].all_token * new_percent / 100 - presale_group[msg.sender].free_token);
        require(new_token > 0, "You have already received your tokens");
        presale_group[msg.sender].free_token += uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }

    function unlockTeamTokens() public checkTimestamp {
        require(team_group[msg.sender].all_token > 0, "You have no presale tokens");
        require(now >= stop_team_stage, "Too early");
        uint new_percent;
        if (now >= stop_team_stage){
            new_percent += 10;
        }
        if (now >= stop_team_stage + 30 seconds){
            new_percent += 15;
        }
        if (now >= stop_team_stage + 60 seconds){
            new_percent += 15;
        }
        if (now >= stop_team_stage + 90 seconds){
            new_percent += 15;
        }
        if (now >= stop_team_stage + 120 seconds){
            new_percent += 15;
        }
        if (now >= stop_team_stage + 150 seconds){
            new_percent += 15;
        }
        if (now >= stop_team_stage + 180 seconds){
            new_percent += 15;
        }

        int256 new_token = int256(team_group[msg.sender].all_token * new_percent / 100 - team_group[msg.sender].free_token);
        require(new_token > 0, "You have already received your tokens");
        team_group[msg.sender].free_token += uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }
    
    function balanceOf(address account) public view returns (uint){
        return seed_group[msg.sender] + presale_group[account].all_token + team_group[account].all_token + advisors_group[msg.sender];
    }
    
    function setStartPresaleStage(uint new_date) public{
        start_presale_stage = new_date;
    }
    
    function setStopPresaleStage(uint new_date) public{
        stop_presale_stage = new_date;
    }
    
    function setStartTeamStage(uint new_date) public{
        stop_team_stage = new_date;
    }
}