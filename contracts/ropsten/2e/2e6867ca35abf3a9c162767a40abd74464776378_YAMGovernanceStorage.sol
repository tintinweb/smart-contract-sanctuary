/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

////////////////////////////////////////////////////////////////////////////////////////
//░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░ ████████  ██████  ██   ██ ███████ ███    ██  // 
//██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗    ██    ██    ██ ██  ██  ██      ████   ██  // 
//╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝    ██    ██    ██ █████   █████   ██ ██  ██  //
//░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░    ██    ██    ██ ██  ██  ██      ██  ██ ██  //
//██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░    ██     ██████  ██   ██ ██      ██   ████  //
//╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░    ██     ██████  ██   ██ ███████ ██   ████  //
////////////////////////////////////////////////////////////////////////////////////////


pragma solidity 0.5.17;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract YAMTokenStorage {

    using SafeMath for uint256;


    bool internal _notEntered;


    string public name;

    string public symbol;


    uint8 public decimals;


    address public gov;


    address public pendingGov;

    address public rebaser;


    address public incentivizer;


    uint256 public totalSupply;

  
    uint256 public constant internalDecimals = 10**24;

  
    uint256 public constant BASE = 10**18;

  
    uint256 public yamsScalingFactor;

    mapping (address => uint256) internal _yamBalances;

    mapping (address => mapping (address => uint256)) internal _allowedFragments;

    uint256 public initSupply;

}


contract YAMGovernanceStorage {

    mapping (address => address) internal _delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }


    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;


    mapping (address => uint32) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping (address => uint) public nonces;
}


contract YAMTokenInterface is YAMTokenStorage, YAMGovernanceStorage {


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


    event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor);

    event NewPendingGov(address oldPendingGov, address newPendingGov);


    event NewGov(address oldGov, address newGov);


    event NewRebaser(address oldRebaser, address newRebaser);


    event NewIncentivizer(address oldIncentivizer, address newIncentivizer);

 
    event Transfer(address indexed from, address indexed to, uint amount);

    event Approval(address indexed owner, address indexed spender, uint amount);


    event Mint(address to, uint256 amount);


    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function balanceOfUnderlying(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function maxScalingFactor() external view returns (uint256);


    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function delegate(address delegatee) external;
    function delegates(address delegator) external view returns (address);
    function getCurrentVotes(address account) external view returns (uint256);


    function mint(address to, uint256 amount) external returns (bool);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function _setRebaser(address rebaser_) external;
    function _setIncentivizer(address incentivizer_) external;
    function _setPendingGov(address pendingGov_) external;
    function _acceptGov() external;
}


contract YAMDelegationStorage {

    address public implementation;
}

contract YAMDelegatorInterface is YAMDelegationStorage {

    event NewImplementation(address oldImplementation, address newImplementation);


    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract YAMDelegator is YAMTokenInterface, YAMDelegatorInterface {

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initSupply_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
    {

        gov = msg.sender;


        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(string,string,uint8,address,uint256)",
                name_,
                symbol_,
                decimals_,
                msg.sender,
                initSupply_
            )
        );


        _setImplementation(implementation_, false, becomeImplementationData);

    }

    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public {
        require(msg.sender == gov, "YAMDelegator::_setImplementation: Caller must be gov");

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }


    function mint(address to, uint256 mintAmount)
        external
        returns (bool)
    {
        to; mintAmount; 
        delegateAndReturn();
    }


    function transfer(address dst, uint256 amount)
        external
        returns (bool)
    {
        dst; amount; 
        delegateAndReturn();
    }


    function transferFrom(
        address src,
        address dst,
        uint256 amount
    )
        external
        returns (bool)
    {
        src; dst; amount; 
        delegateAndReturn();
    }

 
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        spender; amount; 
        delegateAndReturn();
    }


    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        returns (bool)
    {
        spender; addedValue; 
        delegateAndReturn();
    }

    function maxScalingFactor()
        external
        view
        returns (uint256)
    {
        delegateToViewAndReturn();
    }

    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        returns (uint256)
    {
        epoch; indexDelta; positive;
        delegateAndReturn();
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        returns (bool)
    {
        spender; subtractedValue; 
        delegateAndReturn();
    }


    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256)
    {
        owner; spender; 
        delegateToViewAndReturn();
    }


    function delegates(
        address delegator
    )
        external
        view
        returns (address)
    {
        delegator; 
        delegateToViewAndReturn();
    }


    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        owner; 
        delegateToViewAndReturn();
    }


    function balanceOfUnderlying(address owner)
        external
        view
        returns (uint256)
    {
        owner; 
        delegateToViewAndReturn();
    }


    function _setPendingGov(address newPendingGov)
        external
    {
        newPendingGov; 
        delegateAndReturn();
    }

    function _setRebaser(address rebaser_)
        external
    {
        rebaser_; 
        delegateAndReturn();
    }

    function _setIncentivizer(address incentivizer_)
        external
    {
        incentivizer_; 
        delegateAndReturn();
    }


    function _acceptGov()
        external
    {
        delegateAndReturn();
    }


    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        account; blockNumber;
        delegateToViewAndReturn();
    }

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        delegatee; nonce; expiry; v; r; s;
        delegateAndReturn();
    }

    function delegate(address delegatee)
        external
    {
        delegatee;
        delegateAndReturn();
    }

    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        account;
        delegateToViewAndReturn();
    }


    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }


    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }


    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() private view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0xf2)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0xf2), returndatasize) }
        }
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0xf2)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }


    function () external payable {
        require(msg.value == 0,"YAMDelegator:fallback: cannot send value to fallback");


        delegateAndReturn();
    }
}