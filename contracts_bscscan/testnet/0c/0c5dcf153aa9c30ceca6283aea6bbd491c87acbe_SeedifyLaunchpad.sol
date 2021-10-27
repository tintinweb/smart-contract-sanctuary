/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

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

    function allowance(address owner, address spender)external
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract SeedifyLaunchpad is Ownable {
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
    
        // PAUSABILITY DATA
    bool public paused = false;
    
    //modifier
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

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
        uint256 _totalUsers
    ) public {
        name = _name;
        maxCap = _maxCap;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        noOfTiers = _noOfTiers;
        projectOwner = _projectOwner;
        tokenAddress = _tokenAddress;
        ERC20Interface = IERC20(tokenAddress);
        totalUsers = _totalUsers;
    }
    
    function updateStartTime(uint newsaleStart) public onlyOwner whenNotPaused {
        saleStart = newsaleStart;
    } 
    
    function updateEndTime(uint newSaleEnd) public onlyOwner whenNotPaused {
        saleEnd = newSaleEnd;
    } 
    
    function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
    }

    function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
    }

    function updateTier(
        uint256 _tier,
        uint256 _maxTierCap,
        uint256 _minUserCap,
        uint256 _maxUserCap,
        uint256 _tierUsers
    ) external onlyOwner whenNotPaused {
        require(_tier > 0 && _tier <= noOfTiers, "Invalid tier number");
        require(_maxTierCap > 0, "Invalid max tier cap amount");
        require(_maxUserCap > 0, "Invalid max user cap amount");
        require(_tierUsers > 0, "Zero users in tier");
        tierDetails[_tier].maxTierCap = _maxTierCap;
        tierDetails[_tier].minUserCap = _minUserCap;
        tierDetails[_tier].maxUserCap = _maxUserCap;
        tierDetails[_tier].users = _tierUsers;
    }

    function updateTiers(
        uint256[] memory _tier,
        uint256[] memory _maxTierCap,
        uint256[] memory _minUserCap,
        uint256[] memory _maxUserCap,
        uint256[] memory _tierUsers
    ) external onlyOwner whenNotPaused {
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
        whenNotPaused
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