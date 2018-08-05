pragma solidity ^0.4.24;

contract EtheremonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonExternalPayment is EtheremonEnum, BasicAccessControl {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;

    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    address public dataContract;
    uint public gapFactor = 0.001 ether;
    uint16 public priceIncreasingRatio = 1000;
    uint seed = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function setDataContract(address _contract) onlyOwner public {
        dataContract = _contract;
    }

    function setPriceIncreasingRatio(uint16 _ratio) onlyModerators external {
        priceIncreasingRatio = _ratio;
    }

    function setFactor(uint _gapFactor) onlyOwner public {
        gapFactor = _gapFactor;
    }

    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }

    function getRandom(address _player, uint _block, uint _seed, uint _count) constant public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _seed, _count)));
    }

    function catchMonster(address _player, uint32 _classId, string _name) onlyModerators external payable returns(uint tokenId) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        if (class.classId == 0 || class.catchable == false) {
            revert();
        }

        uint price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;
        if (msg.value + gapFactor < price) {
            revert();
        }

        // add new monster
        uint64 objId = data.addMonsterObj(_classId, _player, _name);
        uint8 value;
        seed = getRandom(_player, block.number, seed, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }

        emit Transfer(address(0), _player, objId);

        return objId;
    }

    // public
    function getPrice(uint32 _classId) constant external returns(bool catchable, uint price) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;

        return (class.catchable, price);
    }
}

interface WrapEtheremonInterface {
    function getMonsterPriceInTokens(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        ERC20 token,
        uint32 _classId
    )
        public
        view
        returns (
          uint expectedRate,
          uint slippageRate,
          uint tokenPrice,
          uint ethValue,
          bool catchable
        );

    function catchMonster(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        uint32 _classId,
        string _name,
        ERC20 token,
        uint tokenQty,
        uint maxDestQty,
        uint minRate,
        address walletId
    )
        public
        returns (uint monsterId);
}

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface EtheremonDataBase {
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function addElementToArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);

    // read
    function getElementInArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function getMonsterClass(uint32 _classId) constant external returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
}

contract WrapEtheremonProxy is WrapEtheremonInterface, PermissionGroups {
    event WrapEtheremonSet(address newNetworkContract, address oldNetworkContract);

    WrapEtheremonInterface public wrapEtheremonContract;

    constructor (address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    function setWrapEtheremonContract(WrapEtheremonInterface _wrapEtheremonContract) public onlyAdmin {
        require(_wrapEtheremonContract != address(0));

        emit WrapEtheremonSet(_wrapEtheremonContract, wrapEtheremonContract);

        wrapEtheremonContract = _wrapEtheremonContract;
    }

    /// @dev Get the token price equivalent of the Etheremon monster
    /// @param _kyber KyberNetworkProxyInterface address
    /// @param _etheremon EtheremonExternalPayment address
    /// @param token ERC20 token address
    /// @param _classId Class ID of monster
    /// @return expectedRate, slippageRate, tokenPrice
    function getMonsterPriceInTokens(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        ERC20 token,
        uint32 _classId
    )
        public
        view
        returns (
          uint expectedRate,
          uint slippageRate,
          uint tokenPrice,
          uint ethValue,
          bool catchable
        )
    {
        return wrapEtheremonContract.getMonsterPriceInTokens(
                _kyber,
                _etheremon,
                token,
                _classId
            );
    }

    /// @dev Acquires the monster from Etheremon using tokens
    /// @param _kyber KyberNetworkProxyInterface address
    /// @param _etheremon EtheremonExternalPayment address
    /// @param _classId Class ID of monster
    /// @param _name Name of the monster
    /// @param token ERC20 token address
    /// @param tokenQty Amount of tokens required to acquire the monster
    /// @param maxDestQty Limit on the amount of destination tokens
    /// @param minRate Minimum conversion rate
    /// @param walletId Wallet ID where Kyber referral fees will be sent to
    /// @return monsterId
    function catchMonster(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        uint32 _classId,
        string _name,
        ERC20 token,
        uint tokenQty,
        uint maxDestQty,
        uint minRate,
        address walletId
    )
        public
        returns (uint monsterId)
    {
        return wrapEtheremonContract.catchMonster(
                _kyber,
                _etheremon,
                _classId,
                _name,
                token,
                tokenQty,
                maxDestQty,
                minRate,
                walletId
            );
    }
}