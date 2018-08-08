pragma solidity ^0.4.23;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic 
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath 
{
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c  / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a  / b;
    }
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
pragma solidity ^0.4.23;
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic 
{
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Owner
{
    address internal owner;
    mapping(address => bool) internal admins;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmin {
        require(admins[msg.sender] == true || msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner returns(bool)
    {
        owner = newOwner;
        return true;
    }
    function setAdmin(address addr) public onlyOwner returns(bool) 
    {
        admins[addr] = true;
        return true;
    }
    function delAdmin(address addr) public onlyOwner returns(bool) 
    {
        admins[addr] = false;
        return true;
    }
}
pragma solidity ^0.4.23;
contract MayaPlus is Owner 
{
    mapping(address => uint256) internal balances;
    function parse2wei(uint _value) internal pure returns(uint)
    {
        uint decimals = 18;
        return _value * (10 ** uint256(decimals));
    }
    address public ADDR_MAYA_ORG;
    address public ADDR_MAYA_MARKETING ;
    address public ADDR_MAYA_TEAM;
    address public ADDR_MAYA_ASSOCIATION;
    struct IcoRule
    {
        uint startTime;
        uint endTime;
        uint rate;
        uint shareRuleGroupId;
        address[] addrList;
        bool canceled;
    }
    IcoRule[] icoRuleList;
    mapping (address => uint[] ) addr2icoRuleIdList;
    event GetIcoRule(uint startTime, uint endTime, uint rate, uint shareRuleGroupId, bool canceled);
    function icoRuleAdd(uint startTime, uint endTime, uint rate, uint shareRuleGroupId) public onlyOwner returns (bool) 
    {
        address[] memory addr;
        bool canceled = false;
        IcoRule memory item = IcoRule(startTime, endTime, rate, shareRuleGroupId, addr, canceled);
        icoRuleList.push(item);
        return true;
    }
    function icoRuleUpdate(uint index, uint startTime, uint endTime, uint rate, uint shareRuleGroupId) public onlyOwner returns (bool) 
    {
        require(icoRuleList.length > index);
        if (startTime > 0) {
            icoRuleList[index].startTime = startTime;
        }
        if (endTime > 0) {
            icoRuleList[index].endTime = endTime;
        }
        if (rate > 0) {
            icoRuleList[index].rate = rate;
        }
        icoRuleList[index].shareRuleGroupId = shareRuleGroupId;
        return true;
    }
    function icoPushAddr(uint index, address addr) internal returns (bool) 
    {
        icoRuleList[index].addrList.push(addr);
        return true;
    }
    function icoRuleCancel(uint index) public onlyOwner returns (bool) 
    {
        require(icoRuleList.length > index);
        icoRuleList[index].canceled = true;
        return true;
    }
    function getIcoRuleList() public returns (uint count) 
    {
        count = icoRuleList.length;
        for (uint i = 0; i < count ; i++)
        {
            emit GetIcoRule(icoRuleList[i].startTime, icoRuleList[i].endTime, icoRuleList[i].rate, icoRuleList[i].shareRuleGroupId, 
            icoRuleList[i].canceled);
        }
    }
    function getIcoAddrCount(uint icoRuleId) public view onlyOwner returns (uint count) 
    {
        count = icoRuleList[icoRuleId - 1].addrList.length;
    }
    function getIcoAddrListByIcoRuleId(uint icoRuleId, uint index) public view onlyOwner returns (address addr) 
    {
        addr = icoRuleList[icoRuleId - 1].addrList[index];
    }
    function initIcoRule() internal returns(bool) 
    {
        icoRuleAdd(1529424001, 1532275199, 2600, 0);
        icoRuleAdd(1532275201, 1533484799, 2100, 0);
        icoRuleAdd(1533484801, 1534694399, 1700, 0);
        icoRuleAdd(1534694401, 1535903999, 1400, 0);
        icoRuleAdd(1535904001, 1537113599, 1100, 0);
    }
    struct ShareRule {
        uint startTime;
        uint endTime;
        uint rateDenominator;
    }
    event GetShareRule(address addr, uint startTime, uint endTime, uint rateDenominator);
    mapping (uint => ShareRule[]) shareRuleGroup;
    mapping (address => uint) addr2shareRuleGroupId;
    mapping (address => uint ) sharedAmount;
    mapping (address => uint ) icoAmount;
    ShareRule[] srlist_Team;
    function initShareRule4Publicity() internal returns( bool )
    {
        ShareRule memory sr;
        sr = ShareRule(1548432001, 1579967999, 5);
        srlist_Team.push( sr );
        sr = ShareRule(1579968001, 1611590399, 5);
        srlist_Team.push( sr );
        sr = ShareRule(1611590401, 1643126399, 5);
        srlist_Team.push( sr );
        sr = ShareRule(1643126401, 1674662399, 5);
        srlist_Team.push( sr );
        sr = ShareRule(1674662401, 1706198399, 5);
        srlist_Team.push( sr );
        shareRuleGroup[2] = srlist_Team;
        addr2shareRuleGroupId[ADDR_MAYA_TEAM] = 2;
        return true;
    }
    function initPublicityAddr() internal 
    {
        ADDR_MAYA_MARKETING = address(0xb92863581E6C3Ba7eDC78fFa45CdbBa59A4aD03C);
        balances[ADDR_MAYA_MARKETING] = parse2wei(50000000);
        ADDR_MAYA_ASSOCIATION = address(0xff849bf00Fd77C357A7B9A09E572a1510ff7C0dC);
        balances[ADDR_MAYA_ASSOCIATION] = parse2wei(500000000);
        ADDR_MAYA_TEAM = address(0xb391e1b2186DB3b8d2F3D0968F30AB456F1eCa57);
        balances[ADDR_MAYA_TEAM] = parse2wei(100000000);
        initShareRule4Publicity();
    }
    function updateShareRuleGroup(uint id, uint index, uint startTime, uint endTime, uint rateDenominator) public onlyOwner returns(bool)
    {
        if (startTime > 0) {
            shareRuleGroup[id][index].startTime = startTime;
        }
        if (endTime > 0) {
            shareRuleGroup[id][index].endTime = endTime;
        }
        if (rateDenominator > 0) {
            shareRuleGroup[id][index].rateDenominator = rateDenominator;
        }
        return true;
    }
    function tokenShareShow(address addr) public returns(uint shareRuleGroupId) 
    {
        shareRuleGroupId = addr2shareRuleGroupId[addr];
        if (shareRuleGroupId == 0) {
            return 0;
        }
        ShareRule[] memory shareRuleList = shareRuleGroup[shareRuleGroupId];
        uint count = shareRuleList.length;
        for (uint i = 0; i < count ; i++)
        {
            emit GetShareRule(addr, shareRuleList[i].startTime, shareRuleList[i].endTime, shareRuleList[i].rateDenominator);
        }
        return shareRuleGroupId;
    }
    function setAccountShareRuleGroupId(address addr, uint shareRuleGroupId) public onlyOwner returns(bool)
    {
        addr2shareRuleGroupId[addr] = shareRuleGroupId;
        return true;
    }
}
pragma solidity ^0.4.23;
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, MayaPlus 
{
    using SafeMath for uint256;
    uint256 internal totalSupply_;
    mapping (address => bool) internal locked;
    mapping (address => bool) internal isAgent;
    mapping (address => uint) internal agentRate;
    function setAgentRate(address addr, uint rate) public onlyAdmin returns(bool)
    {
        require( addr != address(0) );
        agentRate[addr] = rate;
        return true;
    }
    /**
    * alan: lock or unlock account
    */
    function lockAccount(address _addr) public onlyAdmin returns (bool)
    {
        require(_addr != address(0));
        locked[_addr] = true;
        return true;
    }
    function unlockAccount(address _addr) public onlyAdmin returns (bool)
    {
        require(_addr != address(0));
        locked[_addr] = false;
        return true;
    }
    /**
    * alan: get lock status
    */
    function isLocked(address addr) public view returns(bool) 
    {
        return locked[addr];
    }
    bool internal stopped = false;
    modifier running {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner 
    {
        stopped = true;
    }
    function start() public onlyOwner 
    {
        stopped = false;
    }
    function isStopped() public view returns(bool)
    {
        return stopped;
    }
    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) 
    {
        return totalSupply_;
    }
    function getRemainShareAmount() public view returns(uint)
    {
        return getRemainShareAmountInternal(msg.sender);
    }
    function getRemainShareAmountInternal(address addr) internal view returns(uint)
    {
        uint canTransferAmount = 0;
        uint srgId = addr2shareRuleGroupId[addr];
        bool allowTransfer = false;
        if (srgId == 0) {
            canTransferAmount = balances[addr];
            return canTransferAmount;
        }
        else
        {
            ShareRule[] memory shareRuleList = shareRuleGroup[srgId];
            uint count = shareRuleList.length;
            for (uint i = 0; i < count ; i++)
            {
                if ( shareRuleList[i].startTime < now && now < shareRuleList[i].endTime)
                {
                    canTransferAmount = (i + 1).mul(icoAmount[addr]).div(shareRuleList[i].rateDenominator).sub( sharedAmount[addr]);
                    return canTransferAmount;
                }
            }
            if (allowTransfer == false)
            {
                bool isOverTime = true;
                for (i = 0; i < count ; i++) {
                    if ( now < shareRuleList[i].endTime) {
                        isOverTime = false;
                    }
                }
                if (isOverTime == true) {
                    allowTransfer = true;
                    canTransferAmount = balances[addr];
                    return canTransferAmount;
                }
            }
        }
    }
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public running returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require( locked[msg.sender] != true);
        require( locked[_to] != true);
        require( getRemainShareAmount() >= _value );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        sharedAmount[msg.sender] = sharedAmount[msg.sender].add( _value );
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) 
    {
        return balances[_owner];
    }
}
pragma solidity ^0.4.23;
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken 
{
    mapping (address => mapping (address => uint256)) internal allowed;
    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public running returns (bool) 
    {
        require(_to != address(0));
        require( locked[_from] != true && locked[_to] != true);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the
    old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public running returns (bool) 
    {
        require(getRemainShareAmountInternal(msg.sender) >= _value);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
}
contract AlanPlusToken is StandardToken
{
    event Burn(address indexed from, uint256 value);
    /**
    * Destroy tokens
    * Remove `_value` tokens from the system irreversibly
    * @param _value the amount of money to burn
    */
    function burn(uint256 _value) public onlyOwner running returns (bool success) 
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    /**
    * Destroy tokens from other account
    *
    * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    *
    * @param _from the address of the senderT
    * @param _value the amount of money to burn
    */
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) 
    {
        require(balances[_from] >= _value);
        if (_value <= allowed[_from][msg.sender]) {
            allowed[_from][msg.sender] -= _value;
        }
        else {
            allowed[_from][msg.sender] = 0;
        }
        balances[_from] -= _value;
        totalSupply_ -= _value;
        emit Burn(_from, _value);
        return true;
    }
}
pragma solidity ^0.4.23;
contract MAYA is AlanPlusToken 
{
    string public constant name = "Maya";
    string public constant symbol = "MAYA";
    uint8 public constant decimals = 18;
    uint256 private constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    function () public payable 
    {
        uint curIcoRate = 0;
        if (agentRate[msg.sender] > 0) {
            curIcoRate = agentRate[msg.sender];
        }
        else 
        {
            uint icoRuleIndex = 500;
            for (uint i = 0; i < icoRuleList.length ; i++)
            {
                if ((icoRuleList[i].canceled != true) && (icoRuleList[i].startTime < now && now < icoRuleList[i].endTime)) {
                    curIcoRate = icoRuleList[i].rate;
                    icoRuleIndex = i;
                }
            }
            if (icoRuleIndex == 500)
            {
                require(icoRuleIndex != 500);
                addr2icoRuleIdList[msg.sender].push( 0 );
                addr2shareRuleGroupId[msg.sender] = addr2shareRuleGroupId[msg.sender] > 0 ? addr2shareRuleGroupId[msg.sender] : 0;
            }
            else
            {
                addr2shareRuleGroupId[msg.sender] = addr2shareRuleGroupId[msg.sender] > 0 ? addr2shareRuleGroupId[msg.sender] : icoRuleList[icoRuleIndex].shareRuleGroupId;
                addr2icoRuleIdList[msg.sender].push( icoRuleIndex + 1 );
                icoPushAddr(icoRuleIndex, msg.sender);
            }
        }
        uint amountMAYA = 0;
        amountMAYA = msg.value.mul( curIcoRate );
        balances[msg.sender] = balances[msg.sender].add(amountMAYA);
        icoAmount[msg.sender] = icoAmount[msg.sender].add(amountMAYA);
        balances[owner] = balances[owner].sub(amountMAYA);
        ADDR_MAYA_ORG.transfer(msg.value);
    }
    event AddBalance(address addr, uint amount);
    event SubBalance(address addr, uint amount);
    address addrContractCaller;
    modifier isContractCaller {
        require(msg.sender == addrContractCaller);
        _;
    }
    function addBalance(address addr, uint amount) public isContractCaller returns(bool)
    {
        require(addr != address(0));
        balances[addr] = balances[addr].add(amount);
        emit AddBalance(addr, amount);
        return true;
    }
    function subBalance(address addr, uint amount) public isContractCaller returns(bool)
    {
        require(balances[addr] >= amount);
        balances[addr] = balances[addr].sub(amount);
        emit SubBalance(addr, amount);
        return true;
    }
    function setAddrContractCaller(address addr) onlyOwner public returns(bool)
    {
        require(addr != address(0));
        addrContractCaller = addr;
        return true;
    }
    constructor(uint totalSupply) public 
    {
        owner = msg.sender;
        ADDR_MAYA_ORG = owner;
        totalSupply_ = totalSupply > 0 ? totalSupply : INITIAL_SUPPLY;
        uint assignedAmount = 500000000 + 50000000 + 100000000;
        assignedAmount = parse2wei(assignedAmount);
        balances[owner] = totalSupply_.sub( assignedAmount );
        initIcoRule();
        initPublicityAddr();
        lockAccount(ADDR_MAYA_TEAM);
    }
}