pragma solidity 0.8.6;

// GP: Generalised factory
// Mapping for contract type and template ID

import "IBentoBoxFactory.sol";
import "IJellyContract.sol";
import "IERC20.sol";

import "SafeTransfer.sol";
import "BoringMath.sol";
import "JellyAccessControls.sol";


contract JellyFactory is SafeTransfer {

    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;

    /// @notice Responsible for access rights to the contract.
    JellyAccessControls public accessControls;

    /// PW: Give people the chance to use Spell factory, or a whitelist of bentoboxes. 
    IBentoBoxFactory public bentoBox;

    bytes32 public constant CONTRACT_MINTER_ROLE = keccak256("CONTRACT_MINTER_ROLE");

    /// @notice Struct to track Contract template.
    struct Contract {
        bool active;
        uint64 templateType;
        bytes32 templateId;
        uint64 contractIndex;
    }

    /// @notice Mapping from contract created through this contract to Contract struct.
    mapping(address => Contract) public contractInfo;

    /// @notice Contracts created using factory.
    address[] public contracts;

    /// @notice Struct to track Contract template.
    struct Template {
        uint64 currentTemplateId;
        uint128 minimumFee;
        uint32 integratorFeePct;
        bool locked;
        address feeAddress;
    }

    // /// @notice mapping from template type to template id
    mapping(bytes32 => Template) public templateInfo;

    /// @notice Template id to track respective contract template.
    uint256 public contractTemplateCount;

    /// @notice Mapping from template id to contract template
    mapping(bytes32 => address) private contractTemplates;

    ///@notice Any donations if set are sent here.
    address payable public jellyWallet;

    /// @notice Event emitted when template is added to factory.
    event ContractTemplateAdded(address newContract, bytes32 templateId);

    /// @notice Event emitted when contract template is removed.
    event ContractTemplateRemoved(address contractAddr, bytes32 templateId);

    /// @notice Event emitted when contract is created using template id.
    event ContractCreated(address indexed owner, address indexed addr, address contractTemplate);


    /**
     * @notice Initializes the factory.
     * @param _accessControls Sets address to get the access controls from.
     */
    constructor(address _accessControls, address _bentoBox) {
        require(_accessControls != address(0), "accessControls cannot be set to zero");
        require(_bentoBox != address(0), "bentoBox cannot be set to zero");

        accessControls = JellyAccessControls(_accessControls);
        bentoBox = IBentoBoxFactory(_bentoBox);

        contractTemplateCount = 0;
    }


    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(bytes32 _templateId, uint256 _amount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        templateInfo[_templateId].minimumFee = BoringMath.to128(_amount);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setIntegratorFeePct(bytes32 _templateId, uint256 _amount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        require(_amount <= 1000, "Percentage is out of 1000");
        templateInfo[_templateId].integratorFeePct = BoringMath.to32(_amount);
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bytes32 _templateId, bool _locked) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be admin"
        );
        templateInfo[_templateId].locked = _locked;
    }

    /**
     * @notice Sets dividend address.
     * @param _wallet Dividend address.
     */
    function setWallet(address payable _wallet) external {
        require(accessControls.hasAdminRole(msg.sender), "JellyFactory: Sender must be operator");
        require(_wallet != address(0));
        jellyWallet = _wallet;
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateId ID of template.
     * @param _feeAddr The address fees are denominated.
     */
    function setTemplateFeeAddr(bytes32 _templateId, address _feeAddr) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be admin"
        );
        templateInfo[_templateId].feeAddress = _feeAddr;
    }


    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasContractMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(CONTRACT_MINTER_ROLE, _address);
    }


    /**
     * @notice Creates a new JellyFactory from template _templateId and transfers fees.
     * @param _templateId Id of the crowdsale template to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return newContract Contract address.
     */
    function deployContract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        public payable returns (address newContract)
    {

        Template memory template = templateInfo[_templateId];    

        /// @dev If the contract is locked, only admin and minters can deploy. 
        if (template.locked) {
            require(accessControls.hasAdminRole(msg.sender) 
                    || accessControls.hasMinterRole(msg.sender)
                    || hasContractMinterRole(msg.sender),
                "JellyFactory: Sender must be minter if locked"
            );
        }

        // PW: COnvert this to erc20 transfers based on feeAddress
        address contractTemplate = contractTemplates[_templateId];
        require(msg.value >= uint256(template.minimumFee), "JellyFactory: Failed to transfer minimumFee");
        require(contractTemplate != address(0), "JellyFactory: Contract template doesn't exist");
        uint256 integratorFee = 0;
        uint256 jellyFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != jellyWallet) {
            integratorFee = jellyFee * uint256(template.integratorFeePct) / 1000;
            jellyFee = jellyFee - integratorFee;
        }
        if (jellyFee > 0) {
            jellyWallet.transfer(jellyFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }

        /// @dev Deploy using the BentoBox factory. 
        newContract = bentoBox.deploy(contractTemplate, _data, false);
        // PW: get from the contract or set from add template.
        uint256 templateType = IJellyContract(newContract).TEMPLATE_TYPE();
     
        contractInfo[address(newContract)] = Contract(true, BoringMath.to64(templateType), _templateId, BoringMath.to64(contracts.length));
        contracts.push(address(newContract));
        emit ContractCreated(msg.sender, address(newContract), contractTemplate);
    }


    /**
     * @notice Creates a new Jelly contract using _templateId.
     * @dev Initializes contract with the parameters passed.
     * @param _templateId Id of the contract template to create.
     * @param _token The token address to be passed.
     * @param _tokenSupply Amount of tokens to be transferred during init.
     * @param _integratorFeeAccount Address to send refferal bonus, if set.
     * @param _data Data to be sent to template on Init.
     * @return newContract address.
     */
    function createContract(
        bytes32 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract)
    {
        newContract = deployContract(_templateId, _integratorFeeAccount, _data);

        if (_tokenSupply > 0) {
            _safeTransferFrom(_token, msg.sender, _tokenSupply);
            require(IERC20(_token).approve(newContract, _tokenSupply), "1");
        }
        IJellyContract(newContract).initContract(_data);

        if (_tokenSupply > 0) {
            uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
            if (remainingBalance > 0) {
                _safeTransfer(_token, msg.sender, remainingBalance);
            }
        }
        return newContract;
    }



    /**
     * @notice Function to add an contract template to create through factory.
     * @dev Should have operator access.
     * @param _template Contract template to create an contract.
     */
    function addContractTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        require(_template != address(0), "JellyFactory: No template address");

        uint256 templateType = IJellyContract(_template).TEMPLATE_TYPE();
        bytes32 templateId = IJellyContract(_template).TEMPLATE_ID();

        // // uint256 templateType = 6;
        // bytes32 templateId = 0x91de7ab16b9fdba45a718187cc72c7f64295b4615f5e7e0ab28c71c1cd262e52;

        require(templateType > 0, "JellyFactory: Incorrect template code");
        
        /// @dev If template type doesnt yet exist, set it to locked
        if (templateInfo[templateId].currentTemplateId == 0) {
            templateInfo[templateId].locked = true;
        }
        contractTemplateCount++;

        contractTemplates[templateId] = _template;
        templateInfo[templateId].currentTemplateId = BoringMath.to64(contractTemplateCount);
        emit ContractTemplateAdded(_template, templateId);
    }

    /**
     * @dev Function to remove an contract template.
     * @dev Should have operator access.
     * @param _templateId Refers to template that is to be deleted.
     */
    function removeContractTemplate(bytes32 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        address template = contractTemplates[_templateId];
        contractTemplates[_templateId] = address(0);

        emit ContractTemplateRemoved(template, _templateId);
    }


    /**
     * @notice Get the address based on template ID.
     * @param _templateId Contract template ID.
     * @return Address of the required template ID.
     */
    function getContractTemplate( bytes32 _templateId) external view returns (address) {
        return contractTemplates[_templateId];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _contractTemplate Contract template address.
     * @return ID of the required template address.
     */
    function getTemplateId(address _contractTemplate) external view returns (bytes32) {
        return contractInfo[_contractTemplate].templateId;
    }

    /**
     * @notice Get the total number of contracts in the factory.
     * @return Contract count.
     */
    function numberOfDeployedContracts() external view returns (uint) {
        return contracts.length;
    }

    function minimumFee(bytes32 _templateId) external view returns(uint128) {
        return templateInfo[_templateId].minimumFee;
    }

    function getContracts() external view returns(address[] memory) {
        return contracts;
    }

    function getContractTemplateId(address _contract) external view returns(bytes32) {
        return contractInfo[_contract].templateId;
    }


}

