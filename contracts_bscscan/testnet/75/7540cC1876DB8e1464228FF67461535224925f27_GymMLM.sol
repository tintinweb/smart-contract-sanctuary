pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWETH.sol";


contract GymMLM is Ownable{
    uint256 public currentId;
    address public bankAddress;
    uint8[15] public directReferralBonuses;

    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;

    mapping(address => address) public userToReferrer;

    event NewReferral(address indexed user, address indexed referral);

    event ReferralRewardReceved(
        address indexed user,
        address indexed referral,
        uint256 amount
    );

    constructor() {
        directReferralBonuses = [10, 7, 5, 4, 4, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1];
        addressToId[msg.sender] = 1;
        idToAddress[1] = msg.sender;
        userToReferrer[msg.sender] = msg.sender;
        currentId = 2;
    }

    modifier onlyBank() {
        require(msg.sender == bankAddress, "GymMLM:: Only bank");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function _addUser(address _user, address _referrer) private {
        addressToId[_user] = currentId;
        idToAddress[currentId] = _user;
        userToReferrer[_user] = _referrer;
        currentId++;
        emit NewReferral(_referrer, _user);
    }

    /**
     * @notice  Function to add GymMLM
     * @param _user Address of user
     * @param _referrerId Address of referrer
     */
    function addGymMLM(address _user, uint256 _referrerId) external onlyBank {
        address _referrer = idToAddress[_referrerId];

        require(_user != address(0), "GymMLM::user is zero address");

        require(_referrer != address(0), "GymMLM::referrer is zero address");

        require(
            userToReferrer[_user] == address(0) ||
                userToReferrer[_user] == _referrer,
            "GymMLM::referrer is zero address"
        );

        // If user didn't exsist before
        if (addressToId[_user] == 0) {
            _addUser(_user, _referrer);
        }
    }

    /**
     * @notice  Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user
    ) public onlyBank {
        uint256 index;
        uint256 length = directReferralBonuses.length;

        IERC20 token = IERC20(_wantAddr);
        if (_wantAddr != 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853) {
            while (index < length && addressToId[userToReferrer[_user]] != 1) {
                address referrer = userToReferrer[_user];
                uint256 reward = (_wantAmt * directReferralBonuses[index]) /
                    100;
                token.transfer(referrer, reward);
                emit ReferralRewardReceved(referrer, _user, reward);
                _user = userToReferrer[_user];
                index++;
            }

            if (index != length) {
                token.transfer(bankAddress, token.balanceOf(address(this)));
            }

            return;
        }

        while (index < length && addressToId[userToReferrer[_user]] != 1) {
            address referrer = userToReferrer[_user];
            uint256 reward = (_wantAmt * directReferralBonuses[index]) / 100;
            IWETH(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853).withdraw(reward);
            payable(referrer).transfer(reward);
            emit ReferralRewardReceved(referrer, _user, reward);
            _user = userToReferrer[_user];
            index++;
        }

        if (index != length) {
            token.transfer(bankAddress, token.balanceOf(address(this)));
        }
    }

    function setBankAddress(address _bank) public onlyOwner{
        bankAddress = _bank;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

