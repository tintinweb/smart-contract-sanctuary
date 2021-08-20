/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

pragma solidity ^0.5.16;
// File: contracts/NFTfi/v1/openzeppelin/Ownable.sol



/**
 * @title Ownable
 * @dev Ownerable 
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/NFTfi/v1/openzeppelin/Roles.sol



/**
 * @title Roles
 * @dev 
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts/NFTfi/v1/openzeppelin/PauserRole.sol




contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/NFTfi/v1/openzeppelin/Pausable.sol




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: contracts/NFTfi/v1/openzeppelin/ReentrancyGuard.sol



/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() public {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: contracts/NFTfi/v1/NFTfiAdmin.sol

pragma solidity ^0.5.16;




// @title Admin contract for NFTfi. Holds owner-only functions to adjust
//        contract-wide fees, parameters, etc.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth, and
//         kittybounties.eth
contract NFTfiAdmin is Ownable, Pausable, ReentrancyGuard {

    /* ****** */
    /* EVENTS */
    /* ****** */

    // @notice This event is fired whenever the admins change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  newAdminFee - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    event AdminFeeUpdated(
        uint256 newAdminFee
    );

    /* ******* */
    /* STORAGE */
    /* ******* */

    // @notice A mapping from from an ERC20 currency address to whether that
    //         currency is whitelisted to be used by this contract. Note that
    //         NFTfi only supports loans that use ERC20 currencies that are
    //         whitelisted, all other calls to beginLoan() will fail.
    mapping (address => bool) public erc20CurrencyIsWhitelisted;

    // @notice A mapping from from an NFT contract's address to whether that
    //         contract is whitelisted to be used by this contract. Note that
    //         NFTfi only supports loans that use NFT collateral from contracts
    //         that are whitelisted, all other calls to beginLoan() will fail.
    mapping (address => bool) public nftContractIsWhitelisted;

    // @notice The maximum duration of any loan started on this platform,
    //         measured in seconds. This is both a sanity-check for borrowers
    //         and an upper limit on how long admins will have to support v1 of
    //         this contract if they eventually deprecate it, as well as a check
    //         to ensure that the loan duration never exceeds the space alotted
    //         for it in the loan struct.
    uint256 public maximumLoanDuration = 53 weeks;

    // @notice The maximum number of active loans allowed on this platform.
    //         This parameter is used to limit the risk that NFTfi faces while
    //         the project is first getting started.
    uint256 public maximumNumberOfActiveLoans = 100;

    // @notice The percentage of interest earned by lenders on this platform
    //         that is taken by the contract admin's as a fee, measured in
    //         basis points (hundreths of a percent).
    uint256 public adminFeeInBasisPoints = 25;

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() internal {
        // Whitelist mainnet WBNB
        erc20CurrencyIsWhitelisted[address(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F)] = true;

        // Whitelist mainnet DAI
        erc20CurrencyIsWhitelisted[address(0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867)] = true;

        // Whitelist mainnet CryptoKitties
        nftContractIsWhitelisted[address(0x49eD51932d25C4E16799C823B03560394d36cbd9)] = true;
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external pure returns (string memory) {
        return "NFTfi Promissory Note";
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external pure returns (string memory) {
        return "NFTfi";
    }

    // @notice This function can be called by admins to change the whitelist
    //         status of an ERC20 currency. This includes both adding an ERC20
    //         currency to the whitelist and removing it.
    // @param  _erc20Currency - The address of the ERC20 currency whose whitelist
    //         status changed.
    // @param  _setAsWhitelisted - The new status of whether the currency is
    //         whitelisted or not.
    function whitelistERC20Currency(address _erc20Currency, bool _setAsWhitelisted) external onlyOwner {
        erc20CurrencyIsWhitelisted[_erc20Currency] = _setAsWhitelisted;
    }

    // @notice This function can be called by admins to change the whitelist
    //         status of an NFT contract. This includes both adding an NFT
    //         contract to the whitelist and removing it.
    // @param  _nftContract - The address of the NFT contract whose whitelist
    //         status changed.
    // @param  _setAsWhitelisted - The new status of whether the contract is
    //         whitelisted or not.
    function whitelistNFTContract(address _nftContract, bool _setAsWhitelisted) external onlyOwner {
        nftContractIsWhitelisted[_nftContract] = _setAsWhitelisted;
    }

    // @notice This function can be called by admins to change the
    //         maximumLoanDuration. Note that they can never change
    //         maximumLoanDuration to be greater than UINT32_MAX, since that's
    //         the maximum space alotted for the duration in the loan struct.
    // @param  _newMaximumLoanDuration - The new maximum loan duration, measured
    //         in seconds.
    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external onlyOwner {
        require(_newMaximumLoanDuration <= uint256(~uint32(0)), 'loan duration cannot exceed space alotted in struct');
        maximumLoanDuration = _newMaximumLoanDuration;
    }

    // @notice This function can be called by admins to change the
    //         maximumNumberOfActiveLoans. 
    // @param  _newMaximumNumberOfActiveLoans - The new maximum number of
    //         active loans, used to limit the risk that NFTfi faces while the
    //         project is first getting started.
    function updateMaximumNumberOfActiveLoans(uint256 _newMaximumNumberOfActiveLoans) external onlyOwner {
        maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
    }

    // @notice This function can be called by admins to change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  _newAdminFeeInBasisPoints - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    function updateAdminFee(uint256 _newAdminFeeInBasisPoints) external onlyOwner {
        require(_newAdminFeeInBasisPoints <= 10000, 'By definition, basis points cannot exceed 10000');
        adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
        emit AdminFeeUpdated(_newAdminFeeInBasisPoints);
    }
}

// File: contracts/NFTfi/v1/openzeppelin/ECDSA.sol



/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/NFTfi/v1/NFTfiSigningUtils.sol

pragma solidity ^0.5.16;


