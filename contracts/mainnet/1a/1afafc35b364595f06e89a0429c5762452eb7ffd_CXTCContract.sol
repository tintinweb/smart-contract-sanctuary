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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public systemAcc; // charge fee

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
     * @dev Throws if called by any account other than the systemAcc.
     */
    modifier onlySys() {
        require(systemAcc !=address(0) && msg.sender == systemAcc);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Pausable {
    using SafeMath for uint256;

    //   mapping(address => uint256) balances;
    mapping(address => uint256) freeBalances;
    mapping(address => uint256) frozenBalances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= freeBalances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_value);
        freeBalances[_to] = freeBalances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return freeBalances[_owner] + frozenBalances[_owner];
    }

    function freeBalanceOf(address _owner) public view returns (uint256 balance) {
        return freeBalances[_owner];
    }

    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= freeBalances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        freeBalances[_from] = freeBalances[_from].sub(_value);
        freeBalances[_to] = freeBalances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
 * @title CXTCToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract CXTCContract is StandardToken {

    string public constant name = "Culture eXchange Token Chain"; // solium-disable-line uppercase
    string public constant symbol = "CXTC"; // solium-disable-line uppercase
    uint8 public constant decimals = 8; // solium-disable-line uppercase

    uint256 public constant freeSupply = 21000000 * (10 ** uint256(decimals)); // 10%自由量
    uint256 public constant frozenSupply = 189000000 * (10 ** uint256(decimals)); // 90%冻结量

    address[] parterAcc;

    struct ArtInfo {
        string idtReport;
        string evtReport;
        string escReport;
        string regReport;
    }

    mapping (string => ArtInfo) internal artInfos;
    mapping (address => mapping (uint256 => uint256)) public freezeRecord;

    event Freeze(address indexed _addr, uint256 indexed _amount, uint256 indexed _timestamp);
    event Defreeze(address indexed _addr, uint256 indexed _amount, uint256 indexed _timestamp);
    event Release(address indexed _addr, uint256 indexed _amount);
    event SetParter(address indexed _addr, uint256 indexed _amount);
    event SetSysAcc(address indexed _addr);
    event NewArt(string indexed _id);
    event SetArtIdt(string indexed _id, string indexed _idtReport);
    event SetArtEvt(string indexed _id, string indexed _evtReport);
    event SetArtEsc(string indexed _id, string indexed _escReport);
    event SetArtReg(string indexed _id, string indexed _regReport);

    /**
     * @dev Constructor
     */
    function CXTCContract() public {
        owner = msg.sender;
        totalSupply_ = freeSupply + frozenSupply;
        freeBalances[owner] = freeSupply;
        frozenBalances[owner] = frozenSupply;
    }

    /**
     * init parter
     */
    function setParter(address _parter, uint256 _amount, uint256 _timestamp) public onlyOwner {
        parterAcc.push(_parter);
        frozenBalances[owner] = frozenBalances[owner].sub(_amount);
        frozenBalances[_parter] = frozenBalances[_parter].add(_amount);
        freezeRecord[_parter][_timestamp] = freezeRecord[_parter][_timestamp].add(_amount);
        Freeze(_parter, _amount, _timestamp);
        SetParter(_parter, _amount);
    }

    /**
     * set systemAccount
     */
    function setSysAcc(address _sysAcc) public onlyOwner returns (bool) {
        systemAcc = _sysAcc;
        SetSysAcc(_sysAcc);
        return true;
    }

    /**
     * new art hash info
     */
    function newArt(string _id, string _regReport) public onlySys returns (bool) {
        ArtInfo memory info = ArtInfo({idtReport: "", evtReport: "", escReport: "", regReport: _regReport});
        artInfos[_id] = info;
        NewArt(_id);
        return true;
    }

    /**
     * get artInfo
     */
    function getArt(string _id) public view returns (string, string, string, string) {
        ArtInfo memory info = artInfos[_id];
        return (info.regReport, info.idtReport, info.evtReport, info.escReport);
    }

    /**
     * set art idtReport
     */
    function setArtIdt(string _id, string _idtReport) public onlySys returns (bool) {
        string idtReport = artInfos[_id].idtReport;
        bytes memory idtReportLen = bytes(idtReport);
        if (idtReportLen.length == 0){
            artInfos[_id].idtReport = _idtReport;
            SetArtIdt(_id, _idtReport);
            return true;
        } else {
            return false;
        }
    }

    /**
     * set art evtReport
     */
    function setArtEvt(string _id, string _evtReport) public onlySys returns (bool) {
        string evtReport = artInfos[_id].evtReport;
        bytes memory evtReportLen = bytes(evtReport);
        if (evtReportLen.length == 0){
            artInfos[_id].evtReport = _evtReport;
            SetArtEvt(_id, _evtReport);
            return true;
        } else {
            return false;
        }
    }

    /**
     * set art escrow report
     */
    function setArtEsc(string _id, string _escReport) public onlySys returns (bool) {
        string escReport = artInfos[_id].escReport;
        bytes memory escReportLen = bytes(escReport);
        if (escReportLen.length == 0){
            artInfos[_id].escReport = _escReport;
            SetArtEsc(_id, _escReport);
            return true;
        } else {
            return false;
        }
    }

    /**
     * issue art coin to user.
     */
    function issue(address _addr, uint256 _amount, uint256 _timestamp) public onlySys returns (bool) {
        // 2018/03/23 = 1521734400
        require(frozenBalances[owner] >= _amount);
        frozenBalances[owner] = frozenBalances[owner].sub(_amount);
        frozenBalances[_addr]= frozenBalances[_addr].add(_amount);
        freezeRecord[_addr][_timestamp] = freezeRecord[_addr][_timestamp].add(_amount);
        Freeze(_addr, _amount, _timestamp);
        return true;
    }

    /**
     * distribute
     */
    function distribute(address _to, uint256 _amount, uint256 _timestamp, address[] _addressLst, uint256[] _amountLst) public onlySys returns(bool) {
        frozenBalances[_to]= frozenBalances[_to].add(_amount);
        freezeRecord[_to][_timestamp] = freezeRecord[_to][_timestamp].add(_amount);
        for(uint i = 0; i < _addressLst.length; i++) {
            frozenBalances[_addressLst[i]] = frozenBalances[_addressLst[i]].sub(_amountLst[i]);
            Defreeze(_addressLst[i], _amountLst[i], _timestamp);
        }
        Freeze(_to, _amount, _timestamp);
        return true;
    }

    /**
     * send with charge fee
     */
    function send(address _to, uint256 _amount, uint256 _fee, uint256 _timestamp) public whenNotPaused returns (bool) {
        require(freeBalances[msg.sender] >= _amount);
        require(_amount >= _fee);
        require(_to != address(0));
        uint256 toAmt = _amount.sub(_fee);
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_amount);
        freeBalances[_to] = freeBalances[_to].add(toAmt);
        // systemAcc
        frozenBalances[systemAcc] = frozenBalances[systemAcc].add(_fee);
        freezeRecord[systemAcc][_timestamp] = freezeRecord[systemAcc][_timestamp].add(_fee);
        Transfer(msg.sender, _to, toAmt);
        Freeze(systemAcc, _fee, _timestamp);
        return true;
    }

    /**
     * user freeze free balance
     */
    function freeze(uint256 _amount, uint256 _timestamp) public whenNotPaused returns (bool) {
        require(freeBalances[msg.sender] >= _amount);
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_amount);
        frozenBalances[msg.sender] = frozenBalances[msg.sender].add(_amount);
        freezeRecord[msg.sender][_timestamp] = freezeRecord[msg.sender][_timestamp].add(_amount);
        Freeze(msg.sender, _amount, _timestamp);
        return true;
    }

    /**
     * auto release
     */
    function release(address[] _addressLst, uint256[] _amountLst) public onlySys returns (bool) {
        require(_addressLst.length == _amountLst.length);
        for(uint i = 0; i < _addressLst.length; i++) {
            freeBalances[_addressLst[i]] = freeBalances[_addressLst[i]].add(_amountLst[i]);
            frozenBalances[_addressLst[i]] = frozenBalances[_addressLst[i]].sub(_amountLst[i]);
            Release(_addressLst[i], _amountLst[i]);
        }
        return true;
    }

    /**
     * bonus shares
     */
    function bonus(uint256 _sum, address[] _addressLst, uint256[] _amountLst) public onlySys returns (bool) {
        require(frozenBalances[systemAcc] >= _sum);
        require(_addressLst.length == _amountLst.length);
        for(uint i = 0; i < _addressLst.length; i++) {
            freeBalances[_addressLst[i]] = freeBalances[_addressLst[i]].add(_amountLst[i]);
            Transfer(systemAcc, _addressLst[i], _amountLst[i]);
        }
        frozenBalances[systemAcc].sub(_sum);
        Release(systemAcc, _sum);
        return true;
    }
}