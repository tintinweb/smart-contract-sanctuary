pragma solidity ^0.5.11;

import "./zeppelin/Pausable.sol";

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(
        bytes32 _id,
        address _contractAddress,
        bytes20 _gitCommitHash
    ) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContract(bytes32 _id) public view returns (address);
}

pragma solidity ^0.5.11;

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

pragma solidity ^0.5.11;

import "./IManager.sol";
import "./IController.sol";

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        _onlyControllerOwner();
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        _whenSystemNotPaused();
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        _whenSystemPaused();
        _;
    }

    constructor(address _controller) public {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }

    function _onlyController() internal view {
        require(msg.sender == address(controller), "caller must be Controller");
    }

    function _onlyControllerOwner() internal view {
        require(msg.sender == controller.owner(), "caller must be Controller owner");
    }

    function _whenSystemNotPaused() internal view {
        require(!controller.paused(), "system is paused");
    }

    function _whenSystemPaused() internal view {
        require(controller.paused(), "system is not paused");
    }
}

pragma solidity ^0.5.11;

import "../Manager.sol";

interface IBridgeMinterToken {
    function transfer(address _to, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function transferOwnership(address _owner) external;

    function balanceOf(address _addr) external view returns (uint256);
}

contract BridgeMinter is Manager {
    address public tokenAddr;
    address public l1MigratorAddr;
    address public l1LPTGatewayAddr;

    modifier onlyL1Migrator() {
        require(msg.sender == l1MigratorAddr, "NOT_L1_MIGRATOR");
        _;
    }

    modifier onlyL1LPTGateway() {
        require(msg.sender == l1LPTGatewayAddr, "NOT_L1_LPT_GATEWAY");
        _;
    }

    constructor(
        address _controller,
        address _tokenAddr,
        address _l1MigratorAddr,
        address _l1LPTGatewayAddr
    ) public Manager(_controller) {
        tokenAddr = _tokenAddr;
        l1MigratorAddr = _l1MigratorAddr;
        l1LPTGatewayAddr = _l1LPTGatewayAddr;
    }

    /**
     * @notice Set LPT address. Only callable by Controller owner
     * @param _tokenAddr LPT address
     */
    function setToken(address _tokenAddr) external onlyControllerOwner {
        tokenAddr = _tokenAddr;
    }

    /**
     * @notice Set L1Migrator address. Only callable by Controller owner
     * @param _l1MigratorAddr L1Migrator address
     */
    function setL1Migrator(address _l1MigratorAddr) external onlyControllerOwner {
        l1MigratorAddr = _l1MigratorAddr;
    }

    /**
     * @notice Set L1LPTGateway address. Only callable by Controller owner
     * @param _l1LPTGatewayAddr L1LPTGateway address
     */
    function setL1LPTGateway(address _l1LPTGatewayAddr) external onlyControllerOwner {
        l1LPTGatewayAddr = _l1LPTGatewayAddr;
    }

    /**
     * @notice Migrate to a new Minter. Only callable by Controller owner
     * @param _newMinterAddr New Minter address
     */
    function migrateToNewMinter(address _newMinterAddr) external onlyControllerOwner {
        require(
            _newMinterAddr != address(this) && _newMinterAddr != address(0),
            "BridgeMinter#migrateToNewMinter: INVALID_MINTER"
        );

        IBridgeMinterToken token = IBridgeMinterToken(tokenAddr);
        // Transfer ownership of token to new Minter
        token.transferOwnership(_newMinterAddr);
        // Transfer current Minter's LPT balance to new Minter
        token.transfer(_newMinterAddr, token.balanceOf(address(this)));
        // Transfer current Minter's ETH balance to new Minter
        // call() should be safe from re-entrancy here because the Controller owner and _newMinterAddr are trusted
        (bool ok, ) = _newMinterAddr.call.value(address(this).balance)("");
        require(ok, "BridgeMinter#migrateToNewMinter: FAIL_CALL");
    }

    /**
     * @notice Send contract's ETH to L1Migrator. Only callable by L1Migrator
     * @return Amount of ETH sent
     */
    function withdrawETHToL1Migrator() external onlyL1Migrator returns (uint256) {
        uint256 balance = address(this).balance;

        // call() should be safe from re-entrancy here because the L1Migrator and l1MigratorAddr are trusted
        (bool ok, ) = l1MigratorAddr.call.value(address(this).balance)("");
        require(ok, "BridgeMinter#withdrawETHToL1Migrator: FAIL_CALL");

        return balance;
    }

    /**
     * @notice Send contract's LPT to L1Migrator. Only callable by L1Migrator
     * @return Amount of LPT sent
     */
    function withdrawLPTToL1Migrator() external onlyL1Migrator returns (uint256) {
        IBridgeMinterToken token = IBridgeMinterToken(tokenAddr);

        uint256 balance = token.balanceOf(address(this));

        token.transfer(l1MigratorAddr, balance);

        return balance;
    }

    /**
     * @notice Mint LPT to address. Only callable by L1LPTGateway
     * @dev Relies on L1LPTGateway for minting rules
     * @param _to Address to receive LPT
     * @param _amount Amount of LPT to mint
     */
    function bridgeMint(address _to, uint256 _amount) external onlyL1LPTGateway {
        IBridgeMinterToken(tokenAddr).mint(_to, _amount);
    }

    /**
     * @notice Deposit ETH. Required for migrateToNewMinter() from older Minter implementation
     */
    function depositETH() external payable returns (bool) {
        return true;
    }

    /**
     * @notice Returns Controller address. Required for migrateToNewMinter() from older Minter implementation
     * @return Controller address
     */
    function getController() public view returns (address) {
        return address(controller);
    }
}

pragma solidity ^0.5.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity ^0.5.11;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}