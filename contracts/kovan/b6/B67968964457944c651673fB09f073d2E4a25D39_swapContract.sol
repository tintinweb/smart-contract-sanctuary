// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ECDSAOffsetRecovery 
{
    function getHashPacked(address user, uint256 amountWithFee, bytes32 originalTxHash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, amountWithFee, originalTxHash));
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function ecOffsetRecover(bytes32 hash, bytes memory signature, uint256 offset)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, add(offset, 0x20)))
            s := mload(add(signature, add(offset, 0x40)))
            v := byte(0, mload(add(signature, add(offset, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        }

        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = keccak256(abi.encodePacked(prefix, hash));
        // solium-disable-next-line arg-overflow
        return ecrecover(toEthSignedMessageHash(hash), v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./ECDSAOffsetRecovery.sol";



/// @title Swap contract for multisignature bridge
contract swapContract is AccessControl, Pausable, ECDSAOffsetRecovery{

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");


    uint128 public numOfThisBlockchain;
    IUniswapV2Router02 public blockchainRouter;
    address public blockchainPool;
    address public blockchainFeeAddress;
    mapping(uint128 => address) public RubicAddresses;
    mapping(uint128 => bool) public existingOtherBlockchain;
    mapping(uint128 => uint128) public feeAmountOfBlockchain;
    mapping(uint128 => uint256) public blockchainCryptoFee;

    uint256 public constant SIGNATURE_LENGTH = 65;
    mapping(bytes32 => bytes32) public processedTransactions;
    uint256 public minConfirmationSignatures;

    uint256 public minTokenAmount;
    uint256 public maxGasPrice;
    uint256 public minConfirmationBlocks;
    uint256 public deadline;

    // emitted every time when user gets crypto or tokens
    event TransferFromOtherBlockchain(address user, uint256 amount, uint256 amountWithoutFee, bytes32 originalTxHash);
    // emitted if the recipient should receive crypto in the target blockchain
    event TransferCryptoToOtherBlockchainUser(uint128 blockchain, address sender, uint256 RBCAmountIn,
                                        string newAddress, uint256 cryptoOutMin, address[] path);
    // emitted if the recipient should receive tokens in the target blockchain
    event TransferTokensToOtherBlockchainUser(uint128 blockchain, address sender, uint256 RBCAmountIn,
                                        string newAddress, uint256 tokenOutMin, address[] path);

    /**
      * @param blockchain Number of blockchain
      * @param tokenInAmount Maximum amount of a token being sold
      * @param firstPath Path used for swapping tokenIn to *RBC (tokenIn address,.., *RBC addres)
      * @param secondPath Path used for swapping *RBC to tokenOut (*RBC address,.., tokenOut address)
      * @param exactRBCtokenOut Exact amount of RBC to get after first swap
      * @param tokenOutMin Minimal amount of tokens (or crypto) to get after second swap
      * @param newAddress Address in the blockchain to which the user wants to transfer
      * @param swapToCrypto This must be _true_ if swapping tokens to desired blockchain's crypto
      */
    struct swapToParams{
        uint128 blockchain;
        uint256 tokenInAmount;
        address[] firstPath;
        address[] secondPath;
        uint256 exactRBCtokenOut;
        uint256 tokenOutMin;
        string newAddress;
        bool swapToCrypto;
    }

    /**
      * @param user User address // "newAddress" from event
      * @param amountWithFee Amount of tokens with included fees // "exactRBCtokenOut" from event
      * @param amountOutMin Minimal amount of tokens to get after second swap // "tokenOutMin" from event
      * @param path Path used for a second swap // "secondPath" from event
      * @param originalTxHash Hash of transaction from other network, on which swap was called
      * @param concatSignatures Concatenated string of signature bytes for verification of transaction
      */
    struct swapFromParams{
        address user;
        uint256 amountWithFee;
        uint256 amountOutMin;
        address[] path;
        bytes32 originalTxHash;
        bytes concatSignatures;
    }

    /** 
      * @dev throws if transaction sender is not in owner role
      */
    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Caller is not in owner role"
        );
        _;
    }

    /** 
      * @dev throws if transaction sender is not in owner or manager role
      */
    modifier onlyOwnerAndManager() {
        require(
            hasRole(OWNER_ROLE, _msgSender()) || hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not in owner or manager role"
        );
        _;
    }

    /** 
      * @dev throws if transaction sender is not in relayer role
      */
    modifier onlyRelayer() {
        require(
            hasRole(RELAYER_ROLE, _msgSender()),
            "swapContract: Caller is not in relayer role"
        );
        _;
    }

    /**
      * @dev Performs check before swap*ToOtherBlockchain-functions and emits events
      * @param params The swapToParams structure
      * @param value The msg.value
      */
    modifier TransferTo(
        swapToParams calldata params,
        uint256 value
    ){
        require(
            bytes(params.newAddress).length > 0,
            "swapContract: No destination address provided"
        );
        require(
            existingOtherBlockchain[params.blockchain] && params.blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            params.firstPath[params.firstPath.length - 1] == RubicAddresses[numOfThisBlockchain],
            "swapContract: the last address in the firstPath must be Rubic"
        );
        require(
            params.secondPath[0] == RubicAddresses[params.blockchain],
            "swapContract: the first address in the secondPath must be Rubic"
        );
        require(
            params.exactRBCtokenOut >= feeAmountOfBlockchain[params.blockchain],
            "swapContract: Not enough amount of tokens"
        );
        require(
            value >= blockchainCryptoFee[params.blockchain],
            "swapContract: Not enough crypto provided"
        );
        _;
        if (params.swapToCrypto){
            emit TransferCryptoToOtherBlockchainUser(params.blockchain, _msgSender(), params.exactRBCtokenOut, params.newAddress, params.tokenOutMin, params.secondPath);
        }
        else{
            emit TransferTokensToOtherBlockchainUser(params.blockchain, _msgSender(), params.exactRBCtokenOut, params.newAddress, params.tokenOutMin, params.secondPath);
        }
    }

    /**
      * @dev Performs check before swap*ToUser-functions
      * @param params The swapFromParams structure
      */
    modifier TransferFrom(
       swapFromParams calldata params
    ){
        require(
            params.amountWithFee > feeAmountOfBlockchain[numOfThisBlockchain],
            "swapContract: Amount must be greater than fee"
        );
        require(
            params.path[0] == RubicAddresses[numOfThisBlockchain],
            "swapContract: the first address in the path must be Rubic"
        );
        require(
            params.user != address(0),
            "swapContract: Address cannot be zero address"
        );
        require(
            params.concatSignatures.length % SIGNATURE_LENGTH == 0,
            "swapContract: Signatures lengths must be divisible by 65"
        );
        require(
            params.concatSignatures.length / SIGNATURE_LENGTH >= minConfirmationSignatures,
            "swapContract: Not enough signatures passed"
        );

        _processTransaction(params.user, params.amountWithFee, params.originalTxHash, params.concatSignatures);
        _;
    }

    /**
      * @dev Constructor of contract
      * @param _numOfThisBlockchain Number of blockchain where contract is deployed
      * @param _numsOfOtherBlockchains List of blockchain number that is supported by bridge
      * @param _minConfirmationSignatures Number of required signatures for token swap
      * @param _minTokenAmount Minimal amount of tokens required for token swap
      * @param _maxGasPrice Maximum gas price on which relayer nodes will operate
      * @param _minConfirmationBlocks Minimal amount of blocks for confirmation on validator nodes
      * @param _RubicAddresses Addresses of Rubic in different blockchains
      */
    constructor(
        uint128 _numOfThisBlockchain,
        uint128 [] memory _numsOfOtherBlockchains,
        uint128 _minConfirmationSignatures,
        uint256 _minTokenAmount,
        uint256 _maxGasPrice,
        uint256 _minConfirmationBlocks,
        address[] memory _RubicAddresses
    )
    {
        for (uint i = 0; i < _numsOfOtherBlockchains.length; i++ ) {
            require(
                _numsOfOtherBlockchains[i] != _numOfThisBlockchain,
                "swapContract: Number of this blockchain is in array of other blockchains"
            );
            existingOtherBlockchain[_numsOfOtherBlockchains[i]] = true;
        }

        for (uint128 i = 0; i < _RubicAddresses.length; i++ ) {
            RubicAddresses[i+1] = _RubicAddresses[i];
        }

        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");
        
        numOfThisBlockchain = _numOfThisBlockchain;
        minConfirmationSignatures = _minConfirmationSignatures;
        minTokenAmount = _minTokenAmount;
        maxGasPrice = _maxGasPrice;
        minConfirmationBlocks = _minConfirmationBlocks;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    /** 
      * @dev Returns true if blockchain of passed id is registered to swap
      * @param blockchain number of blockchain
      */
    function getOtherBlockchainAvailableByNum(uint128 blockchain) external view returns (bool)
    {
        return existingOtherBlockchain[blockchain];
    }

    function _processTransaction(address user, uint256 amountWithFee, bytes32 originalTxHash, bytes memory concatSignatures) private{
        bytes32 hashedParams = getHashPacked(user, amountWithFee, originalTxHash);
        (bool processed, bytes32 savedHash) = isProcessedTransaction(originalTxHash);
        require(!processed && savedHash != hashedParams, "swapContract: Transaction already processed");

        uint256 signaturesCount = concatSignatures.length / uint256(SIGNATURE_LENGTH);
        address[] memory validatorAddresses = new address[](signaturesCount);
        for (uint256 i = 0; i < signaturesCount; i++) {
            address validatorAddress = ecOffsetRecover(hashedParams, concatSignatures, i * SIGNATURE_LENGTH);
            require(isValidator(validatorAddress), "swapContract: Validator address not in whitelist");
            for (uint256 j = 0; j < i; j++) {
                require(validatorAddress != validatorAddresses[j], "swapContract: Validator address is duplicated");
            }
            validatorAddresses[i] = validatorAddress;
        }
        processedTransactions[originalTxHash] = hashedParams;
    }

    /**
      * @dev Transfers tokens from sender to the contract.
      * User calls this function when he wants to transfer tokens to another blockchain.
      * @notice User must have approved tokenInAmount of tokenIn
      */
    function swapTokensToOtherBlockchain(
        swapToParams calldata params)
    external payable whenNotPaused TransferTo(
        params,
        msg.value
    )
    {
        IERC20 tokenIn = IERC20(params.firstPath[0]);
        if (params.firstPath.length > 1){
            require(tokenIn.transferFrom(msg.sender, address(this), params.tokenInAmount),
                                                    'swapContract: Transfer tokens from sender failed');
            require(tokenIn.approve(address(blockchainRouter), params.tokenInAmount), 'approve failed.');
            uint[] memory amounts = blockchainRouter.swapTokensForExactTokens(params.exactRBCtokenOut, params.tokenInAmount,
                                                                    params.firstPath, blockchainPool,
                                                                    block.timestamp + deadline);
            tokenIn.transfer(_msgSender(), params.tokenInAmount - amounts[0]);
        }
        else if (params.firstPath.length == 1){
            require(tokenIn.transferFrom(msg.sender, blockchainPool, params.exactRBCtokenOut),
                                                    'swapContract: Transfer tokens from sender failed');
        }
        else{
            revert("swapContract: invalid firstPath");
        }
    }

    /**
      * @dev Transfers tokens from sender to the contract.
      * User calls this function when he wants to transfer tokens to another blockchain.
      * @notice User must have approved tokenInAmount of tokenIn
      */
    function swapCryptoToOtherBlockchain(
        swapToParams calldata params
    )
    external payable whenNotPaused TransferTo(
        params,
        msg.value
    )
    {
        uint256 cryptoWithoutFee = msg.value - blockchainCryptoFee[params.blockchain];
        uint256[] memory amounts = blockchainRouter.swapETHForExactTokens{value: cryptoWithoutFee}(
            params.exactRBCtokenOut, params.firstPath, blockchainPool, block.timestamp + deadline);
        bool success = payable(_msgSender()).send(cryptoWithoutFee - amounts[0]);
        require(success, "swapContract: crypto transfer back to caller failed");
    }

    /**
      * @dev Transfers tokens to end user in current blockchain
      */
    function swapTokensToUserWithFee(
        swapFromParams calldata params
    )
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(
            params
        )
    {
        uint256 amountWithoutFee = params.amountWithFee - feeAmountOfBlockchain[numOfThisBlockchain];

        IERC20 RBCToken = IERC20(params.path[0]);

        if (params.path.length == 1){
            require(RBCToken.transferFrom(blockchainPool, params.user, amountWithoutFee),
                                                            "swapContract: transfer from pool failed");
            require(RBCToken.transferFrom(blockchainPool,
                                                    blockchainFeeAddress,
                                                    feeAmountOfBlockchain[numOfThisBlockchain]),
                                                            "swapContract: fee transfer failed");
        }
        else if (params.path.length > 1){
            require(RBCToken.transferFrom(blockchainPool, address(this), amountWithoutFee),
                                                            "swapContract: transfer from pool failed");
            require(RBCToken.transferFrom(blockchainPool,
                                                    blockchainFeeAddress,
                                                    feeAmountOfBlockchain[numOfThisBlockchain]),
                                                            "swapContract: fee transfer failed");
            require(RBCToken.approve(address(blockchainRouter), amountWithoutFee),
                                                            "swapContract: approve to Swap failed");
            blockchainRouter.swapExactTokensForTokens(
                amountWithoutFee,
                params.amountOutMin,
                params.path,
                params.user,
                block.timestamp + deadline
            );
        }
        else{
            revert("swapContract: wrong path");
        }
        emit TransferFromOtherBlockchain(params.user, params.amountWithFee, amountWithoutFee, params.originalTxHash);
    }

     /**
      * @dev Transfers tokens to end user in current blockchain
      */
    function swapCryptoToUserWithFee(
        swapFromParams calldata params
    )
        external
        onlyRelayer
        whenNotPaused
        TransferFrom(
            params
        )
    {
        uint256 amountWithoutFee = params.amountWithFee - feeAmountOfBlockchain[numOfThisBlockchain];

        IERC20 RBCToken = IERC20(params.path[0]);
        require(RBCToken.transferFrom(blockchainPool, address(this), amountWithoutFee),
                                                        "swapContract: transfer from pool failed");
        require(RBCToken.transferFrom(blockchainPool,
                                                blockchainFeeAddress,
                                                feeAmountOfBlockchain[numOfThisBlockchain]),
                                                        "swapContract: fee transfer failed");
        require(RBCToken.approve(address(blockchainRouter), amountWithoutFee),
                                                        "swapContract: approve to Swap failed");
        blockchainRouter.swapExactTokensForETH(
            amountWithoutFee,
            params.amountOutMin,
            params.path,
            params.user,
            block.timestamp + deadline
        );
        emit TransferFromOtherBlockchain(params.user, params.amountWithFee, amountWithoutFee, params.originalTxHash);
    }

    // OTHER BLOCKCHAIN MANAGEMENT
    /** 
      * @dev Registers another blockchain for availability to swap
      * @param numOfOtherBlockchain number of blockchain
      */
    function addOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            numOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            !existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = true;
    }

    /** 
      * @dev Unregisters another blockchain for availability to swap
      * @param numOfOtherBlockchain number of blockchain
      */
    function removeOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = false;
    }

    /** 
      * @dev Change existing blockchain id
      * @param oldNumOfOtherBlockchain number of existing blockchain
      * @param newNumOfOtherBlockchain number of new blockchain
      */
    function changeOtherBlockchain(
        uint128 oldNumOfOtherBlockchain,
        uint128 newNumOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            oldNumOfOtherBlockchain != newNumOfOtherBlockchain,
            "swapContract: Cannot change blockchains with same number"
        );
        require(
            newNumOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            existingOtherBlockchain[oldNumOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        require(
            !existingOtherBlockchain[newNumOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        
        existingOtherBlockchain[oldNumOfOtherBlockchain] = false;
        existingOtherBlockchain[newNumOfOtherBlockchain] = true;
    }

    /**
      * @dev Changes deadline used in swaps
      * @param _deadline New deadline
      */

    function setDeadline(uint256 _deadline) external onlyOwnerAndManager{
        require(_deadline > 0, "swapContract: deadline cannot be less than zero");
        deadline = _deadline;
    }

    /**
      * @dev Changes/Set Router address
      * @param _router the new Router address
      */

    function setRouter(IUniswapV2Router02 _router) external onlyOwnerAndManager{
        blockchainRouter = _router;
    }

    /**
      * @dev Changes/Set Pool address
      * @param _poolAddress the new Pool address
      */

    function setPoolAddress(address _poolAddress) external onlyOwnerAndManager{
        blockchainPool = _poolAddress;
    }

    // FEE MANAGEMENT

    /**
      * @dev Sends collected crypto fee to the owner
      */

    function collectCryptoFee() external onlyOwner{
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "swapContract: fail collecting fee");
    }

    /** 
      * @dev Changes address which receives fees from transfers
      * @param newFeeAddress New address for fees
      */
    function setFeeAddress(address newFeeAddress) external onlyOwnerAndManager
    {
        blockchainFeeAddress = newFeeAddress;
    }

    /** 
      * @dev Changes fee values for blockchains in feeAmountOfBlockchain variables
      * @param _blockchainNum Existing number of blockchain
      * @param feeAmount Fee amount to substruct from transfer amount
      */
    function setFeeAmountOfBlockchain(uint128 _blockchainNum, uint128 feeAmount) external onlyOwnerAndManager
    {
        feeAmountOfBlockchain[_blockchainNum] = feeAmount;
    }

    /**
      * @dev Changes crypto fee values for blockchains in blockchainCryptoFee variables
      * @param _blockchainNum Existing number of blockchain
      * @param feeAmount Fee amount that must be sent calling transferToOtherBlockchain
      */
    function setCryptoFeeOfBlockchain(uint128 _blockchainNum, uint256 feeAmount) external onlyOwnerAndManager{
        blockchainCryptoFee[_blockchainNum] = feeAmount;
    }

    /**
      * @dev Changes the address of Rubic in the certain blockchain
      * @param _blockchainNum Existing number of blockchain
      * @param _RubicAddress The Rubic address
      */
    function setRubicAddressOfBlockchain(uint128 _blockchainNum, address _RubicAddress) external onlyOwnerAndManager{
        RubicAddresses[_blockchainNum] = _RubicAddress;
    }

    // VALIDATOR CONFIRMATIONS MANAGEMENT

    /** 
      * @dev Changes requirement for minimal amount of signatures to validate on transfer
      * @param _minConfirmationSignatures Number of signatures to verify
      */
    function setMinConfirmationSignatures(uint256 _minConfirmationSignatures) external onlyOwner {
        require(_minConfirmationSignatures > 0, "swapContract: At least 1 confirmation can be set");
        minConfirmationSignatures = _minConfirmationSignatures;
    }

    /** 
      * @dev Changes requirement for minimal token amount on transfers
      * @param _minTokenAmount Amount of tokens
      */
    function setMinTokenAmount(uint256 _minTokenAmount) external onlyOwnerAndManager {
        minTokenAmount = _minTokenAmount;
    }

    /** 
      * @dev Changes parameter of maximum gas price on which relayer nodes will operate
      * @param _maxGasPrice Price of gas in wei
      */
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwnerAndManager {
        require(_maxGasPrice > 0, "swapContract: Gas price cannot be zero");
        maxGasPrice = _maxGasPrice;
    }

    /** 
      * @dev Changes requirement for minimal amount of block to consider tx confirmed on validator
      * @param _minConfirmationBlocks Amount of blocks
      */

    function setMinConfirmationBlocks(uint256 _minConfirmationBlocks) external onlyOwnerAndManager {
        minConfirmationBlocks = _minConfirmationBlocks;
    }


    /** 
      * @dev Transfers permissions of contract ownership. 
      * Will setup new owner and one manager on contract.
      * Main purpose of this function is to transfer ownership from deployer account ot real owner
      * @param newOwner Address of new owner
      * @param newManager Address of new manager
      */
    function transferOwnerAndSetManager(address newOwner, address newManager) external onlyOwner {
        require(newOwner != _msgSender(), "swapContract: New owner must be different than current");
        require(newOwner != address(0x0), "swapContract: Owner cannot be zero address");
        require(newManager != address(0x0), "swapContract: Owner cannot be zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(OWNER_ROLE, newOwner);
        _setupRole(MANAGER_ROLE, newManager);
        renounceRole(OWNER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /** 
      * @dev Pauses transfers of tokens on contract
      */
    function pauseExecution() external onlyOwner {
        _pause();
    }

    /** 
      * @dev Resumes transfers of tokens on contract
      */
    function continueExecution() external onlyOwner {
        _unpause();
    }

    /** 
      * @dev Function to check if address is belongs to owner role
      * @param account Address to check
      */
    function isOwner(address account) public view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    /** 
      * @dev Function to check if address is belongs to manager role
      * @param account Address to check
      */
    function isManager(address account) public view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    /** 
      * @dev Function to check if address is belongs to relayer role
      * @param account Address to check
      */
    function isRelayer(address account) public view returns (bool) {
        return hasRole(RELAYER_ROLE, account);
    }

    /** 
      * @dev Function to check if address is belongs to validator role
      * @param account Address to check
      * 
      */
    function isValidator(address account) public view returns (bool) {
        return hasRole(VALIDATOR_ROLE, account);
    }

    /** 
      * @dev Function to check if transfer of tokens on previous
      * transaction from other blockchain was executed
      * @param originalTxHash Transaction hash to check
      */
    function isProcessedTransaction(bytes32 originalTxHash) public view returns (bool processed, bytes32 hashedParams) {
        hashedParams = processedTransactions[originalTxHash];
        processed = hashedParams != bytes32(0);
    }

    /**
      * @dev Plain fallback function to receive crypto
      */
    receive() external payable{

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