pragma solidity 0.8.6;

interface IBentoBoxFactory {
    function deploy(address masterContract, bytes calldata data, bool useCreate2) external payable returns (address cloneAddress) ;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IERC20 {

    /// @notice ERC20 Functions 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

pragma solidity 0.8.6;

contract SafeTransfer {

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }


    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }


    /// @dev Transfer helper from UniswapV2 Router
    function _safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }


    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
                abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }


}

pragma solidity 0.8.6;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to48(uint256 a) internal pure returns (uint48 c) {
        require(a <= type(uint48).max, "BoringMath: uint48 Overflow");
        c = uint48(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max, "BoringMath: uint16 Overflow");
        c = uint16(a);
    }

    function to8(uint256 a) internal pure returns (uint8 c) {
        require(a <= type(uint8).max, "BoringMath: uint8 Overflow");
        c = uint8(a);
    }

}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath48 {
    function add(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint8.
library BoringMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.8.6;

import "JellyMinterAccess.sol";

contract JellyAccessControls is JellyMinterAccess {
    /// @notice Role definitions

    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");

    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    constructor()  {
        TEMPLATE_TYPE = 7;
        TEMPLATE_ID = keccak256("ACCESS_CONTROLS");
    }


    /////////////
    // Lookups //
    /////////////


    /**
     * @notice Used to check whether an address has the smart contract role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasSmartContractRole(address _address) public view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }


    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the smart contract role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addSmartContractRole(address _address) external {
        grantRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the smart contract role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeSmartContractRole(address _address) external {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }


}

pragma solidity 0.8.6;

import "JellyOperatorAccess.sol";

contract JellyMinterAccess is JellyOperatorAccess {
    /// @notice Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Events for adding and removing various roles

    event MinterRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event MinterRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );

    constructor()  {
    }


    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasMinterRole(address _address) public view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the minter role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addMinterRole(address _address) external {
        grantRole(MINTER_ROLE, _address);
        emit MinterRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the minter role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeMinterRole(address _address) external {
        revokeRole(MINTER_ROLE, _address);
        emit MinterRoleRemoved(_address, _msgSender());
    }


}

pragma solidity 0.8.6;

import "JellyAdminAccess.sol";

contract JellyOperatorAccess is JellyAdminAccess {
    /// @notice Role definitions
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Events for adding and removing various roles

    event OperatorRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event OperatorRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    constructor()  {
    }


    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the operator role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasOperatorRole(address _address) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the operator role to an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract receiving the new role
     */
    function addOperatorRole(address _address) external {
        grantRole(OPERATOR_ROLE, _address);
        emit OperatorRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the operator role from an address
     * @dev The sender must have the admin role
     * @param _address EOA or contract affected
     */
    function removeOperatorRole(address _address) external {
        revokeRole(OPERATOR_ROLE, _address);
        emit OperatorRoleRemoved(_address, _msgSender());
    }


}

pragma solidity 0.8.6;

import "AccessControl.sol";
import "IJellyContract.sol";


contract JellyAdminAccess is AccessControl, IJellyContract  {

    /// @notice Jelly template id for the pool factory.
    uint256 public override TEMPLATE_TYPE = 7;
    bytes32 public override TEMPLATE_ID = keccak256("ADMIN_ACCESS");


    /// @dev Whether access is initialised.
    bool private initAccess;

    /// @notice Events for adding and removing various roles.
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    /// @notice The deployer needs to initAccessControls()
    constructor() {

    }

    /**
     * @notice Initializes access controls.
     * @param _admin Admins address.
     */
    function initAccessControls(address _admin) public {
        require(!initAccess, "Already initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        initAccess = true;
    }

    /////////////
    // Lookups //
    /////////////

    /**
     * @notice Used to check whether an address has the admin role.
     * @param _address EOA or contract being checked.
     * @return bool True if the account has the role or false if it does not.
     */
    function hasAdminRole(address _address) public  view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    ///////////////
    // Modifiers //
    ///////////////

    /**
     * @notice Grants the admin role to an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract receiving the new role.
     */
    function addAdminRole(address _address) external {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }

    /**
     * @notice Removes the admin role from an address.
     * @dev The sender must have the admin role.
     * @param _address EOA or contract affected.
     */
    function removeAdminRole(address _address) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }


    function init(bytes calldata _data) external virtual override payable {}

    function initContract(
        bytes calldata _data
    ) public virtual override {
        (
        address _admin
        ) = abi.decode(_data, (address));

        initAccessControls(_admin);
    }

   /** 
     * @dev Generates init data for Farm Factory
  */
    function getInitData(
        address _admin

    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(_admin);
    }


}

pragma solidity ^0.8.0;

import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}