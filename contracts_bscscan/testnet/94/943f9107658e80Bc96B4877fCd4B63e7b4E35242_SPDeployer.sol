pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

import "./PreSale.sol";
import "./Interfaces/IPreSale.sol";

contract SPDeployer {
    using SafeMath for uint256;
    address public admin;
    address public coin;

    mapping(address => bool) public isPreSaleExist;
    mapping(address => mapping(uint8 => address)) public getPreSale;
    mapping(address => uint8) public preSaleCount;
    address[] public allPreSales;

    modifier onlyAdmin() {
        require(msg.sender == admin, "SnowPlow: Not an admin");
        _;
    }

    event PreSaleCreated(
        address indexed _user,
        address indexed _preSale,
        uint256 indexed _length
    );

    constructor() {
        admin = msg.sender;
        coin = 0xEF5476A98aE30eb71241780ED83BF53ca00C2f5c;
    }

    receive() external payable {}

    // 0- _tokenPrice
    // 1- _hardCap
    // 2- _presaleStratTime
    // 3- _presaleEndTime
    // 5- _maxAmount1
    // 6- _maxAmount2
    // 7- _maxAmount3
    // 8- _maxAmount4

    function createPreSale(uint256[] memory _preSaleData)
        external onlyAdmin()
        returns (address preSaleContract)
    {
        require(address(msg.sender) != address(0), "SnowPlow: ZERO_ADDRESS");

        bytes memory bytecode = type(preSale).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, coin, preSaleCount[msg.sender]));

        assembly {
            preSaleContract := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        
        IPreSale(preSaleContract).initialize(
            admin,
            coin,
            _preSaleData
        );

        getPreSale[address(msg.sender)][
            ++preSaleCount[msg.sender]
        ] = preSaleContract;
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(
            msg.sender,
            preSaleContract,
            allPreSales.length
        );
    }

    function setAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setCoinAddress(address _coin) external onlyAdmin {
        coin = _coin;
    }

    function getAllPreSalesLength() external view returns (uint256) {
        return allPreSales.length;
    }

}

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

import "./Interfaces/IBEP20.sol";
import "./Libraries/SafeMath.sol";

