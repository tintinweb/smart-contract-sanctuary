// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

/**
 * @dev 
 */

import './abstracts/Context.sol';

import './interfaces/IDOSC.sol';

contract DemocraticOwnership is Context, IDOSC{

    address private admin1;
    address private admin2;
    address private admin3;
    address private admin4;
    address private admin5;

    address public firstVoter;
    address public secondVoter;

    address public addressAuthorized;

    uint256 public endChangeTime;
    uint256 public endVotingTime;    
    uint256 public duration;
    
    uint public numberOfVote;
    uint public numberOfChanges;
        
    struct Call {
        uint date;
        string SmartContractName;
        string FunctionName;
    }

    mapping(uint => Call) public calls;
    mapping(address => bool) public authorizedSC;
    mapping(address => bool) public ownership;

    event ChangeRegistered(
        uint time, 
        string scname, 
        string funcname
    );

    function readAuthorizedAddress() external view override returns (address) {
        require(authorizedSC[_msgSender()], "must be authorized");
        return addressAuthorized;
    }

    function readEndChangeTime() external view override returns (uint) {
        require(authorizedSC[_msgSender()], "must be authorized");
        return endChangeTime;
    }

    function addSC(address scToAdd) external onlyAdmins() {
        authorizedSC[scToAdd] = true;
    }

    function registerCall(string memory scname, string memory funcname) external override {
        require(authorizedSC[_msgSender()], "must be authorized");
        uint time = block.timestamp;
        require(time <= endChangeTime, 'No Change is possible');
        numberOfChanges += 1;
        Call memory newcall = Call(time, scname, funcname);
        calls[numberOfChanges] = newcall;

        emit ChangeRegistered(time, scname, funcname);
    }

    function reInitVoters() private {
        firstVoter = address(0);
        secondVoter = address(0);
        endVotingTime = 0;
        numberOfVote = 0;
    }

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

    modifier onlyAdmins() {
        require(ownership[_msgSender()], 'Only admins');
        _;
    }

    constructor(address _admin1, 
                address _admin2,
                address _admin3,
                address _admin4,
                address _admin5,
                uint _duration) 
    {
        require(_admin1 != address(0), 'can not be zero Address');
        require(_admin2 != address(0), 'can not be zero Address');
        require(_admin3 != address(0), 'can not be zero Address');
        require(_admin4 != address(0), 'can not be zero Address');
        require(_admin5 != address(0), 'can not be zero Address');

        admin1 = _admin1;
        ownership[admin1] = true;
        admin2 = _admin2;
        ownership[admin2] = true;
        admin3 = _admin3;
        ownership[admin3] = true;
        admin4 = _admin4;
        ownership[admin4] = true;
        admin5 = _admin5;
        ownership[admin5] = true;
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
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

/**
 * @dev Provides the interface of democratic ownership smart contract
 * to interact with. The callable functions are readAuthorizedAddress,
 * readEndChangeTime and RegisterCall.
 */

interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function registerCall(string memory scname, string memory funcname) external;
}