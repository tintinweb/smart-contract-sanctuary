// File: contracts\interface\IAddressResolver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAddressResolver {
    
    function key2address(bytes32 key) external view returns(address);
    function address2key(address addr) external view returns(bytes32);
    function requireAndKey2Address(bytes32 name, string calldata reason) external view returns(address);

    function setAddress(bytes32 key, address addr) external;
    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external;
}

// File: @openzeppelin\contracts\math\SafeMath.sol


pragma solidity ^0.6.0;

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

// File: contracts\interface\IMintProposal.sol


pragma solidity ^0.6.12;

interface IMintProposal {
    function approve(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        address  to,
        address trustee,
        uint256 trusteeCount
    ) external returns (bool);
}

// File: contracts\MintProposal.sol


pragma solidity ^0.6.12;




contract MintProposal is IMintProposal {
    using SafeMath for uint256;

    bytes32 public constant BORINGDAO = "BoringDAO";
    IAddressResolver addrReso;

    constructor(IAddressResolver _addrResovler) public {
        addrReso = _addrResovler;
    }

    struct Proposal {
        bytes32 tunnelKey;
        uint256 amount;
        uint256 voteCount;
        address creater;
        bool finished;
        bool isExist;
        mapping(address => bool) voteState;
        address to;
        string txid;
    }
    // mapping(address => bool) voteState;

    mapping(bytes32 => Proposal) public proposals;

    function approve(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        address to,
        address trustee,
        uint256 trusteeCount
    ) public override onlyBoringDAO returns (bool) {
        require(msg.sender == addrReso.key2address(BORINGDAO));
        bytes32 pid = keccak256(
            abi.encodePacked(_tunnelKey, _txid, _amount, to)
        );
        if (proposals[pid].isExist == false) {
            // new proposal
            Proposal memory p = Proposal({
                tunnelKey: _tunnelKey,
                to: to,
                txid: _txid,
                amount: _amount,
                creater: trustee,
                voteCount: 1,
                finished: false,
                isExist: true
            });
            proposals[pid] = p;
            proposals[pid].voteState[trustee] = true;
            emit VoteMintProposal(_tunnelKey, _txid, _amount, to, trustee, p.voteCount, trusteeCount);
        } else {
            // exist proposal
            Proposal storage p = proposals[pid];
            // had voted nothing to do more
            if(p.voteState[trustee] == true) {
                return false;
            }
            // proposal finished noting to do more
            if (p.finished) {
                return false;
            }
            p.voteCount = p.voteCount.add(1);
            p.voteState[trustee] = true;
            emit VoteMintProposal(_tunnelKey, _txid, _amount, to, trustee, p.voteCount, trusteeCount);
        }
        Proposal storage p = proposals[pid];
        uint threshold = trusteeCount.mod(3) == 0 ? trusteeCount.mul(2).div(3) : trusteeCount.mul(2).div(3).add(1);
        if (p.voteCount >= threshold) {
            p.finished = true;
            return true;
        } else {
            return false;
        }
    }

    modifier onlyBoringDAO {
        require(msg.sender == addrReso.key2address(BORINGDAO), "MintProposal::caller is not boringDAO");
        _;
    }

    event VoteMintProposal(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        address to,
        address trustee,
        uint votedCount,
        uint256 trusteeCount
    );

}