contract preSale {
    using SafeMath for uint256;

    address public admin;
    address public deployer;
    IBEP20 public token;
    IBEP20 public coin;

    uint256[4] public distributionPercentages;
    uint256 public tokenPrice;
    uint256 private secretKey;
    uint256[4] public maxAmount;
    uint256 public hardCap;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleTokens;
    uint256 public amountRaised;
    uint256 public soldTokens;
    uint256 public totalUser;
    uint256 public precision;
    uint256 public claimStartTime;
    uint256 public claimLockTime;

    mapping(address => uint256) internal tokenBalance;
    mapping(address => uint256) internal coinBalance;
    mapping(address => uint256) public claimedCount;
    mapping(address => uint256) public claimTime;

    bool public allow;
    bool public canClaim;

    modifier onlyAdmin() {
        require(msg.sender == admin, "SnowPlow: Not an admin");
        _;
    }

    modifier allowed() {
        require(allow == true, "SnowPlow: Not allowed");
        _;
    }

    event tokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountcoin
    );

    event tokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event PreSaleEnded(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        allow = true;
        precision = 1000000000;
        distributionPercentages = [10, 10, 40, 40];
        claimLockTime = 60 days;
    }

    // 0- _tokenPrice
    // 1- _hardCap
    // 2- _presaleStratTime
    // 3- _presaleEndTime
    // 4- _secretKey
    // 5- _maxAmount1
    // 6- _maxAmount2
    // 7- _maxAmount3
    // 8- _maxAmount4

    // called once by the deployer contract at time of deployment
    function initialize(
        address _admin,
        address _coin,
        uint256[] memory _preSaleData
    ) external {
        require(msg.sender == deployer, "SnowPlow: FORBIDDEN"); // sufficient check
        admin = _admin;
        coin = IBEP20(_coin);
        tokenPrice = _preSaleData[0];
        hardCap = _preSaleData[1];
        preSaleStartTime = _preSaleData[2];
        preSaleEndTime = _preSaleData[3];
        secretKey = _preSaleData[4];
        maxAmount[0] = _preSaleData[5];
        maxAmount[1] = _preSaleData[6];
        maxAmount[2] = _preSaleData[7];
        maxAmount[3] = _preSaleData[8];
        preSaleTokens = coinToToken(hardCap);
    }

    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _coinAmount, uint8 _tier, uint256 _secretKey) public allowed {
        require(secretKey == _secretKey, "SnowPlow: Less than min Amount");
        require(block.timestamp >= preSaleStartTime, "SnowPlow: Presale not started yet"); // time check
        require(block.timestamp < preSaleEndTime, "SnowPlow: Presale time over"); // time check
        require(
            amountRaised.add(_coinAmount) <= hardCap,
            "SnowPlow: Hardcap reached"
        );

        uint256 numberOfTokens = coinToToken(_coinAmount);
        uint256 maxBuy = coinToToken(maxAmount[_tier]);

        require(_coinAmount <= maxAmount[_tier], "SnowPlow: Greater than max Amount");
        require(
            numberOfTokens.add(tokenBalance[msg.sender]) <= maxBuy,
            "SnowPlow: Amount exceeded max limit"
        );

        if (tokenBalance[msg.sender] == 0) {
            totalUser++;
        }
        
        coin.transferFrom(msg.sender, address(this), _coinAmount);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(_coinAmount);
        soldTokens = soldTokens.add(numberOfTokens);
        amountRaised = amountRaised.add(_coinAmount);

        emit tokenBought(msg.sender, numberOfTokens, _coinAmount);
    }

    function claim() public allowed {
        require(canClaim == true, "SnowPlow: Distribution not started yet");
        require(claimedCount[msg.sender] < 4, "SnowPlow: Already Claimed.");
        if(claimTime[msg.sender] == 0) {
            claimTime[msg.sender] = claimStartTime;
        }

        uint256 numberOfTokens = tokenBalance[msg.sender].mul(10**(token.decimals())).div(precision);
        require(numberOfTokens > 0, "SnowPlow: Not enough balance");
        require(block.timestamp > claimTime[msg.sender] + claimLockTime, "SnowPlow: wait for next claim.");

        uint256 dividends = block.timestamp.sub(claimTime[msg.sender]).div(claimLockTime);
        
        uint256 totalTokens;
        for(uint256 i = 0; i < dividends; i++) {
            if(claimedCount[msg.sender] < 4) {
                totalTokens = totalTokens.add(numberOfTokens.mul(distributionPercentages[claimedCount[msg.sender]]).div(100));
                claimedCount[msg.sender]++;
            } 
        }

        token.transfer(msg.sender, totalTokens);
        // tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(totalTokens);
        claimTime[msg.sender] = block.timestamp;
        emit tokenClaimed(msg.sender, totalTokens);
    }

    function endPreSale() public onlyAdmin {

        coin.transfer(admin, amountRaised);
        preSaleEndTime = block.timestamp;

        emit PreSaleEnded(admin, amountRaised);
    }

    function setTokenForDistribution(IBEP20 _token, bool _state, uint256 _amount) external onlyAdmin {
        token = _token;
        canClaim = _state;
        claimStartTime = block.timestamp;
        _token.transferFrom(admin, address(this), _amount);
    }

    // to check number of token for buying
    function coinToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(precision).div(10**(coin.decimals()));
        return numberOfTokens;
    }

    // to check contribution
    function userContribution(address _user) public view returns (uint256) {
        return coinBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns (uint256) {
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin {
        allow = _enable;
    }

    // to remove tokens form contract in case some one sent tokens by mistake
    function removeStuckToken(IBEP20 _token, uint256 _amount) external onlyAdmin {
        _token.transfer(admin, _amount);
    }

    // to remove tokens form contract in case some one sent coins by mistake
    function removeStuckCoin(uint256 _amount) external onlyAdmin {
        payable(admin).transfer(_amount);
    }

    function getContractcoinBalance() public view returns (uint256) {
        return coin.balanceOf(address(this));
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

}

pragma solidity ^0.8.7;

//  SPDX-License-Identifier: MIT

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IPreSale{

    function initialize(
        address _admin,
        address coin,
        uint256[] memory _preSaleData
    ) external ;

    
}

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}