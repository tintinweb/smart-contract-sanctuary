/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.9;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract SeedifyLaunchpad is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    uint256 public maxCap;
    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public totalBUSDReceivedInAllTier;
    uint256 public noOfTiers;
    uint256 public totalUsers;
    address public projectOwner;
    address public tokenAddress;
    IERC20 public ERC20Interface;
    uint8 public immutable phaseNo;

    struct Tier {
        uint256 maxTierCap;
        uint256 minUserCap;
        uint256 maxUserCap;
        uint256 amountRaised;
        uint256 users;
    }

    struct user {
        uint256 tier;
        uint256 investedAmount;
    }

    event UserInvestment(
        address indexed user,
        uint256 amount,
        uint8 indexed phase
    );

    mapping(uint256 => Tier) public tierDetails;
    mapping(address => user) public userDetails;

    constructor(
        string memory _name,
        uint256 _maxCap,
        uint256 _saleStart,
        uint256 _saleEnd,
        uint256 _noOfTiers,
        address _projectOwner,
        address _tokenAddress,
        uint256 _totalUsers,
        uint8 _phaseNo
    ) {
        name = _name;
        require(_maxCap > 0, "Zero max cap");
        maxCap = _maxCap;
        require(
            _saleStart > block.timestamp && _saleEnd > _saleStart,
            "Invalid timings"
        );
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        require(_noOfTiers > 0, "Zero tiers");
        noOfTiers = _noOfTiers;
        require(_projectOwner != address(0), "Zero project owner address");
        projectOwner = _projectOwner;
        require(_tokenAddress != address(0), "Zero token address");
        tokenAddress = _tokenAddress;
        ERC20Interface = IERC20(tokenAddress);
        require(_totalUsers > 0, "Zero users");
        totalUsers = _totalUsers;
        phaseNo = _phaseNo;
    }
    function updateMaxCap(uint256 _maxCap) public onlyOwner {
        require(_maxCap > 0, "Zero max cap");
        maxCap = _maxCap;
    }

    function updateStartTime(uint256 newsaleStart) public onlyOwner {
        require(block.timestamp < saleStart, "Sale already started");
        saleStart = newsaleStart;
    }

    function updateEndTime(uint256 newSaleEnd) public onlyOwner {
        require(
            newSaleEnd > saleStart && newSaleEnd > block.timestamp,
            "Sale end can't be less than sale start"
        );
        saleEnd = newSaleEnd;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateTiers(
        uint256[] memory _tier,
        uint256[] memory _maxTierCap,
        uint256[] memory _minUserCap,
        uint256[] memory _maxUserCap,
        uint256[] memory _tierUsers
    ) external onlyOwner {
        require(
            _tier.length == _maxTierCap.length &&
                _maxTierCap.length == _minUserCap.length &&
                _minUserCap.length == _maxUserCap.length &&
                _maxUserCap.length == _tierUsers.length,
            "Lengths mismatch"
        );

        for (uint256 i = 0; i < _tier.length; i++) {
            require(
                _tier[i] > 0 && _tier[i] <= noOfTiers,
                "Invalid tier number"
            );
            require(_maxTierCap[i] > 0, "Invalid max tier cap amount");
            require(_maxUserCap[i] > 0, "Invalid max user cap amount");
            require(_tierUsers[i] > 0, "Zero users in tier");
            tierDetails[_tier[i]] = Tier(
                _maxTierCap[i],
                _minUserCap[i],
                _maxUserCap[i],
                0,
                _tierUsers[i]
            );
        }
    }

    function updateUsers(address[] memory _users, uint256[] memory _tiers)
        external
        onlyOwner
    {
        require(_users.length == _tiers.length, "Array length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            require(_tiers[i] > 0 && _tiers[i] <= noOfTiers, "Invalid tier");
            userDetails[_users[i]].tier = _tiers[i];
        }
    }

    function buyTokens(uint256 amount)
        external
        whenNotPaused
        _hasAllowance(msg.sender, amount)
        returns (bool)
    {
        require(block.timestamp >= saleStart, "Sale not started yet");
        require(block.timestamp <= saleEnd, "Sale Ended");
        require(
            totalBUSDReceivedInAllTier.add(amount) <= maxCap,
            "Exceeds pool max cap"
        );
        uint256 userTier = userDetails[msg.sender].tier;
        require(userTier > 0 && userTier <= noOfTiers, "User not whitelisted");
        uint256 expectedAmount = amount.add(
            userDetails[msg.sender].investedAmount
        );
        require(
            expectedAmount >= tierDetails[userTier].minUserCap,
            "Amount less than user min cap"
        );
        require(
            expectedAmount <= tierDetails[userTier].maxUserCap,
            "Amount greater than user max cap"
        );

        require(
            expectedAmount <= tierDetails[userTier].maxTierCap,
            "Amount greater than the tier max cap"
        );

        totalBUSDReceivedInAllTier = totalBUSDReceivedInAllTier.add(amount);
        tierDetails[userTier].amountRaised = tierDetails[userTier]
            .amountRaised
            .add(amount);
        userDetails[msg.sender].investedAmount = expectedAmount;
        ERC20Interface.safeTransferFrom(msg.sender, projectOwner, amount);
        emit UserInvestment(msg.sender, expectedAmount, phaseNo);
        return true;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        // ERC20Interface = IERC20(tokenAddress);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}