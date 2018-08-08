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

interface UserRankInterface {
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

    function getNextRank(address _user) external returns (uint);

    function getPreSaleRank(address owner, uint _index) external;

    function getRank(address owner, uint _index) external;
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

    mapping(bytes4 => bool) allowedFuncs;

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


contract CandyLandInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);

    function mint(address _to, uint256 _amount) public returns (bool);

    function MAX_SUPPLY() external view returns (uint);
}

interface DividendManagerInterface {
    function payDividend() external payable;
}
//TODO marketplace
contract CandyLandSale is LandAccessControl, CanReceiveApproval {
    using SafeMath for uint256;

    UserRankInterface public userRank;
    ERC20 public candyToken;
    CandyLandInterface public candyLand;

    event FundsTransferred(address dividendManager, uint value);
    event TokensTransferred(address wallet, uint value);
    event BuyLand(address indexed owner, uint count);


    function CandyLandSale(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
        allowedFuncs[bytes4(keccak256("_receiveBuyLandForCandy(address,uint256)"))] = true;
    }


    function init() onlyLandManagement whenPaused external {
        userRank = UserRankInterface(landManagement.userRankAddress());
        candyToken = ERC20(landManagement.candyToken());
        candyLand = CandyLandInterface(landManagement.candyLandAddress());
    }
    
    function() public payable {
        buyLandForEth();
    }

    function buyLandForEth() onlyWhileEthSaleOpen public payable {
        require(candyLand.totalSupply() <= candyLand.MAX_SUPPLY());
        //MAX_SUPPLY проверяется так же в _mint
        uint landPriceWei = landManagement.landPriceWei();
        require(msg.value >= landPriceWei);

        uint weiAmount = msg.value;
        uint landCount = 0;
        uint _landAmount = 0;
        uint userRankIndex = userRank.getUserRank(msg.sender);
        uint ranksCount = userRank.ranksCount();

        for (uint i = userRankIndex; i <= ranksCount && weiAmount >= landPriceWei; i++) {

            uint userLandLimit = userRank.getRankLandLimit(i).sub(candyLand.balanceOf(msg.sender)).sub(_landAmount);
            landCount = weiAmount.div(landPriceWei);

            if (landCount <= userLandLimit) {

                _landAmount = _landAmount.add(landCount);
                weiAmount = weiAmount.sub(landCount.mul(landPriceWei));
                break;

            } else {
                /*
                  Заведомо больше чем лимит, поэтому забираем весь лимит и если это не последнний ранг и есть
                  деньги на следубщий покупаем его и переходим на новый шаг.
                */
                _landAmount = _landAmount.add(userLandLimit);
                weiAmount = weiAmount.sub(userLandLimit.mul(landPriceWei));

                uint nextPrice = (i == 0 && landManagement.firstRankForFree()) ? 0 : userRank.getRankPriceEth(i + 1);

                if (i == ranksCount || weiAmount < nextPrice) {
                    break;
                }

                userRank.getNextRank(msg.sender);
                weiAmount = weiAmount.sub(nextPrice);
            }

        }

        require(_landAmount > 0);
        candyLand.mint(msg.sender, _landAmount);

        emit BuyLand(msg.sender, _landAmount);

        if (weiAmount > 0) {
            msg.sender.transfer(weiAmount);
        }

    }


    function buyLandForCandy(uint _count) external {
        _buyLandForCandy(msg.sender, _count);
    }

    function _receiveBuyLandForCandy(address _owner, uint _count) onlySelf onlyPayloadSize(2) public {
        _buyLandForCandy(_owner, _count);
    }


    function findRankByCount(uint _rank, uint _totalRanks, uint _balance, uint _count) internal view returns (uint, uint) {
        uint landLimit = userRank.getRankLandLimit(_rank).sub(_balance);
        if (_count > landLimit && _rank < _totalRanks) {
            return findRankByCount(_rank + 1, _totalRanks, _balance, _count);
        }
        return (_rank, landLimit);
    }

    function getBuyLandInfo(address _owner, uint _count) public view returns (uint, uint, uint){
        uint rank = userRank.getUserRank(_owner);
        uint neededRank;
        uint landLimit;
        uint totalPrice;
        (neededRank, landLimit) = findRankByCount(
            rank,
            userRank.ranksCount(),
            candyLand.balanceOf(_owner),
            _count
        );

        uint landPriceCandy = landManagement.landPriceCandy();

        if (_count > landLimit) {
            _count = landLimit;
        }
        require(_count > 0);

        if (rank < neededRank) {
            totalPrice = userRank.getIndividualPrice(_owner, neededRank);
            if (rank == 0 && landManagement.firstRankForFree()) {
                totalPrice = totalPrice.sub(userRank.getRankPriceCandy(1));
            }
        }
        totalPrice = totalPrice.add(_count.mul(landPriceCandy));

        return (rank, neededRank, totalPrice);
    }

    function _buyLandForCandy(address _owner, uint _count) internal {
        require(_count > 0);
        require(candyLand.totalSupply().add(_count) <= candyLand.MAX_SUPPLY());
        uint rank;
        uint neededRank;
        uint totalPrice;

        (rank, neededRank, totalPrice) = getBuyLandInfo(_owner, _count);
        require(candyToken.transferFrom(_owner, this, totalPrice));
        if (rank < neededRank) {
            userRank.getRank(_owner, neededRank);
        }
        candyLand.mint(_owner, _count);
        emit BuyLand(_owner, _count);
    }

    function createPresale(address _owner, uint _count, uint _rankIndex) onlyManager whilePresaleOpen public {
        require(candyLand.totalSupply().add(_count) <= candyLand.MAX_SUPPLY());
        userRank.getRank(_owner, _rankIndex);
        candyLand.mint(_owner, _count);
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(landManagement.walletAddress(), candyToken.balanceOf(this));
        emit TokensTransferred(landManagement.walletAddress(), candyToken.balanceOf(this));
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(landManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(landManagement.dividendManagerAddress(), _value);
    }


    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        //require(_token == landManagement.candyToken());
        require(msg.sender == address(candyToken));
        require(allowedFuncs[bytesToBytes4(_extraData)]);
        require(address(this).call(_extraData));
        emit ReceiveApproval(_from, _value, _token);
    }
}