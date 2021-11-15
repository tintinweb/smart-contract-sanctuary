//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../libraries/SafeMath.sol';

contract Membership is Ownable {
    using SafeMath for uint256;
    enum MemberType {
        VIP1,
        VIP7,
        VIPX
    }
    /* member address => expiry time */
    mapping(address => uint256) public memberTimeMap;
    /* member address => member type */
    mapping(address => MemberType) public memberTypeMap;
    /* member type => member fee */
    mapping(MemberType => uint256) public memberFeeMap;

    uint256 public referralRate = 35; // 35%
    uint256 public discount = 5 ether; // -5 ether
    uint256 public totalMember = 0;

    event Member(uint256 indexed index, address user, uint8 memberType);

    constructor() public {
        setMemberFees(1 ether, 5 ether, 35 ether);
        _grantMember(msg.sender, uint256(MemberType.VIPX));
    }

    function registerVIP(
        address user,
        uint256 memberType,
        address referral
    ) public payable {
        uint256 memberFee = memberFeeMap[MemberType(memberType)];
        if (MemberType(memberType) == MemberType.VIPX && memberTypeMap[referral] == MemberType.VIPX) {
            if (memberFee > discount) {
                memberFee = memberFee.sub(discount);
            }
        }

        require(msg.value >= memberFee, 'Insufficient member fee');

        _grantMember(user, memberType);

        uint256 fee = msg.value;
        if (referral != address(0x0) && referral != owner() && referral != user && memberTimeMap[referral] > 0) {
            uint256 referralFee = memberFee.mul(referralRate) / 100;
            payable(referral).transfer(referralFee);
            fee = fee.sub(referralFee);
        }

        payable(owner()).transfer(fee);
    }

    function isMember(address user) external view returns (bool) {
        return memberTimeMap[user] > now;
    }

    function getVIPInfo(address user) external view returns (uint256, uint256) {
        return (memberTimeMap[user], now);
    }

    function getVIPFee()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (memberFeeMap[MemberType.VIP1], memberFeeMap[MemberType.VIP7], memberFeeMap[MemberType.VIPX]);
    }

    function setMemberFees(
        uint256 fee1,
        uint256 fee7,
        uint256 feeX
    ) public payable onlyOwner {
        memberFeeMap[MemberType.VIP1] = fee1;
        memberFeeMap[MemberType.VIP7] = fee7;
        memberFeeMap[MemberType.VIPX] = feeX;
    }

    function updateReferralRate(uint256 _referralRate) external onlyOwner {
        require(_referralRate <= 100, 'Invaild referral rate');
        referralRate = _referralRate;
    }

    function setDiscount(uint256 _discount) external payable onlyOwner {
        discount = _discount;
    }

    function grantMember(address user, uint256 memberType) external payable onlyOwner {
        _grantMember(user, memberType);
    }

    function _grantMember(address user, uint256 memberType) private {
        require(memberType < 3, 'Invalid member type');

        if (memberTimeMap[user] == 0) {
            memberTimeMap[user] = block.timestamp;
        }

        if (memberType == uint256(MemberType.VIP1)) {
            memberTimeMap[user] += 1 days;
        } else if (memberType == uint256(MemberType.VIP7)) {
            memberTimeMap[user] += 1 weeks;
        } else {
            memberTimeMap[user] += 10000 * 365 days;
        }

        memberTypeMap[user] = MemberType(memberType);

        emit Member(totalMember, user, uint8(memberType));

        totalMember += 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

