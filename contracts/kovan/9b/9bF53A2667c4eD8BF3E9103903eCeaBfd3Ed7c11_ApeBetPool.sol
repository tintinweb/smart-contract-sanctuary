/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


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

    function mint(address holder, uint256 amount) external;

    function burn(address holder, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IApeBetBookMaker {
    struct SportEvent {
        string event_status;
        uint256 winner;
        uint256 moneyline_home;
        uint256 moneyline_away;
        uint256 moneyline_draw;
    }

    struct Bet {
        uint256 bet_winner;
        uint256 bet_amount;
        uint256 bet_payout;
    }

    function maxPoolPayout() external view returns (uint256);

    function events(bytes16 _event_id, uint256 _affiliate_id)
        external
        view
        returns (SportEvent memory);

    function updateMaxPoolPayout(uint256 amount) external;

    function removePayout(
        bytes16 _event_id,
        uint256 _affiliate_id,
        address _user
    ) external;

    function bets(
        bytes16 _event_id,
        uint256 _affiliate_id,
        address _user
    ) external view returns (Bet memory);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ApeBetPool is Ownable {
    using SafeMath for uint256;

    IERC20 public betToken;
    IApeBetBookMaker private bookMaker;
    address public bookMakerAddress;
    uint256 public supplierDeposit = 0;
    uint256 public userDeposit = 0;
    mapping(address => uint256) public deposits;

    modifier onlyBookMakerOwner() {
        require(msg.sender == bookMakerAddress, "You have no permission!");
        _;
    }

    constructor() {}

    function changeBetToken(address _betTokenAddress) external onlyOwner {
        betToken = IERC20(_betTokenAddress);
    }

    function changeBookMaker(address _bookMakerAddress) external onlyOwner {
        bookMaker = IApeBetBookMaker(_bookMakerAddress);
        bookMakerAddress = _bookMakerAddress;
        bookMaker.updateMaxPoolPayout(address(this).balance);
    }

    receive() external payable {
        bookMaker.updateMaxPoolPayout(msg.value);
        supplierDeposit = supplierDeposit.add(msg.value);
    }

    function claimPayout(bytes16 _event_id, uint256 _affiliate_id) external {
        require(
            bookMaker.bets(_event_id, _affiliate_id, msg.sender).bet_payout !=
                0,
            "You have nothing to claim."
        );

        msg.sender.transfer(
            bookMaker.bets(_event_id, _affiliate_id, msg.sender).bet_payout
        );

        bookMaker.removePayout(_event_id, _affiliate_id, msg.sender);
    }

    function depositUserETH() public payable {
        userDeposit = userDeposit.add(msg.value);
    }

    // Functions for suppliers.
    function depositETH() external payable {
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        supplierDeposit = supplierDeposit.add(msg.value);
        bookMaker.updateMaxPoolPayout(msg.value);
        betToken.mint(msg.sender, msg.value.mul(100));
    }

    function getRewardETH(uint256 amount)
        public
        view
        returns (uint256 rewardETH)
    {
        // return amount.mul(1e4).div(betToken.balanceOf(msg.sender));
        rewardETH = bookMaker
            .maxPoolPayout()
            .mul(deposits[msg.sender].mul(1e4).div(supplierDeposit))
            .mul(amount.mul(1e4).div(betToken.balanceOf(msg.sender)))
            .div(1e8);
        return rewardETH;
    }


    function depositBetToken(uint256 amount) external {
        uint256 ethAmount = getRewardETH(amount);

        msg.sender.transfer(ethAmount);

        betToken.burn(msg.sender, amount);
        deposits[msg.sender] = deposits[msg.sender].sub(ethAmount);
        supplierDeposit = supplierDeposit.sub(ethAmount);
    }
}