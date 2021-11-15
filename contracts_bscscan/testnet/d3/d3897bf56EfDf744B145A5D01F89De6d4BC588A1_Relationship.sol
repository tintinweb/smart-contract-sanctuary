pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Relationship {
    uint256 public currentId;
    address public bankAddress;
    uint8[15] public directReferralBonuses;

    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => uint256) public userToReferrer;


    constructor(address _bank) {
        bankAddress = _bank;
        directReferralBonuses = [10, 7, 5, 4, 4, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1];
        addressToId[msg.sender] = 1;
        idToAddress[1] = msg.sender;
        userToReferrer[1] = 1;
        currentId = 2;
    }


    modifier onlyBank() {
        require(msg.sender == bankAddress, "Relationship:: Only bank");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function isOnRelationship(address _user)
        external
        view
        returns (bool _result) 
    {
        userToReferrer[addressToId[_user]] != (0) ? _result = true : _result = false;
    }

    /**
     * @notice  Function to add relationship
     * @param _user Address of user
     * @param _referrer Address of referrer 
     */
    function addRelationship(address _user, address _referrer)  
        external
        onlyBank
    {
        require(
            _user != address(0),
            "Relationship::user address can't be zero"
        );
        require(
            _referrer != address(0),
            "Relationship::referrer address can't be zero"
        );
        require(
            userToReferrer[addressToId[_referrer]] != 0,
            "Relationship::referrer with given address doesn't exist"
        );

        if (userToReferrer[addressToId[_user]] != 0) {
            return;
        }

        addressToId[_user] = currentId;
        idToAddress[currentId] = _user;
        userToReferrer[currentId] = addressToId[_referrer];
        currentId++;
    }

    /**
     * @notice  Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     * @param _isToken If false, will trasfer BNB
     */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user,
        bool _isToken
    ) external onlyBank {
        uint256 index;
        uint256 length = directReferralBonuses.length;
        uint256 userId = addressToId[_user];

        IERC20 token = IERC20(_wantAddr);
        while (index < length && userToReferrer[userId] != 1) {
            if (_isToken) {
                token.transfer(
                    idToAddress[userToReferrer[userId]],
                    (_wantAmt * directReferralBonuses[index]) / 100 
                );
            } else {
                payable(idToAddress[userToReferrer[userId]]).transfer(
                    (_wantAmt * directReferralBonuses[index]) / 100
                );
            }
            userId = userToReferrer[userId];
            index++;
        }

        if (index != length) {
            if (_isToken) {
                token.transfer(bankAddress, token.balanceOf(address(this)));
                return;
            }
            payable(bankAddress).transfer(address(this).balance); 
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

