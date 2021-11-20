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

    uint256 public tokenPrice;
    uint256 public minAmount;
    uint256[4] public maxAmount;
    uint256 public hardCap;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleTokens;
    uint256 public amountRaised;
    uint256 public soldTokens;
    uint256 public totalUser;
    uint256 public precision;

    mapping(address => uint256) internal tokenBalance;
    mapping(address => uint256) internal coinBalance;

    bool public allow;
    bool public canClaim;

    modifier onlyAdmin() {
        require(msg.sender == admin, "BULK: Not an admin");
        _;
    }

    modifier allowed() {
        require(allow == true, "BULK: Not allowed");
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
    }

    // 0- _tokenPrice
    // 1- _hardCap
    // 2- _presaleStratTime
    // 3- _presaleEndTime
    // 4- _minAmount
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
        require(msg.sender == deployer, "BULK: FORBIDDEN"); // sufficient check
        admin = _admin;
        coin = IBEP20(_coin);
        tokenPrice = _preSaleData[0];
        hardCap = _preSaleData[1];
        preSaleStartTime = _preSaleData[2];
        preSaleEndTime = _preSaleData[3];
        minAmount = _preSaleData[4];
        maxAmount[0] = _preSaleData[5];
        maxAmount[1] = _preSaleData[6];
        maxAmount[2] = _preSaleData[7];
        maxAmount[3] = _preSaleData[8];
        preSaleTokens = coinToToken(hardCap);
    }

    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _coinAmount, uint8 _tier) public allowed {
        require(block.timestamp >= preSaleStartTime, "BULK: Presale not started yet"); // time check
        require(block.timestamp < preSaleEndTime, "BULK: Presale time over"); // time check
        require(
            amountRaised.add(_coinAmount) <= hardCap,
            "BULK: Hardcap reached"
        );

        uint256 numberOfTokens = coinToToken(_coinAmount);
        uint256 maxBuy = coinToToken(maxAmount[_tier]);

        require(_coinAmount >= minAmount, "BULK: Less than min Amount");
        require(_coinAmount <= maxAmount[_tier], "BULK: Greater than max Amount");
        require(
            numberOfTokens.add(tokenBalance[msg.sender]) <= maxBuy,
            "BULK: Amount exceeded max limit"
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
        require(canClaim == true, "BULK: Distribution not started yet");

        uint256 numberOfTokens = tokenBalance[msg.sender].mul(10**(token.decimals())).div(precision);
        require(numberOfTokens > 0, "BULK: Not enough balance");

        token.transfer(msg.sender, numberOfTokens);
        tokenBalance[msg.sender] = 0;

        emit tokenClaimed(msg.sender, numberOfTokens);
    }

    function endPreSale() public onlyAdmin {

        coin.transfer(admin, amountRaised);
        preSaleEndTime = block.timestamp;

        emit PreSaleEnded(admin, amountRaised);
    }

    function setTokenForDistribution(address _token, bool _state) external onlyAdmin {
        token = IBEP20(_token);
        canClaim = _state;
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