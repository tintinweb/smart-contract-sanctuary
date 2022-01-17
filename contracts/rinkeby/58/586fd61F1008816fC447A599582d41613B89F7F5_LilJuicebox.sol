// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import '@rari-capital/solmate/src/tokens/ERC20.sol';
import '@rari-capital/solmate/src/utils/SafeTransferLib.sol';

/// @title Project Share ERC20
/// @author Miguel Piedrafita
/// @notice ERC20 token representing a share on LilJuicebox
contract ProjectShare is ERC20 {
	/// ERRORS ///

	/// @notice Thrown when trying to directly call the mint or burn functions
	error Unauthorized();

	/// @notice The manager of this campaign
	address public immutable manager;

	/// @notice Deploys a ProjectShare instance with the specified name and symbol
	/// @param name The name of the deployed token
	/// @param symbol The symbol of the deployed token
	/// @dev Deployed from the constructor of the LilJuicebox contract
	constructor(string memory name, string memory symbol) payable ERC20(name, symbol, 18) {
		manager = msg.sender;
	}

	/// @notice Grants the specified address a specified amount of tokens
	/// @param to The address that will receive the tokens
	/// @param amount the amount of tokens to receive
	/// @dev This function should be called from within LilJuicebox, and will revert if manually accessed
	function mint(address to, uint256 amount) public payable {
		if (msg.sender != manager) revert Unauthorized();

		_mint(to, amount);
	}

	/// @notice Burns a specified amount of tokens from a specified address' balance
	/// @param from The address that will get their tokens burned
	/// @param amount the amount of tokens to burn
	/// @dev This function should be called from within LilJuicebox, and will revert if manually accessed
	function burn(address from, uint256 amount) public payable {
		if (msg.sender != manager) revert Unauthorized();

		_burn(from, amount);
	}
}

/// @title lil juicebox
/// @author Miguel Piedrafita
/// @notice Very simple token sale + refund manager.
contract LilJuicebox {
	/// ERRORS ///

	/// @notice Thrown when trying to change the state of the campaign or renounce the contract without being the manager
	error Unauthorized();

	/// @notice Thrown when trying to claim a refund while refunds are closed
	error RefundsClosed();

	/// @notice Thrown when trying to contribute while contributions are closed
	error ContributionsClosed();

	/// @notice Thrown when trying to contribute with an address that is not ba5ed
	error NotBased();

	/// EVENTS ///

	/// @notice Emitted when the manager renounces the contract, locking its current state forever
	event Renounced();

	/// @notice Emitted when the manager withdrawns a share of the raised funds
	/// @param amount The amount of ETH withdrawn
	event Withdrawn(uint256 amount);

	/// @notice Emitted when the state of the campaign is changed
	/// @param state The new state of the campaign
	event StateUpdated(State state);

	/// @notice Emitted when a contributor successfully claims a refund
	/// @param contributor The address of the contributor
	/// @param amount The amount of ETH refunded
	event Refunded(address indexed contributor, uint256 amount);

	/// @notice Emitted when a user contributes to the campaign
	/// @param contributor The address of the contributor
	/// @param amount The amount of ETH contributed
	event Contributed(address indexed contributor, uint256 amount);

	/// @notice Possible states of a campagin
	enum State {
		CLOSED,
		OPEN,
		REFUNDING
	}

	/// @notice The address of the user who can withdraw funds and change the state of the campaign
	address public manager;

	/// @notice The current state of the campaign
	/// @dev This automatically generates a getter for us!
	State public getState;

	/// @notice The address of the ERC20 token representing shares of this campaign
	ProjectShare public immutable token;

	/// @notice The amount of ERC20 tokens to issue per ETH received
	uint256 public constant TOKENS_PER_ETH = 1_000_000;

	/// @notice Deploys a LilJuicebox instance with the specified name and symbol
	/// @param name The name of the ERC20 token
	/// @param symbol The symbol of the ERC20 token
	constructor(string memory name, string memory symbol) payable {
		manager = msg.sender;
		getState = State.OPEN;
		token = new ProjectShare(name, symbol);
	}

	/// @notice Contribute to the campaign by sending ETH, if contributions are open
	function contribute() public payable {
		if (getState != State.OPEN) revert ContributionsClosed();
		if (!isBased()) revert NotBased();

		emit Contributed(msg.sender, msg.value);

		token.mint(msg.sender, msg.value * TOKENS_PER_ETH);
	}

	/// @notice check if the contributor has a ba5ed address
	/// @return bool denoting if addresses first 5 bytes are ba5ed hex code 
	function isBased() public view returns (bool) {
		return uint160(msg.sender) >> 140 == 0xba5ed;
	}

	/// @notice Receive a refund for your contribution to the campaign, if refunds are open
	function refund(uint256 amount) public payable {
		if (getState != State.REFUNDING) revert RefundsClosed();

		uint256 refundETH;
		assembly {
			refundETH := div(amount, TOKENS_PER_ETH)
		}

		token.burn(msg.sender, amount);
		emit Refunded(msg.sender, refundETH);

		SafeTransferLib.safeTransferETH(msg.sender, refundETH);
	}

	/// @notice Withdraw a share of the raised funds, only available to the manager of the campaign
	function withdraw() public payable {
		if (msg.sender != manager) revert Unauthorized();

		uint256 amount = address(this).balance;

		emit Withdrawn(amount);
		SafeTransferLib.safeTransferETH(msg.sender, amount);
	}

	/// @notice Update the state of the campaign, only available to the manager of the campaign
	/// @param state The new state of the campaign
	function setState(State state) public payable {
		if (msg.sender != manager) revert Unauthorized();

		getState = state;
		emit StateUpdated(state);
	}

	/// @notice Renounce ownership of the campaign, effectively locking all settings in place. Only available to the manager of the campaign
	function renounce() public payable {
		if (msg.sender != manager) revert Unauthorized();

		emit Renounced();
		manager = address(0);
	}

	/// @dev This function ensures this contract can receive ETH
	receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}