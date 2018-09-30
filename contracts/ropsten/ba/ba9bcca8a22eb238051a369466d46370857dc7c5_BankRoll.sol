pragma solidity ^0.4.23;

contract BankRoll {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    modifier onlySkcContract() {
        require(msg.sender == skcAddress);
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event tokenToPointEvent(uint256 _id, address indexed _recharger, uint256 _amount);
    event pointToTokenEvent(uint256 _id, address indexed sender, uint256 amount);
    event ledgerRecordEvent(uint256 _id, address[] _address, uint256[] _oldPiont, uint256[] _newPoint);

    /*=====================================
    =            CONSTANTS                =
    =====================================*/

    address public owner;
    address public skcAddress;
    mapping (address => uint256) internal points;
    mapping (address => bool) internal admins;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor (address _skcAddress)
    public
    {
        owner = msg.sender;
        skcAddress = _skcAddress;
    }

    function tokenToPointByMetaMask(uint256 _id, uint _amount)
    public
    returns (bool)
    {
        return tokenToPoint(_id, msg.sender, _amount);
    }

    function tokenToPointBySkcContract(uint256 _id, address _recharger, uint _amount)
    public
    onlySkcContract
    returns (bool)
    {
        return tokenToPoint(_id, _recharger, _amount);
    }

    function tokenToPoint(uint256 _id, address _recharger, uint _amount)
    internal
    returns (bool)
    {
        bool isSuccess = skcAddress.call(bytes4(keccak256("redeemGamePoints(address,uint256)")), _recharger, _amount);
        require(isSuccess);
        emit tokenToPointEvent(_id, _recharger, _amount);
        return true;
    }

    function pointToToken(uint256 _id, address _withdrawer, uint _amount)
    public
    onlyAdministrator
    returns (bool)
    {
        bool isSuccess = skcAddress.call(bytes4(keccak256("transfer(address,uint256)")), _withdrawer, _amount);
        require(isSuccess);
        emit pointToTokenEvent(_id, _withdrawer, _amount);
        return true;
    }

    function updateLedger(uint256 _id, address[] _address, uint256[] _oldPionts, uint256[] _newPoints)
    public
    onlyAdministrator
    {
        require(_address.length <= 500);
        require(_address.length == _oldPionts.length);
        require(_oldPionts.length == _newPoints.length);
        for (uint i = 0; i < _address.length; i++) {
            //用户游戏积分更新
            points[_address[i]] = _newPoints[i];
        }
        emit ledgerRecordEvent(_id, _address, _oldPionts, _newPoints);
    }

    function setAdministrator(address[] _administrators)
    public
    onlyOwner
    {
        for (uint i = 0; i < _administrators.length; i++) {
            admins[_administrators[i]] = true;
        }
    }

    function unsetAdministrator(address[] _administrators)
    public
    onlyOwner
    {
        for (uint i = 0; i < _administrators.length; i++) {
            admins[_administrators[i]] = false;
        }
    }

    function setSkcAdderss(address _skcAddress)
    public
    onlyOwner
    {
        skcAddress = _skcAddress;
    }


    function replaceAdministrator(address oldOwner, address newOwner)
    public
    onlyOwner
    {
        admins[oldOwner] = false;
        admins[newOwner] = true;
    }

    //合约拥有者查询管理员
    function getAdministrator(address adr)
    public
    view
    returns (bool)
    {
        return admins[adr];
    }

    //用户查询链上记录的积分，可能链下不同步
    function point(address who)
    public
    view
    returns (uint256)
    {
        return points[who];
    }

}