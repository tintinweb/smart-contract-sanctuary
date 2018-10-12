pragma solidity ^0.4.24;

// File: contracts/interfaces/IOwned.sol

/*
    Owned Contract Interface
*/
contract IOwned {
    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function transferOwnershipNow(address newContractOwner) public;
}

// File: contracts/utility/Owned.sol

/*
    This is the "owned" utility contract used by bancor with one additional function - transferOwnershipNow()
    
    The original unmodified version can be found here:
    https://github.com/bancorprotocol/contracts/commit/63480ca28534830f184d3c4bf799c1f90d113846
    
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner
        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
        @dev transfers the contract ownership without needing the new owner to accept ownership
        @param newContractOwner    new contract owner
    */
    function transferOwnershipNow(address newContractOwner) ownerOnly public {
        require(newContractOwner != owner);
        emit OwnerUpdate(owner, newContractOwner);
        owner = newContractOwner;
    }

}

// File: contracts/interfaces/IERC20.sol

/*
    Smart Token Interface
*/
contract IERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/interfaces/ICommunityAccount.sol

/*
    Community Account Interface
*/
contract ICommunityAccount is IOwned {
    function setStakedBalances(uint _amount, address msgSender) public;
    function setTotalStaked(uint _totalStaked) public;
    function setTimeStaked(uint _timeStaked, address msgSender) public;
    function setEscrowedTaskBalances(uint uuid, uint balance) public;
    function setEscrowedProjectBalances(uint uuid, uint balance) public;
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public;
    function setTotalTaskEscrow(uint balance) public;
    function setTotalProjectEscrow(uint balance) public;
}

// File: contracts/CommunityAccount.sol

/**
@title Tribe Account
@notice This contract is used as a community&#39;s data store.
@notice Advantages:
@notice 1) Decouple logic contract from data contract
@notice 2) Safely upgrade logic contract without compromising stored data
*/
contract CommunityAccount is Owned, ICommunityAccount {

    // Staking Variables.  In community token
    mapping (address => uint256) public stakedBalances;
    mapping (address => uint256) public timeStaked;
    uint public totalStaked;

    // Escrow variables.  In native token
    uint public totalTaskEscrow;
    uint public totalProjectEscrow;
    mapping (uint256 => uint256) public escrowedTaskBalances;
    mapping (uint256 => uint256) public escrowedProjectBalances;
    mapping (uint256 => address) public escrowedProjectPayees;
    
    /**
    @notice This function allows the community to transfer tokens out of the contract.
    @param tokenContractAddress Address of community contract
    @param destination Destination address of user looking to remove tokens from contract
    @param amount Amount to transfer out of community
    */
    function transferTokensOut(address tokenContractAddress, address destination, uint amount) public ownerOnly returns(bool result) {
        IERC20 token = IERC20(tokenContractAddress);
        return token.transfer(destination, amount);
    }

    /**
    @notice This is the community staking method
    @param _amount Amount to be staked
    @param msgSender Address of the staker
    */
    function setStakedBalances(uint _amount, address msgSender) public ownerOnly {
        stakedBalances[msgSender] = _amount;
    }

    /**
    @param _totalStaked Set total amount staked in community
     */
    function setTotalStaked(uint _totalStaked) public ownerOnly {
        totalStaked = _totalStaked;
    }

    /**
    @param _timeStaked Time of user staking into community
    @param msgSender Staker address
     */
    function setTimeStaked(uint _timeStaked, address msgSender) public ownerOnly {
        timeStaked[msgSender] = _timeStaked;
    }

    /**
    @param uuid id of escrowed task
    @param balance Balance to be set of escrowed task
     */
    function setEscrowedTaskBalances(uint uuid, uint balance) public ownerOnly {
        escrowedTaskBalances[uuid] = balance;
    }

    /**
    @param uuid id of escrowed project
    @param balance Balance to be set of escrowed project
     */
    function setEscrowedProjectBalances(uint uuid, uint balance) public ownerOnly {
        escrowedProjectBalances[uuid] = balance;
    }

    /**
    @param uuid id of escrowed project
    @param payeeAddress Address funds will go to once project completed
     */
    function setEscrowedProjectPayees(uint uuid, address payeeAddress) public ownerOnly {
        escrowedProjectPayees[uuid] = payeeAddress;
    }

    /**
    @param balance Balance which to set total task escrow to
     */
    function setTotalTaskEscrow(uint balance) public ownerOnly {
        totalTaskEscrow = balance;
    }

    /**
    @param balance Balance which to set total project to
     */
    function setTotalProjectEscrow(uint balance) public ownerOnly {
        totalProjectEscrow = balance;
    }
}