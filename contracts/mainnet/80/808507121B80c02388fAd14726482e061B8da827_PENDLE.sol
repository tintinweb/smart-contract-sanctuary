/* solhint-disable  const-name-snakecase*/
// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IPENDLE.sol";
import "./Permissions.sol";
import "./Withdrawable.sol";
import "./SafeMath.sol";

/**
 * @notice The mechanics for delegating votes to other accounts is adapted from Compound
 *   https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol
 ***/
contract PENDLE is IPENDLE, Permissions, Withdrawable {
    using SafeMath for uint256;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    bool public constant override isPendleToken = true;
    string public constant name = "Pendle";
    string public constant symbol = "PENDLE";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    uint256 private constant TEAM_INVESTOR_ADVISOR_AMOUNT = 94917125 * 1e18;
    uint256 private constant ECOSYSTEM_FUND_TOKEN_AMOUNT = 46 * 1_000_000 * 1e18;
    uint256 private constant PUBLIC_SALES_TOKEN_AMOUNT = 16582875 * 1e18;
    uint256 private constant INITIAL_LIQUIDITY_EMISSION = 1200000 * 1e18;
    uint256 private constant CONFIG_DENOMINATOR = 1_000_000_000_000;
    uint256 private constant CONFIG_CHANGES_TIME_LOCK = 7 days;
    uint256 public override emissionRateMultiplierNumerator;
    uint256 public override terminalInflationRateNumerator;
    address public override liquidityIncentivesRecipient;
    bool public override isBurningAllowed;
    uint256 public override pendingEmissionRateMultiplierNumerator;
    uint256 public override pendingTerminalInflationRateNumerator;
    address public override pendingLiquidityIncentivesRecipient;
    bool public override pendingIsBurningAllowed;
    uint256 public override configChangesInitiated;
    uint256 public override startTime;
    uint256 public lastWeeklyEmission;
    uint256 public lastWeekEmissionSent;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;
    mapping(address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    event PendingConfigChanges(
        uint256 pendingEmissionRateMultiplierNumerator,
        uint256 pendingTerminalInflationRateNumerator,
        address pendingLiquidityIncentivesRecipient,
        bool pendingIsBurningAllowed
    );

    event ConfigsChanged(
        uint256 emissionRateMultiplierNumerator,
        uint256 terminalInflationRateNumerator,
        address liquidityIncentivesRecipient,
        bool isBurningAllowed
    );

    /**
     * @notice Construct a new PENDLE token
     */
    constructor(
        address _governance,
        address pendleTeamTokens,
        address pendleEcosystemFund,
        address salesMultisig,
        address _liquidityIncentivesRecipient
    ) Permissions(_governance) {
        require(
            pendleTeamTokens != address(0) &&
                pendleEcosystemFund != address(0) &&
                salesMultisig != address(0) &&
                _liquidityIncentivesRecipient != address(0),
            "ZERO_ADDRESS"
        );
        _mint(pendleTeamTokens, TEAM_INVESTOR_ADVISOR_AMOUNT);
        _mint(pendleEcosystemFund, ECOSYSTEM_FUND_TOKEN_AMOUNT);
        _mint(salesMultisig, PUBLIC_SALES_TOKEN_AMOUNT);
        _mint(_liquidityIncentivesRecipient, INITIAL_LIQUIDITY_EMISSION * 26);
        emissionRateMultiplierNumerator = (CONFIG_DENOMINATOR * 989) / 1000; // emission rate = 98.9% -> 1.1% decay
        terminalInflationRateNumerator = 379848538; // terminal inflation rate = 2% => weekly inflation = 0.0379848538%
        liquidityIncentivesRecipient = _liquidityIncentivesRecipient;
        startTime = block.timestamp;
        lastWeeklyEmission = INITIAL_LIQUIDITY_EMISSION;
        lastWeekEmissionSent = 26; // already done liquidity emissions for the first 26 weeks
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return Whether or not the approval succeeded
     **/
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override returns (bool) {
        _transfer(src, dst, amount);
        _approve(
            src,
            msg.sender,
            allowances[src][msg.sender].sub(amount, "TRANSFER_EXCEED_ALLOWANCE")
        );
        return true;
    }

    /**
     * @dev Increases the allowance granted to spender by the caller.
     * @param spender The address to increase the allowance from.
     * @param addedValue The amount allowance to add.
     * @return returns true if allowance has increased, otherwise false
     **/
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decreases the allowance granted to spender by the caller.
     * @param spender The address to reduce the allowance from.
     * @param subtractedValue The amount allowance to subtract.
     * @return Returns true if allowance has decreased, otherwise false.
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowances[msg.sender][spender].sub(subtractedValue, "NEGATIVE_ALLOWANCE")
        );
        return true;
    }

    /**
     * @dev Burns an amount of tokens from the msg.sender
     * @param amount The amount to burn
     * @return Returns true if the operation is successful
     **/
    function burn(uint256 amount) public override returns (bool) {
        require(isBurningAllowed, "BURNING_NOT_ALLOWED");
        _burn(msg.sender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     **/
    function allowance(address account, address spender) external view override returns (uint256) {
        return allowances[account][spender];
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
            );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID_SIGNATURE");
        require(nonce == nonces[signatory]++, "INVALID_NONCE");
        require(block.timestamp <= expiry, "SIGNATURE_EXPIRED");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else
                this function will revert to prevent misinformation
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "NOT_YET_DETERMINED");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transfer(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(src != address(0), "SENDER_ZERO_ADDR");
        require(dst != address(0), "RECEIVER_ZERO_ADDR");
        require(dst != address(this), "SEND_TO_TOKEN_CONTRACT");

        balances[src] = balances[src].sub(amount, "TRANSFER_EXCEED_BALANCE");
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _approve(
        address src,
        address dst,
        uint256 amount
    ) internal virtual {
        require(src != address(0), "OWNER_ZERO_ADDR");
        require(dst != address(0), "SPENDER_ZERO_ADDR");

        allowances[src][dst] = amount;
        emit Approval(src, dst, amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "BLOCK_NUM_EXCEED_32_BITS");

        if (
            nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function initiateConfigChanges(
        uint256 _emissionRateMultiplierNumerator,
        uint256 _terminalInflationRateNumerator,
        address _liquidityIncentivesRecipient,
        bool _isBurningAllowed
    ) external override onlyGovernance {
        require(_liquidityIncentivesRecipient != address(0), "ZERO_ADDRESS");
        pendingEmissionRateMultiplierNumerator = _emissionRateMultiplierNumerator;
        pendingTerminalInflationRateNumerator = _terminalInflationRateNumerator;
        pendingLiquidityIncentivesRecipient = _liquidityIncentivesRecipient;
        pendingIsBurningAllowed = _isBurningAllowed;
        emit PendingConfigChanges(
            _emissionRateMultiplierNumerator,
            _terminalInflationRateNumerator,
            _liquidityIncentivesRecipient,
            _isBurningAllowed
        );
        configChangesInitiated = block.timestamp;
    }

    function applyConfigChanges() external override {
        require(configChangesInitiated != 0, "UNINITIATED_CONFIG_CHANGES");
        require(
            block.timestamp > configChangesInitiated + CONFIG_CHANGES_TIME_LOCK,
            "TIMELOCK_IS_NOT_OVER"
        );

        _mintLiquidityEmissions(); // We must settle the pending liquidity emissions first, to make sure the weeks in the past follow the old configs

        emissionRateMultiplierNumerator = pendingEmissionRateMultiplierNumerator;
        terminalInflationRateNumerator = pendingTerminalInflationRateNumerator;
        liquidityIncentivesRecipient = pendingLiquidityIncentivesRecipient;
        isBurningAllowed = pendingIsBurningAllowed;
        configChangesInitiated = 0;
        emit ConfigsChanged(
            emissionRateMultiplierNumerator,
            terminalInflationRateNumerator,
            liquidityIncentivesRecipient,
            isBurningAllowed
        );
    }

    function claimLiquidityEmissions() external override returns (uint256 totalEmissions) {
        require(msg.sender == liquidityIncentivesRecipient, "NOT_INCENTIVES_RECIPIENT");
        totalEmissions = _mintLiquidityEmissions();
    }

    function _mintLiquidityEmissions() internal returns (uint256 totalEmissions) {
        uint256 _currentWeek = _getCurrentWeek();
        if (_currentWeek <= lastWeekEmissionSent) {
            return 0;
        }
        for (uint256 i = lastWeekEmissionSent + 1; i <= _currentWeek; i++) {
            if (i <= 259) {
                lastWeeklyEmission = lastWeeklyEmission.mul(emissionRateMultiplierNumerator).div(
                    CONFIG_DENOMINATOR
                );
            } else {
                lastWeeklyEmission = totalSupply.mul(terminalInflationRateNumerator).div(
                    CONFIG_DENOMINATOR
                );
            }
            _mint(liquidityIncentivesRecipient, lastWeeklyEmission);
            totalEmissions = totalEmissions.add(lastWeeklyEmission);
        }
        lastWeekEmissionSent = _currentWeek;
    }

    // get current 1-indexed week id
    function _getCurrentWeek() internal view returns (uint256 weekId) {
        weekId = (block.timestamp - startTime) / (7 days) + 1;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "MINT_TO_ZERO_ADDR");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BURN_FROM_ZERO_ADDRESS");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BURN_EXCEED_BALANCE");
        balances[account] = accountBalance.sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }
}