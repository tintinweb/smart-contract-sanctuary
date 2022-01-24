// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './abstracts/Context.sol';
import './interfaces/IDOSC.sol';

/// @author Nova Labs Scientists
/// @title Democratic Ownership
/// @notice  This contract is used for security reasons.
contract DemocraticOwnership is Context, IDOSC{

    /// @return is the public address of the first voter
    address public firstVoter;
            
    /// @return is the public address of the second voter
    address public secondVoter;
    
    address private addressAuthorized;
    uint256 private endChangeTime;

    /// @return is the timestamp until the voting process is reset
    uint256 public endVotingTime;

    /// @return is the number of seconds during the voting process active and restricted functions are callable
    uint256 public immutable duration;
    
    /// @return current number of vote during the voting process
    uint256 public numberOfVote;

    /// @return number of restricted call registered
    uint256 public numberOfChanges;
    
    /// @param date block timestamp of the registered Call
    /// @param SmartContractName Name of the smart contract that has a restricted call
    /// @param FunctionName name of the function that proceed to the restricted call
    struct Call {
        uint256 date;
        string SmartContractName;
        string FunctionName;
    }

    /// @custom:mapping used to map the change number id and the Call Structure data
    mapping(uint256 => Call) public calls;

    /// @custom:mapping used to verify is the address calling the smart contract is an owner or not. 
    mapping(address => bool) public ownership;

    /// @dev this event is emited each time the registerCall function is called.
    /// @param time block timestamp of the registered Call
    /// @param scname Name of the smart contract that has a restricted call
    /// @param funcname name of the function that proceed to the restricted call
    /// @notice it contains the same variables as the Call structure
    event ChangeRegistered(
        uint time, 
        string scname, 
        string funcname
    );

    /// @dev Return the latest authorized address to execute restricted functions in other contracts.
    /// @return addressAuthorized: the latest authorized address.
    /// @notice contracts that call this function must be authorized by calling the addSC function first.
    function readAuthorizedAddress() external view override returns (address) {
        return addressAuthorized;
    }

    /// @dev Return the latest block timestamp until a change in any contract parameter is allowed.
    /// @return endChangeTime: the latest block timestamp.
    /// @notice contracts that call this function must be authorized by calling the addSC function first.
    function readEndChangeTime() external view override returns (uint) {
        return endChangeTime;
    }

    /// @param scname name of the smart contract you are executing a change.
    /// @param funcname name of the function that has been called
    /// @dev Restricted functions in other smart contract have to call this function to register the change in parameters
    /// @notice contracts that call this function must be authorized by calling the addSC function first.
    function registerCall(string memory scname, string memory funcname) external override {
        uint time = block.timestamp;
        require(time <= endChangeTime, 'No Change is possible');
        numberOfChanges += 1;
        Call memory newcall = Call(time, scname, funcname);
        calls[numberOfChanges] = newcall;

        emit ChangeRegistered(time, scname, funcname);
    }

    /// @custom:fprivate Resets the state variables for the voteForChange funciton
    function reInitVoters() private {
        firstVoter = address(0);
        secondVoter = address(0);
        endVotingTime = 0;
        numberOfVote = 0;
    }

    /// @dev An admin call this function vote to allow a call on any restricted function managed by the contract
    /// @notice We need 3 vote to authorize a change, and the permission last only the duration time
    /// @notice If there is no 3 calls within the duration period, the votes will be reset
    /// @notice Only the second admin who calls the voteForChange function will be able to execute the restricted call
    function voteForChange () external onlyAdmins(){
        if (block.timestamp > endVotingTime && numberOfVote != 0){
            reInitVoters();
        }
        
        require(_msgSender() != firstVoter && _msgSender() != secondVoter, 'You already voted');
        numberOfVote +=  1;

        if( numberOfVote == 1) {
            endVotingTime = block.timestamp + duration;
            firstVoter = _msgSender();
        } else if (numberOfVote == 2) {
            secondVoter = _msgSender();
            addressAuthorized = _msgSender();
        }  else {
            endChangeTime = block.timestamp + duration;
            reInitVoters();
        }
    }

    /// @notice This modifier is used to avoid none admin users to call specific functions
    modifier onlyAdmins() {
        require(ownership[_msgSender()], 'Only admins');
        _;
    }

    /// @param _listAdmin list of all the administrator's public address.
    /// @param _duration number of seconds before a democratic process is reinitialize and number of seconds an admin is authorized to change parameters.
    /// @notice The duration should be a short period of time (recommended 30 minutes).
    constructor(address[] memory _listAdmin,
                uint _duration) 
    {
        for(uint i=0; i < _listAdmin.length; i++){
            ownership[_listAdmin[i]] = true;
        }
        duration = _duration;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @author Nova Labs Scientists
/// @notice  Provides the interface of democratic ownership smart contract to interact with.
interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function registerCall(string memory scname, string memory funcname) external;
}