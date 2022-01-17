/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-11
 */

pragma solidity 0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public ownerWallet;

    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

// interface Hentaiholiday {
//     function setApproved(address operator, bool approved) external returns (uint256);
// }
interface BEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Powermade is Ownable {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 currentlevel;
        uint256 totalEarnedreferral;
        uint256 referrerID;
        mapping(uint256 => LevelPlan) levelplan;
    }

    struct LevelPlan {
        bool isExist;
        uint256 levelExpired;
        uint256 referredUsers;
        uint256 referrerID;
        address[] referral;
        uint256 virtualID;
        uint256 totalEarnedreferral;
    }

    mapping(uint256 => uint256) public LEVEL_PRICE;
    mapping(uint256 => uint256) public POOL_PRICE;
    mapping(address => UserStruct) public users;
    mapping(uint256 => address) public userList;

    uint256 public currUserID = 0;
    uint256 public projectAmount = 50;
    uint256 public maxDownLimit = 5;

    address public tokenAddress;

    constructor(address busdToken) public {
        owner = msg.sender;
        ownerWallet = msg.sender;

        tokenAddress = busdToken;

        LEVEL_PRICE[1] = 20;
        LEVEL_PRICE[2] = 10;
        LEVEL_PRICE[3] = 7;
        LEVEL_PRICE[4] = 5;
        LEVEL_PRICE[5] = 8;

        POOL_PRICE[1] = 179000000000000000000;
        POOL_PRICE[2] = 600000000000000000000;
        POOL_PRICE[3] = 1180000000000000000000;
        POOL_PRICE[4] = 1750000000000000000000;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            totalEarnedreferral: 0,
            currentlevel: 7,
            referrerID: currUserID
        });

        users[msg.sender].levelplan[1].levelExpired = 1;
        users[msg.sender].levelplan[2].levelExpired = 1;
        users[msg.sender].levelplan[3].levelExpired = 1;
        users[msg.sender].levelplan[4].levelExpired = 1;

        users[msg.sender].levelplan[1].isExist = true;
        users[msg.sender].levelplan[2].isExist = true;
        users[msg.sender].levelplan[3].isExist = true;
        users[msg.sender].levelplan[4].isExist = true;

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
    }

    function ActivatePlan(
        uint256 _referrerID,
        uint256 _level,
        uint256 amount
    ) public {
        require(
            _referrerID > 0 && _referrerID <= currUserID,
            "Incorrect referral ID"
        );
        require(amount == POOL_PRICE[1], "Incorrect Value");

        BEP20 t = BEP20(tokenAddress);
        uint256 approveValue = t.allowance(msg.sender, address(this));

        uint256 balanceOfowner = t.balanceOf(msg.sender);

        require(approveValue >= amount, "Insufficient Balance");
        require(balanceOfowner >= amount, "Insufficient Balance");

        for (uint256 l = _level - 1; l > 0; l--) {
            require(
                users[msg.sender].levelplan[l].levelExpired != 0,
                "Buy the previous level"
            );
        }

        UserStruct memory userStruct;
        currUserID++;
        uint256 virtualID;
        virtualID = _referrerID;
        if (
            users[userList[virtualID]].levelplan[_level].referral.length >=
            maxDownLimit
        ) virtualID = users[findFreeReferrer(userList[virtualID], _level)].id;

        if (_level == 1) {
            userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                totalEarnedreferral: 0,
                currentlevel: 1,
                referrerID: _referrerID
            });

            users[msg.sender] = userStruct;
            userList[currUserID] = msg.sender;

            users[msg.sender].levelplan[2].levelExpired = 0;
            users[msg.sender].levelplan[3].levelExpired = 0;
            users[msg.sender].levelplan[4].levelExpired = 0;

            users[msg.sender].levelplan[2].isExist = false;
            users[msg.sender].levelplan[3].isExist = false;
            users[msg.sender].levelplan[4].isExist = false;
        }

        users[msg.sender].currentlevel = _level;

        users[msg.sender].levelplan[_level].levelExpired = 1;
        users[msg.sender].levelplan[_level].isExist = true;

        users[msg.sender].levelplan[_level].referredUsers = 0;
        users[msg.sender].levelplan[_level].referrerID = _referrerID;
        users[msg.sender].levelplan[_level].virtualID = virtualID;

        users[userList[virtualID]].levelplan[_level].referredUsers + 1;
        users[userList[virtualID]].levelplan[_level].referral.push(msg.sender);

        payReferral(_level, msg.sender, 1);
    }

    function findFreeReferrer(address _user, uint256 _level)
        public
        view
        returns (address)
    {
        if (users[_user].levelplan[_level].referral.length < maxDownLimit)
            return _user;
        address[] memory referrals = new address[](500);
        referrals[0] = users[_user].levelplan[_level].referral[0];
        referrals[1] = users[_user].levelplan[_level].referral[1];
        referrals[2] = users[_user].levelplan[_level].referral[2];
        referrals[3] = users[_user].levelplan[_level].referral[3];
        referrals[4] = users[_user].levelplan[_level].referral[4];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 500; i++) {
            if (
                users[referrals[i]].levelplan[_level].referral.length ==
                maxDownLimit
            ) {
                referrals[(i + 1) * 5] = users[referrals[i]]
                    .levelplan[_level]
                    .referral[0];
                referrals[(i + 1) * 5 + 1] = users[referrals[i]]
                    .levelplan[_level]
                    .referral[1];
                referrals[(i + 1) * 5 + 2] = users[referrals[i]]
                    .levelplan[_level]
                    .referral[2];
                referrals[(i + 1) * 5 + 3] = users[referrals[i]]
                    .levelplan[_level]
                    .referral[3];
                referrals[(i + 1) * 5 + 4] = users[referrals[i]]
                    .levelplan[_level]
                    .referral[4];
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, "No Free Referrer");

        return freeReferrer;
    }

    function payReferral(
        uint256 level,
        address _useraddress,
        uint256 inc
    ) internal {
        BEP20 t = BEP20(tokenAddress);

        if (inc == 1) {
            uint256 projectTransfer = POOL_PRICE[level].mul(projectAmount).div(
                100
            );

            t.transferFrom(msg.sender, ownerWallet, projectTransfer);
        }
        if (inc <= 5) {
            address referer = userList[
                users[_useraddress].levelplan[level].virtualID
            ];
            uint256 referAmount = POOL_PRICE[level].mul(LEVEL_PRICE[inc]).div(
                100
            );

            if (users[referer].isExist) {
                t.transferFrom(msg.sender, referer, referAmount);
                users[referer]
                    .levelplan[level]
                    .totalEarnedreferral += referAmount;

                users[referer].totalEarnedreferral += referAmount;
            } else {
                t.transferFrom(msg.sender, ownerWallet, referAmount);
            }
            inc += 1;
            payReferral(level, referer, inc);
        }
    }

    function getUserExist() public view returns (bool) {
        require(users[msg.sender].isExist, "User Not Exists");
        return users[msg.sender].isExist ? true : false;
    }

    function getUserExistId(uint256 id) public view returns (address) {
        require(users[msg.sender].isExist, "User Not Exists");
        return userList[id];
    }

    function getuseridUsingAddress(address useraddress)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        return users[useraddress].id;
    }

    function getCurrentPlan(address useraddress) public view returns (uint256) {
        require(users[msg.sender].isExist, "User Not Exists");
        return users[useraddress].currentlevel;
    }

    function gettotalEarnedreferral(address useraddress)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        return users[useraddress].totalEarnedreferral;
    }

    function getreferrerID(address useraddress) public view returns (uint256) {
        require(users[msg.sender].isExist, "User Not Exists");
        return users[useraddress].referrerID;
    }

    function getPlanReferredUsersCount(address useraddress, uint256 level)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        require(
            users[useraddress].levelplan[level].isExist,
            "User Not purchased that plan"
        );
        return users[useraddress].levelplan[level].referredUsers;
    }

    function getPlanreferrerID(address useraddress, uint256 level)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        require(
            users[useraddress].levelplan[level].isExist,
            "User Not purchased that plan"
        );
        return users[useraddress].levelplan[level].referrerID;
    }

    function getPlanreferral(address useraddress, uint256 level)
        public
        view
        returns (address[] memory)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        require(
            users[useraddress].levelplan[level].isExist,
            "User Not purchased that plan"
        );
        return users[useraddress].levelplan[level].referral;
    }

    function getPlanvirtualID(address useraddress, uint256 level)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        require(
            users[useraddress].levelplan[level].isExist,
            "User Not purchased that plan"
        );
        return users[useraddress].levelplan[level].virtualID;
    }

    function getPlantotalEarnedreferral(address useraddress, uint256 level)
        public
        view
        returns (uint256)
    {
        require(users[msg.sender].isExist, "User Not Exists");
        require(
            users[useraddress].levelplan[level].isExist,
            "User Not purchased that plan"
        );
        return users[useraddress].levelplan[level].totalEarnedreferral;
    }
}