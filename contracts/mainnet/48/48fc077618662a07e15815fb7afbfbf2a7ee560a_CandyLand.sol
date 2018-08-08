pragma solidity 0.4.21;

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

contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface LandManagementInterface {
    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    //    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function megaCandyToken() external view returns (address);
    function userRankAddress() external view returns (address);
    function candyLandAddress() external view returns (address);
    function candyLandSaleAddress() external view returns (address);

    function isUnicornContract(address _unicornContractAddress) external view returns (bool);

    function paused() external view returns (bool);
    function presaleOpen() external view returns (bool);
    function firstRankForFree() external view returns (bool);

    function ethLandSaleOpen() external view returns (bool);

    function landPriceWei() external view returns (uint);
    function landPriceCandy() external view returns (uint);

    function registerInit(address _contract) external;
}

interface UserRankInterface  {
    function buyNextRank() external;
    function buyRank(uint _index) external;
    function getIndividualPrice(address _user, uint _index) external view returns (uint);
    function getRankPriceEth(uint _index) external view returns (uint);
    function getRankPriceCandy(uint _index) external view returns (uint);
    function getRankLandLimit(uint _index) external view returns (uint);
    function getRankTitle(uint _index) external view returns (string);
    function getUserRank(address _user) external view returns (uint);
    function getUserLandLimit(address _user) external view returns (uint);
    function ranksCount() external view returns (uint);
    function getNextRank(address _user)  external returns (uint);
    function getPreSaleRank(address owner, uint _index) external;
    function getRank(address owner, uint _index) external;
}

contract MegaCandyInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burn(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}


contract LandAccessControl {

    LandManagementInterface public landManagement;

    function LandAccessControl(address _landManagementAddress) public {
        landManagement = LandManagementInterface(_landManagementAddress);
        landManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == landManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == landManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == landManagement.communityAddress());
        _;
    }

    modifier whenNotPaused() {
        require(!landManagement.paused());
        _;
    }

    modifier whenPaused {
        require(landManagement.paused());
        _;
    }

    modifier onlyWhileEthSaleOpen {
        require(landManagement.ethLandSaleOpen());
        _;
    }

    modifier onlyLandManagement() {
        require(msg.sender == address(landManagement));
        _;
    }

    modifier onlyUnicornContract() {
        require(landManagement.isUnicornContract(msg.sender));
        _;
    }

    modifier onlyCandyLand() {
        require(msg.sender == address(landManagement.candyLandAddress()));
        _;
    }


    modifier whilePresaleOpen() {
        require(landManagement.presaleOpen());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return landManagement.paused();
    }
}


contract CanReceiveApproval {
    event ReceiveApproval(address from, uint256 value, address token);

    mapping (bytes4 => bool) allowedFuncs;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }

    modifier onlySelf(){
        require(msg.sender == address(this));
        _;
    }


    function bytesToBytes4(bytes b) internal pure returns (bytes4 out) {
        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i << 3);
        }
    }

}


