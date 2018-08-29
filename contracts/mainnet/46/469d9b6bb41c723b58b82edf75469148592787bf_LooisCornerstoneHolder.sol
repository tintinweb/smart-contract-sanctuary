pragma solidity ^0.4.24;

contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable {
    address public owner;
    address[] public managers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor() public {
        owner = msg.sender;
        managers.push(msg.sender);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() {
        require(isManager(msg.sender));
        _;
    }

    function isManager(address manager) view internal returns (bool ok) {
        for (uint i = 0; i < managers.length; i++) {
            if (managers[i] == manager) {
                return true;
            }
        }
        return false;
    }

    function addManager(address manager) onlyOwner public {
        require(manager != 0x0);
        require(!isManager(manager));
        managers.push(manager);
    }

    function removeManager(address manager) onlyOwner public {
        require(manager != 0x0);
        require(isManager(manager));
        for (uint i = 0; i < managers.length; i++) {
            if (managers[i] == manager) {
                managers[i] = managers[managers.length - 1];
                break;
            }
        }
        managers.length -= 1;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) onlyOwner public returns (bool success) {
        require(newOwner != 0x0);
        removeManager(owner);
        addManager(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }
}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

    constructor() public payable { }

    /**
     * @dev Transfers the current balance to the owner and terminates the contract.
     */
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
    }
}

contract LooisCornerstoneHolder is Ownable, Destructible {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;
    bool public tokenInitialized;
    bool public stopInvest;
    uint256 public totalSupply;
    uint256 public restSupply;
    uint256 public releaseTime;
    uint8 public releasedRoundCount;

    // release percent of each round
    uint8 public firstRoundPercent;
    uint8 public secondRoundPercent;
    uint8 public thirdRoundPercent;
    uint8 public fourthRoundPercent;

    address[] public investors;
    mapping(address => uint256) public investorAmount;
    mapping(address => uint256) public releasedAmount;

    event Release(address indexed _investor, uint256 indexed _value);

    modifier onlyTokenInitialized() {
        require(tokenInitialized);
        _;
    }

    constructor(uint8 _firstRoundPercent, uint8 _secondRoundPercent, uint8 _thirdRoundPercent, uint8 _fourthRoundPercent) public {
        require(_firstRoundPercent + _secondRoundPercent + _thirdRoundPercent + _fourthRoundPercent == 100);

        firstRoundPercent = _firstRoundPercent;
        secondRoundPercent = _secondRoundPercent;
        thirdRoundPercent = _thirdRoundPercent;
        fourthRoundPercent = _fourthRoundPercent;
        tokenInitialized = false;
        stopInvest = false;
        releasedRoundCount = 0;
    }

    function initTokenAndReleaseTime(ERC20 _token, uint256 _releaseTime) onlyOwner public {
        require(!tokenInitialized);
        require(_releaseTime > block.timestamp);

        releaseTime = _releaseTime;
        token = _token;
        totalSupply = token.balanceOf(this);
        restSupply = totalSupply;
        tokenInitialized = true;
    }

    function isInvestor(address _investor) view internal returns (bool ok) {
        for (uint i = 0; i < investors.length; i++) {
            if (investors[i] == _investor) {
                return true;
            }
        }
        return false;
    }

    function addInvestor(address _investor, uint256 _value) onlyManager onlyTokenInitialized public {
        require(_investor != 0x0);
        require(_value > 0);
        require(!stopInvest);

        uint256 value = 10**18 * _value;
        if (!isInvestor(_investor)) {
            require(restSupply > value);

            investors.push(_investor);
        } else {
            require(restSupply + investorAmount[_investor] > value);

            restSupply = restSupply.add(investorAmount[_investor]);
        }
        restSupply = restSupply.sub(value);
        investorAmount[_investor] = value;
    }

    function removeInvestor(address _investor) onlyManager onlyTokenInitialized public {
        require(_investor != 0x0);
        require(!stopInvest);
        require(isInvestor(_investor));

        for (uint i = 0; i < investors.length; i++) {
            if (investors[i] == _investor) {
                investors[i] = investors[investors.length - 1];
                restSupply = restSupply.add(investorAmount[_investor]);
                investorAmount[_investor] = 0;
                break;
            }
        }
        investors.length -= 1;
    }

    function release() onlyManager onlyTokenInitialized public {
        require(releasedRoundCount <= 3);
        require(block.timestamp >= releaseTime);

        uint8 releasePercent;
        if (releasedRoundCount == 0) {
            releasePercent = firstRoundPercent;
        } else if (releasedRoundCount == 1) {
            releasePercent = secondRoundPercent;
        } else if (releasedRoundCount == 2) {
            releasePercent = thirdRoundPercent;
        } else {
            releasePercent = fourthRoundPercent;
        }

        for (uint8 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 amount = investorAmount[investor];
            if (amount > 0) {
                uint256 releaseAmount = amount.div(100).mul(releasePercent);
                if (releasedAmount[investor].add(releaseAmount) > amount) {
                    releaseAmount = amount.sub(releasedAmount[investor]);
                }
                token.safeTransfer(investor, releaseAmount);
                releasedAmount[investor] = releasedAmount[investor].add(releaseAmount);
                emit Release(investor, releaseAmount);
            }
        }
        // Next release time is 30 days later.
        releaseTime = releaseTime.add(60 * 60 * 24 * 30);
        releasedRoundCount = releasedRoundCount + 1;
        stopInvest = true;
    }

    // if the balance of this contract is not empty, release all balance to the owner
    function releaseRestBalance() onlyOwner onlyTokenInitialized public {
        require(releasedRoundCount > 3);
        uint256 balance = token.balanceOf(this);
        require(balance > 0);

        token.safeTransfer(owner, balance);
        emit Release(owner, balance);
    }

    // if the balance of this contract is not empty, release all balance to a recipient
    function releaseRestBalanceAndSend(address _recipient) onlyOwner onlyTokenInitialized public {
        require(_recipient != 0x0);
        require(releasedRoundCount > 3);
        uint256 balance = token.balanceOf(this);
        require(balance > 0);

        token.safeTransfer(_recipient, balance);
        emit Release(_recipient, balance);
    }
}