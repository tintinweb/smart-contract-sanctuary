// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

/**
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
 
    address private governor;
    address public pendingGovernor;

    event newPendingOwnership(address indexed from, address indexed to);
    event newOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `newOwnershipAccept` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit newPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function newOwnershipAccept() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit newOwnership(oldGovernor, governor);
        emit newPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

/**
 * The token is initially owned by the deployer address, who create the initial distribution.
 * For convenience, an initial supply can be passed in the constructor that will be
 * assigned to the deployer.
 *
 */
contract GREENDOGE is Governed, ERC20, ERC20Burnable {
    using SafeMath for uint256;
  
    // initialSupply variable initial state
    bool initialSupplyFinished = false;
  
    constructor() ERC20("Green Doge", "GREENDOGE") {
        Governed._initialize(msg.sender);
     }

    /**
     * @dev This implementation is agnostic to the way tokens are created. 
     * This means that a supply mechanism has to be added in a derived contract.
     * 
     *  'initailSupplyfinish' must be 'false' to execute this function,
     *  however after first use, 'true' will be changed to 'false' to lock this function forever.
     * 
     */
    function initialSupply(address contractAddress, uint256 InitialSupply) public onlyGovernor {
        require(initialSupplyFinished == false);
        _totalSupply = _totalSupply.add(InitialSupply);
        _balances[contractAddress] = _balances[contractAddress].add(InitialSupply);
        InitialSupplyFinished = true;
    }

   /**
     * @dev This return state of initialSupply function:
     * 
     * 'false' means that initialSupply is not done yet.
     * 'true' means that it's locked forever.
     * 
     */
    function isInitialSupplyFinished () public view returns (bool) {
        return InitialSupplyFinished;
    }
}