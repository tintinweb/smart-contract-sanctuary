/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 * 
///////////////////////THETAN ARENA////////////////////////

/////////////A KEY DRIVER OF VALUE WITHIN THE UNIVERSE OF THETAN ARENA IS THE MONETARY REWARD SYSTEM
DELIVERED VIA ROBUST, WELL-BALANCED ECONOMICS, SUPPORTED BY BOTH IN-GAME AND
BLOCKCHAIN MECHANICS. A SUPPLEMENTAL OBJECTIVE OF THE DEVELOPMENT TEAM IS TO
DRIVE REAL-WORLD HUMAN INNOVATION AND PROGRESS BY LEVERAGING THIS VIRTUAL WORLD AS
AN EXPERIMENTAL SANDBOX FOR ECONOMIC AND GOVERNANCE RESEARCH. THETAN ARENA IS DRIVEN
BY A DUAL TOKEN SYSTEM (ARENA | BATTLE), WITH MULTI-CURRENCY BINANCE ASSET SUPPORT////////////////

//////////////ARENA WILL SERVE AS THE NATIVE IN-GAME CURRENCY WITHIN THETAN ARENA. IT IS THE
LUBRICANT OF THE METAVERSE. PLAYERS WILL INITIALLY LEVERAGE ARENA TO ACQUIRE DIGITAL
ASSETS SUCH AS WEAPON, LEGEND, CREW AND EQUIPMENT. HOWEVER, AS IN ANY
REAL ECONOMY, A FINANCIAL SYSTEM IS NECESSARY TO FACILITATE COMMERCE. WHETHER IT
BE THROUGH NPC MERCHANTS, OR DIRECT PEER-TO-PEER TRANSACTIONS, ATLAS IS THE UNIT
OF ACCOUNT TO EXECUTE OPERATIONAL REQUIREMENTS.
OPERATING A BUSINESS IS CHALLENGING. MANAGING RESOURCES WILL REQUIRE CRITICAL
STRATEGIC DECISION MAKING. 
PLAYERS SEEKING THE MONETARY REWARDS AVAILABLE INGAME WILL NEED TO CAREFULLY BALANCE THEIR OPERATING EXPENSES AGAINST INCOME
DERIVED. OPERATING EXPENSES, SUCH AS PERSONNEL FOR MINING EQUIPMENT, FUEL FOR
WEAPON, AND REPAIRS FOR DAMAGES WILL ALL NEED TO BE PAID IN THETAN. IT WILL ALSO SERVE
AS THE PREDOMINANT CURRENCY WITHIN THE NFT MARKETPLACE.///////////////

ＴＨＩＳ　ＰＲＯＪＥＣＴ ＩＳ ＮＯＷ ＯＮ ＴＥＳＴＩＮＧ ＰＲＯＣＥＳＳ
ＩＦ ＳＵＰＰＯＲＴＥＲ ＷＡＮＴ ＴＯ ＦＯＲＭ ＵＰ Ａ ＦＡＮ ＣＯＭＭＵＮＩＴＹ
ＰＬＥＡＳＥ ＤＯ ＩＴ ＢＹ ＹＯＵＲＳＥＬＦ

 （FIRST STAGE）JUN - SEP
1. PRE-SALE (FROM 19 AUG TO 15 SEP)
2. PROVIDE TOTALLY 500BNB-ARENA LIQUIDITY
3. FIRST AIRDROP REGISTRATION
4. WORK ON BUILDING WEBSITE
5. NFT MARKETPLACE


（SECOND STAGE）SEP - OCT
- LAUNCH TG AND DISCORD COMMUNITY
- 2ND AIRDROP REGISTRATION
- LISTING ON COINGECKO AND COINMARKETBASE
- SOCIAL MEDIA MARKETING CAMPAIGN WITH INFLUENCER

（LAST STAGE） NOV - DEC
- THE OFFICIAL LAUNCH OF THETAN ARENA 
- LISTING ON BINANCE AND COINBASE

ＬＥＴ＇Ｓ ＧＲＯＷ ＴＨＥ ＩＮＤＵＳＴＲＹ ＯＦ ＧＡＭＥＦＩ ＡＮＤ ＢＥＣＯＭＥ ＴＨＥ ＮＥＸＴ ＡＸＳ

///////////////////////THETAN AREN COPYRIGHT 2021////////////////////////////
*/




pragma solidity ^0.8.2;


contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Thetan Arena";
    string public symbol = "Arena";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}