// @title  Helper contract for NFTfi. This contract manages verifying signatures
//         from off-chain NFTfi orders.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth,
//         and kittybounties.eth
// @notice Cite: I found the following article very insightful while creating
//         this contract:
//         https://dzone.com/articles/signing-and-verifying-ethereum-signatures
// @notice Cite: I also relied on this article somewhat:
//         https://forum.openzeppelin.com/t/sign-it-like-you-mean-it-creating-and-verifying-ethereum-signatures/697
contract NFTfiSigningUtils {

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() internal {}

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice OpenZeppelin's ECDSA library is used to call all ECDSA functions
    //         directly on the bytes32 variables themselves.
    using ECDSA for bytes32;

    // @notice This function gets the current chain ID.
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // @notice This function is called in NFTfi.beginLoan() to validate the
    //         borrower's signature that the borrower provided off-chain to
    //         verify that they did indeed want to use this NFT for this loan.
    // @param  _nftCollateralId - The ID within the NFTCollateralContract for
    //         the NFT being used as collateral for this loan. The NFT is
    //         stored within this contract during the duration of the loan.
    // @param  _borrowerNonce - The nonce referred to here
    //         is not the same as an Ethereum account's nonce. We are referring
    //         instead to nonces that are used by both the lender and the
    //         borrower when they are first signing off-chain NFTfi orders.
    //         These nonces can be any uint256 value that the user has not
    //         previously used to sign an off-chain order. Each nonce can be
    //         used at most once per user within NFTfi, regardless of whether
    //         they are the lender or the borrower in that situation. This
    //         serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once.
    //         Second, it allows a user to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _nftCollateralContract - The ERC721 contract of the NFT
    //         collateral
    // @param  _borrower - The address of the borrower.
    // @param  _borrowerSignature - The ECDSA signature of the borrower,
    //         obtained off-chain ahead of time, signing the following
    //         combination of parameters: _nftCollateralId, _borrowerNonce,
    //         _nftCollateralContract, _borrower.
    // @return A bool representing whether verification succeeded, showing that
    //         this signature matched this address and parameters.
    function isValidBorrowerSignature(
        uint256 _nftCollateralId,
        uint256 _borrowerNonce,
        address _nftCollateralContract,
        address _borrower,
        bytes memory _borrowerSignature
    ) public view returns(bool) {
        if(_borrower == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(abi.encodePacked(
                _nftCollateralId,
                _borrowerNonce,
                _nftCollateralContract,
                _borrower,
                chainId
            ));

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_borrowerSignature) == _borrower);
        }
    }

    // @notice This function is called in NFTfi.beginLoan() to validate the
    //         lender's signature that the lender provided off-chain to
    //         verify that they did indeed want to agree to this loan according
    //         to these terms.
    // @param  _loanPrincipalAmount - The original sum of money transferred
    //         from lender to borrower at the beginning of the loan, measured
    //         in loanERC20Denomination's smallest units.
    // @param  _maximumRepaymentAmount - The maximum amount of money that the
    //         borrower would be required to retrieve their collateral. If
    //         interestIsProRated is set to false, then the borrower will
    //         always have to pay this amount to retrieve their collateral.
    // @param  _nftCollateralId - The ID within the NFTCollateralContract for
    //         the NFT being used as collateral for this loan. The NFT is
    //         stored within this contract during the duration of the loan.
    // @param  _loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
    //         (measured in basis points, e.g. hundreths of a percent) for the
    //         loan, that must be repaid pro-rata by the borrower at the
    //         conclusion of the loan or risk seizure of their nft collateral.
    // @param  _adminFeeInBasisPoints - The percent (measured in basis
    //         points) of the interest earned that will be taken as a fee by
    //         the contract admins when the loan is repaid. The fee is stored
    //         in the loan struct to prevent an attack where the contract
    //         admins could adjust the fee right before a loan is repaid, and
    //         take all of the interest earned.
    // @param  _lenderNonce - The nonce referred to here
    //         is not the same as an Ethereum account's nonce. We are referring
    //         instead to nonces that are used by both the lender and the
    //         borrower when they are first signing off-chain NFTfi orders.
    //         These nonces can be any uint256 value that the user has not
    //         previously used to sign an off-chain order. Each nonce can be
    //         used at most once per user within NFTfi, regardless of whether
    //         they are the lender or the borrower in that situation. This
    //         serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once.
    //         Second, it allows a user to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _nftCollateralContract - The ERC721 contract of the NFT
    //         collateral
    // @param  _loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    // @param  _lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  _interestIsProRated - A boolean value determining whether the
    //         interest will be pro-rated if the loan is repaid early, or
    //         whether the borrower will simply pay maximumRepaymentAmount.
    // @param  _lenderSignature - The ECDSA signature of the lender,
    //         obtained off-chain ahead of time, signing the following
    //         combination of parameters: _loanPrincipalAmount,
    //         _maximumRepaymentAmount _nftCollateralId, _loanDuration,
    //         _loanInterestRateForDurationInBasisPoints, _lenderNonce,
    //         _nftCollateralContract, _loanERC20Denomination, _lender,
    //         _interestIsProRated.
    // @return A bool representing whether verification succeeded, showing that
    //         this signature matched this address and parameters.
    function isValidLenderSignature(
        uint256 _loanPrincipalAmount,
        uint256 _maximumRepaymentAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _loanInterestRateForDurationInBasisPoints,
        uint256 _adminFeeInBasisPoints,
        uint256 _lenderNonce,
        address _nftCollateralContract,
        address _loanERC20Denomination,
        address _lender,
        bool _interestIsProRated,
        bytes memory _lenderSignature
    ) public view returns(bool) {
        if(_lender == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(abi.encodePacked(
                _loanPrincipalAmount,
                _maximumRepaymentAmount,
                _nftCollateralId,
                _loanDuration,
                _loanInterestRateForDurationInBasisPoints,
                _adminFeeInBasisPoints,
                _lenderNonce,
                _nftCollateralContract,
                _loanERC20Denomination,
                _lender,
                _interestIsProRated,
                chainId
            ));

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_lenderSignature) == _lender);
        }
    }
}

// File: contracts/NFTfi/v1/openzeppelin/IERC165.sol



/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/NFTfi/v1/openzeppelin/IERC721.sol




/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: contracts/NFTfi/v1/openzeppelin/IERC721Receiver.sol



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: contracts/NFTfi/v1/openzeppelin/SafeMath.sol



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/NFTfi/v1/openzeppelin/Address.sol



/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/NFTfi/v1/openzeppelin/ERC165.sol




