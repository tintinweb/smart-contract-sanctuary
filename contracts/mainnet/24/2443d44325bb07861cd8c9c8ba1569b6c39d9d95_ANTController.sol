// Sources flattened with buidler v1.4.3 https://buidler.dev

// File contracts/interfaces/IMiniMeLike.sol

pragma solidity ^0.5.0;


/**
 * @dev A sparse MiniMe-like interface containing just `generateTokens()`.
 */
interface IMiniMeLike {
    /**
     * @notice Generates `_amount` tokens that are assigned to `_owner`
     * @param _owner The address that will be assigned the new tokens
     * @param _amount The quantity of tokens generated
     * @return True if the tokens are generated correctly
    */
    function generateTokens(address _owner, uint _amount) external returns (bool);
}


// File contracts/interfaces/ITokenController.sol

pragma solidity ^0.5.0;


/**
 * @dev The MiniMe token controller contract must implement these functions
 *      ANT was compiled with solc 0.4.8, so there is no point in marking any of the functions as `view`.
 */
interface ITokenController {
    /**
    * @notice Called when `_owner` sends ether to the MiniMe Token contract
    * @param _owner The address that sent the ether to create tokens
    * @return True if the ether is accepted, false if it throws
    */
    function proxyPayment(address _owner) external payable returns (bool);

    /**
    * @notice Notifies the controller about a token transfer allowing the controller to react if desired
    * @param _from The origin of the transfer
    * @param _to The destination of the transfer
    * @param _amount The amount of the transfer
    * @return False if the controller does not authorize the transfer
    */
    function onTransfer(address _from, address _to, uint _amount) external returns (bool);

    /**
    * @notice Notifies the controller about an approval allowing the controller to react if desired
    * @param _owner The address that calls `approve()`
    * @param _spender The spender in the `approve()` call
    * @param _amount The amount in the `approve()` call
    * @return False if the controller does not authorize the approval
    */
    function onApprove(address _owner, address _spender, uint _amount) external returns (bool);
}


// File contracts/ANTController.sol

pragma solidity 0.5.17;




contract ANTController is ITokenController {
    string private constant ERROR_NOT_MINTER = "ANTC_SENDER_NOT_MINTER";
    string private constant ERROR_NOT_ANT = "ANTC_SENDER_NOT_ANT";

    IMiniMeLike public ant;
    address public minter;

    event ChangedMinter(address indexed minter);

    /**
    * @dev Ensure the msg.sender is the minter
    */
    modifier onlyMinter {
        require(msg.sender == minter, ERROR_NOT_MINTER);
        _;
    }

    constructor(IMiniMeLike _ant, address _minter) public {
        ant = _ant;
        _changeMinter(_minter);
    }

    /**
    * @notice Generate ANT for a specified address
    * @dev Note that failure to generate the requested tokens will result in a revert
    * @param _owner Address to receive ANT
    * @param _amount Amount to generate
    * @return True if the tokens are generated correctly
    */
    function generateTokens(address _owner, uint256 _amount) external onlyMinter returns (bool) {
        return ant.generateTokens(_owner, _amount);
    }

    /**
    * @notice Change the permitted minter to another address
    * @param _newMinter Address that will be permitted to mint ANT
    */
    function changeMinter(address _newMinter) external onlyMinter {
        _changeMinter(_newMinter);
    }

    // Default ITokenController settings for allowing token transfers.
    // ANT was compiled with solc 0.4.8, so there is no point in marking any of these functions as `view`:
    //   - The original interface does not specify these as `constant`
    //   - ANT does not use a `staticcall` when calling into these functions

    /**
    * @dev Callback function called from MiniMe-like instances when ETH is sent into the token contract
    *      It allows specifying a custom logic to control if the ETH should be accepted or not
    * @return Always false, this controller does not permit the ANT contract to receive ETH transfers
    */
    function proxyPayment(address /* _owner */) external payable returns (bool) {
        // We only apply this extra check here to ensure `proxyPayment()` cannot be sent ETH from arbitrary addresses
        require(msg.sender == address(ant), ERROR_NOT_ANT);
        return false;
    }

    /**
    * @dev Callback function called from MiniMe-like instances when an ERC20 transfer is requested
    *      It allows specifying a custom logic to control if a transfer should be allowed or not
    * @return Always true, this controller allows all transfers
    */
    function onTransfer(address /* _from */, address /* _to */, uint /* _amount */) external returns (bool) {
        return true;
    }

    /**
    * @dev Callback function called from MiniMe-like instances when an ERC20 approval is requested
    *      It allows specifying a custom logic to control if an approval should be allowed or not
    * @return Always true, this controller allows all approvals
    */
    function onApprove(address /* _owner */, address /* _spender */, uint /* _amount */) external returns (bool) {
        return true;
    }

    // Internal fns

    function _changeMinter(address _newMinter) internal {
        minter = _newMinter;
        emit ChangedMinter(_newMinter);
    }
}