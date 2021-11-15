pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";


contract GymMLM {
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

    constructor(address _bank) {
        bankAddress = _bank;
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
        if (_wantAddr != 0xDfb1211E2694193df5765d54350e1145FD2404A1) {
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
            IWETH(0xDfb1211E2694193df5765d54350e1145FD2404A1).withdraw(reward);
            payable(referrer).transfer(reward);
            emit ReferralRewardReceved(referrer, _user, reward);
            _user = userToReferrer[_user];
            index++;
        }

        if (index != length) {
            token.transfer(bankAddress, token.balanceOf(address(this)));
        }
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

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

