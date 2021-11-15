// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1ETHGateway } from "../../../iOVM/bridge/tokens/iOVM_L1ETHGateway.sol";
import { iOVM_L2DepositedToken } from "../../../iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";

/* Library Imports */
import { OVM_CrossDomainEnabled } from "../../../libraries/bridge/OVM_CrossDomainEnabled.sol";
import { Lib_AddressResolver } from "../../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_AddressManager } from "../../../libraries/resolver/Lib_AddressManager.sol";

/**
 * @title OVM_L1ETHGateway
 * @dev The L1 ETH Gateway is a contract which stores deposited ETH that is in use on L2.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_L1ETHGateway is iOVM_L1ETHGateway, OVM_CrossDomainEnabled, Lib_AddressResolver {

    /********************
     * Public Constants *
     ********************/

    uint32 public constant override getFinalizeDepositL2Gas = 1200000;

    /********************************
     * External Contract References *
     ********************************/

    address public ovmEth;

    /***************
     * Constructor *
     ***************/

    // This contract lives behind a proxy, so the constructor parameters will go unused.
    constructor()
        OVM_CrossDomainEnabled(address(0))
        Lib_AddressResolver(address(0))
        public
    {}

    /******************
     * Initialization *
     ******************/

    /**
     * @param _libAddressManager Address manager for this OE deployment
     * @param _ovmEth L2 OVM_ETH implementation of iOVM_DepositedToken
     */
    function initialize(
        address _libAddressManager,
        address _ovmEth
    )
        public
    {
        require(libAddressManager == Lib_AddressManager(0), "Contract has already been initialized.");
        libAddressManager = Lib_AddressManager(_libAddressManager);
        ovmEth = _ovmEth;
        messenger = resolve("Proxy__OVM_L1CrossDomainMessenger");
    }

    /**************
     * Depositing *
     **************/

    receive()
        external
        payable
    {
        _initiateDeposit(msg.sender, msg.sender);
    }

    /**
     * @dev deposit an amount of the ETH to the caller's balance on L2
     */
    function deposit() 
        external
        override
        payable
    {
        _initiateDeposit(msg.sender, msg.sender);
    }

    /**
     * @dev deposit an amount of ETH to a recipients's balance on L2
     * @param _to L2 address to credit the withdrawal to
     */
    function depositTo(
        address _to
    )
        external
        override
        payable
    {
        _initiateDeposit(msg.sender, _to);
    }

    /**
     * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of the deposit.
     *
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     */
    function _initiateDeposit(
        address _from,
        address _to
    )
        internal
    {
        // Construct calldata for l2ETHGateway.finalizeDeposit(_to, _amount)
        bytes memory data =
            abi.encodeWithSelector(
                iOVM_L2DepositedToken.finalizeDeposit.selector,
                _to,
                msg.value
            );

        // Send calldata into L2
        sendCrossDomainMessage(
            ovmEth,
            data,
            getFinalizeDepositL2Gas
        );

        emit DepositInitiated(_from, _to, msg.value);
    }

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
     * L1 ETH token.
     * Since only the xDomainMessenger can call this function, it will never be called before the withdrawal is finalized. 
     *
     * @param _to L1 address to credit the withdrawal to
     * @param _amount Amount of the ETH to withdraw
     */
    function finalizeWithdrawal(
        address _to,
        uint256 _amount
    )
        external
        override
        onlyFromCrossDomainAccount(ovmEth)
    {
        _safeTransferETH(_to, _amount);

        emit WithdrawalFinalized(_to, _amount);
    }

    /**********************************
     * Internal Functions: Accounting *
     **********************************/

    /**
     * @dev Internal accounting function for moving around L1 ETH.
     *
     * @param _to L1 address to transfer ETH to
     * @param _value Amount of ETH to send to
     */
    function _safeTransferETH(
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iAbs_BaseCrossDomainMessenger
 */
interface iAbs_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L1ETHGateway
 */
interface iOVM_L1ETHGateway {

    /**********
     * Events *
     **********/

    event DepositInitiated(
        address indexed _from,
        address _to,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address indexed _to,
        uint256 _amount
    );

    /********************
     * Public Functions *
     ********************/

    function deposit()
        external
        payable;

    function depositTo(
        address _to
    )
        external
        payable;

    /*************************
     * Cross-chain Functions *
     *************************/

    function finalizeWithdrawal(
        address _to,
        uint _amount
    )
        external;

    function getFinalizeDepositL2Gas()
        external
        view
        returns(
            uint32
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L2DepositedToken
 */
interface iOVM_L2DepositedToken {

    /**********
     * Events *
     **********/

    event WithdrawalInitiated(
        address indexed _from,
        address _to,
        uint256 _amount
    );

    event DepositFinalized(
        address indexed _to,
        uint256 _amount
    );    


    /********************
     * Public Functions *
     ********************/

    function withdraw(
        uint _amount
    )
        external;

    function withdrawTo(
        address _to,
        uint _amount
    )
        external;


    /*************************
     * Cross-chain Functions *
     *************************/

    function finalizeDeposit(
        address _to,
        uint _amount
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
/* Interface Imports */
import { iAbs_BaseCrossDomainMessenger } from "../../iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {
    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/    
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(
        address _sourceDomainAccount
    ) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }
    
    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used. 
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns(
            iAbs_BaseCrossDomainMessenger
        )
    {
        return iAbs_BaseCrossDomainMessenger(messenger);
    }

    /**
     * @notice Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        bytes memory _data,
        uint32 _gasLimit
    ) internal {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Contract Imports */
import { Ownable } from "./Lib_Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string _name,
        address _newAddress
    );

    /*******************************************
     * Contract Variables: Internal Accounting *
     *******************************************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    function setAddress(
        string memory _name,
        address _address
    )
        public
        onlyOwner
    {
        emit AddressSet(_name, _address);
        addresses[_getNameHash(_name)] = _address;
    }

    function getAddress(
        string memory _name
    )
        public
        view
        returns (address)
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {

    /*******************************************
     * Contract Variables: Contract References *
     *******************************************/

    Lib_AddressManager public libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    )  {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address _contract
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Ownable
 * @dev Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
abstract contract Ownable {

    /*************
     * Variables *
     *************/

    address public owner;


    /**********
     * Events *
     **********/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /***************
     * Constructor *
     ***************/

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    function renounceOwnership()
        public
        virtual
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "Ownable: new owner cannot be the zero address"
        );

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

