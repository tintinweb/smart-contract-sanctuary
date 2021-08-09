//SourceUnit: PolyFarm.sol

pragma solidity 0.5.10;

// SPDX-License-Identifier: UNLICENSED

/*

 * @dev Provides information about the current execution context, including the

 * sender of the transaction and its data. While these are generally available

 * via msg.sender and msg.data, they should not be accessed in such a direct

 * manner, since when dealing with GSN meta-transactions the account sending and

 * paying for execution may not be the actual sender (as far as an application

 * is concerned).

 *

 * This contract is only required for intermediate, library-like contracts.

 */

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;
    }
}

/**

 * @title TRC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**

 * @title SafeMath

 * @dev Unsigned math operations with safety checks that revert on error

 */

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() internal {
        _owner = _msgSender();

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Leaves the contract without owner. It will not be possible to call

     * `onlyOwner` functions anymore. Can only be called by the current owner.

     *

     * NOTE: Renouncing ownership will leave the contract without an owner,

     * thereby removing any functionality that is only available to the owner.

     */

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract PolyFarm is Ownable {
    using SafeMath for uint256;
    address public wyzthTOKEN;
    address public ULETOKEN;

    struct userInfo {
        uint256 farmedToken;
        uint256 lastUpdated;
        uint256 lockableDays;
        address token;
    }

    uint256 public constant minimumDepositTRX = 100E6;
    address[] public tokens;
    mapping(uint256 => uint256) public allocation;
    mapping(address => userInfo) public users;
    mapping(address => uint256) public minimumtokenDeposit;

    constructor(address wyzth, address ULE) public {
        wyzthTOKEN = wyzth;
        ULETOKEN = ULE;
        allocation[90] = 10;
        allocation[180] = 15;
        allocation[270] = 20;
        allocation[360] = 25;
    }

    function addTokens(address[] memory token, uint256[] memory _minimumDeposit)
        public
    {
        for (uint256 i = 0; i < token.length; i++) {
            tokens.push(token[i]);
            minimumtokenDeposit[tokens[i]] = _minimumDeposit[i];
        }
    }

    function farm(
        uint256 _amount,
        address _token,
        uint256 _lockableDays
    ) public {
        userInfo storage user = users[msg.sender];
        require(user.farmedToken == 0, "Muliple farm not allowed");
        require(_amount >= minimumtokenDeposit[_token], "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        ITRC20(_token).transferFrom(msg.sender, address(this), _amount);
        user.farmedToken = _amount;
        user.lastUpdated = now;
        user.lockableDays = _lockableDays;
        user.token = _token;
    }

    function farmTRX(uint256 _lockableDays) public payable {
        userInfo storage user = users[msg.sender];
        require(user.farmedToken == 0, "Muliple farm not allowed");
        require(msg.value >= minimumDepositTRX, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        user.farmedToken = msg.value;
        user.lastUpdated = now;
        user.lockableDays = _lockableDays;
    }

    function pendindRewards()
        public
        view
        returns (uint256 wyzthReward, uint256 uleReward)
    {
        userInfo storage user = users[msg.sender];
        uint256 leftout = now.sub(user.lastUpdated);
        uint256 toDays = leftout.div(1 days);
        if (users[msg.sender].lockableDays > toDays) {
            return (0, 0);
        } else {
            wyzthReward = allocation[users[msg.sender].lockableDays]
            .mul(users[msg.sender].farmedToken)
            .div(10000)
            .mul(user.lockableDays);
            uleReward = wyzthReward.mul(10);
            if (user.token == tokens[0]) {
                return (wyzthReward, uleReward);
            } else if (user.token == tokens[3]) {
                return (wyzthReward.mul(100), uleReward.mul(100));
            } else if (user.token == tokens[2]) {
                return (
                    wyzthReward.div(2).mul(1E14),
                    uleReward.div(2).mul(1E14)
                );
            } else if (user.token == tokens[1]) {
                return (wyzthReward.div(2), uleReward.div(2));
            } else {
                return (
                    wyzthReward.div(2).mul(1E12),
                    uleReward.div(2).mul(1E12)
                );
            }
        }
    }

    function harvest() public {
        userInfo storage user = users[msg.sender];
        require(user.farmedToken > 0, "No staked balance found");
        (uint256 wyzthReward, uint256 uleReward) = pendindRewards();
        require(wyzthReward > 0 && uleReward > 0, "Too soon");
        uint256 amounttoTransferred;
        if (user.token == address(0)) {
            msg.sender.transfer(user.farmedToken);
            amounttoTransferred = wyzthReward;
        } else if (user.token == tokens[0]) {
            amounttoTransferred = user.farmedToken.add(wyzthReward);
        } else {
            ITRC20(user.token).transfer(msg.sender, user.farmedToken);
            amounttoTransferred = wyzthReward;
        }
        safeTransferWYZ(msg.sender, amounttoTransferred);
        safeTransferULE(msg.sender, uleReward);
        user.farmedToken = 0;
    }

    function safeTransferWYZ(address _farmer, uint256 _amount) internal {
        uint256 tokenBal = ITRC20(wyzthTOKEN).balanceOf(address(this));
        if (_amount > tokenBal) {
            ITRC20(wyzthTOKEN).transfer(_farmer, tokenBal);
        } else {
            ITRC20(wyzthTOKEN).transfer(_farmer, _amount);
        }
    }

    function safeTransferULE(address _farmer, uint256 _amount) internal {
        uint256 tokenBal = ITRC20(ULETOKEN).balanceOf(address(this));
        if (_amount > tokenBal) {
            ITRC20(ULETOKEN).transfer(_farmer, tokenBal);
        } else {
            ITRC20(ULETOKEN).transfer(_farmer, _amount);
        }
    }

    // EMERGENCY ONLY.
    function emergencyWithdraw() public onlyOwner {
        safeTransferWYZ(
            msg.sender,
            ITRC20(wyzthTOKEN).balanceOf(address(this))
        );
        safeTransferULE(msg.sender, ITRC20(ULETOKEN).balanceOf(address(this)));
        msg.sender.transfer((address(this)).balance);
        for (uint256 i = 0; i < tokens.length; i++) {
            ITRC20(tokens[i]).transfer(
                msg.sender,
                ITRC20(tokens[i]).balanceOf(address(this))
            );
        }
    }
}