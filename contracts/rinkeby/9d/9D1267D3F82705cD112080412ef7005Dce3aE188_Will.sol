/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Will */
contract Will is Ownable {
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
    event TransferSuccess(
        address indexed estateHolder,
        address indexed beneficiary,
        address token,
        uint256 amount
    );

    event TransferFailure(
        address indexed estateHolder,
        address indexed beneficiary,
        address token,
        uint256 amount,
        string message
    );

    event Initialized(address indexed estateHolder);

    /// Estate modification functions, limited to the estate holder

    /** @notice creates an estate going to `beneficiary` and sets the checkin cadence of `cadence`
     */
    function initializeEstate(address beneficiary, uint256 cadence) public {
        require(
            beneficiaries[msg.sender].length == 0,
            "This sender already has an estate initialized"
        );
        require(
            cadence >= 60,
            "Cadence must be greater than 1 minute (60 seconds)"
        );

        // initialize beneficiaries ONLY if one is provided that is not address(0)
        if (beneficiary != address(0)) {
            beneficiaries[msg.sender].push(Beneficiary(beneficiary, 10000));
        }
        lastCheckIn[msg.sender] = block.timestamp;
        cadences[msg.sender] = cadence;

        emit Initialized(msg.sender);
    }

    /** @notice If an estate exists this removes all info from this contract.
     * @dev This does not revoke approve individual token permissions for this contract.
     */
    function revoke() public onlyEstateHolder {
        delete beneficiaries[msg.sender];
        lastCheckIn[msg.sender] = 0;
        cadences[msg.sender] = 0;
    }

    /** @notice Replaces beneficiaries and splits for the sender's estate.
     * @dev This also checks in the estate holder.
     * @param newAddresses addresses to add to will
     * @param newSplits splits to add to these beneficiaries
     */
    function updateBeneficiaries(
        address[] calldata newAddresses,
        uint256[] calldata newSplits
    ) public onlyEstateHolder {
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

        /// check the user in
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /** @notice Updates the sender's checkin cadence.
     * @dev Requires that the sender has run initializeEstate() in the past.
     * @param cadence the checkin cadence in seconds.
     */
    function updateCadence(uint256 cadence) public onlyEstateHolder {
        require(
            cadence >= 60,
            "Cadence must be greater than 1 minute (60 seconds)"
        );
        cadences[msg.sender] = cadence;
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /** @notice Allows the sender to checkin.
     * @dev TODO do we need more protection around time?
     * @dev Requires that the sender has run initializeEstate() in the past.
     */
    function checkin() public onlyEstateHolder {
        lastCheckIn[msg.sender] = block.timestamp;
    }

    /// Estate holder view only functions

    /** @notice Returns the time since the last checkin of `msg.sender`
     * @return time since last checkin.
     */
    function getTimeSinceLastCheckin()
        public
        view
        onlyEstateHolder
        returns (uint256)
    {
        uint256 lastCheckInMem = lastCheckIn[msg.sender];
        if (lastCheckInMem == 0) {
            return 0;
        }
        return (block.timestamp - lastCheckInMem);
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
    function getBeneficiaries()
        public
        view
        onlyEstateHolder
        returns (Beneficiary[] memory)
    {
        return beneficiaries[msg.sender];
    }

    /// CONTRACT OWNER ONLY view functions for convenience in web2

    /** @notice Gets a set of beneficiaries, restricted to the owner of contract
     * @param estateHolder owner of estate
     */
    function getBeneficiariesOwner(address estateHolder)
        public
        view
        onlyOwner
        returns (Beneficiary[] memory)
    {
        return beneficiaries[estateHolder];
    }

    /** @notice Checks the estate's checkin cadence, restricted to owner of contract
     * @param estateHolder owner of estate
     */
    function getCadenceOwner(address estateHolder)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return cadences[estateHolder];
    }

    /** @notice Checks how long it has been since the last checkin, restricted to owner of contract
     * @param estateHolder owner of estate
     */
    function getTimeSinceLastCheckinOwner(address estateHolder)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return lastCheckIn[estateHolder];
    }

    /// Public functions that can be called by anyone

    /** @notice Transfers the estate to beneficiaries if the estate holder is dead.
     * @param estateHolder the estate that will be distributed.
     */
    function transferIfDead(address estateHolder, address[] calldata tokens)
        public
    {
        // ensure user is an estate holder, fail if not
        require(
            cadences[estateHolder] != 0,
            "No estate exists for the specified address. Please start by having them call 'initializeEstate()'"
        );
        // Check timing, fail if the user has checked in within their cadence
        uint256 diff = block.timestamp - lastCheckIn[estateHolder];
        require(diff > cadences[estateHolder], "estate holder isn't dead!");

        // Loop through the ERC20 assets the estateHolder owns, transfer
        for (uint256 i = 0; i < tokens.length; i++) {
            //
            // get the token, check the allowance and balance
            splitTokenForBeneficiaries(tokens[i], estateHolder);
        }
    }

    /// Private Functions

    /** @notice Splits the tokens from the estate to the beneficiaries according to will.
     * @dev this function is only called by transferIfDead.
     * @param tokenAddress the address of the token to split.
     * @param estateHolder the address of the estate holder.
     */
    function splitTokenForBeneficiaries(
        address tokenAddress,
        address estateHolder
    ) private {
        if (!isContract(tokenAddress)) return;
        IERC20 token = IERC20(tokenAddress);
        try token.allowance(estateHolder, address(this)) returns (
            uint256 allowance
        ) {
            try token.balanceOf(estateHolder) returns (uint256 balance) {
                // External calls succeeded, proceed.
                // If the estate holder does not have this token or has not given the contract allowance, skip
                if (allowance == 0 || balance == 0) return;

                // The value that gets sent should be the lower of allowance and balance
                if (balance < allowance) {
                    allowance = balance;
                }

                // Run through the beneficiaries and accordingly split up the assets
                for (
                    uint256 i = 0;
                    i < beneficiaries[estateHolder].length;
                    i++
                ) {
                    uint256 splitTransferAmount = (beneficiaries[estateHolder][
                        i
                    ].split * allowance) / (10000);

                    // Execute transferFrom
                    try
                        token.transferFrom(
                            estateHolder,
                            beneficiaries[estateHolder][i].beneficiaryAddress,
                            splitTransferAmount
                        )
                    {
                        emit TransferSuccess(
                            estateHolder,
                            beneficiaries[estateHolder][i].beneficiaryAddress,
                            tokenAddress,
                            splitTransferAmount
                        );
                    } catch Error(string memory _err) {
                        emit TransferFailure(
                            estateHolder,
                            beneficiaries[estateHolder][i].beneficiaryAddress,
                            tokenAddress,
                            splitTransferAmount,
                            _err
                        );
                        return;
                    }
                }
            } catch {
                return;
            }
        } catch {
            return;
        }
    }

    /** @notice Checks if the inputted address is a contract or not - to prevent failure.
     * @dev this function is only called by transferIfDead.
     * @param _addr the address of the token to split.
     */
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /// Modifiers

    /** @notice Executes to restrict methods to estate holder only
     */
    modifier onlyEstateHolder() {
        require(
            cadences[msg.sender] != 0,
            "No estate exists for this sender, please start by calling 'initializeEstate()'"
        );
        _;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
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