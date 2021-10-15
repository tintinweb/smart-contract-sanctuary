/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/Ownable.sol





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Open Zeppelin's ownable doesn't quite work with factory pattern because _owner has private access.
 * When you create a DU, open-zeppelin _owner would be 0x0 (no state from template). Then no address could change _owner to the DU owner.
 * With this custom Ownable, the first person to call initialiaze() can set owner.
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address owner_) {
        owner = owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "error_onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == pendingOwner, "error_onlyPendingOwner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


// File contracts/PurchaseListener.sol





/**
 * PurchaseListener gets a chance to react when a data subscription is bought on the Streamr Marketplace
 *   where the PurchaseListener is set as the data product's beneficiary.
 */
interface PurchaseListener {
    /**
     * Similarly to ETH transfer, returning false will decline the transaction
     *   (declining should probably cause revert, but that's up to the caller)
     * IMPORTANT: include onlyMarketplace modifier to your implementations!
     */
    function onPurchase(bytes32 productId, address subscriber, uint endTimestamp, uint priceDatacoin, uint feeDatacoin)
        external returns (bool accepted);
}


// File contracts/CloneLib.sol




//solhint-disable avoid-low-level-calls
//solhint-disable no-inline-assembly

/** NOTE: DO NOT MODIFY. This code has been audited, and the test was removed in truffle -> waffle transition */
library CloneLib {
    /**
     * Returns bytecode of a new contract that clones template
     * Adapted from https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-sdk/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
     * Which in turn adapted it from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
     */
    function cloneBytecode(address template) internal pure returns (bytes memory code) {
        bytes20 targetBytes = bytes20(template);
        assembly {
            code := mload(0x40)
            mstore(0x40, add(code, 0x57)) // code length is 0x37 plus 0x20 for bytes length field. update free memory pointer
            mstore(code, 0x37) // store length in first 32 bytes

            // store clone source address after first 32 bytes
            mstore(add(code, 0x20), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(code, 0x34), targetBytes)
            mstore(add(code, 0x48), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
    }

    /**
     * Predict the CREATE2 address.
     * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1014.md for calculation details
     */
    function predictCloneAddressCreate2(
        address template,
        address deployer,
        bytes32 salt
    ) internal pure returns (address proxy) {
        bytes32 codehash = keccak256(cloneBytecode(template));
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            codehash
        )))));
    }

    /**
     * Deploy given bytecode using CREATE2, address can be known in advance, get it from predictCloneAddressCreate2
     * Optional 2-step deployment first runs the constructor, then supplies an initialization function call.
     * @param code EVM bytecode that would be used in a contract deploy transaction (to=null)
     * @param initData if non-zero, send an initialization function call in the same tx with given tx input data (e.g. encoded Solidity function call)
     */
    function deployCodeAndInitUsingCreate2(
        bytes memory code,
        bytes memory initData,
        bytes32 salt
    ) internal returns (address payable proxy) {
        uint256 len = code.length;
        assembly {
            proxy := create2(0, add(code, 0x20), len, salt)
        }
        require(proxy != address(0), "error_alreadyCreated");
        if (initData.length != 0) {
            (bool success, ) = proxy.call(initData);
            require(success, "error_initialization");
        }
    }

    /**
     * Deploy given bytecode using old-style CREATE, address is hash(sender, nonce)
     * Optional 2-step deployment first runs the constructor, then supplies an initialization function call.
     * @param code EVM bytecode that would be used in a contract deploy transaction (to=null)
     * @param initData if non-zero, send an initialization function call in the same tx with given tx input data (e.g. encoded Solidity function call)
     */
    function deployCodeAndInitUsingCreate(
        bytes memory code,
        bytes memory initData
    ) internal returns (address payable proxy) {
        uint256 len = code.length;
        assembly {
            proxy := create(0, add(code, 0x20), len)
        }
        require(proxy != address(0), "error_create");
        if (initData.length != 0) {
            (bool success, ) = proxy.call(initData);
            require(success, "error_initialization");
        }
    }
}


// File contracts/xdai-mainnet-bridge/IAMB.sol





// Tokenbridge Arbitrary Message Bridge
interface IAMB {

    //only on mainnet AMB:
    function executeSignatures(bytes calldata _data, bytes calldata _signatures) external;

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function requiredSignatures() external view returns (uint256);
    function numMessagesSigned(bytes32 _message) external view returns (uint256);
    function signature(bytes32 _hash, uint256 _index) external view returns (bytes memory);
    function message(bytes32 _hash) external view returns (bytes memory);
    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);
}


// File contracts/xdai-mainnet-bridge/ITokenMediator.sol





interface ITokenMediator {
    function bridgeContract() external view returns (address);

    //returns:
    //Multi-token mediator: 0xb1516c26 == bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    //Single-token mediator: 0x76595b56 ==  bytes4(keccak256(abi.encodePacked("erc-to-erc-amb")))
    function getBridgeMode() external pure returns (bytes4 _data);