contract CandyLand is ERC20, LandAccessControl, CanReceiveApproval {
    using SafeMath for uint256;

    UserRankInterface public userRank;
    MegaCandyInterface public megaCandy;
    ERC20 public candyToken;

    struct Gardener {
        uint period;
        uint price;
        bool exists;
    }

    struct Garden {
        uint count;
        uint startTime;
        address owner;
        uint gardenerId;
        uint lastCropTime;
        uint plantationIndex;
        uint ownerPlantationIndex;
    }

    string public constant name = "Unicorn Land";
    string public constant symbol = "Land";
    uint8 public constant decimals = 0;

    uint256 totalSupply_;
    uint256 public MAX_SUPPLY = 30000;

    uint public constant plantedTime = 1 hours;
    uint public constant plantedRate = 1 ether;
    //uint public constant priceRate = 1 ether;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) planted;

    mapping(uint => Gardener) public gardeners;
    // Mapping from garden ID to Garde struct
    mapping(uint => Garden) public gardens;

    // garden index => gardenId
    mapping(uint => uint) public plantation;
    uint public plantationSize = 0;

    //user plantations
    // owner => array (index => gardenId)
    mapping(address => mapping(uint => uint)) public ownerPlantation;
    mapping(address => uint) public ownerPlantationSize;


    uint gardenerId = 0;
    uint gardenId = 0;


    event Mint(address indexed to, uint256 amount);
    event MakePlant(address indexed owner, uint gardenId, uint count, uint gardenerId);
    event GetCrop(address indexed owner, uint gardenId, uint  megaCandyCount);
    event NewGardenerAdded(uint gardenerId, uint _period, uint _price);
    event GardenerChange(uint gardenerId, uint _period, uint _price);
    event NewLandLimit(uint newLimit);
    event TokensTransferred(address wallet, uint value);

    function CandyLand(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
        allowedFuncs[bytes4(keccak256("_receiveMakePlant(address,uint256,uint256)"))] = true;

        addGardener(24,   700000000000000000);
        addGardener(120, 3000000000000000000);
        addGardener(240, 5000000000000000000);
        addGardener(720,12000000000000000000);
    }


    function init() onlyLandManagement whenPaused external {
        userRank = UserRankInterface(landManagement.userRankAddress());
        megaCandy = MegaCandyInterface(landManagement.megaCandyToken());
        candyToken = ERC20(landManagement.candyToken());
    }


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender].sub(planted[msg.sender]));
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function plantedOf(address _owner) public view returns (uint256 balance) {
        return planted[_owner];
    }

    function freeLandsOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner].sub(planted[_owner]);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from].sub(planted[_from]));
        require(_value <= allowed[_from][msg.sender]);
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function transferFromSystem(address _from, address _to, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from].sub(planted[_from]));
        //    require(_value <= balances[_from]);
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) onlyUnicornContract public returns (bool) {
        require(totalSupply_.add(_amount) <= MAX_SUPPLY);
        require(balances[_to].add(_amount) <= userRank.getUserLandLimit(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }


    function makePlant(uint _count, uint _gardenerId) public {
        _makePlant(msg.sender, _count, _gardenerId);
    }


    function _receiveMakePlant(address _beneficiary, uint _count, uint _gardenerId) onlySelf onlyPayloadSize(3) public {
        _makePlant(_beneficiary, _count, _gardenerId);
    }


    function _makePlant(address _owner, uint _count, uint _gardenerId) internal {
        require(_count <= balances[_owner].sub(planted[_owner]) && _count > 0);

        //require(candyToken.transferFrom(msg.sender, this, _count.mul(priceRate)));

        if (_gardenerId > 0) {
            require(gardeners[_gardenerId].exists);
            require(candyToken.transferFrom(_owner, this, gardeners[_gardenerId].price.mul(_count)));
        }

        gardens[++gardenId] = Garden({
            count: _count,
            startTime: now,
            owner: _owner,
            gardenerId: _gardenerId,
            lastCropTime: now,
            plantationIndex: plantationSize,
            ownerPlantationIndex: ownerPlantationSize[_owner]
            });

        planted[_owner] = planted[_owner].add(_count);
        //update global plantation list
        plantation[plantationSize++] = gardenId;
        //update user plantation list
        ownerPlantation[_owner][ownerPlantationSize[_owner]++] = gardenId;

        emit MakePlant(_owner, gardenId, _count, gardenerId);
    }


    function getCrop(uint _gardenId) public {
        require(msg.sender == gardens[_gardenId].owner);
        require(now >= gardens[_gardenId].lastCropTime.add(plantedTime));

        uint crop = 0;
        uint cropCount = 1;
        uint remainingCrops = 0;

        if (gardens[_gardenId].gardenerId > 0) {
            uint finishTime = gardens[_gardenId].startTime.add(gardeners[gardens[_gardenId].gardenerId].period);
            //время текущей сбоки урожая
            uint currentCropTime = now < finishTime ? now : finishTime;
            //количество урожаев которое соберем сейчас
            cropCount = currentCropTime.sub(gardens[_gardenId].lastCropTime).div(plantedTime);
            //время последней сборки урожая + время 1 урожая на количество урожаев которое соберем сейчас
            gardens[_gardenId].lastCropTime = gardens[_gardenId].lastCropTime.add(cropCount.mul(plantedTime));
            //количество оставшихся урожаев
            remainingCrops = finishTime.sub(gardens[_gardenId].lastCropTime).div(plantedTime);
        }

        crop = gardens[_gardenId].count.mul(plantedRate).mul(cropCount);
        if (remainingCrops == 0) {
            planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);

            //delete from global plantation list
            gardens[plantation[--plantationSize]].plantationIndex = gardens[_gardenId].plantationIndex;
            plantation[gardens[_gardenId].plantationIndex] = plantation[plantationSize];
            delete plantation[plantationSize];

            //delete from user plantation list
            gardens[ownerPlantation[msg.sender][--ownerPlantationSize[msg.sender]]].ownerPlantationIndex = gardens[_gardenId].ownerPlantationIndex;
            ownerPlantation[msg.sender][gardens[_gardenId].ownerPlantationIndex] = ownerPlantation[msg.sender][ownerPlantationSize[msg.sender]];
            delete ownerPlantation[msg.sender][ownerPlantationSize[msg.sender]];

            delete gardens[_gardenId];

        }

        megaCandy.mint(msg.sender, crop);
        emit GetCrop(msg.sender, _gardenId, crop);
    }


    function addGardener(uint _period, uint _price) onlyOwner public  {
        gardeners[++gardenerId] = Gardener({
            period: _period * 1 hours,
            price: _price,
            exists: true
            });
        emit NewGardenerAdded(gardenerId, _period, _price);
    }


    function editGardener(uint _gardenerId, uint _period, uint _price) onlyOwner public  {
        require(gardeners[_gardenerId].exists);
        Gardener storage g = gardeners[_gardenerId];
        g.period = _period;
        g.price = _price;
        emit GardenerChange(_gardenerId, _period, _price);
    }


    function getUserLandLimit(address _user) public view returns(uint) {
        return userRank.getRankLandLimit(userRank.getUserRank(_user)).sub(balances[_user]);
    }


    function setLandLimit() external onlyCommunity {
        require(totalSupply_ == MAX_SUPPLY);
        MAX_SUPPLY = MAX_SUPPLY.add(1000);
        emit NewLandLimit(MAX_SUPPLY);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }


    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        //require(_token == landManagement.candyToken());
        require(msg.sender == address(candyToken));
        require(allowedFuncs[bytesToBytes4(_extraData)]);
        require(address(this).call(_extraData));
        emit ReceiveApproval(_from, _value, _token);
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(landManagement.walletAddress(), candyToken.balanceOf(this));
        emit TokensTransferred(landManagement.walletAddress(), candyToken.balanceOf(this));
    }

}