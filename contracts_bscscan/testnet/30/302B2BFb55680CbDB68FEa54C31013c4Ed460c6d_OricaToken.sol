/*
    Developed specially for the Orica Token.
*/
pragma solidity ^0.5.16;
import "./BEP20Token.sol";
import"./IERC721.sol";

contract OricaToken is BEP20Token{

   /*****
    *  Description:
    *  The sale of tokens begins on the specified date (Sat Aug 14 2021 00: 00: 00 GMT+0) only for users
    *  from the whitelist list. To find out whether a user belongs to this list, you need to call this mapping.
    *
    *  Parameters:
    *  user address, type - eth address.
    *
    *  Return values:
    *  bool: true - the user is included in the whitelist
    *       false - the user is not included in the whitelist
    *
    *  Note:
    *  The call does not require spending Gas.
    *****/
    mapping (address => bool) public whitelist;

   /*****
    *  1 - Owner
    *  2 - SuperAdmin
    *  3 - Admin Seed
    *  4 - Admin Presale
    *  5 - Admin Team
    *  6 - Admin Advisors
    *  7 - Pool - only admin presale
    *****/
    mapping (address => uint) public roles;

    bool public is_presale_enable;

    mapping (address => uint) public seed_group;
    uint public seed_amount;

    mapping (address => frozen_tokens) public presale_group;

    mapping (address => frozen_tokens) public team_group;
    uint public team_amount;

    mapping (address => uint) public advisors_group;
    uint public advisors_amount;

   /*****
    *  AUXILIARY
    *  Lists of users who have bought tokens for a particular group
    *****/
    address[] seed_users;
    mapping (address => bool) internal _is_seed_user;
    address[] presale_users;
    mapping (address => bool) internal _is_presale_user;
    address[] team_users;
    mapping (address => bool) internal _is_team_user;
    address[] advisor_users;
    mapping (address => bool) internal _is_advisor_user;

    struct frozen_tokens{
        uint all_tokens;
        uint frozen_tokens;    // -> all_tokens
    }

   /*****
    *  Description:
    *  The percentage of unfrozen tokens to the total number of purchased tokens at this stage.
    *  Shows the total share of unlocked Presale tokens for all users.
    *
    *  Return values:
    *  Percentage of unlocked tokens, type-uint.
    *
    *  Note:
    *  The call does not require spending Gas.
    *****/
    uint public allowed_presale;
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

    uint private _timetamp_last_block;

   /*****
    *  Auxiliary function
    *
    *  Prevents the contract from  overloading at the point in time
    *****/
    modifier checkTimestamp(){
        require(_timetamp_last_block < now, "Invalid block timestamp");
        _timetamp_last_block = now;
        _;
    }

   /*****
    *  Auxiliary modifiers
    *
    *  Description:
    *  Checking the role compliance
    *
    *  Requirement:
    *  Successful for the token owner, the system administrator and the administrator of the specified group
    *****/
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

    modifier nonZeroAmount(uint amount){
        require(amount > 0, "Amount must be non zero.");
        _;
    }
   /*****
    *  Description:
    *  Initializing values
    *
    *  Note:
    *  The contract owner becomes the owner of the tokens.
    *  The starting number of tokens for groups is specified
    *  Specified deadline for the closed sale of tokens in Presale group - Sun Aug 15 2021 00:00:00 GMT+0
    *****/
    constructor() public{
        seed_amount = 5000000000000000000000000;
        team_amount = 15000000000000000000000000;
        advisors_amount = 10000000000000000000000000;

        deadline_for_whitelist = Aug142021 + 1 days;

        _timetamp_last_block = now;

        roles[msg.sender] = 1;
    }

   /*****
    *  Description:
    *  Checking the role compliance
    *
    *  Parameters:
    *  addr – the address of the user, type - eth address
    *
    *  Requirement:
    *  Successful for the token owner, System Administrator, Presale Group Administrator, as well as for the pool
    *
    *  Return values:
    *  true - if the the user has necessary access,
    *  false - if hasn't
    *****/
    function _isAdminPresale(address addr) internal view returns (bool) {
        return roles[addr] == 4 || roles[addr] == 2 || roles[addr] == 1 || roles[addr] == 7;
    }

   /*****
    *  Description:
    *  A list of users of the Seed group.
    *
    *  Return values:
    *  array of addresses - an array of addresses of buyers of the Seed group.
    ******/
    function getSeedUsers() public view returns(address[] memory){
        return seed_users;
    }

   /*****
    *  Description:
    *  List of users who bought tokens during the Presale phase
    *
    *  Return values:
    *  array of addresses - an array of addresses of Presale group buyers.
    *
    *  Note:
    *  The array may contain duplicate values if the tokens were issued to the user several times.
    *  The call does not require spending Gas.
    *****/
    function getPresaleUsers() public view returns(address[] memory){
        return presale_users;
    }

   /*****
    *  Description:
    *  A list of Team Group users.
    *
    *  Return values:
    *  array of addresses - an array of addresses of buyers of the Team group.
    *
    *  Note:
    *  The array may contain duplicate values if the tokens were issued to the user several times. The call does not require spending Gas.
    *****/
    function getTeamUsers() public view returns(address[] memory){
        return team_users;
    }

   /*****
    *  Description:
    *  List of Advisors group users.
    *
    *  Return values:
    *  array of addresses - an array of addresses of the group's Advisors buyers.
    *
    *  Note:
    *  The array may contain duplicate values if the tokens were issued to the user several times.
    *  The call does not require spending Gas.
    *
    *  Return values:
    *  all_token - the total number of tokens purchased, type - uint;
    *  free_token - unfrozen number of tokens, type - uint.
    *
    *  Note:
    *  The call does not require spending Gas.
    *****/
    function getAdvisorsUsers() public view returns(address[] memory){
        return advisor_users;
    }

   /*****
    *  Description:
    *  Issues tokens to the buyer of the Seed group. Tokens are available for spending as soon as the transaction is completed.
    *
    *  Parameters:
    *  recipient - the recipient of the Seed token, type - eth address;
    *  amount - the number of tokens issued, type - uint.
    *
    *  Requirements:
    *  The number of tokens issued is greater than 0;
    *  The number of tokens issued does not exceed the number of available tokens for this group.
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The method can be called again for a specific address, the number of tokens will be added to the one already entered.
    *  The method can only be called by the token owner or the system administrator or the administrator of the Seed group.
    *  When the method is executed, the number of available tokens for issuing will be reduced.
    *****/
    function addMoneySeed(address recipient, uint amount) public onlyAdminSeed checkTimestamp nonZeroAmount(amount) returns(bool){
        require(amount <= seed_amount, "Exceeding the available number of tokens");

        if (!_is_seed_user[recipient]){
            _is_seed_user[recipient] = true;
            seed_users.push(recipient);
        }

        seed_group[recipient] += amount;
        seed_amount -= amount;
        super._transfer(owner(), recipient, amount);

        return true;
    }

   /*****
    *  Description:
    *  Issues tokens to the user and immediately freezes them.
    *
    *  Parameters:
    *  recipient – the address of the token buyer, type - eth address
    *  amount – the number of tokens sold, type-uint
    *
    *  Requirements:
    *  The number of tokens sold must be greater than zero;
    *  The Presale stage is enabled;
    *  The sale is only possible during the period from Sat Aug 14 2021 00:00:00 GMT+0 to Wed Sep 01 2021 00:00:00 GMT+0;
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The Presale tokens of the group are issued by the Pool using the transfer () function. Manually calling this method is only necessary in an emergency.
    *****/
    function addMoneyPresale(address recipient, uint amount) public onlyAdminPresale checkTimestamp nonZeroAmount(amount) returns(bool){
        require(is_presale_enable, "The sale was forcibly terminated");

        require(now >= Aug142021, "The purchase of a token for the Presale stage is not available. Too early.");

        require(now < Sep12021, "The purchase of a token for the Presale stage is not available. Too late.");

        if (now < deadline_for_whitelist){
            require(whitelist[recipient], "Free presale not yet authorized");
        }

        if (!_is_presale_user[recipient]){
            _is_presale_user[recipient] = true;
            presale_users.push(recipient);
        }

        presale_group[recipient].all_tokens += amount;
        presale_group[recipient].frozen_tokens = presale_group[recipient].all_tokens;
        super._transfer(msg.sender, owner(), amount);

        return true;
    }

   /*****
    *  Description:
    *  Opens a new Presale stage, unlocking tokens for all users for a specified percentage.
    *
    *  Parameters:
    *  increase_percentage – the number of defrosted percentages, type - uint
    *
    *  Requirements:
    *  Unblocking takes place starting from September 1, 2021, 00:00 GMT+0.
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The unlocked tokens go to the general user account available for spending.
    *****/
    function openNextPresaleStage(uint increase_percentage) public onlyAdminPresale checkTimestamp returns(bool){
        // Right time is September 1, 2021
        require(now >= Sep12021, "Not available for spending. It's too early.");
        require(allowed_presale + increase_percentage <= 100, "More then 100 percent");
        uint new_percentage = increase_percentage + allowed_presale;
        //25 = 15 + 10
        for (uint i=0; i < presale_users.length; i++) {
            int256 new_token = int256(presale_group[presale_users[i]].all_tokens * new_percentage / 100 - (presale_group[presale_users[i]].all_tokens - presale_group[presale_users[i]].frozen_tokens));
            //15 = 24 - 9
            if (new_token <= 0){
                continue;
            }
            presale_group[presale_users[i]].frozen_tokens -= uint(new_token);
            super._transfer(owner(), presale_users[i], uint(new_token));
        }
        allowed_presale += increase_percentage;
        return true;
    }

   /*****
    *  Description:
    *  Launches the sale of Presale group tokens.
    *
    *  Requirements:
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *****/
    function startPresale() public onlyAdminPresale checkTimestamp returns(bool) {
        is_presale_enable = true;
        return true;
    }

   /*****
    *  Description:
    *  Stops the sale of Presale group tokens .
    *
    *  Requirements:
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *****/
    function stopPresale() public onlyAdminPresale checkTimestamp returns(bool) {
        is_presale_enable = false;
        return true;
    }

   /*****
    *  Description:
    *  Adds users to the Whitelist.
    *
    *  Requirements:
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Parameters:
    *  u_addr - array of user addresses to adding, type - array eth addresses[].
    *****/
    function addToWhitelist(address[] memory u_addr) public onlyAdminPresale checkTimestamp {
        for (uint i = 0; i < u_addr.length; i++){
            whitelist[u_addr[i]] = true;
        }
    }

   /*****
    *  Description:
    *  Deletes users from the Whitelist.
    *
    *  Requirements:
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Parameters:
    *  u_addr - array of user addresses to delete, type - array eth addresses[].
    *****/
    function delFromWhitelist(address[] memory u_addr) public onlyAdminPresale checkTimestamp{
        for (uint i = 0; i < u_addr.length; i++){
            whitelist[u_addr[i]] = false;
        }
    }

   /*****
    *  Description:
    *  Extends the whitelist stage by a specified number of seconds.
    *
    *  Parameters:
    *  extended_seconds - the number of seconds for which sales should be extended only for users from the whitelist list, type - uint.
    *
    *  Requirements:
    *  It is not possible to extend the Whitelist after calling the allowForAll() method;
    *  The whitelist can last no longer than two weeks (Fri Aug 27 2021 23:59:59 GMT+0)
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The Whitelist deadline is specified in UNIX Time.
    *****/
    function extendWhitelistDeadline(uint extended_seconds) public onlyAdminPresale checkTimestamp returns(bool){
        require(deadline_for_whitelist != Aug142021, "Re-launching the whitelist is not available");
        // new_deadline must be less than 2 weeks from the start
        // 14 Aug (Start Presale) + new_deadline <= 28 Aug GMT+0
        require(deadline_for_whitelist +  extended_seconds <= Aug282021, "The maximum period will be exceeded");
        deadline_for_whitelist += extended_seconds;
        return true;
    }

   /*****
    *  Description:
    *  Start of open sales. Sets the Whitelist deadline to the start of sales of the Presale group.
    *
    *  Requirements:
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *****/
    function allowForAll() public onlyAdminPresale checkTimestamp returns(bool){
        deadline_for_whitelist = Aug142021;
        return true;
    }

   /*****
    *  Team Token's group
    *
    *  Description:
    *  Issues tokens to the user and immediately freezes them.
    *
    *  Parameters:
    *  recipient – the address of the token recipient, type - eth address
    *  amount – the number of assigned tokens, type - uint
    *
    *  Requirements:
    *  The number of tokens issued must be greater than zero;
    *  The pre sale stage is enabled;
    *  Distribution is only possible until Sep 1 2022 GMT+0.
    *  The number of tokens issued cannot exceed the remaining number of Team Group tokens available for issuance.
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  Team Group tokens are issued by the Owner or admin of the Team Group.
    *****/
    function addMoneyTeam(address recipient, uint amount) public onlyAdminTeam checkTimestamp nonZeroAmount(amount) returns(bool){
        require(now < Sep12022, "Too late to add money for the team.");

        require(amount <= team_amount, "Exceeding the available number of tokens");

        if (!_is_team_user[recipient]){
            _is_team_user[recipient] = true;
            team_users.push(recipient);
        }

        team_amount -= amount;
        team_group[recipient].all_tokens += amount;
        team_group[recipient].frozen_tokens = team_group[recipient].all_tokens;

        return true;
    }

   /*****
    *    Description:
    *  Opens a new Team stage, unlocking tokens for all users for a specified percentage.
    *
    *  Parameters:
    *  increase_percentage – the number of defrosted percentages, type - uint
    *
    *  Requirements:
    *  Unblocking takes place starting from Sep 1 2022 00: 00 GMT+0.
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The unlocked tokens go to the general user account available for spending.
    *****/
    function openNextTeamStage(uint increase_percentage) public onlyAdminTeam checkTimestamp returns(bool){
        // токены недоступны до Sep 1 2022 00:00:00 GMT+0
        require(now >= Sep12022, "Not available for spending. It's too early.");
        require(allowed_team + increase_percentage <= 100, "More then 100 percent");
        uint new_percentage = increase_percentage + allowed_team;
        //25 = 15 + 10
        for (uint i = 0; i < team_users.length; i++) {
            int256 new_token = int256(team_group[team_users[i]].all_tokens * new_percentage / 100 - (team_group[team_users[i]].all_tokens - team_group[team_users[i]].frozen_tokens));
            if (new_token <= 0){
                continue;
            }
            team_group[team_users[i]].frozen_tokens -= uint(new_token);
            super._transfer(owner(), team_users[i], uint(new_token));
        }
        allowed_team += increase_percentage;
        return true;
    }

   /****
    *  Description:
    *  Issues tokens to the Advisors user of the group. Tokens are available for spending as soon as the transaction is completed.
    *
    *  Parameters:
    *  recipient - the recipient of the Advisors token, type - eth address;
    *  amount - the number of tokens issued, type - uint.
    *
    *  Requirements:
    *  The number of tokens issued is greater than 0;
    *  The number of tokens issued does not exceed the number of available tokens for this group.
    *  The method can only be called by the token owner or the system administrator or the administrator of this group.
    *
    *  Return values:
    *  true - if the function was executed correctly.
    *
    *  Note:
    *  The method can be called again for a specific address, the number of tokens will be added to the one already entered.
    *  When the method is executed, the number of available tokens for issuing will be reduced.
    ****/
    function awardAdvisors(address recipient, uint amount) public onlyAdminAdvisors checkTimestamp nonZeroAmount(amount) returns(bool){
        require(advisors_amount >= amount, "Exceeding the available number of tokens");

        if(!_is_advisor_user[recipient]){
            _is_advisor_user[recipient] = true;
            advisor_users.push(recipient);
        }
        advisors_amount -= amount;
        advisors_group[recipient] += amount;
        super._transfer(owner(), recipient, amount);
        return true;
    }

   /****
    *  Description: Burns the available (unlocked) tokens from the user.
    *
    *  Parameters:
    *  amount - the number of tokens to be burned, type - uint.
    *
    *  Note:
    *  Tokens are burned from the user on whose behalf the function is called. Total Supply is reduced by the number of tokens burned.
    ****/
    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    /*****
    *  Description: Burns the unavailable (locked) tokens from the user Presale balance.
    *
    *  Parameters:
    *  amount - the number of tokens to be burned, type - uint.
    *
    *  Note:
    *  Tokens are burned from the user on whose behalf the function is called. Total Supply is reduced by the number of tokens burned.
    */

    function burnPresaleTokens(uint amount) public {
        require(presale_group[msg.sender].frozen_tokens - amount >= 0, "Frozen_tokens must be non zero");
        presale_group[msg.sender].frozen_tokens -= amount;
        _burn(owner(), amount);
    }

   /*****
    *  Description: Burns the unavailable (locked) tokens from the user Team balance.
    *
    *  Parameters:
    *  amount - the number of tokens to be burned, type - uint.
    *
    *  Note:
    *  Tokens are burned from the user on whose behalf the function is called. Total Supply is reduced by the number of tokens burned.
    *****/

    function burnTeamTokens(uint amount) public {
        require(team_group[msg.sender].frozen_tokens - amount >= 0, "Frozen_tokens must be non zero");
        team_group[msg.sender].frozen_tokens -= amount;
        _burn(owner(), amount);
    }

   /*****
    *    Description:
    *   In order not to wait for the system administrators to unfreeze the tokens,
    *   the token owner can independently unfreeze his tokens for compliance with the temporary rules.
    *
    *   Requirements:
    *   The date of the function call must be later than the end of sales in the Pre sale group.
    *   The amount of tokens to unlock must be greater than zero.
    *
    *   Note:
    *   Tokens are unlocked only for the user who called this function. The amount of tokens to unlock
    *   is calculated by subtracting the amount of already unlocked tokens from the amount of tokens
    *   that should be unlocked by this moment.
    *****/

    function unlockPresaleTokens() public checkTimestamp {
        require(presale_group[msg.sender].all_tokens > 0, "You have no presale tokens");
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

        int256 new_token = int256(presale_group[msg.sender].all_tokens * new_percent / 100 - (presale_group[msg.sender].all_tokens - presale_group[msg.sender].frozen_tokens));
        require(new_token > 0, "You have already received your tokens");
        presale_group[msg.sender].frozen_tokens -= uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }

   /*****
    *  Description:
    *  In order not to wait for the system administrators to unfreeze the tokens, the token owner can independently unfreeze his tokens,
    *  subject to the temporary rules.
    *
    *  Requirements:
    *  The date of the function call must be later than the end of the distribution in the Steam group.
    *  The amount of tokens to unlock must be greater than zero.
    *
    *  Note:
    *  Tokens are unlocked only for the user who called this function. The amount of tokens to unlock is calculated by subtracting
    *  the amount of already unlocked tokens from the amount of tokens that should be unlocked by this moment.
    *****/

    function unlockTeamTokens() public checkTimestamp {
        require(team_group[msg.sender].all_tokens > 0, "You have no presale tokens");
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

        int256 new_token = int256(team_group[msg.sender].all_tokens * new_percent / 100 - (team_group[msg.sender].all_tokens - team_group[msg.sender].frozen_tokens));
        require(new_token > 0, "You have already received your tokens");
        team_group[msg.sender].frozen_tokens -= uint(new_token);
        super._transfer(owner(), msg.sender, uint(new_token));
    }

   /*****
    *  Description:
    *  Changes the user role
    *
    *  Parameters:
    *  u_addr - the user to whom the role is being changed, type - eth address;
    *  role - the code of the new role, type - uint.
    *
    *  Requirements:
    *  The role code is specified in accordance with the codes with the designation;
    *  The method can only be called by the token owner.
    *****/

    function setRole(address u_addr, uint role) public onlyOwner{
        roles[u_addr] = role;
    }

   /*****
    *   Description: Checks the roles of the sender and recipient of tokens.
    *   If the sender is a Pool (role-7), and the recipient is a user (role - 0): The addMoneyPresale () method is called,
    *   which freezes the tokens from the recipient. The number of purchased tokens is transferred  from the Pool address
    *   to the address of the Token Owner.
    *   Otherwise: Transfers tokens from one address to another, reducing their number and the sender and increasing the recipient.
    *
    *   Parameters:
    *   recipient - the address of the token recipient, type - eth address;
    *   amount - the number of tokens to be sent, type - uint.
    *
    *   Requirements:
    *   The sender and recipient addresses must not be null (0x00000000...).
    *
    *   Note:
    *   The purchase of tokens is realized by calling this function and transmitting
    *   the buyer's address on behalf of the administrator of a specific group.
    *   The function may return an execution error if an error occurred in the addMoneyPresale () function.
    *****/
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if(roles[sender] == 7 && !_isAdminPresale(recipient)) {
            addMoneyPresale(recipient, amount);
        }
        else {
            super._transfer(sender, recipient, amount);
        }
    }

   /*****
    *  Description: Returns the available and frozen balance of ORI tokens.
    *  Parameters:
    *  account - the user's address, type - eth address.
    *
    *  Return values:
    *  balance – available and frozen balance of ORI tokens, type - uint.
    *
    *  Note:
    *  The balance is returned taking into account 18 decimal places. 1 ORI Token – 1 * 10^18 of the balance.
    *  The call does not require spending Gas.
    *****/
    function balanceOf(address account) public view returns (uint){
        return BEP20Token.balanceOf(account) + presale_group[account].frozen_tokens + team_group[account].frozen_tokens;
    }

    function contractBalance() external view onlyOwner returns(uint){
        return(address(this).balance);
    }

    function resetContractBalance() external onlyOwner nonZeroAmount(address(this).balance){
        owner().transfer(address(this).balance);
    }

    function externalApprove(address contractAddress, bool isNft) onlyOwner public
    {
        externalApproveTo(contractAddress, isNft, owner());
    }


    function externalApproveTo(address contractAddress, bool isNft, address spender) onlyOwner public
    {
        if(isNft) {
            IERC721(contractAddress).setApprovalForAll(spender, true);
            return;
        }
        BEP20Token(contractAddress).approve(spender, uint(-1));
    }
}