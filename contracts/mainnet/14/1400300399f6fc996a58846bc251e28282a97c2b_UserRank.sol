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


contract UserRank is LandAccessControl, CanReceiveApproval {
    using SafeMath for uint256;

    ERC20 public candyToken;

    struct Rank{
        uint landLimit;
        uint priceCandy;
        uint priceEth;
        string title;
    }

    mapping (uint => Rank) public ranks;
    uint public ranksCount = 0;

    mapping (address => uint) public userRanks;

    event TokensTransferred(address wallet, uint value);
    event NewRankAdded(uint index, uint _landLimit, string _title, uint _priceCandy, uint _priceEth);
    event RankChange(uint index, uint priceCandy, uint priceEth);
    event BuyNextRank(address indexed owner, uint index);
    event BuyRank(address indexed owner, uint index);



    function UserRank(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {

        allowedFuncs[bytes4(keccak256("_receiveBuyNextRank(address)"))] = true;
        allowedFuncs[bytes4(keccak256("_receiveBuyRank(address,uint256)"))] = true;
        //3350000000000000 for candy

        addRank(1,   36000000000000000000,   120600000000000000,"Cryptolord");
        addRank(5,   144000000000000000000,  482400000000000000,"Forklord");
        addRank(10,  180000000000000000000,  603000000000000000,"Decentralord");
        addRank(20,  360000000000000000000,  1206000000000000000,"Technomaster");
        addRank(50,  1080000000000000000000, 3618000000000000000,"Bitmaster");
        addRank(100, 1800000000000000000000, 6030000000000000000,"Megamaster");
        addRank(200, 3600000000000000000000, 12060000000000000000,"Cyberduke");
        addRank(400, 7200000000000000000000, 24120000000000000000,"Nanoprince");
        addRank(650, 9000000000000000000000, 30150000000000000000,"Hyperprince");
        addRank(1000,12600000000000000000000,42210000000000000000,"Ethercaesar");


    }

    function init() onlyLandManagement whenPaused external {
        candyToken = ERC20(landManagement.candyToken());
    }



    function addRank(uint _landLimit, uint _priceCandy, uint _priceEth, string _title) onlyOwner public  {
        //стоимость добавляемого должна быть не ниже предыдущего
        require(ranks[ranksCount].priceCandy <= _priceCandy && ranks[ranksCount].priceEth <= _priceEth);
        ranksCount++;
        Rank storage r = ranks[ranksCount];

        r.landLimit = _landLimit;
        r.priceCandy = _priceCandy;
        r.priceEth = _priceEth;
        r.title = _title;
        emit NewRankAdded(ranksCount, _landLimit,_title,_priceCandy,_priceEth);
    }


    function editRank(uint _index, uint _priceCandy, uint _priceEth) onlyManager public  {
        require(_index > 0 && _index <= ranksCount);
        if (_index > 1) {
            require(ranks[_index - 1].priceCandy <= _priceCandy && ranks[_index - 1].priceEth <= _priceEth);
        }
        if (_index < ranksCount) {
            require(ranks[_index + 1].priceCandy >= _priceCandy && ranks[_index + 1].priceEth >= _priceEth);
        }

        Rank storage r = ranks[_index];
        r.priceCandy = _priceCandy;
        r.priceEth = _priceEth;
        emit RankChange(_index, _priceCandy, _priceEth);
    }

    function buyNextRank() public {
        _buyNextRank(msg.sender);
    }

    function _receiveBuyNextRank(address _beneficiary) onlySelf onlyPayloadSize(1) public {
        _buyNextRank(_beneficiary);
    }

    function buyRank(uint _index) public {
        _buyRank(msg.sender, _index);
    }

    function _receiveBuyRank(address _beneficiary, uint _index) onlySelf onlyPayloadSize(2) public {
        _buyRank(_beneficiary, _index);
    }


    function _buyNextRank(address _beneficiary) internal {
        uint _index = userRanks[_beneficiary] + 1;
        require(_index <= ranksCount);

        require(candyToken.transferFrom(_beneficiary, this, ranks[_index].priceCandy));
        userRanks[_beneficiary] = _index;
        emit BuyNextRank(_beneficiary, _index);
    }


    function _buyRank(address _beneficiary, uint _index) internal {
        require(_index <= ranksCount);
        require(userRanks[_beneficiary] < _index);

        uint fullPrice = _getPrice(userRanks[_beneficiary], _index);

        require(candyToken.transferFrom(_beneficiary, this, fullPrice));
        userRanks[_beneficiary] = _index;
        emit BuyRank(_beneficiary, _index);
    }


    function getPreSaleRank(address _user, uint _index) onlyManager whilePresaleOpen public {
        require(_index <= ranksCount);
        require(userRanks[_user] < _index);
        userRanks[_user] = _index;
        emit BuyRank(_user, _index);
    }



    function getNextRank(address _user) onlyUnicornContract public returns (uint) {
        uint _index = userRanks[_user] + 1;
        require(_index <= ranksCount);
        userRanks[_user] = _index;
        return _index;
        emit BuyNextRank(msg.sender, _index);
    }


    function getRank(address _user, uint _index) onlyUnicornContract public {
        require(_index <= ranksCount);
        require(userRanks[_user] <= _index);
        userRanks[_user] = _index;
        emit BuyRank(_user, _index);
    }


    function _getPrice(uint _userRank, uint _index) private view returns (uint) {
        uint fullPrice = 0;

        for(uint i = _userRank+1; i <= _index; i++)
        {
            fullPrice = fullPrice.add(ranks[i].priceCandy);
        }

        return fullPrice;
    }


    function getIndividualPrice(address _user, uint _index) public view returns (uint) {
        require(_index <= ranksCount);
        require(userRanks[_user] < _index);

        return _getPrice(userRanks[_user], _index);
    }


    function getRankPriceCandy(uint _index) public view returns (uint) {
        return ranks[_index].priceCandy;
    }


    function getRankPriceEth(uint _index) public view returns (uint) {
        return ranks[_index].priceEth;
    }

    function getRankLandLimit(uint _index) public view returns (uint) {
        return ranks[_index].landLimit;
    }


    function getRankTitle(uint _index) public view returns (string) {
        return ranks[_index].title;
    }

    function getUserRank(address _user) public view returns (uint) {
        return userRanks[_user];
    }

    function getUserLandLimit(address _user) public view returns (uint) {
        return ranks[userRanks[_user]].landLimit;
    }


    function withdrawTokens() public onlyManager  {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(landManagement.walletAddress(), candyToken.balanceOf(this));
        emit TokensTransferred(landManagement.walletAddress(), candyToken.balanceOf(this));
    }


    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        //require(_token == landManagement.candyToken());
        require(msg.sender == address(candyToken));
        require(allowedFuncs[bytesToBytes4(_extraData)]);
        require(address(this).call(_extraData));
        emit ReceiveApproval(_from, _value, _token);
    }

}