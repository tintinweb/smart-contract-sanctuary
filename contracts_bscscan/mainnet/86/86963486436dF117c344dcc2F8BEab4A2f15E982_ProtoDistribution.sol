// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SafeMath.sol";
import "./Address.sol";
import "./ProtoType.sol";
import "./ProtoBEP20V2.sol";

library ProtoDistribution {
    using SafeMath for uint256;
    using Address for address;
    using ProtoBEP20V2 for ProtoType.Universe;

    function getProtoShare(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        return allocation.shares[account];
    }

    function unlockTime(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        if (allocation.isCoreWallet[account]) return block.timestamp + 120 days;
        if (allocation.isAidWallet[account]) return block.timestamp + 95 days;
        return allocation.lockTimes[account];
    }

    function vestingTime(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        if (allocation.isCoreWallet[account]) return 730;
        if (allocation.isAidWallet[account]) return 90;
        return 1825;
    }

    function getAllocation(
        ProtoType.PreAllocation storage allocation,
        address account
    )
        public
        view
        returns (
            uint256 _share,
            uint256 _unlockTime,
            uint256 _vestingTime
        )
    {
        return (
            getProtoShare(allocation, account),
            unlockTime(allocation, account),
            vestingTime(allocation, account)
        );
    }

    function preAllocatedWallets(ProtoType.PreAllocation storage allocation)
        external
        pure
        returns (address[39] memory)
    {
        return [
            0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31,
            0x96cB54D88cDC95bD27c176BA73843b231FA37007,
            0x5D37B29E4Fd931033cac0F08700572edEc4F87a4,
            0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31,
            0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a,
            0x5c8736014EefE5B47899a34E81a6A81921b70e9E,
            0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0,
            0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6,
            0x0bf368960898DDB4602638eC29d7733e0430f197,
            0xE6160014858e64d22Ba4a1098c4e287f65323438,
            0xc7986e638D670811C5a5E3fc9F2e731afFe51933,
            0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317,
            0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b,
            0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8,
            0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283,
            0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b,
            0xd837a89655dcfA336B289524D5B0bB2cD649feAE,
            0xE4D4205B508918815e7b894D6A1205E9E923Ef23,
            0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18,
            0x822A016190008124f0855EEf5159Bfc5B9F17BaB,
            0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49,
            0x2C94c6a843cDF400A3aCb41e9e776E40712050AB,
            0xC33A0fd7aF52331c31fDE62883365c07E73457fc,
            0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d,
            0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725,
            0x9d3cD26da568093fF2d68B5d38c124832DC23cA9,
            0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34,
            0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f,
            0x93fA1B33C8993345e3597171F5d39D40f036Cd2B,
            0x08E4717a449E175B7bFc1FF71d8228F64677a370,
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F,
            0x47fd4076556EB209c616cCD5619393CC913e6E8A,
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972,
            0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20,
            0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302,
            0xfC864d405AfcB40127A2c1555a0C7EE01E172023,
            0xb77fCf61E3e97fd0f2f757E66B88D95631b02541,
            0x77a45B76BDAC9A9C4bDd66e400Dd048B1b2C6236,
            0xE180B12EC6dF7EbB24D7C525E8F8b73433542e5a
        ];
    }

    function initProtoDistribution(
        ProtoType.PreAllocation storage allocation,
        ProtoType.Universe storage state
    ) external {
        require(!allocation.isInitialized, "Already Initialized");
        uint256 currentRate = state._getRate();
        require(currentRate > 0, "Rate cannot be zero");

        allocation.aidWallets = [
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F,
            0x47fd4076556EB209c616cCD5619393CC913e6E8A,
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972
        ];

        allocation.coreWallets = [
            0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31,
            0x96cB54D88cDC95bD27c176BA73843b231FA37007,
            0x5D37B29E4Fd931033cac0F08700572edEc4F87a4,
            0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31,
            0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a,
            0x5c8736014EefE5B47899a34E81a6A81921b70e9E,
            0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0,
            0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6,
            0x0bf368960898DDB4602638eC29d7733e0430f197,
            0xE6160014858e64d22Ba4a1098c4e287f65323438,
            0xc7986e638D670811C5a5E3fc9F2e731afFe51933,
            0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317,
            0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b,
            0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8,
            0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283,
            0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b,
            0xd837a89655dcfA336B289524D5B0bB2cD649feAE,
            0xE4D4205B508918815e7b894D6A1205E9E923Ef23,
            0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18,
            0x822A016190008124f0855EEf5159Bfc5B9F17BaB,
            0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49,
            0x2C94c6a843cDF400A3aCb41e9e776E40712050AB,
            0xC33A0fd7aF52331c31fDE62883365c07E73457fc,
            0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d,
            0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725,
            0x9d3cD26da568093fF2d68B5d38c124832DC23cA9,
            0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34,
            0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f,
            0x93fA1B33C8993345e3597171F5d39D40f036Cd2B,
            0x08E4717a449E175B7bFc1FF71d8228F64677a370
        ];

        for (uint256 i = 0; i < allocation.coreWallets.length; i++) {
            allocation.isCoreWallet[allocation.coreWallets[i]] = true;
            state._dceLawClaimAllowed[allocation.coreWallets[i]] = true;
        }

        for (uint256 i = 0; i < allocation.aidWallets.length; i++) {
            allocation.isAidWallet[allocation.aidWallets[i]] = true;
            state._dceLawClaimAllowed[allocation.aidWallets[i]] = true;
        }

        allocation.shares[0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0x96cB54D88cDC95bD27c176BA73843b231FA37007] = uint256(
            660000e18
        ).mul(currentRate);
        allocation.shares[0x5D37B29E4Fd931033cac0F08700572edEc4F87a4] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31] = uint256(
            1980000e18
        ).mul(currentRate);
        allocation.shares[0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0x5c8736014EefE5B47899a34E81a6A81921b70e9E] = uint256(
            5280000e18
        ).mul(currentRate);
        allocation.shares[0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0] = uint256(
            4620000e18
        ).mul(currentRate);
        allocation.shares[0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0x0bf368960898DDB4602638eC29d7733e0430f197] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0xE6160014858e64d22Ba4a1098c4e287f65323438] = uint256(
            7260000e18
        ).mul(currentRate);
        allocation.shares[0xc7986e638D670811C5a5E3fc9F2e731afFe51933] = uint256(
            6600000e18
        ).mul(currentRate);
        allocation.shares[0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317] = uint256(
            1650000e18
        ).mul(currentRate);
        allocation.shares[0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b] = uint256(
            1650000e18
        ).mul(currentRate);
        allocation.shares[0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8] = uint256(
            1650000e18
        ).mul(currentRate);
        allocation.shares[0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283] = uint256(
            1650000e18
        ).mul(currentRate);
        allocation.shares[0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0xd837a89655dcfA336B289524D5B0bB2cD649feAE] = uint256(
            6600000e18
        ).mul(currentRate);
        allocation.shares[0xE4D4205B508918815e7b894D6A1205E9E923Ef23] = uint256(
            6600000e18
        ).mul(currentRate);
        allocation.shares[0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18] = uint256(
            5940000e18
        ).mul(currentRate);
        allocation.shares[0x822A016190008124f0855EEf5159Bfc5B9F17BaB] = uint256(
            7260000e18
        ).mul(currentRate);
        allocation.shares[0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49] = uint256(
            6600000e18
        ).mul(currentRate);
        allocation.shares[0x2C94c6a843cDF400A3aCb41e9e776E40712050AB] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0xC33A0fd7aF52331c31fDE62883365c07E73457fc] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0x9d3cD26da568093fF2d68B5d38c124832DC23cA9] = uint256(
            3300000e18
        ).mul(currentRate);
        allocation.shares[0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34] = uint256(
            2640000e18
        ).mul(currentRate);
        allocation.shares[0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0x93fA1B33C8993345e3597171F5d39D40f036Cd2B] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0x08E4717a449E175B7bFc1FF71d8228F64677a370] = uint256(
            1320000e18
        ).mul(currentRate);
        allocation.shares[0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F] = uint256(
            1650000e18
        ).mul(currentRate);
        allocation.shares[0x47fd4076556EB209c616cCD5619393CC913e6E8A] = uint256(
            1567500e18
        ).mul(currentRate);
        allocation.shares[0x9b22E636CACA80C9E243E6bDe1fdc198a297a972] = uint256(
            825000e18
        ).mul(currentRate);

        allocation.shares[0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20] = uint256(
            33000000e18
        ).mul(currentRate);
        allocation.shares[0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302] = uint256(
            33000000e18
        ).mul(currentRate);
        allocation.shares[0xfC864d405AfcB40127A2c1555a0C7EE01E172023] = uint256(
            132000000e18
        ).mul(currentRate);
        allocation.shares[0xb77fCf61E3e97fd0f2f757E66B88D95631b02541] = uint256(
            26400000e18
        ).mul(currentRate);
        allocation.shares[0x77a45B76BDAC9A9C4bDd66e400Dd048B1b2C6236] = uint256(
            33000000e18
        ).mul(currentRate);
        allocation.shares[0xE180B12EC6dF7EbB24D7C525E8F8b73433542e5a] = uint256(
            33000000e18
        ).mul(currentRate);

        allocation.totalLock = uint256(554400000e18).mul(currentRate);

        allocation.lockTimes[allocation.listingSafe] =
            block.timestamp +
            110 days;
        allocation.lockTimes[allocation.reserveSafe] =
            block.timestamp +
            110 days;
        allocation.lockTimes[allocation.daoSafe] = block.timestamp + 140 days;
        allocation.lockTimes[allocation.auditsDevelopmentSafe] =
            block.timestamp +
            95 days;
        allocation.lockTimes[allocation.marketingSafe] =
            block.timestamp +
            95 days;
        allocation.lockTimes[allocation.yieldSafe] = block.timestamp + 95 days;

        allocation.isInitialized = true;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./Pancake.sol";