    function relayTokensAndCall(address token, address _receiver, uint256 _value, bytes calldata _data) external;
}


// File contracts/IERC677Receiver.sol





interface IERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external;
}


// File contracts/DataUnionMainnet.sol











contract DataUnionMainnet is Ownable, PurchaseListener, IERC677Receiver {

    event RevenueReceived(uint256 amount);

    // NOTE: any variables set below will NOT be visible in clones from CloneLib / factories
    //       clones must set variables in initialize()

    IERC20 public tokenMainnet;
    IERC20 public tokenSidechain;
    ITokenMediator public tokenMediatorMainnet;
    ITokenMediator public tokenMediatorSidechain;
    address public sidechainDUFactory;
    uint256 public sidechainMaxGas;

    address public sidechainDUTemplate; // needed to compute sidechain address

    // only passed to the sidechain, hence not made public
    uint256 initialAdminFeeFraction;
    uint256 initialDataUnionFeeFraction;
    address initialDataUnionBeneficiary;

    function version() public pure returns (uint256) { return 2; }

    uint256 public tokensSentToBridge;

    constructor() Ownable(address(0)) {}

    function initialize(
        address _tokenMainnet,
        address _mediatorMainnet,
        address _tokenSidechain,
        address _mediatorSidechain,
        address _sidechainDUFactory,
        uint256 _sidechainMaxGas,
        address _sidechainDUTemplate,
        address _owner,
        uint256 _adminFeeFraction,
        uint256 _dataUnionFeeFraction,
        address _dataUnionBeneficiary,
        address[] memory agents
    )  public {
        require(!isInitialized(), "init_once");

        //during setup, msg.sender is admin
        owner = msg.sender;

        tokenMainnet = IERC20(_tokenMainnet);
        tokenMediatorMainnet = ITokenMediator(_mediatorMainnet);
        tokenSidechain = IERC20(_tokenSidechain);
        tokenMediatorSidechain = ITokenMediator(_mediatorSidechain);
        sidechainDUFactory = _sidechainDUFactory;
        sidechainMaxGas = _sidechainMaxGas;
        sidechainDUTemplate = _sidechainDUTemplate;

        initialAdminFeeFraction = _adminFeeFraction;
        initialDataUnionFeeFraction = _dataUnionFeeFraction;
        initialDataUnionBeneficiary = _dataUnionBeneficiary;

        //transfer to real admin
        owner = _owner;
        deployNewDUSidechain(agents);
    }

    function isInitialized() public view returns (bool) {
        return address(tokenMainnet) != address(0);
    }

    function amb() public view returns (IAMB) {
        return IAMB(tokenMediatorMainnet.bridgeContract());
    }

    function deployNewDUSidechain(address[] memory agents) public {
        bytes memory data = abi.encodeWithSignature(
            "deployNewDUSidechain(address,address,address,address[],uint256,uint256,address)",
            address(tokenSidechain),
            address(tokenMediatorSidechain),
            owner,
            agents,
            initialAdminFeeFraction,
            initialDataUnionFeeFraction,
            initialDataUnionBeneficiary
        );
        amb().requireToPassMessage(sidechainDUFactory, data, sidechainMaxGas);
    }

    function sidechainAddress() public view returns (address) {
        return CloneLib.predictCloneAddressCreate2(sidechainDUTemplate, sidechainDUFactory, bytes32(uint256(uint160(address(this)))));
    }

    /**
     * ERC677 callback function, see https://github.com/ethereum/EIPs/issues/677
     * Sends the tokens arriving through a transferAndCall to the sidechain (ignore arguments/calldata)
     * Only the token contract is authorized to call this function
     */
    function onTokenTransfer(address, uint256, bytes calldata) override external {
        require(msg.sender == address(tokenMainnet), "error_onlyTokenContract");
        sendTokensToBridge();
    }

    //function onPurchase(bytes32 productId, address subscriber, uint256 endTimestamp, uint256 priceDatacoin, uint256 feeDatacoin)
    function onPurchase(bytes32, address, uint256, uint256, uint256) external override returns (bool) {
        sendTokensToBridge();
        return true;
    }

    function sendTokensToBridge() public returns (uint256) {
        uint256 newTokens = tokenMainnet.balanceOf(address(this));
        if (newTokens == 0) { return 0; }

        emit RevenueReceived(newTokens);

        // transfer memberEarnings
        require(tokenMainnet.approve(address(tokenMediatorMainnet), newTokens), "approve_failed");

        // must send some non-zero data to trigger the callback function
        tokenMediatorMainnet.relayTokensAndCall(address(tokenMainnet), sidechainAddress(), newTokens, abi.encodePacked("DU2"));

        // check that memberEarnings were sent
        require(tokenMainnet.balanceOf(address(this)) == 0, "not_transferred");
        tokensSentToBridge += newTokens;

        return newTokens;
    }
}