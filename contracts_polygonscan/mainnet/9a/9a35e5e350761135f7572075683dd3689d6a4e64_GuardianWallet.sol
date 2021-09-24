/**
 *Submitted for verification at polygonscan.com on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract GuardianActionsUpgradeableProxy {
    address implementation;
    mapping(address => bool) admins;
    
    uint256 version;
    
    constructor () {
        admins[msg.sender] = true;
    }
    
    function _delegate(address _implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())
            
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())
            
            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    fallback() external payable {
        _delegate(implementation);
    }
    
    receive() external payable {
        _delegate(implementation);
    }
    
    function setImplementation (address _implementation) public {
        require(admins[msg.sender], "Must be admin");
        version++;
        implementation = _implementation;
    }
    
    function addAdmin (address _admin) public {
        require(admins[msg.sender], "Must be admin");
        admins[_admin] = true;
    }
    
    function removeAdmin (address _admin) public {
        require(admins[msg.sender], "Must be admin");
        require(admins[_admin], "Address is not an admin");
        admins[_admin] = false;
    }
}








contract GuardianWallet {

    struct Guardian {
        bool exists; //does this mapping exist
        address addr; //address of guardian
        bool active; //is this guardian currently a.... guardian?
    }
    
    struct Action {
        uint8 id; //the type of action
        bytes32[] params; //the parameters for the action to be performed
        uint8 required; //how many guardians are required for approval
        uint8 approved; //how many have...
        address[] approvals; //addresses of approvals
        bool executed; //has the action been executed?
    }
    
    uint public balance = 0; //native currency balance (ie. ETH/MATIC/BNB/...)
    address public owner; //contract deployer (and first guardian)
    Guardian[] public guardians; //all Guardians (past and present)
    Action[] public actions; //all actions requested (past and present)
    uint8 public numGuardians = 0; //current number of guardians active
    uint256 public numActions = 0; //incremental action ID counter
    mapping(address => Guardian) addrToGuardian;
    
    uint160 nativeAsset = uint160(0x0000000000000000000000000000000000000000);


    constructor() payable {
        balance += msg.value;
        owner = msg.sender;
        addGuardian(msg.sender);
    }
    
    
    fallback() external payable {
        balance += msg.value;
    }

    
    receive() external payable {
        balance += msg.value;
    }

    function requireGuardian(address addr) internal {
        require(addrToGuardian[addr].exists && addrToGuardian[addr].active, "Only guardians may call this function");
    }
    
    function addGuardian(address addr) public {
        require(
            (addrToGuardian[msg.sender].exists && addrToGuardian[msg.sender].active) 
            || 
            (numGuardians == 0 && msg.sender == owner), 
            "Only guardians may call this function"
        );
        
        Guardian memory guardian = addrToGuardian[addr];
        if (guardian.exists) {
            require(guardian.active == false, "Specified address is already a guardian");
            guardian.active = true;
            numGuardians++;
            return;
        }
        
        guardian = Guardian({
            exists: true,
            addr: addr,
            active: true
        });
        
        guardians.push(guardian);
        addrToGuardian[addr] = guardian;
        numGuardians++;
        //emit guardian added event
    }
    
    
    
    function removeGuardian(address addr) public {
        requireGuardian(msg.sender);
        require(numGuardians > 1, "Must always have atleast one guardian");
        Guardian storage guardian = addrToGuardian[addr];
        require(guardian.exists && guardian.active, "Specified address is not a guardian");
        guardian.active = false;
        numGuardians--;
        //emit guardian removal event
    }
    
    
    function getBalance(address asset) public view returns (uint256 currentBalance) {
        if (uint160(asset) == nativeAsset) return balance;
        return IERC20(asset).balanceOf(address(this));
    }
    
    
    /*
        Deposit the native currency to the contract
    */
    function deposit() public payable returns (uint256 newBalance) {
        balance += msg.value;
        return balance;
    }

    
    /*
        Withdraw the native currency (e.g. ETH, MATIC, BNB, ...) to the caller's address
    */
    function withdraw(address asset, uint256 amount, address recipient) public returns (uint256 actionId) {
        requireGuardian(msg.sender);
        uint256 balanceOfAsset = getBalance(asset);
        require(balanceOfAsset >= amount, "Insufficient balance");
        bool native = uint160(asset) == nativeAsset;
        Action memory a = Action({
            id: 0x1,
            params: new bytes32[](3),
            required: numGuardians,
            approved: 1,
            approvals: new address[](numGuardians),
            executed: false
        });
        a.approvals[0] = msg.sender;
        a.params[0] = bytes32(uint256(uint160(asset)));
        a.params[1] = bytes32(amount);
        a.params[2] = bytes32(uint256(uint160(recipient)));
        actions.push(a);
        
        //emit
        return actions.length - 1;
    }
    
    
    /*
        Approve a pending action
    */
    function approve(uint actionId) public returns (bool readyToExecute) {
        requireGuardian(msg.sender);
        Action storage action = actions[actionId];
        require(action.id > 0, "Invalid action");
        
        uint8 len = action.required <= uint8(action.approvals.length) ? action.required : uint8(action.approvals.length);
        for (uint8 i = 0; i < len; i++) {
            if (action.approvals[i] == msg.sender) {
                if (action.approved == action.required) return true;
                require(false, "You have already approved this action");
            }
        }
        
        action.approvals[action.approved] = msg.sender;
        //emit approval event here
        return ++action.approved == action.required;
    }
    
    
    function execute(uint256 actionId) public returns (bool sent) {
        requireGuardian(msg.sender);
        Action storage action = actions[actionId];
        require(action.id > 0, "Invalid action");
        require(action.approved == action.required, "Not enough approvals");
        require(!action.executed, "Already executed");
        
        if (action.id == 0x1) {
            //withdraw
            address asset = address(uint160(uint256(action.params[0])));
            uint256 amount = uint256(action.params[1]);
            address payable recipient = payable(address(uint160(uint256(action.params[2]))));
            if (uint160(asset) == nativeAsset) {
                (bool sent, bytes memory data) = recipient.call{ gas: 25000, value: amount }("");
                //emit
                return sent;
            }
            bool sent = IERC20(asset).transfer(recipient, amount);
            //emit
            return sent;
            
        } else {
            require(false, "Invalid action");
        }
    }

}