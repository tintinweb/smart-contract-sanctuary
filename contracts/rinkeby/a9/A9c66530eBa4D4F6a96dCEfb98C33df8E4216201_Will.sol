/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title Will */
contract Will {
    /// Owner address to confirm some calls
    address owner_;

    /// The set of the contract's supported tokens to transfer
    address[] supportedTokens;

    struct Beneficiary {
        address beneficiaryAddress;
        uint256 split; /// multiplied by 10000 (4 decimal point accuracy) - so 0.25 split is 2500
    }

    /// Mapping of an estate holder's address to their set of beneficiaries
    mapping(address => Beneficiary[]) beneficiaries;

    /// Estate information for the estateholder
    mapping(address => uint256) cadences;
    mapping(address => uint256) lastCheckIn;

    /// Events
    event initialized(address sender, address beneficiary, uint256 cadence);
    event revoked(address sender);
    event beneficiariesUpdated(address[] addresses, uint256[] splits);
    event tokenAddedToWill(address tokenAddress);
    event holderDiedAndTokensTransferred(address estateHolder);

    constructor() {
        owner_ = msg.sender;
    }

    ///View only functions, some with restrictions

    /** @notice Returns the time since the last checkin of `estateHolder`
     * @param estateHolder estate holder's address.
     * @return time since last checkin.
     */
    function timeSinceLastCheckin(address estateHolder)
        public
        view
        returns (uint256)
    {
        require(
            msg.sender == owner_,
            "This function is only supported by the contract owner"
        );
        if (lastCheckIn[estateHolder] == 0) {
            return 0;
        }
        return (block.timestamp - lastCheckIn[estateHolder]);
    }

    /** @notice Adds `tokenAddress` to the global list of supported tokens.
     * @dev TODO an infinite number of addresses can be added via this method - is that okay?
     * @param tokenAddress address of the token being added.
     */
    function addSupportedToken(address tokenAddress) public {
        /// Ensure that the token isn't already supported
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            require(
                tokenAddress != supportedTokens[i],
                "This token is already supported!"
            );
        }

        supportedTokens.push(tokenAddress);
        emit tokenAddedToWill(tokenAddress);
    }

    /** @notice checks of the sender is an estate holder.
     * @return bool if the sender is an estate holder or noot.
     */
    function isEstateHolder() public view returns (bool) {
        return beneficiaries[msg.sender].length != 0;
    }

    /** @notice the estate owner can get a list of their beneficiaries.
     * @return list of the sender's beneficiaries.
     */
    function getBeneficiaryInfo() public view returns (Beneficiary[] memory) {
        return beneficiaries[msg.sender];
    }

    /// Estate modification functions

    /** @notice creates an estate going to `beneficiary` and sets the checkin cadence of `cadence`
     */
    function initialize(address beneficiary, uint256 cadence) public {
        beneficiaries[msg.sender].push(Beneficiary(beneficiary, 10000));
        lastCheckIn[msg.sender] = block.timestamp;
        cadences[msg.sender] = cadence;
        emit initialized(msg.sender, beneficiary, cadence);
    }

    /** @notice If an estate exists this removes all info from this contract.
     * @dev This does not revoke approve individual token permissions for this contract.
     */
    function revoke() public {
        require(
            beneficiaries[msg.sender].length != 0,
            "No estate exists for this sender."
        );
        delete beneficiaries[msg.sender];
        lastCheckIn[msg.sender] = 0;
        cadences[msg.sender] = 0;
        emit revoked(msg.sender);
    }

    /** @notice Replaces beneficiaries and splits for the sender's estate.
     * @dev This also checks in the estate holder.
     * @param newAddresses addresses to add to will
     * @param newSplits splits to add to these beneficiaries
     */
    function updateBeneficiaries(
        address[] calldata newAddresses,
        uint256[] calldata newSplits
    ) public {
        require(
            beneficiaries[msg.sender].length != 0,
            "No estate exists for this sender."
        );
        require(
            newAddresses.length == newSplits.length,
            "There must be the same number of beneficiaries and splits"
        );
        require(
            newAddresses.length > 0,
            "You can't empty all beneficiaries. If you want to terminate the contract, call 'revoke()'"
        );

        uint256 newSplitTotal = 0;

        for (uint256 i = 0; i < newAddresses.length; i++) {
            newSplitTotal += newSplits[i];
            if (newSplitTotal > 10000) break;
        }

        require(
            newSplitTotal <= 10000,
            "The splits for the given beneficiaries exceed 100%. Please re-try."
        );

        /// Begin the delete and reloop to add new beneficiaries
        delete beneficiaries[msg.sender];

        for (uint256 i = 0; i < newAddresses.length; i++) {
            /// Create new Beneficiary struct and add to storage
            beneficiaries[msg.sender].push(
                Beneficiary(newAddresses[i], newSplits[i])
            );
        }

        emit beneficiariesUpdated(newAddresses, newSplits);

        /// check the user in
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /** @notice Updates the sender's checkin cadence.
     * @dev Requires that the sender has run initialize() in the past.
     * @param cadence the checkin cadence in seconds.
     */
    function updateCadence(uint256 cadence) public {
        require(
            beneficiaries[msg.sender].length != 0,
            "No estate exists for this sender, please start by calling 'initialize()'"
        );
        cadences[msg.sender] = cadence;
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /** @notice Allows the sender to checkin.
     * @dev TODO do we need more protection around time?
     * @dev Requires that the sender has run initialize() in the past.
     */
    function checkin() public {
        require(
            beneficiaries[msg.sender].length != 0,
            "No estate exists for this sender, please start by calling 'initialize()'"
        );
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /** @notice Transfers the estate to beneficiaries if the estate holder is dead.
     * @dev TODO do we need more protections around checkins? This must be a public function.
     * @param estateHolder the estate that will be distributed.
     */
    function transferIfDead(address estateHolder) public {
        // ensure user is an estate holder, fail if not
        require(
            beneficiaries[estateHolder].length != 0,
            "No estate exists for the specified address. Please start by having them call 'initialize()'"
        );
        // Check timing, fail if the user has checked in within their cadence
        uint256 diff = block.timestamp - lastCheckIn[estateHolder];
        require(diff > cadences[estateHolder], "estate holder isn't dead!");

        // Loop through the ERC20 assets the estateHolder owns, transfer
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            // get the token, check the allowance and balance
            splitTokenForBeneficiaries(
                IERC20(supportedTokens[i]),
                estateHolder
            );
        }

        emit holderDiedAndTokensTransferred(estateHolder);
    }

    /// Private Functions

    /** @notice Splits the tokens from the estate to the beneficiaries according to will.
     * @dev this function is only called by transferIfDead.
     * @param token the address of the token to split.
     * @param estateHolder the address of the estate holder.
     */
    function splitTokenForBeneficiaries(IERC20 token, address estateHolder)
        private
    {
        uint256 allowance = token.allowance(estateHolder, address(this));
        uint256 balance = token.balanceOf(estateHolder);

        // If the estate holder does not have this token or has not given the contract allowance, skip
        if (allowance == 0 || balance == 0) return;

        // The value that gets sent should be the lower of allowance and balance
        if (balance < allowance) {
            allowance = balance;
        }

        // Run through the beneficiaries and accordingly split up the assets
        for (uint256 i = 0; i < beneficiaries[estateHolder].length; i++) {
            uint256 splitTransferAmount = (beneficiaries[estateHolder][i]
                .split * allowance) / (10000);

            // Execute transferFrom
            token.transferFrom(
                estateHolder,
                beneficiaries[estateHolder][i].beneficiaryAddress,
                splitTransferAmount
            );
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}