/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.5.12;

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

contract LibNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed usr,
        bytes32 indexed arg1,
        bytes32 indexed arg2,
        bytes data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize() // end of memory ensures zero
            mstore(0x40, add(mark, 288)) // update free memory pointer
            mstore(mark, 0x20) // bytes type data offset
            mstore(add(mark, 0x20), 224) // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224) // bytes payload
            log4(
                mark,
                288, // calldata
                shl(224, shr(224, calldataload(0))), // msg.sig
                caller(), // msg.sender
                calldataload(4), // arg1
                calldataload(36) // arg2
            )
        }
    }
}

contract Auth is LibNote {
    mapping(address => uint256) public wards;
    address public deployer;

    function rely(address usr) external note auth {
        wards[usr] = 1;
    }

    function deny(address usr) external note auth {
        wards[usr] = 0;
    }

    modifier auth {
        require(wards[msg.sender] == 1 || deployer == msg.sender, "Auth/not-authorized");
        _;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

    function mint(address account, uint256 amount) external;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
}


interface VatLike {
    function slip(
        bytes32,
        address,
        int256
    ) external;

    function move(
        address,
        address,
        uint256
    ) external;
}



interface CurveGaugeWrapper {

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function set_approve_deposit(address addr, bool can_deposit) external;

    function decimals() external view returns (uint8);

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

    function mint(address account, uint256 amount) external;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface CurveGauge {

    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;

    function lp_token() external view returns (address);
    function minter() external view returns (address);
    function crv_token() external view returns (address);
    function voting_escrow() external view returns (address);
}

interface CurveGaugeReward {
    function rewarded_token() external returns (address);
    function claim_rewards(address addr) external;
}

interface Minter {
    function mint(address gauge_addr) external;
}

interface VotingEscrow {

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;
}

contract Bag {

    using SafeMath for uint256;

    address public owner;
    uint256 amnt;

    constructor() public {
        owner = msg.sender;
    }

    function claim(CurveGauge curveGauge, CurveGaugeReward curveGaugeReward) internal {
        address minter = curveGauge.minter();
        Minter(minter).mint(address(curveGauge));

        if (address(curveGaugeReward) != address(0)) {
            curveGaugeReward.claim_rewards(address(this));
        }
    }

    function transferToken(uint256 wad, address token, address usr, uint256 total) internal {
        uint256 tokenToTransfer = IERC20(token).balanceOf(address(this)).mul(wad).div(total);
        require(IERC20(token).transfer(usr, tokenToTransfer), "GJFC/bag-failed-tkn-tran");
    }

    function exit(CurveGauge curveGauge, address gem, address usr, uint256 wad, 
                  CurveGaugeReward curveGaugeReward) external {
        require(owner == msg.sender, "GJFC/bag-exit-auth");

        uint256 amntBefore = amnt;
        amnt = amnt.sub(wad);

        claim(curveGauge, curveGaugeReward);

        transferToken(wad, curveGauge.crv_token(), usr, amntBefore);
        if (address(curveGaugeReward) != address(0)) {
            transferToken(wad, curveGaugeReward.rewarded_token(), usr, amntBefore);
        }
        curveGauge.withdraw(wad);

        require(IERC20(gem).transfer(usr, wad), "GJFC/bag-failed-transfer");
    }

    function join(CurveGauge curveGauge, address gem, uint256 wad, CurveGaugeReward curveGaugeReward) external {
        require(owner == msg.sender, "GJFC/bag-join-auth");

        amnt = amnt.add(wad);
        claim(curveGauge, curveGaugeReward);


        IERC20(gem).approve(address(curveGauge), wad);
        curveGauge.deposit(wad);
    }

    function init(CurveGauge curveGauge) external {
        require(owner == msg.sender, "GJFC/bag-init-auth");
        IERC20 crv = IERC20(curveGauge.crv_token());
        crv.approve(curveGauge.voting_escrow(), uint256(-1));
    }

    function create_lock(CurveGauge curveGauge, uint256 _value, uint256 _unlock_time) external {
        require(owner == msg.sender, "GJFC/bag-crt-auth");
        VotingEscrow votingEscrow = VotingEscrow(curveGauge.voting_escrow());
        votingEscrow.create_lock(_value, _unlock_time);
    }

    function increase_amount(CurveGauge curveGauge, uint256 _value) external {
        require(owner == msg.sender, "GJFC/bag-inc-amnt-auth");
        VotingEscrow votingEscrow = VotingEscrow(curveGauge.voting_escrow());
        votingEscrow.increase_amount(_value);
    }

    function increase_unlock_time(CurveGauge curveGauge, uint256 _unlock_time) external {
        require(owner == msg.sender, "GJFC/bag-inc-time-auth");
        VotingEscrow votingEscrow = VotingEscrow(curveGauge.voting_escrow());
        votingEscrow.increase_unlock_time(_unlock_time);
    }

    function withdraw(CurveGauge curveGauge, address usr) external {
        require(owner == msg.sender, "GJFC/bag-with-auth");
        VotingEscrow votingEscrow = VotingEscrow(curveGauge.voting_escrow());
        votingEscrow.withdraw();

        IERC20 crv = IERC20(curveGauge.crv_token());

        require(
            crv.transfer(usr, crv.balanceOf(address(this))),
            "GJFC/failed-transfer"
        );
    }
}



/**
 * @title MakerDAO like adapter for gem join
 *
 * see MakerDAO docs for details
*/
contract GemJoinForCurve is LibNote {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external note auth {
        wards[usr] = 1;
    }

    function deny(address usr) external note auth {
        wards[usr] = 0;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "GJFC/not-authorized");
        _;
    }


    VatLike public vat; // CDP Engine
    bytes32 public ilk; // Collateral Type
    IERC20 public gem;
    CurveGauge public curveGauge;
    CurveGaugeReward public curveGaugeReward;
    uint256 public dec;
    uint256 public live; // Active Flag

    mapping(address => address) public bags;


    constructor(
        address vat_,
        bytes32 ilk_,
        address curveGauge_,
        bool withReward
    ) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        curveGauge = CurveGauge(curveGauge_);
        if (withReward) {
            curveGaugeReward = CurveGaugeReward(curveGauge_);
        }
        gem = IERC20(curveGauge.lp_token());
        require(address(gem) != address(0));

        dec = gem.decimals();
        require(dec >= 18, "GJFC/decimals-18-or-higher");
    }

    function makeBag(address user) internal returns (address bag) {
        if (bags[user] != address(0)) {
            bag = bags[user];
        } else {
            Bag b = new Bag();
            b.init(curveGauge);
            bag = address(b);
            bags[user] = bag;
        }
    }

    function cage() external note auth {
        live = 0;
    }

    function join(address urn, uint256 wad) external note {
        require(live == 1, "GJFC/not-live");
        require(int256(wad) >= 0, "GJFC/overflow");
        vat.slip(ilk, urn, int256(wad));

        address bag = makeBag(msg.sender);

        require(
            gem.transferFrom(msg.sender, bag, wad),
            "GJFC/failed-transfer"
        );

        Bag(bag).join(curveGauge, address(gem), wad, curveGaugeReward);
    }

    function exit(address usr, uint256 wad) external note {
        require(wad <= 2**255, "GJFC/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));

        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");

        Bag(bag).exit(curveGauge, address(gem), usr, wad, curveGaugeReward);
    }

    function create_lock(uint256 _value, uint256 _unlock_time) external {
        require(live == 1, "GJFC/not-live");

        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");

        require(
            IERC20(curveGauge.crv_token()).transferFrom(msg.sender, bag, _value),
            "GJFC/failed-transfer"
        );

        Bag(bag).create_lock(curveGauge, _value, _unlock_time);
    }

    function increase_amount(uint256 _value) external {
        require(live == 1, "GJFC/not-live");

        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");

        require(
            IERC20(curveGauge.crv_token()).transferFrom(msg.sender, bag, _value),
            "GJFC/failed-transfer"
        );

        Bag(bag).increase_amount(curveGauge, _value);
    }

    function increase_unlock_time(uint256 _unlock_time) external {
        require(live == 1, "GJFC/not-live");

        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");
        Bag(bag).increase_unlock_time(curveGauge, _unlock_time);
    }

    function withdraw() external {
        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");
        Bag(bag).withdraw(curveGauge, msg.sender);
    }
}



contract BagSimple {

    using SafeMath for uint256;

    address public owner;
    uint256 amnt;

    constructor() public {
        owner = msg.sender;
    }

    function claim(CurveGauge curveGauge) internal {
        address minter = curveGauge.minter();
        Minter(minter).mint(address(curveGauge));
    }

    function transferToken(uint256 wad, address token, address usr, uint256 total) internal {
        uint256 tokenToTransfer = IERC20(token).balanceOf(address(this)).mul(wad).div(total);
        require(IERC20(token).transfer(usr, tokenToTransfer), "GJFC/bag-failed-tkn-tran");
    }

    function exit(CurveGauge curveGauge, address gem, address usr, uint256 wad) external {
        require(owner == msg.sender, "GJFC/bag-exit-auth");

        uint256 amntBefore = amnt;
        amnt = amnt.sub(wad);

        claim(curveGauge);

        transferToken(wad, curveGauge.crv_token(), usr, amntBefore);
        curveGauge.withdraw(wad);

        require(IERC20(gem).transfer(usr, wad), "GJFC/bag-failed-transfer");
    }

    function join(CurveGauge curveGauge, address gem, uint256 wad) external {
        require(owner == msg.sender, "GJFC/bag-join-auth");

        amnt = amnt.add(wad);
        claim(curveGauge);


        IERC20(gem).approve(address(curveGauge), wad);
        curveGauge.deposit(wad);
    }

    function init(CurveGauge curveGauge) external {
        require(owner == msg.sender, "GJFC/bag-init-auth");
        IERC20 crv = IERC20(curveGauge.crv_token());
        crv.approve(curveGauge.voting_escrow(), uint256(-1));
    }
}



/**
 * @title MakerDAO like adapter for gem join
 *
 * see MakerDAO docs for details
 * simple optimized version with no boost
*/
contract GemJoinForCurveSimple is LibNote {

    using SafeMath for uint256;

    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external note auth {
        wards[usr] = 1;
    }

    function deny(address usr) external note auth {
        wards[usr] = 0;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "GJFC/not-authorized");
        _;
    }


    VatLike public vat; // CDP Engine
    bytes32 public ilk; // Collateral Type
    IERC20 public gem;
    CurveGauge public curveGauge;
    uint256 public dec;
    uint256 public live; // Active Flag
    uint256 public totalCollateral;

    mapping(address => address) public bags;


    constructor(
        address vat_,
        bytes32 ilk_,
        address curveGauge_,
        bool
    ) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        curveGauge = CurveGauge(curveGauge_);
        gem = IERC20(curveGauge.lp_token());
        require(address(gem) != address(0));

        dec = gem.decimals();
        require(dec >= 18, "GJFC/decimals-18-or-higher");
    }

    function makeBag(address user) internal returns (address bag) {
        if (bags[user] != address(0)) {
            bag = bags[user];
        } else {
            BagSimple b = new BagSimple();
            b.init(curveGauge);
            bag = address(b);
            bags[user] = bag;
        }
    }

    function cage() external note auth {
        live = 0;
    }

    function join(address urn, uint256 wad) external note {
        require(live == 1, "GJFC/not-live");
        require(int256(wad) >= 0, "GJFC/overflow");
        vat.slip(ilk, urn, int256(wad));
        totalCollateral = totalCollateral.add(wad);

        address bag = makeBag(msg.sender);

        require(
            gem.transferFrom(msg.sender, bag, wad),
            "GJFC/failed-transfer"
        );

        BagSimple(bag).join(curveGauge, address(gem), wad);
    }

    function exit(address usr, uint256 wad) external note {
        require(wad <= 2**255, "GJFC/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        totalCollateral = totalCollateral.sub(wad);

        address bag = bags[msg.sender];
        require(bag != address(0), "GJFC/zero-bag");

        BagSimple(bag).exit(curveGauge, address(gem), usr, wad);
    }
}