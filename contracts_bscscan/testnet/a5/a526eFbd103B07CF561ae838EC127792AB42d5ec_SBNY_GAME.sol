/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface DateAPI {
    function date() external view returns (string memory);
}

contract SBNY_GAME {
    mapping (address => mapping (string  => uint256)) private dailyClaims;
    address private owner;
    address private baseToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private dateApi = 0xE2c47AEB7998eB7150D7A077e0e20870B7f08615;
    uint256 private dailyMaxClaim = 2;
    uint256 private minReward = 1;
    uint256 private maxReward = 10;

    modifier onlyOwner() {
        require(owner == msg.sender, 'you are not owner');
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function withdrawToken(address tokenContract, uint256 amount) public virtual onlyOwner {
        IERC20 _tokenContract = IERC20(tokenContract);
        _tokenContract.transfer(msg.sender, amount);
    }

    function setData(address _baseToken, uint256 _dailyMaxClaim, uint256 _minReward, uint256 _maxReward) public virtual onlyOwner {
        baseToken = _baseToken;
        dailyMaxClaim = _dailyMaxClaim;
        minReward = _minReward;
        maxReward = _maxReward;
    }

    function date() public view returns (string memory) {
        DateAPI a = DateAPI(dateApi);
        return a.date();
    }

    function getDailyClaimLimit(address user) public view returns (uint256) {
        return dailyMaxClaim - dailyClaims[user][date()];
    }

    function claim(uint256 amount) public virtual {
        uint256 addressLimit = getDailyClaimLimit(msg.sender);
        require(addressLimit > 0, 'daily limit reached');
        require(amount >= minReward && amount <= maxReward, 'max/min reward');

        IERC20 _tokenContract = IERC20(baseToken);
        _tokenContract.transfer(msg.sender, amount * 10**18);

        dailyClaims[msg.sender][date()] += 1;
    }
}