/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/NFTfi/v1/openzeppelin/ERC721.sol








/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256('balanceOf(address)')) ^
     *     bytes4(keccak256('ownerOf(uint256)')) ^
     *     bytes4(keccak256('approve(address,uint256)')) ^
     *     bytes4(keccak256('getApproved(uint256)')) ^
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

// File: contracts/NFTfi/v1/openzeppelin/IERC20.sol



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/NFTfi/v1/NFTfi.sol

pragma solidity ^0.5.16;






// @title  Main contract for NFTfi. This contract manages the ability to create
//         NFT-backed peer-to-peer loans.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth, and
//         kittybounties.eth
// @notice There are five steps needed to commence an NFT-backed loan. First,
//         the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi
//         contract to move their NFT's on their behalf. Second, the borrower
//         signs an off-chain message for each NFT that they would like to
//         put up for collateral. This prevents borrowers from accidentally
//         lending an NFT that they didn't mean to lend, due to approveAll()
//         approving their entire collection. Third, the lender calls
//         erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's
//         ERC20 tokens on their behalf. Fourth, the lender signs an off-chain
//         message, proposing the amount, rate, and duration of a loan for a
//         particular NFT. Fifth, the borrower calls NFTfi.beginLoan() to
//         accept these terms and enter into the loan. The NFT is stored in the
//         contract, the borrower receives the loan principal in the specified
//         ERC20 currency, and the lender receives an NFTfi promissory note (in
//         ERC721 form) that represents the rights to either the
//         principal-plus-interest, or the underlying NFT collateral if the
//         borrower does not pay back in time. The lender can freely transfer
//         and trade this ERC721 promissory note as they wish, with the
//         knowledge that transferring the ERC721 promissory note tranfsers the
//         rights to principal-plus-interest and/or collateral, and that they
//         will no longer have a claim on the loan. The ERC721 promissory note
//         itself represents that claim.
// @notice A loan may end in one of two ways. First, a borrower may call
//         NFTfi.payBackLoan() and pay back the loan plus interest at any time,
//         in which case they receive their NFT back in the same transaction.
//         Second, if the loan's duration has passed and the loan has not been
//         paid back yet, a lender can call NFTfi.liquidateOverdueLoan(), in
//         which case they receive the underlying NFT collateral and forfeit
//         the rights to the principal-plus-interest, which the borrower now
//         keeps.
// @notice If the loan was agreed to be a pro-rata interest loan, then the user
//         only pays the principal plus pro-rata interest if repaid early.
//         However, if the loan was agreed to be a fixed-repayment loan (by
//         specifying UINT32_MAX as the value for
//         loanInterestRateForDurationInBasisPoints), then the borrower pays
//         the maximumRepaymentAmount regardless of whether they repay early
//         or not.
contract NFTfi is NFTfiAdmin, NFTfiSigningUtils, ERC721 {

    // @notice OpenZeppelin's SafeMath library is used for all arithmetic
    //         operations to avoid overflows/underflows.
    using SafeMath for uint256;

    /* ********** */
    /* DATA TYPES */
    /* ********** */

    // @notice The main Loan struct. The struct fits in six 256-bits words due
    //         to Solidity's rules for struct packing.
    struct Loan {
        // A unique identifier for this particular loan, sourced from the
        // continuously increasing parameter totalNumLoans.
        uint256 loanId;
        // The original sum of money transferred from lender to borrower at the
        // beginning of the loan, measured in loanERC20Denomination's smallest
        // units.
        uint256 loanPrincipalAmount;
        // The maximum amount of money that the borrower would be required to
        // repay retrieve their collateral, measured in loanERC20Denomination's
        // smallest units. If interestIsProRated is set to false, then the
        // borrower will always have to pay this amount to retrieve their
        // collateral, regardless of whether they repay early.
        uint256 maximumRepaymentAmount;
        // The ID within the NFTCollateralContract for the NFT being used as
        // collateral for this loan. The NFT is stored within this contract
        // during the duration of the loan.
        uint256 nftCollateralId;
        // The block.timestamp when the loan first began (measured in seconds).
        uint64 loanStartTime;
        // The amount of time (measured in seconds) that can elapse before the
        // lender can liquidate the loan and seize the underlying collateral.
        uint32 loanDuration;
        // If interestIsProRated is set to true, then this is the interest rate
        // (measured in basis points, e.g. hundreths of a percent) for the loan,
        // that must be repaid pro-rata by the borrower at the conclusion of
        // the loan or risk seizure of their nft collateral. Note that if
        // interestIsProRated is set to false, then this value is not used and
        // is irrelevant.
        uint32 loanInterestRateForDurationInBasisPoints;
        // The percent (measured in basis points) of the interest earned that
        // will be taken as a fee by the contract admins when the loan is
        // repaid. The fee is stored here to prevent an attack where the
        // contract admins could adjust the fee right before a loan is repaid,
        // and take all of the interest earned.
        uint32 loanAdminFeeInBasisPoints;
        // The ERC721 contract of the NFT collateral
        address nftCollateralContract;
        // The ERC20 contract of the currency being used as principal/interest
        // for this loan.
        address loanERC20Denomination;
        // The address of the borrower.
        address borrower;
        // A boolean value determining whether the interest will be pro-rated
        // if the loan is repaid early, or whether the borrower will simply
        // pay maximumRepaymentAmount.
        bool interestIsProRated;
    }

    /* ****** */
    /* EVENTS */
    /* ****** */

    // @notice This event is fired whenever a borrower begins a loan by calling
    //         NFTfi.beginLoan(), which can only occur after both the lender
    //         and borrower have approved their ERC721 and ERC20 contracts to
    //         use NFTfi, and when they both have signed off-chain messages that
    //         agree on the terms of the loan.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  borrower - The address of the borrower.
    // @param  lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  maximumRepaymentAmount - The maximum amount of money that the
    //         borrower would be required to retrieve their collateral. If
    //         interestIsProRated is set to false, then the borrower will
    //         always have to pay this amount to retrieve their collateral.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  loanStartTime - The block.timestamp when the loan first began
    //         (measured in seconds).
    // @param  loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  loanInterestRateForDurationInBasisPoints - If interestIsProRated
    //         is set to true, then this is the interest rate (measured in
    //         basis points, e.g. hundreths of a percent) for the loan, that
    //         must be repaid pro-rata by the borrower at the conclusion of the
    //         loan or risk seizure of their nft collateral. Note that if
    //         interestIsProRated is set to false, then this value is not used
    //         and is irrelevant.
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    // @param  loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    // @param  interestIsProRated - A boolean value determining whether the
    //         interest will be pro-rated if the loan is repaid early, or
    //         whether the borrower will simply pay maximumRepaymentAmount.
    event LoanStarted(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount,
        uint256 nftCollateralId,
        uint256 loanStartTime,
        uint256 loanDuration,
        uint256 loanInterestRateForDurationInBasisPoints,
        address nftCollateralContract,
        address loanERC20Denomination,
        bool interestIsProRated
    );

    // @notice This event is fired whenever a borrower successfully repays
    //         their loan, paying principal-plus-interest-minus-fee to the
    //         lender in loanERC20Denomination, paying fee to owner in
    //         loanERC20Denomination, and receiving their NFT collateral back.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  borrower - The address of the borrower.
    // @param  lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  amountPaidToLender The amount of ERC20 that the borrower paid to
    //         the lender, measured in the smalled units of
    //         loanERC20Denomination.
    // @param  adminFee The amount of interest paid to the contract admins,
    //         measured in the smalled units of loanERC20Denomination and
    //         determined by adminFeeInBasisPoints. This amount never exceeds
    //         the amount of interest earned.
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    // @param  loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    event LoanRepaid(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 amountPaidToLender,
        uint256 adminFee,
        address nftCollateralContract,
        address loanERC20Denomination
    );

    // @notice This event is fired whenever a lender liquidates an outstanding
    //         loan that is owned to them that has exceeded its duration. The
    //         lender receives the underlying NFT collateral, and the borrower
    //         no longer needs to repay the loan principal-plus-interest.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  borrower - The address of the borrower.
    // @param  lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  loanMaturityDate - The unix time (measured in seconds) that the
    //         loan became due and was eligible for liquidation.
    // @param  loanLiquidationDate - The unix time (measured in seconds) that
    //         liquidation occurred.
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    event LoanLiquidated(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 loanMaturityDate,
        uint256 loanLiquidationDate,
        address nftCollateralContract
    );


    /* ******* */
    /* STORAGE */
    /* ******* */

    // @notice A continuously increasing counter that simultaneously allows
    //         every loan to have a unique ID and provides a running count of
    //         how many loans have been started by this contract.
    uint256 public totalNumLoans = 0;

    // @notice A counter of the number of currently outstanding loans.
    uint256 public totalActiveLoans = 0;


    // @notice A mapping from a loan's identifier to the loan's details,
    //         represted by the loan struct. To fetch the lender, call
    //         NFTfi.ownerOf(loanId).
    mapping (uint256 => Loan) public loanIdToLoan;

    // @notice A mapping tracking whether a loan has either been repaid or
    //         liquidated. This prevents an attacker trying to repay or
    //         liquidate the same loan twice.
    mapping (uint256 => bool) public loanRepaidOrLiquidated;

    // @notice A mapping that takes both a user's address and a loan nonce
    //         that was first used when signing an off-chain order and checks
    //         whether that nonce has previously either been used for a loan,
    //         or has been pre-emptively cancelled. The nonce referred to here
    //         is not the same as an Ethereum account's nonce. We are referring
    //         instead to nonces that are used by both the lender and the
    //         borrower when they are first signing off-chain NFTfi orders.
    //         These nonces can be any uint256 value that the user has not
    //         previously used to sign an off-chain order. Each nonce can be
    //         used at most once per user within NFTfi, regardless of whether
    //         they are the lender or the borrower in that situation. This
    //         serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once.
    //         Second, it allows a user to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    mapping (address => mapping (uint256 => bool)) private _nonceHasBeenUsedForUser;

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() public {}

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice This function is called by a borrower when they want to commence
    //         a loan, but can only be called after first: (1) the borrower has
    //         called approve() or approveAll() on the NFT contract for the NFT
    //         that will be used as collateral, (2) the borrower has signed an
    //         off-chain message indicating that they are willing to use this
    //         NFT as collateral, (3) the lender has called approve() on the
    //         ERC20 contract of the principal, and (4) the lender has signed
    //         an off-chain message agreeing to the terms of this loan supplied
    //         in this transaction.
    // @notice Note that a user may submit UINT32_MAX as the value for
    //         _loanInterestRateForDurationInBasisPoints to indicate that they
    //         wish to take out a fixed-repayment loan, where the interest is
    //         not pro-rated if repaid early.
    // @param  _loanPrincipalAmount - The original sum of money transferred
    //         from lender to borrower at the beginning of the loan, measured
    //         in loanERC20Denomination's smallest units.
    // @param  _maximumRepaymentAmount - The maximum amount of money that the
    //         borrower would be required to retrieve their collateral,
    //         measured in the smallest units of the ERC20 currency used for
    //         the loan. If interestIsProRated is set to false (by submitting
    //         a value of UINT32_MAX for
    //         _loanInterestRateForDurationInBasisPoints), then the borrower
    //         will always have to pay this amount to retrieve their
    //         collateral, regardless of whether they repay early.
    // @param  _nftCollateralId - The ID within the NFTCollateralContract for
    //         the NFT being used as collateral for this loan. The NFT is
    //         stored within this contract during the duration of the loan.
    // @param  _loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
    //         (measured in basis points, e.g. hundreths of a percent) for the
    //         loan, that must be repaid pro-rata by the borrower at the
    //         conclusion of the loan or risk seizure of their nft collateral.
    //         However, a user may submit UINT32_MAX as the value for
    //         _loanInterestRateForDurationInBasisPoints to indicate that they
    //         wish to take out a fixed-repayment loan, where the interest is
    //         not pro-rated if repaid early. Instead, maximumRepaymentAmount
    //         will always be the amount to be repaid.
    // @param  _adminFeeInBasisPoints - The percent (measured in basis
    //         points) of the interest earned that will be taken as a fee by
    //         the contract admins when the loan is repaid. The fee is stored
    //         in the loan struct to prevent an attack where the contract
    //         admins could adjust the fee right before a loan is repaid, and
    //         take all of the interest earned.
    // @param  _borrowerAndLenderNonces - An array of two UINT256 values, the
    //         first of which is the _borrowerNonce and the second of which is
    //         the _lenderNonce. The nonces referred to here are not the same
    //         as an Ethereum account's nonce. We are referring instead to
    //         nonces that are used by both the lender and the borrower when
    //         they are first signing off-chain NFTfi orders. These nonces can
    //         be any uint256 value that the user has not previously used to
    //         sign an off-chain order. Each nonce can be used at most once per
    //         user within NFTfi, regardless of whether they are the lender or
    //         the borrower in that situation. This serves two purposes. First,
    //         it prevents replay attacks where an attacker would submit a
    //         user's off-chain order more than once. Second, it allows a user
    //         to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _nftCollateralContract - The address of the ERC721 contract of
    //         the NFT collateral.
    // @param  _loanERC20Denomination - The address of the ERC20 contract of
    //         the currency being used as principal/interest for this loan.
    // @param  _lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  _borrowerSignature - The ECDSA signature of the borrower,
    //         obtained off-chain ahead of time, signing the following
    //         combination of parameters: _nftCollateralId, _borrowerNonce,
    //         _nftCollateralContract, _borrower.
    // @param  _lenderSignature - The ECDSA signature of the lender,
    //         obtained off-chain ahead of time, signing the following
    //         combination of parameters: _loanPrincipalAmount,
    //         _maximumRepaymentAmount _nftCollateralId, _loanDuration,
    //         _loanInterestRateForDurationInBasisPoints, _lenderNonce,
    //         _nftCollateralContract, _loanERC20Denomination, _lender,
    //         _interestIsProRated.
    function beginLoan(
        uint256 _loanId,
        uint256 _loanPrincipalAmount,
        uint256 _maximumRepaymentAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _loanInterestRateForDurationInBasisPoints,
        uint256 _adminFeeInBasisPoints,
        uint256[2] memory _borrowerAndLenderNonces,
        address _nftCollateralContract,
        address _loanERC20Denomination,
        address _lender
    ) public whenNotPaused nonReentrant {

        // Save loan details to a struct in memory first, to save on gas if any
        // of the below checks fail, and to avoid the "Stack Too Deep" error by
        // clumping the parameters together into one struct held in memory.
        Loan memory loan = Loan({
            loanId: _loanId, //currentLoanId,
            loanPrincipalAmount: _loanPrincipalAmount,
            maximumRepaymentAmount: _maximumRepaymentAmount,
            nftCollateralId: _nftCollateralId,
            loanStartTime: uint64(now), //_loanStartTime
            loanDuration: uint32(_loanDuration),
            loanInterestRateForDurationInBasisPoints: uint32(_loanInterestRateForDurationInBasisPoints),
            loanAdminFeeInBasisPoints: uint32(_adminFeeInBasisPoints),
            nftCollateralContract: _nftCollateralContract,
            loanERC20Denomination: _loanERC20Denomination,
            borrower: msg.sender, //borrower
            interestIsProRated: (_loanInterestRateForDurationInBasisPoints != ~(uint32(0)))
        });

        // Sanity check loan values.
        require(loan.loanId >= totalNumLoans, 'Negative interest rate loans are not allowed.');
        require(loan.maximumRepaymentAmount >= loan.loanPrincipalAmount, 'Negative interest rate loans are not allowed.');
        require(uint256(loan.loanDuration) <= maximumLoanDuration, 'Loan duration exceeds maximum loan duration');
        require(uint256(loan.loanDuration) != 0, 'Loan duration cannot be zero');
        require(uint256(loan.loanAdminFeeInBasisPoints) == adminFeeInBasisPoints, 'The admin fee has changed since this order was signed.');

        // Check that both the collateral and the principal come from supported
        // contracts.
        require(erc20CurrencyIsWhitelisted[loan.loanERC20Denomination], 'Currency denomination is not whitelisted to be used by this contract');
        require(nftContractIsWhitelisted[loan.nftCollateralContract], 'NFT collateral contract is not whitelisted to be used by this contract');

        // Check loan nonces. These are different from Ethereum account nonces.
        // Here, these are uint256 numbers that should uniquely identify
        // each signature for each user (i.e. each user should only create one
        // off-chain signature for each nonce, with a nonce being any arbitrary
        // uint256 value that they have not used yet for an off-chain NFTfi
        // signature).
        require(!_nonceHasBeenUsedForUser[msg.sender][_borrowerAndLenderNonces[0]], 'Borrower nonce invalid, borrower has either cancelled/begun this loan, or reused this nonce when signing');
        _nonceHasBeenUsedForUser[msg.sender][_borrowerAndLenderNonces[0]] = true;
        require(!_nonceHasBeenUsedForUser[_lender][_borrowerAndLenderNonces[1]], 'Lender nonce invalid, lender has either cancelled/begun this loan, or reused this nonce when signing');
        _nonceHasBeenUsedForUser[_lender][_borrowerAndLenderNonces[1]] = true;

        // Check that both signatures are valid.
        // require(isValidBorrowerSignature(
        //     loan.nftCollateralId,
        //     _borrowerAndLenderNonces[0],//_borrowerNonce,
        //     loan.nftCollateralContract,
        //     msg.sender,      //borrower,
        //     _borrowerSignature
        // ), 'Borrower signature is invalid');
        // require(isValidLenderSignature(
        //     loan.loanPrincipalAmount,
        //     loan.maximumRepaymentAmount,
        //     loan.nftCollateralId,
        //     loan.loanDuration,
        //     loan.loanInterestRateForDurationInBasisPoints,
        //     loan.loanAdminFeeInBasisPoints,
        //     _borrowerAndLenderNonces[1],//_lenderNonce,
        //     loan.nftCollateralContract,
        //     loan.loanERC20Denomination,
        //     _lender,
        //     loan.interestIsProRated,
        //     _lenderSignature
        // ), 'Lender signature is invalid');

        // Add the loan to storage before moving collateral/principal to follow
        // the Checks-Effects-Interactions pattern.
        loanIdToLoan[totalNumLoans] = loan;
        totalNumLoans = totalNumLoans.add(1);

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans.add(1);
        require(totalActiveLoans <= maximumNumberOfActiveLoans, 'Contract has reached the maximum number of active loans allowed by admins');

        // Transfer collateral from borrower to this contract to be held until
        // loan completion.
        IERC721(loan.nftCollateralContract).transferFrom(msg.sender, address(this), loan.nftCollateralId);

        // Transfer principal from lender to borrower.
        IERC20(loan.loanERC20Denomination).transferFrom(_lender, msg.sender, loan.loanPrincipalAmount);

        // Issue an ERC721 promissory note to the lender that gives them the
        // right to either the principal-plus-interest or the collateral.
        _mint(_lender, loan.loanId);

        // Emit an event with all relevant details from this transaction.
        emit LoanStarted(
            loan.loanId,
            msg.sender,      //borrower,
            _lender,
            loan.loanPrincipalAmount,
            loan.maximumRepaymentAmount,
            loan.nftCollateralId,
            now,             //_loanStartTime
            loan.loanDuration,
            loan.loanInterestRateForDurationInBasisPoints,
            loan.nftCollateralContract,
            loan.loanERC20Denomination,
            loan.interestIsProRated
        );
    }

    // @notice This function is called by a borrower when they want to repay
    //         their loan. It can be called at any time after the loan has
    //         begun. The borrower will pay a pro-rata portion of their
    //         interest if the loan is paid off early. The interest will
    //         continue to accrue after the loan has expired. This function can
    //         continue to be called by the borrower even after the loan has
    //         expired to retrieve their NFT. Note that the lender can call
    //         NFTfi.liquidateOverdueLoan() at any time after the loan has
    //         expired, so a borrower should avoid paying their loan after the
    //         due date, as they risk their collateral being seized. However,
    //         if a lender has called NFTfi.liquidateOverdueLoan() before a
    //         borrower could call NFTfi.payBackLoan(), the borrower will get
    //         to keep the principal-plus-interest.
    // @notice This function is purposefully not pausable in order to prevent
    //         an attack where the contract admin's pause the contract and hold
    //         hostage the NFT's that are still within it.
    // @param _loanId  A unique identifier for this particular loan, sourced
    //        from the continuously increasing parameter totalNumLoans.
    function payBackLoan(uint256 _loanId) external nonReentrant {
        // Sanity check that payBackLoan() and liquidateOverdueLoan() have
        // never been called on this loanId. Depending on how the rest of the
        // code turns out, this check may be unnecessary.
        require(!loanRepaidOrLiquidated[_loanId], 'Loan has already been repaid or liquidated');

        // Fetch loan details from storage, but store them in memory for the
        // sake of saving gas.
        Loan memory loan = loanIdToLoan[_loanId];

        // Check that the borrower is the caller, only the borrower is entitled
        // to the collateral.
        require(msg.sender == loan.borrower, 'Only the borrower can pay back a loan and reclaim the underlying NFT');

        // Fetch current owner of loan promissory note.
        address lender = ownerOf(_loanId);

        // Calculate amounts to send to lender and admins
        uint256 interestDue = (loan.maximumRepaymentAmount).sub(loan.loanPrincipalAmount);
        if(loan.interestIsProRated == true){
            interestDue = _computeInterestDue(
                loan.loanPrincipalAmount,
                loan.maximumRepaymentAmount,
                now.sub(uint256(loan.loanStartTime)),
                uint256(loan.loanDuration),
                uint256(loan.loanInterestRateForDurationInBasisPoints)
            );
        }
        uint256 adminFee = _computeAdminFee(interestDue, uint256(loan.loanAdminFeeInBasisPoints));
        uint256 payoffAmount = ((loan.loanPrincipalAmount).add(interestDue)).sub(adminFee);

        // Mark loan as repaid before doing any external transfers to follow
        // the Checks-Effects-Interactions design pattern.
        loanRepaidOrLiquidated[_loanId] = true;

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans.sub(1);

        // Transfer principal-plus-interest-minus-fees from borrower to lender
        IERC20(loan.loanERC20Denomination).transferFrom(loan.borrower, lender, payoffAmount);

        // Transfer fees from borrower to admins
        IERC20(loan.loanERC20Denomination).transferFrom(loan.borrower, owner(), adminFee);

        // Transfer collateral from this contract to borrower.
        require(_transferNftToAddress(
            loan.nftCollateralContract,
            loan.nftCollateralId,
            loan.borrower
        ), 'NFT was not successfully transferred');

        // Destroy the lender's promissory note.
        _burn(_loanId);

        // Emit an event with all relevant details from this transaction.
        emit LoanRepaid(
            _loanId,
            loan.borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            payoffAmount,
            adminFee,
            loan.nftCollateralContract,
            loan.loanERC20Denomination
        );

        // Delete the loan from storage in order to achieve a substantial gas
        // savings and to lessen the burden of storage on Ethereum nodes, since
        // we will never access this loan's details again, and the details are
        // still available through event data.
        delete loanIdToLoan[_loanId];
    }

    // @notice This function is called by a lender once a loan has finished its
    //         duration and the borrower still has not repaid. The lender
    //         can call this function to seize the underlying NFT collateral,
    //         although the lender gives up all rights to the
    //         principal-plus-collateral by doing so.
    // @notice This function is purposefully not pausable in order to prevent
    //         an attack where the contract admin's pause the contract and hold
    //         hostage the NFT's that are still within it.
    // @notice We intentionally allow anybody to call this function, although
    //         only the lender will end up receiving the seized collateral. We
    //         are exploring the possbility of incentivizing users to call this
    //         function by using some of the admin funds.
    // @param _loanId  A unique identifier for this particular loan, sourced
    //        from the continuously increasing parameter totalNumLoans.
    function liquidateOverdueLoan(uint256 _loanId) external nonReentrant {
        // Sanity check that payBackLoan() and liquidateOverdueLoan() have
        // never been called on this loanId. Depending on how the rest of the
        // code turns out, this check may be unnecessary.
        require(!loanRepaidOrLiquidated[_loanId], 'Loan has already been repaid or liquidated');

        // Fetch loan details from storage, but store them in memory for the
        // sake of saving gas.
        Loan memory loan = loanIdToLoan[_loanId];

        // Ensure that the loan is indeed overdue, since we can only liquidate
        // overdue loans.
        uint256 loanMaturityDate = (uint256(loan.loanStartTime)).add(uint256(loan.loanDuration));
        require(now > loanMaturityDate, 'Loan is not overdue yet');

        // Fetch the current lender of the promissory note corresponding to
        // this overdue loan.
        address lender = ownerOf(_loanId);

        // Mark loan as liquidated before doing any external transfers to
        // follow the Checks-Effects-Interactions design pattern.
        loanRepaidOrLiquidated[_loanId] = true;

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans.sub(1);

        // Transfer collateral from this contract to the lender, since the
        // lender is seizing collateral for an overdue loan.
        require(_transferNftToAddress(
            loan.nftCollateralContract,
            loan.nftCollateralId,
            lender
        ), 'NFT was not successfully transferred');

        // Destroy the lender's promissory note for this loan, since by seizing
        // the collateral, the lender has forfeit the rights to the loan
        // principal-plus-interest.
        _burn(_loanId);

        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            loan.borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            loanMaturityDate,
            now,
            loan.nftCollateralContract
        );

        // Delete the loan from storage in order to achieve a substantial gas
        // savings and to lessen the burden of storage on Ethereum nodes, since
        // we will never access this loan's details again, and the details are
        // still available through event data.
        delete loanIdToLoan[_loanId];
    }

    // @notice This is function can allow BEP tokens as WBNB or DAI.
    // @param _address - This address is the token smart contract address for allowance.
    function allowCurrencyContract(address _address) external nonReentrant {
        erc20CurrencyIsWhitelisted[_address] = true;
    }
    

    // @notice This function can be called by either a lender or a borrower to
    //         cancel all off-chain orders that they have signed that contain
    //         this nonce. If the off-chain orders were created correctly,
    //         there should only be one off-chain order that contains this
    //         nonce at all.
    // @param  _nonce - The nonce referred to here is not the same as an
    //         Ethereum account's nonce. We are referring instead to nonces
    //         that are used by both the lender and the borrower when they are
    //         first signing off-chain NFTfi orders. These nonces can be any
    //         uint256 value that the user has not previously used to sign an
    //         off-chain order. Each nonce can be used at most once per user
    //         within NFTfi, regardless of whether they are the lender or the
    //         borrower in that situation. This serves two purposes. First, it
    //         prevents replay attacks where an attacker would submit a user's
    //         off-chain order more than once. Second, it allows a user to
    //         cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    function cancelLoanCommitmentBeforeLoanHasBegun(uint256 _nonce) external {
        require(!_nonceHasBeenUsedForUser[msg.sender][_nonce], 'Nonce invalid, user has either cancelled/begun this loan, or reused a nonce when signing');
        _nonceHasBeenUsedForUser[msg.sender][_nonce] = true;
    }

    /* ******************* */
    /* READ-ONLY FUNCTIONS */
    /* ******************* */

    // @notice This function can be used to view the current quantity of the
    //         ERC20 currency used in the specified loan required by the
    //         borrower to repay their loan, measured in the smallest unit of
    //         the ERC20 currency. Note that since interest accrues every
    //         second, once a borrower calls repayLoan(), the amount will have
    //         increased slightly.
    // @param  _loanId  A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @return The amount of the specified ERC20 currency required to pay back
    //         this loan, measured in the smallest unit of the specified ERC20
    //         currency.
    function getPayoffAmount(uint256 _loanId) public view returns (uint256) {
        Loan storage loan = loanIdToLoan[_loanId];
        if(loan.interestIsProRated == false){
            return loan.maximumRepaymentAmount;
        } else {
            uint256 loanDurationSoFarInSeconds = now.sub(uint256(loan.loanStartTime));
            uint256 interestDue = _computeInterestDue(loan.loanPrincipalAmount, loan.maximumRepaymentAmount, loanDurationSoFarInSeconds, uint256(loan.loanDuration), uint256(loan.loanInterestRateForDurationInBasisPoints));
            return (loan.loanPrincipalAmount).add(interestDue);
        }
    }

    // @notice This function can be used to view whether a particular nonce
    //         for a particular user has already been used, either from a
    //         successful loan or a cancelled off-chain order.
    // @param  _user - The address of the user. This function works for both
    //         lenders and borrowers alike.
    // @param  _nonce - The nonce referred to here is not the same as an
    //         Ethereum account's nonce. We are referring instead to nonces
    //         that are used by both the lender and the borrower when they are
    //         first signing off-chain NFTfi orders. These nonces can be any
    //         uint256 value that the user has not previously used to sign an
    //         off-chain order. Each nonce can be used at most once per user
    //         within NFTfi, regardless of whether they are the lender or the
    //         borrower in that situation. This serves two purposes. First, it
    //         prevents replay attacks where an attacker would submit a user's
    //         off-chain order more than once. Second, it allows a user to
    //         cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @return A bool representing whether or not this nonce has been used for
    //         this user.
    function getWhetherNonceHasBeenUsedForUser(address _user, uint256 _nonce) public view returns (bool) {
        return _nonceHasBeenUsedForUser[_user][_nonce];
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    // @notice A convenience function that calculates the amount of interest
    //         currently due for a given loan. The interest is capped at
    //         _maximumRepaymentAmount minus _loanPrincipalAmount.
    // @param  _loanPrincipalAmount - The total quantity of principal first
    //         loaned to the borrower, measured in the smallest units of the
    //         ERC20 currency used for the loan.
    // @param  _maximumRepaymentAmount - The maximum amount of money that the
    //         borrower would be required to retrieve their collateral. If
    //         interestIsProRated is set to false, then the borrower will
    //         always have to pay this amount to retrieve their collateral.
    // @param  _loanDurationSoFarInSeconds - The elapsed time (in seconds) that
    //         has occurred so far since the loan began until repayment.
    // @param  _loanTotalDurationAgreedTo - The original duration that the
    //         borrower and lender agreed to, by which they measured the
    //         interest that would be due.
    // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
    ///        that the borrower and lender agreed would be due after the
    //         totalDuration passed.
    // @return The quantity of interest due, measured in the smallest units of
    //         the ERC20 currency used to pay this loan.
    function _computeInterestDue(uint256 _loanPrincipalAmount, uint256 _maximumRepaymentAmount, uint256 _loanDurationSoFarInSeconds, uint256 _loanTotalDurationAgreedTo, uint256 _loanInterestRateForDurationInBasisPoints) internal pure returns (uint256) {
        uint256 interestDueAfterEntireDuration = (_loanPrincipalAmount.mul(_loanInterestRateForDurationInBasisPoints)).div(uint256(10000));
        uint256 interestDueAfterElapsedDuration = (interestDueAfterEntireDuration.mul(_loanDurationSoFarInSeconds)).div(_loanTotalDurationAgreedTo);
        if(_loanPrincipalAmount.add(interestDueAfterElapsedDuration) > _maximumRepaymentAmount){
            return _maximumRepaymentAmount.sub(_loanPrincipalAmount);
        } else {
            return interestDueAfterElapsedDuration;
        }
    }

    // @notice A convenience function computing the adminFee taken from a
    //         specified quantity of interest
    // @param  _interestDue - The amount of interest due, measured in the
    //         smallest quantity of the ERC20 currency being used to pay the
    //         interest.
    // @param  _adminFeeInBasisPoints - The percent (measured in basis
    //         points) of the interest earned that will be taken as a fee by
    //         the contract admins when the loan is repaid. The fee is stored
    //         in the loan struct to prevent an attack where the contract
    //         admins could adjust the fee right before a loan is repaid, and
    //         take all of the interest earned.
    // @return The quantity of ERC20 currency (measured in smalled units of
    //         that ERC20 currency) that is due as an admin fee.
    function _computeAdminFee(uint256 _interestDue, uint256 _adminFeeInBasisPoints) internal pure returns (uint256) {
    	return (_interestDue.mul(_adminFeeInBasisPoints)).div(10000);
    }

    // @notice We call this function when we wish to transfer an NFT from our
    //         contract to another destination. Since some prominent NFT
    //         contracts do not conform to the same standard, we try multiple
    //         variations on transfer/transferFrom, and check whether any
    //         succeeded.
    // @notice Some nft contracts will not allow you to approve your own
    //         address or do not allow you to call transferFrom() when you are
    //         the sender, (for example, CryptoKitties does not allow you to),
    //         while other nft contracts do not implement transfer() (since it
    //         is not part of the official ERC721 standard but is implemented
    //         in some prominent nft projects such as Cryptokitties), so we
    //         must try calling transferFrom() and transfer(), and see if one
    //         succeeds.
    // @param  _nftContract - The NFT contract that we are attempting to
    //         transfer an NFT from.
    // @param  _nftId - The ID of the NFT that we are attempting to transfer.
    // @param  _recipient - The destination of the NFT that we are attempting
    //         to transfer.
    // @return A bool value indicating whether the transfer attempt succeeded.
    function _transferNftToAddress(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
        // Try to call transferFrom()
        bool transferFromSucceeded = _attemptTransferFrom(_nftContract, _nftId, _recipient);
        if(transferFromSucceeded){
            return true;
        } else {
            // Try to call transfer()
            bool transferSucceeded = _attemptTransfer(_nftContract, _nftId, _recipient);
            return transferSucceeded;
        }
    }

    // @notice This function attempts to call transferFrom() on the specified
    //         NFT contract, returning whether it succeeded.
    // @notice We only call this function from within _transferNftToAddress(),
    //         which is function attempts to call the various ways that
    //         different NFT contracts have implemented transfer/transferFrom.
    // @param  _nftContract - The NFT contract that we are attempting to
    //         transfer an NFT from.
    // @param  _nftId - The ID of the NFT that we are attempting to transfer.
    // @param  _recipient - The destination of the NFT that we are attempting
    //         to transfer.
    // @return A bool value indicating whether the transfer attempt succeeded.
    function _attemptTransferFrom(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
        // @notice Some NFT contracts will not allow you to approve an NFT that
        //         you own, so we cannot simply call approve() here, we have to
        //         try to call it in a manner that allows the call to fail.
        _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).approve.selector, address(this), _nftId));

        // @notice Some NFT contracts will not allow you to call transferFrom()
        //         for an NFT that you own but that is not approved, so we
        //         cannot simply call transferFrom() here, we have to try to
        //         call it in a manner that allows the call to fail.
        (bool success, ) = _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).transferFrom.selector, address(this), _recipient, _nftId));
        return success;
    }

    // @notice This function attempts to call transfer() on the specified
    //         NFT contract, returning whether it succeeded.
    // @notice We only call this function from within _transferNftToAddress(),
    //         which is function attempts to call the various ways that
    //         different NFT contracts have implemented transfer/transferFrom.
    // @param  _nftContract - The NFT contract that we are attempting to
    //         transfer an NFT from.
    // @param  _nftId - The ID of the NFT that we are attempting to transfer.
    // @param  _recipient - The destination of the NFT that we are attempting
    //         to transfer.
    // @return A bool value indicating whether the transfer attempt succeeded.
    function _attemptTransfer(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
        // @notice Some NFT contracts do not implement transfer(), since it is
        //         not a part of the official ERC721 standard, but many
        //         prominent NFT projects do implement it (such as
        //         Cryptokitties), so we cannot simply call transfer() here, we
        //         have to try to call it in a manner that allows the call to
        //         fail.
        (bool success, ) = _nftContract.call(abi.encodeWithSelector(ICryptoKittiesCore(_nftContract).transfer.selector, _recipient, _nftId));
        return success;
    }

    /* ***************** */
    /* FALLBACK FUNCTION */
    /* ***************** */

    // @notice By calling 'revert' in the fallback function, we prevent anyone
    //         from accidentally sending funds directly to this contract.
    function() external payable {
        revert();
    }
}

// @notice The interface for interacting with the CryptoKitties contract. We
//         include this special case because CryptoKitties is one of the most
//         used NFT contracts on Ethereum and will likely be used by NFTfi, but
//         it does not perfectly abide by the ERC721 standard, since it preceded
//         the official standardization of ERC721.
contract ICryptoKittiesCore {
    function transfer(address _to, uint256 _tokenId) external;
}