library ProtoType {
    using SafeMath for uint256;
    using Address for address;

    struct Universe {
        mapping(address => uint256) _rProtoOwned;
        mapping(address => uint256) _tProtoOwned;
        mapping(address => LockedProto) _lOwned;
        mapping(address => bool) _isExcludedFromFee;
        mapping(address => bool) _isExcluded;
        mapping(address => bool) _dceProtoClaimed;
        mapping(address => bool) _dceLawClaimAllowed;
        mapping(address => uint256) approvedProposalsExpiry;
        mapping(address => mapping(address => uint256)) _allowances;
        address[] _excluded;
        uint256 MAX;
        uint256 _tTotal;
        uint256 _rTotal;
        uint256 _tFeeTotal;
        uint256 _tLiquidityFeeTotal;
        uint256 _tBurnTotal;
        uint256 _taxFee;
        uint256 _previousTaxFee;
        uint256 _liquidityFee;
        uint256 _previousLiquidityFee;
        address pancakeSwapV2Pair;
        IPancakeSwapV2Router02 pancakeSwapV2Router;
        bool inSwapAndLiquify;
        bool inSwapBUSD;
        bool swapAndLiquifyEnabled;
        bool transferEnabled;
        address[2] charity;
        address daoSafe;
        address auditsDevelopmentSafe;
        address marketingSafe;
        address accumulationSafe;
        address[3] aidWallet;
        uint256 _toSwapBUSD;
        uint256 MAXTxAmount;
        uint256 numTokensSellToAddToLiquidity;
        uint256 numTokensSellToSwapBUSD;
        address _daoCouncil;
        address BUSDAddress;
        address pancakeRouterAddress;
        address lawGovernance;
    }

    struct LockedProto {
        bool isUnlocked;
        uint256 unlockedTime;
        uint256 vesting;
        uint256 lastReward;
        uint256 count;
        uint256 amount;
        uint256 lockedAmount;
        uint256 rOwned;
    }

    struct PreAllocation {
        bool isInitialized;
        uint256 totalLock;
        address daoCouncil;
        address accumulationSafe;
        address auditsDevelopmentSafe;
        address marketingSafe;
        address daoSafe;
        address yieldSafe;
        address listingSafe;
        address reserveSafe;
        address[3] aidWallets;
        address[30] coreWallets;
        mapping(address => bool) isCoreWallet;
        mapping(address => bool) isAidWallet;
        mapping(address => bool) isCharityWallet;
        mapping(address => uint256) lockTimes;
        mapping(address => uint256) shares;
    }

    function daoCouncil(ProtoType.Universe storage state)
        public
        view
        returns (address)
    {
        return state._daoCouncil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";
import "./IProtoDistribution.sol";
import "./ProtoType.sol";
import "./ProtoDao.sol";

library ProtoBEP20V2 {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoDao for ProtoType.Universe;
    using ProtoType for ProtoType.LockedProto;

    event Approval(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    function totalSupply(ProtoType.Universe storage state)
        public
        view
        returns (uint256)
    {
        return state._tTotal;
    }

    function balanceOf(ProtoType.Universe storage state, address account)
        public
        view
        returns (uint256)
    {
        if (state._isExcluded[account]) return state._tProtoOwned[account];
        return tokenFromReflection(state, state._rProtoOwned[account]);
    }

    function lockedProto(ProtoType.Universe storage state, address account)
        external
        view
        returns (ProtoType.LockedProto memory)
    {
        return state._lOwned[account];
    }

    function _approve(
        ProtoType.Universe storage state,
        address owner,
        address spender,
        uint256 amount
    ) public {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        state._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapAndLiquify(
        ProtoType.Universe storage state,
        uint256 toSwapLiquidityProto
    ) public {
        require(!state.inSwapAndLiquify);
        state.inSwapAndLiquify = true;
        // split the contract balance into halves
        uint256 half = toSwapLiquidityProto.div(2);
        uint256 otherHalf = toSwapLiquidityProto.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(state, half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeSwap
        addLiquidity(state, otherHalf, newBalance);

        state._tLiquidityFeeTotal = state._tLiquidityFeeTotal.sub(
            toSwapLiquidityProto
        ); // reset the accumulation tracker.
        emit SwapAndLiquify(half, newBalance, otherHalf);
        state.inSwapAndLiquify = false;
    }

    function swapTokensForBNB(
        ProtoType.Universe storage state,
        uint256 tokenAmount
    ) public {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = state.pancakeSwapV2Router.WETH();

        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            tokenAmount
        );

        // make the swap
        state
            .pancakeSwapV2Router
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function shareBUSD(ProtoType.Universe storage state) public {
        require(!state.inSwapAndLiquify);
        state.inSwapAndLiquify = true;
        swapTokenForBUSD(state, state._toSwapBUSD);
        state._toSwapBUSD = 0; // ensures accumulated Proto count is reset once pancake swap of Proto-BUSD is done.
        IBEP20 BUSDtoken = IBEP20(state.BUSDAddress);
        uint256 busdReceived = BUSDtoken.balanceOf(address(this));
        BUSDtoken.transfer(
            state.charity[0],
            ((busdReceived.div(9)).mul(4)).div(2)
        );
        BUSDtoken.transfer(
            state.charity[1],
            ((busdReceived.div(9)).mul(4)).div(2)
        );
        BUSDtoken.transfer(
            state.accumulationSafe,
            (busdReceived.div(9)).mul(5)
        );
        state.inSwapAndLiquify = false;
    }

    function swapTokenForBUSD(ProtoType.Universe storage state, uint256 amount)
        public
    {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = state.pancakeSwapV2Router.WETH();
        path[2] = state.BUSDAddress; // BUSD address

        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            amount
        );

        // make the swap
        state
            .pancakeSwapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of BUSD
            path,
            address(this),
            block.timestamp + 2 minutes
        );
    }

    function removeAllFee(ProtoType.Universe storage state) public {
        if (state._taxFee == 0 && state._liquidityFee == 0) return;

        state._previousTaxFee = state._taxFee;
        state._previousLiquidityFee = state._liquidityFee;

        state._taxFee = 0;
        state._liquidityFee = 0;
    }

    function restoreAllFee(ProtoType.Universe storage state) public {
        state._taxFee = state._previousTaxFee;
        state._liquidityFee = state._previousLiquidityFee;
    }

    function _transfer(
        ProtoType.Universe storage state,
        address from,
        address to,
        uint256 amount
    ) public {
        require(
            state.transferEnabled || (msg.sender == state.daoCouncil()),
            "BEP20: Token is not transferable"
        );
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != state.daoCouncil() && to != state.daoCouncil())
            require(
                amount <= state.MAXTxAmount,
                "Transfer amount exceeds the state.MAXTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeSwap pair.
        uint256 toSwapLiquidity = state._tLiquidityFeeTotal;
        if (toSwapLiquidity >= state.MAXTxAmount) {
            toSwapLiquidity = state.MAXTxAmount;
        }

        bool overMinTokenBalance = toSwapLiquidity >=
            state.numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !state.inSwapAndLiquify &&
            from != state.pancakeSwapV2Pair &&
            state.swapAndLiquifyEnabled
        ) {
            toSwapLiquidity = state.numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(state, toSwapLiquidity);
        }

        if (
            state._toSwapBUSD >= state.numTokensSellToSwapBUSD &&
            from != state.pancakeSwapV2Pair &&
            !state.inSwapAndLiquify &&
            state.swapAndLiquifyEnabled
        ) {
            shareBUSD(state);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to state._isExcludedFromFee account then remove the fee
        if (state._isExcludedFromFee[from] || state._isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(state, from, to, amount, takeFee);
    }

    function transferFrom(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(state, sender, recipient, amount);
        _approve(
            state,
            sender,
            msg.sender,
            state._allowances[sender][msg.sender].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        ProtoType.Universe storage state,
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            state,
            msg.sender,
            spender,
            state._allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        ProtoType.Universe storage state,
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            state,
            msg.sender,
            spender,
            state._allowances[msg.sender][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) public {
        if (!takeFee) removeAllFee(state);

        if (state._isExcluded[sender] && !state._isExcluded[recipient]) {
            _transferFromExcluded(state, sender, recipient, amount);
        } else if (!state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferToExcluded(state, sender, recipient, amount);
        } else if (state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferBothExcluded(state, sender, recipient, amount);
        } else {
            _transferStandard(state, sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee(state);
    }

    function _transferInternal(
        ProtoType.Universe storage state,
        address recipient,
        uint256 tAmount
    ) public {
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            tAmount.mul(_getRate(state))
        );
        if (state._isExcluded[recipient])
            state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
                tAmount
            );

        emit Transfer(msg.sender, recipient, tAmount);
    }

    function _transferStandard(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
            tTransferAmount
        );
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._tProtoOwned[sender] = state._tProtoOwned[sender].sub(tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferLockedStandard(
        ProtoType.Universe storage state,
        address receiver,
        uint256 transferRewardAmount,
        uint256 transferVestingAmount
    ) public {
        address sender = address(this);
        uint256 transferAmount = transferRewardAmount.add(
            transferVestingAmount
        );
        require(transferAmount > 0, "Claimable amount is zero");

        uint256 rAmount = reflectionFromToken(state, transferAmount, false);
        require(
            rAmount <= state._lOwned[receiver].rOwned,
            "Not enough tokens to claim"
        );

        require(
            state._rProtoOwned[sender] >= rAmount,
            "Not enough tokens in contract to release"
        );

        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[receiver] = state._rProtoOwned[receiver].add(
            rAmount
        );
        state._lOwned[receiver].rOwned = state._lOwned[receiver].rOwned.sub(
            rAmount
        );

        if (transferVestingAmount > 0) {
            state._lOwned[receiver].lockedAmount = state
            ._lOwned[receiver]
            .lockedAmount
            .sub(transferVestingAmount);
        }

        emit Transfer(sender, receiver, transferAmount);
    }

    function _transferBothExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._tProtoOwned[sender] = state._tProtoOwned[sender].sub(tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
            tTransferAmount
        );
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        ProtoType.Universe storage state,
        uint256 rFee,
        uint256 tFee
    ) public {
        if (rFee > 0 && tFee > 0) {
            uint256 OneFifth = ((tFee.div(state._taxFee)).mul(100)).div(2); //0.5 (variable)
            uint256 halfFifth = ((tFee.div(state._taxFee)).mul(100)).div(4); //0.25 token (variable)
            uint256 rOneFifth = ((rFee.div(state._taxFee)).mul(100)).div(2); //0.5 (variable)
            uint256 aidOnehalf = OneFifth.div(2);
            _transferInternal(state, state.daoSafe, halfFifth.mul(3)); //0.75 to DAO
            _transferInternal(state, state.marketingSafe, halfFifth.mul(3)); //0.75 state.marketingSafe
            _transferInternal(
                state,
                state.auditsDevelopmentSafe,
                halfFifth.mul(3)
            ); // 0.75 dev and audit
            _transferInternal(state, (address(0)), OneFifth.mul(2)); //1 to burn
            _transferInternal(state, state.aidWallet[0], aidOnehalf); // AID  0.25
            _transferInternal(state, state.aidWallet[1], aidOnehalf.div(2)); // AID 2 0.125
            _transferInternal(state, state.aidWallet[2], aidOnehalf.div(2)); // AID 3 0.125
            state._toSwapBUSD = state._toSwapBUSD.add(OneFifth.mul(2)); // 1% charity
            state._toSwapBUSD = state._toSwapBUSD.add((halfFifth).mul(5)); // 1.25 Acculamation Safe
            state._rTotal = state._rTotal.sub((rOneFifth.mul(5))); // Instant rewards 2.5
            state._tFeeTotal = state._tFeeTotal.add((OneFifth.mul(5)));
            state._tBurnTotal = state._tBurnTotal.add(OneFifth.mul(2));

            uint256 toSwapBUSDProtos = OneFifth.mul(2); // 1% charity
            toSwapBUSDProtos = toSwapBUSDProtos.add((halfFifth).mul(5)); // 1.25% accumulation safe
            _transferInternal(state, address(this), toSwapBUSDProtos);
        }
    }

    function tokenFromReflection(
        ProtoType.Universe storage state,
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= state._rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(state);
        return rAmount.div(currentRate);
    }

    function reflectionFromToken(
        ProtoType.Universe storage state,
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= state._tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(state, tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(state, tAmount);
            return rTransferAmount;
        }
    }

    function _getValues(ProtoType.Universe storage state, uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(state, tAmount);
        uint256 currentRate = _getRate(state);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(ProtoType.Universe storage state, uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(state, tAmount);
        uint256 tLiquidity = calculateLiquidityFee(state, tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate(ProtoType.Universe storage state)
        public
        view
        returns (uint256)
    {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(state);
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(ProtoType.Universe storage state)
        public
        view
        returns (uint256, uint256)
    {
        uint256 rSupply = state._rTotal;
        uint256 tSupply = state._tTotal;
        for (uint256 i = 0; i < state._excluded.length; i++) {
            if (
                state._rProtoOwned[state._excluded[i]] > rSupply ||
                state._tProtoOwned[state._excluded[i]] > tSupply
            ) return (state._rTotal, state._tTotal);
            rSupply = rSupply.sub(state._rProtoOwned[state._excluded[i]]);
            tSupply = tSupply.sub(state._tProtoOwned[state._excluded[i]]);
        }
        if (rSupply < state._rTotal.div(state._tTotal))
            return (state._rTotal, state._tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(ProtoType.Universe storage state, uint256 _amount)
        public
        view
        returns (uint256)
    {
        return _amount.mul(state._taxFee).div(10**4);
    }

    function calculateLiquidityFee(
        ProtoType.Universe storage state,
        uint256 _amount
    ) public view returns (uint256) {
        return _amount.mul(state._liquidityFee).div(10**4);
    }

    function excludeFromReward(
        ProtoType.Universe storage state,
        address account
    ) external {
        require(!state._isExcluded[account], "Account is already excluded");
        if (state._rProtoOwned[account] > 0) {
            state._tProtoOwned[account] = tokenFromReflection(
                state,
                state._rProtoOwned[account]
            );
        }
        state._isExcluded[account] = true;
        state._excluded.push(account);
    }

    function includeInReward(ProtoType.Universe storage state, address account)
        external
    {
        require(state._isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < state._excluded.length; i++) {
            if (state._excluded[i] == account) {
                state._excluded[i] = state._excluded[
                    state._excluded.length - 1
                ];
                state._tProtoOwned[account] = 0;
                state._isExcluded[account] = false;
                state._excluded.pop();
                break;
            }
        }
    }

    function setswapAndLiquifyEnabled(
        ProtoType.Universe storage state,
        bool _enabled
    ) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        state.swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function addLiquidity(
        ProtoType.Universe storage state,
        uint256 tokenAmount,
        uint256 bnbAmount
    ) public {
        // approve token transfer to cover all possible scenarios
        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            tokenAmount
        );

        // add the liquidity
        state.pancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            state.daoCouncil(),
            block.timestamp
        );
    }

    function isExcludedFromReward(
        ProtoType.Universe storage state,
        address account
    ) public view returns (bool) {
        return state._isExcluded[account];
    }

    function _takeLiquidity(
        ProtoType.Universe storage state,
        uint256 tLiquidity
    ) public {
        uint256 currentRate = _getRate(state);
        state._tLiquidityFeeTotal = state._tLiquidityFeeTotal.add(tLiquidity);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        state._rProtoOwned[address(this)] = state
        ._rProtoOwned[address(this)]
        .add(rLiquidity);
        if (state._isExcluded[address(this)])
            state._tProtoOwned[address(this)] = state
            ._tProtoOwned[address(this)]
            .add(tLiquidity);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IPancakeSwapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IPancakeSwapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IBEP20 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProtoDistribution {
    function getProtoShare(address account) external view returns (uint256);

    function unlockTime(address account) external view returns (uint256);

    function vestingTime(address account) external view returns (uint256);

    function getAllocation(address account)
        external
        view
        returns (
            uint256 _share,
            uint256 _unlockTime,
            uint256 _vestingTime
        );

    function preAllocatedWallets() external pure returns (address[39] memory);

    function initProtoDistribution(uint256 currentRate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";
import "./ProtoType.sol";

import "./ProtoDistribution.sol";
import "./ProtoBEP20V2.sol";
import "./ILawGovernance.sol";

library ProtoDao {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoType for ProtoType.LockedProto;
    using ProtoDistribution for ProtoType.PreAllocation;
    using ProtoBEP20V2 for ProtoType.Universe;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address, address, uint256);

    function _initProto(
        ProtoType.Universe storage state,
        ProtoType.PreAllocation storage allocation
    ) external {
        state.MAX = ~uint256(0);
        state._tTotal = 660000000e18;
        state._rTotal = (state.MAX - (state.MAX % state._tTotal));
        state._taxFee = 850; // 8.5
        state._previousTaxFee = state._taxFee;
        state._liquidityFee = 150; // 1.5
        state._previousLiquidityFee = state._liquidityFee;

        state.swapAndLiquifyEnabled = false;
        state.transferEnabled = true;
        state.MAXTxAmount = 120 * 10**6 * 10**18;
        state.numTokensSellToAddToLiquidity = 90000 * 10**18;
        state.numTokensSellToSwapBUSD = 80000 * 10**18;

        state._daoCouncil = 0x77132d30e3E7dBF2d8d0790090B3113DD3248223; // This will be transfered to Proto.Gold daoCouncil 0x76621B905cf21C4FceF8F4Ae1711c5a7bc040bc1 Binance Gnosis Multisig - BSC after DCE Two
        state.BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        state.pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        state.accumulationSafe = 0xE8a446d95cBDcD548511210628260632C748290a; // Proto Accumulation Safe - BSC
        state
        .auditsDevelopmentSafe = 0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20; // Proto Audits and Development Safe - BSC
        state.marketingSafe = 0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302; // Proto Marketing Multisig Safe - BSC
        state.daoSafe = 0xfC864d405AfcB40127A2c1555a0C7EE01E172023; // Proto DAO Multisig Safe - BSC

        state.charity = [
            0xd500EF7C6267233ed6711263d8f085e9856dCb23, // Proto Charity 1 Multisig Safe - BSC
            0x303C2B8eF3a12593a90a4cd80Dd0E0Be255B6715 // Proto Charity 2 Multisig Safe – BSC
        ];

        state.aidWallet = [
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F, // Aid 1
            0x47fd4076556EB209c616cCD5619393CC913e6E8A, // Aid 2
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972 // Aid 3
        ];

        allocation.initProtoDistribution(state);
        address[39] memory preAllocatedWallets = allocation
        .preAllocatedWallets();

        for (uint64 i = 0; i < preAllocatedWallets.length; i++) {
            (
                uint256 _share,
                uint256 _unlockTime,
                uint256 _vestingTime
            ) = allocation.getAllocation(preAllocatedWallets[i]);
            uint256 tokens = state.tokenFromReflection(_share);
            state._lOwned[preAllocatedWallets[i]] = ProtoType.LockedProto({
                isUnlocked: false,
                unlockedTime: _unlockTime,
                vesting: _vestingTime,
                lastReward: 0,
                count: 0,
                amount: tokens,
                lockedAmount: tokens,
                rOwned: _share
            });

            state._dceProtoClaimed[preAllocatedWallets[i]] = true;
        }

        state._rProtoOwned[address(this)] = allocation.totalLock;
        uint256 rDceSwapAndPancakeLiquiditySupply = state._rTotal.sub(
            allocation.totalLock
        );
        state._rProtoOwned[
            state.daoCouncil()
        ] = rDceSwapAndPancakeLiquiditySupply;

        emit Transfer(
            address(0),
            state.daoCouncil(),
            state.tokenFromReflection(rDceSwapAndPancakeLiquiditySupply)
        );

        // New Pancake Router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(
            state.pancakeRouterAddress
        );
        // set the rest of the contract variables
        state.pancakeSwapV2Router = _pancakeSwapV2Router;

        //exclude owner and this contract from fee
        state._isExcludedFromFee[state.daoCouncil()] = true;
        state._isExcludedFromFee[address(this)] = true;
    }

    function setdaoSafe(ProtoType.Universe storage state, address _v) external {
        state.daoSafe = _v;
    }

    function setauditsDevelopmentSafe(
        ProtoType.Universe storage state,
        address _v
    ) external {
        state.auditsDevelopmentSafe = _v;
    }

    function setmarketingSafe(ProtoType.Universe storage state, address _v)
        external
    {
        state.marketingSafe = _v;
    }

    function isProposalAccepted(
        ProtoType.Universe storage state,
        address newImplementation
    ) public view returns (bool) {
        ILawGovernance governor = ILawGovernance(state.lawGovernance);
        return governor.isProposalAccepted(newImplementation);
    }

    function approveProposal(
        ProtoType.Universe storage state,
        address newImplementation,
        bool isCurrentImplementation
    ) external {
        require(
            isCurrentImplementation ||
                state.approvedProposalsExpiry[newImplementation] == 0,
            "Proposal already marked as approved"
        );

        require(
            isCurrentImplementation ||
                isProposalAccepted(state, newImplementation),
            "Proposal not accepted"
        );
        state.approvedProposalsExpiry[newImplementation] =
            block.timestamp +
            24 hours;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface ILawGovernance {
    function isProposalAccepted(address implementation)
        external
        view
        returns (bool);
}

