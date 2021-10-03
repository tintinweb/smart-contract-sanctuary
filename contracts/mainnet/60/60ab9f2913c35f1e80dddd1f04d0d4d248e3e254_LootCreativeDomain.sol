/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/LootCreativeDomain.sol

pragma solidity 0.7.4;




interface LCDProject {
    function mintWithLoot(address minter, uint256 tokenId) external;
    function mintWithoutLoot(address minter, uint256 tokenId) external payable;
    function mintAsCurator(address minter, uint256 tokenId) external;
    function getProps(uint256 tokenId) external view returns(string memory);
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface LCDCustomProject {
    function mintCustom(address minter, uint256 tokenId) external payable;
    function mintCustomAsCurator(address minter, uint256 tokenId) external;
    function getProps(uint256 tokenId) external view returns(string memory);
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}


contract LootCreativeDomain is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private registryPrice = 50000000000000000; // initiated at 0.05 ETH
    uint256 private customPropPrice = 10000000000000000; // initiated at 0.01 ETH

    uint256 private constant NUM_LOOT = 8000;
    uint256 public protocolClaimableFees;

    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface lootContract = LootInterface(lootAddress);

    address public gov;
    address public protocol;
    IERC20 public lcdToken;

    mapping(address => Project) projectRegistry;

    mapping(address => mapping(uint256 => string)) projectToTokenIdToLambdaProp;
    mapping(address => mapping(uint256 => string)) projectToTokenIdToOmegaProp;
    mapping(address => mapping(uint256 => string)) projectToTokenIdToCustomURI;

    mapping(address => uint256) affiliateOrCuratorFeesClaimable;
    mapping(address => mapping(uint256 => bool)) tokenRegistry;

    event ProjectRegister(
        address indexed _project,
        uint256 _lootPrice,
        uint256 _nonLootPrice,
        uint256 _nonLootMintCap,
        uint256 _curatorMintCap,
        uint256 _timestamp,
        bool _isCustomProject
    );

    event Endorse(
        address indexed _project,
        uint256 _amountPerMint,
        uint256 _timestamp
    );

    event RevokeEndorse(
        address indexed _project,
        uint256 _timestamp
    );

    event LCDMint(
        address indexed _project,
        address indexed _minter,
        uint256 _tokenId,
        bool _mintWithLoot
    );

    event FeeClaim(
        address indexed _claimer,
        uint256 _amount,
        uint256 _timestamp
    );

    event ProtocolClaim(
        uint256 _amount,
        uint256 _timestamp
    );

    event LambdaPropSet(
        address indexed _project,
        uint256 indexed _tokenId,
        string _lambdaProp,
        address indexed _affiliate
    );

    event OmegaPropSet(
        address indexed _project,
        uint256 indexed _tokenId,
        string _omegaProp,
        address indexed _affiliate
    );

    event CustomURISet(
        address indexed _project,
        uint256 indexed _tokenId,
        string _customURI,
        address indexed _affiliate
    );

    struct Project {
        address curator;
        uint256 lootPrice;
        uint256 nonLootPrice;
        uint256 nonLootMintCap;
        uint256 nonLootMints;
        uint256 curatorMintCap;
        uint256 curatorMints;
        uint256 endorsementPerMint;
        bool isCustomURIEnabled;
        bool isCustomProject;
    }

    constructor(IERC20 _lcdToken) public {
        gov = msg.sender;
        protocol = msg.sender;
        lcdToken = _lcdToken;
    }

    modifier onlyGov {
        require(msg.sender == gov, "Not gov");
        _;
    }

    modifier onlyProtocol {
        require(msg.sender == protocol, "Not protocol");
        _;
    }

    /*
    *
    * Mint
    *
    */

    /*
    * Mint on standard projects as Loot holder
    */
    function mintWithLoot(address _project, uint256 _lootId) public payable nonReentrant {
        Project memory project = projectRegistry[_project];
        require(lootContract.ownerOf(_lootId) == msg.sender, "Not owner");
        require(msg.value == project.lootPrice, "Incorrect value");
        require(!project.isCustomProject, "Custom project");

        LCDProject(_project).mintWithLoot(msg.sender, _lootId);

        _registerId(_project, _lootId);
        _registerFeesFromMint(_project, project.lootPrice);
        _distributeEndorsement(msg.sender, project.endorsementPerMint);

        emit LCDMint(_project, msg.sender, _lootId, true);
    }

    /*
    * Mint on standard projects as non-Loot holder
    * Note that the tokenId is not accepted as a param; it's generated linearly
    */
    function mintWithoutLoot(address _project) public payable nonReentrant {
        Project memory project = projectRegistry[_project];
        require(msg.value == project.nonLootPrice, "Incorrect value");
        require(project.nonLootMints < project.nonLootMintCap, "Capped");
        require(!project.isCustomProject, "Custom project");

        project.nonLootMints++;
        uint256 tokenId = NUM_LOOT.add(project.nonLootMints);

        LCDProject(_project).mintWithoutLoot(msg.sender, tokenId);

        _registerId(_project, tokenId);
        _registerFeesFromMint(_project, project.nonLootPrice);
        _distributeEndorsement(msg.sender, project.endorsementPerMint);

        emit LCDMint(_project, msg.sender, tokenId, false);
    }

    /*
    * Mint on custom projects as anyone
    */
    function mintCustom(address _project, uint256 _tokenId) public payable {
        Project memory project = projectRegistry[_project];
        require(project.isCustomProject, "Not custom project");
        require(msg.value == project.nonLootPrice, "Incorrect value");
        require(_tokenId > 0 && _tokenId <= project.nonLootMintCap, "Invalid id");

        LCDCustomProject(_project).mintCustom(msg.sender, _tokenId);
        project.nonLootMints++;

        _registerId(_project, _tokenId);
        _registerFeesFromMint(_project, project.nonLootPrice);
        _distributeEndorsement(msg.sender, project.endorsementPerMint);

        emit LCDMint(_project, msg.sender, _tokenId, false);
    }

    /*
    * Mint on standard projects as curator
    */
    function mintAsCurator(address _project, uint256 _tokenId) public {
        Project memory project = projectRegistry[_project];
        require(msg.sender == project.curator, "Not curator");
        require(!project.isCustomProject, "Custom project");
        require(project.curatorMints < project.curatorMintCap, "No more mints");
        require(
            _tokenId > NUM_LOOT.add(project.nonLootMintCap) &&
            _tokenId <= NUM_LOOT.add(project.nonLootMintCap).add(project.curatorMintCap),
            "Invalid id"
        );

        LCDProject(_project).mintAsCurator(msg.sender, _tokenId);
        _registerId(_project, _tokenId);

        emit LCDMint(_project, msg.sender, _tokenId, false);
    }

    /*
    * Mint on custom projects as curator
    */
    function mintCustomAsCurator(address _project, uint256 _tokenId) public {
        Project memory project = projectRegistry[_project];
        require(msg.sender == project.curator, "Not curator");
        require(project.isCustomProject, "Not custom project");
        require(
            _tokenId > project.nonLootMintCap &&
            _tokenId <= project.nonLootMintCap.add(project.curatorMintCap), "Invalid id"
        );

        LCDCustomProject(_project).mintCustomAsCurator(msg.sender, _tokenId);
        _registerId(_project, _tokenId);

        emit LCDMint(_project, msg.sender, _tokenId, false);
    }

    /*
    *
    * Gov
    *
    */

    /*
    * Called to incentivize minters with LCD tokens on certain projects
    */
    function endorse(address _project, uint256 _endorsementPerMint) public onlyGov {
        require(_endorsementPerMint <= 5e16, "Too high");
        projectRegistry[_project].endorsementPerMint = _endorsementPerMint;

        emit Endorse(_project, _endorsementPerMint, block.timestamp);
    }

    /*
    * Called to no longer incentivize a project
    */
    function revokeEndorsement(address _project) public onlyGov {
        projectRegistry[_project].endorsementPerMint = 0;

        emit RevokeEndorse(_project, block.timestamp);
    }

    /*
    * Change ETH amount required to register custom prop on LCD (wei notation)
    */
    function changeCustomPropPrice(uint256 _newPrice) public onlyGov {
        customPropPrice = _newPrice;
    }

    /*
    * Change ETH amount required to register project on LCD (wei notation)
    */
    function changeRegistryPrice(uint256 _newPrice) public onlyGov {
        registryPrice = _newPrice;
    }

    /*
    * Withdraw ERC20s from contract
    */
    function withdrawTokens(address token) public onlyGov {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /*
    * Set new gov address
    */
    function setGov(address _gov) public onlyGov {
        require(_gov != address(0));
        gov = _gov;
    }

    /*
    * Set new protocol address
    */
    function setProtocol(address _protocol) public onlyProtocol {
        require(_protocol != address(0));
        protocol = _protocol;
    }

    /*
    *
    * Claim Fees
    *
    */

    /*
    * Affiliate or curator claim of ETH fees
    */
    function claim(address _claimer) public nonReentrant {
        require(msg.sender == _claimer, "Not affiliate/curator");
        uint256 claimable = affiliateOrCuratorFeesClaimable[_claimer];
        require(claimable > 0, "Nothing to claim");
        affiliateOrCuratorFeesClaimable[_claimer] = 0;

        (bool sent, ) = _claimer.call{value: claimable}("");
        require(sent, "Failed");

        emit FeeClaim(_claimer, claimable, block.timestamp);
    }

    /*
    * Protocol claim of ETH fees
    */
    function protocolClaim() public onlyProtocol {
        uint256 claimable = protocolClaimableFees;
        protocolClaimableFees = 0;
        (bool sent, ) = protocol.call{value: claimable}("");
        require(sent, "Failed");

        emit ProtocolClaim(claimable, block.timestamp);
    }

    /*
    *
    * Curator
    *
    */

    /*
    * Registers NFT project where Loot owners are entitled to mint with respective lootId
    * _project: NFT address
    * _lootPrice: ETH payable per Loot mint (can be 0) - wei notation
    * _nonLootPrice: ETH payable per non-Loot mint (can be 0) - wei notation
    * _nonLootMintCap: Tokens mintable to non-Loot owners
    * _curatorMintCap: Tokens mintable by curator
    * _isCustomURIEnabled: bool for whether token holders can set Custom URI for token on LCD contract
    */
    function registerProject(
        address _project,
        uint256 _lootPrice,
        uint256 _nonLootPrice,
        uint256 _nonLootMintCap,
        uint256 _curatorMintCap,
        bool _isCustomURIEnabled
    ) public payable {
        require(msg.value == registryPrice, "Incorrect value");
        Project storage project = projectRegistry[_project];
        require(project.curator == address(0), "Project exists");

        project.curator = msg.sender;
        project.lootPrice = _lootPrice;
        project.nonLootPrice = _nonLootPrice;
        project.nonLootMintCap = _nonLootMintCap;
        project.curatorMintCap = _curatorMintCap;
        project.isCustomURIEnabled = _isCustomURIEnabled;

        _registerFeesFromProp(address(0), registryPrice);

        emit ProjectRegister(_project, _lootPrice, _nonLootPrice, _nonLootMintCap, _curatorMintCap, block.timestamp, false);
    }

    /*
    * Registers NFT project where minting is not linked to Loot ownership
    * _project: NFT address
    * _price: ETH payable per mint (can be 0) - wei notation
    * _mintCap: total Rokens mintable by public
    * _curatorMintCap: Tokens mintable by curator
    * _isCustomURIEnabled: bool for whether token holders can set Custom URI for token on LCD contract
    */
    function registerCustomProject(
        address _project,
        uint256 _price,
        uint256 _mintCap,
        uint256 _curatorMintCap,
        bool _isCustomURIEnabled
    ) public payable {
        require(msg.value == registryPrice, "Incorrect value");
        Project storage project = projectRegistry[_project];
        require(project.curator == address(0), "Project exists");

        project.curator = msg.sender;
        project.nonLootPrice = _price;
        project.nonLootMintCap = _mintCap;
        project.curatorMintCap = _curatorMintCap;
        project.isCustomProject = true;
        project.isCustomURIEnabled = _isCustomURIEnabled;

        _registerFeesFromProp(address(0), registryPrice);

        emit ProjectRegister(_project, 0, _price, _mintCap, _curatorMintCap, block.timestamp, true);
    }

    /*
    * Changes curator of project and recipient of future mint fees
    */
    function changeCurator(address _project, address _newCurator) public {
        require(msg.sender == projectRegistry[_project].curator, "Not curator");
        require(_newCurator != address(0));
        projectRegistry[_project].curator = _newCurator;
    }

    /*
    *
    * Props
    *
    */

    /*
    * Set a custom string prop
    * Lambda prop has no specific intended use case. Developers can use this
    * prop to unlock whichever features or experiences they want to incorporate
    * into their creation
    * _affiliate is (for example) the developer of gaming or visual experience
    * that integrates the NFT
    * Affiliate earns 80% of ETH fee
    */
    function setLambdaProp(
        address _project,
        uint256 _tokenId,
        string memory _lambdaProp,
        address _affiliate
    ) public payable nonReentrant {
        require(msg.sender == LCDProject(_project).ownerOf(_tokenId), "Not owner");
        require(msg.value == customPropPrice, "Incorrect value");

        projectToTokenIdToLambdaProp[_project][_tokenId] = _lambdaProp;
        _registerFeesFromProp(_affiliate, customPropPrice);

        emit LambdaPropSet(_project, _tokenId, _lambdaProp, _affiliate);
    }

    /*
    * Set a custom string prop
    * Omega prop has no specific intended use case. Developers can use this
    * prop to unlock whichever features or experiences they want to incorporate
    * into their creation
    * _affiliate is (for example) the developer of gaming or visual experience
    * that integrates the NFT
    * Omega prop price == 2x Lambda prop price
    * Affiliate earns 80% of ETH fee
    */
    function setOmegaProp(
        address _project,
        uint256 _tokenId,
        string memory _omegaProp,
        address _affiliate
    ) public payable nonReentrant {
        require(msg.sender == LCDProject(_project).ownerOf(_tokenId), "Not owner");
        require(msg.value == customPropPrice * 2, "Incorrect value");

        projectToTokenIdToOmegaProp[_project][_tokenId] = _omegaProp;
        _registerFeesFromProp(_affiliate, customPropPrice * 2);

        emit OmegaPropSet(_project, _tokenId, _omegaProp, _affiliate);
    }

    /*
    * LCD allows token holders to set a custom URI of their choosing if curator has enabled feature
    * See LootVanGogh project for example use case, where rarity/properties are returned statically
    * via getProps but user can modify custom URI interpretation of those props
    * Example of _customURI prop would be an IPFS url
    * _affiliate is (for example) the developer of gaming or visual experience
    * that integrates the NFT
    * Affiliate earns 80% of ETH fee
    */
    function setCustomURI(
        address _project,
         uint256 _tokenId,
         string memory _customURI,
         address _affiliate
    ) public payable nonReentrant {
        require(projectRegistry[_project].isCustomURIEnabled, "Disabled");
        require(msg.sender == LCDProject(_project).ownerOf(_tokenId), "Not owner");
        require(msg.value == customPropPrice, "Incorrect value");

        projectToTokenIdToCustomURI[_project][_tokenId] = _customURI;
        _registerFeesFromProp(_affiliate, customPropPrice);

        emit CustomURISet(_project, _tokenId, _customURI, _affiliate);
    }

    /*
    *
    * Reads
    *
    */

    /*
    * Returns whether token is included in LCD canonical registry
    */
    function isTokenRegistered(address _project, uint256 _tokenId) public view returns(bool){
        return tokenRegistry[_project][_tokenId];
    }

    /*
    * Returns a custom string set on LCD contract via setLambdaProp
    * Lambda prop has no specific intended use case. Developers can use this
    * prop to unlock whichever features or experiences they want to incorporate
    * into their creation
    */
    function getLambdaProp(address _project, uint256 _tokenId) public view returns(string memory){
        return projectToTokenIdToLambdaProp[_project][_tokenId];
    }

    /*
    * Returns a custom string set on LCD contract via setOmegaProp
    * Omega prop has no specific intended use case. Developers can use this
    * prop to unlock whichever features or experiences they want to incorporate
    * into their creation
    */
    function getOmegaProp(address _project, uint256 _tokenId) public view returns(string memory){
        return projectToTokenIdToOmegaProp[_project][_tokenId];
    }

    /*
    * Returns either a custom URI set on LCD contract or tokenURI from respective project contract
    */
    function tokenURI(address _project, uint256 _tokenId) public view returns(string memory){
        if(bytes(projectToTokenIdToCustomURI[_project][_tokenId]).length > 0){
            return projectToTokenIdToCustomURI[_project][_tokenId];
        }
        return LCDProject(_project).tokenURI(_tokenId);
    }

    /*
    * Randomly-generated, constantly changing number for a given token to be used interpretatively
    * (as creator sees fit) on contracts, frontends, game experiences, etc.
    */
    function getRandomProp(address _project, uint256 _tokenId) public view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _project, _tokenId))).div(1e18);
    }

    function getCustomTokenURI(address _project, uint256 _tokenId) public view returns(string memory){
        return projectToTokenIdToCustomURI[_project][_tokenId];
    }

    /*
    * Returns concatenated prop string for tokenId with global LCD properties
    * and project-specific properties
    */
    function getProps(address _project, uint256 _tokenId) public view returns(string memory){
        require(isTokenRegistered(_project, _tokenId), "Unregistered");
        return string(
            abi.encodePacked(
                LCDProject(_project).getProps(_tokenId),
                " + lambda:",
                getLambdaProp(_project, _tokenId),
                " + omega:",
                getOmegaProp(_project, _tokenId),
                " + URI:",
                tokenURI(_project, _tokenId)
            )
        );
    }

    /*
    * Returns registry price, custom URI/lambdaProp price, omegaPropPrice
    */
    function getPropPrices() public view returns(uint256, uint256, uint256){
        return (registryPrice, customPropPrice, customPropPrice * 2);
    }

    /*
    * Returns claimable ETH amount for given affiliate or curator
    */
    function getAffiliateOrCuratorClaimable(address _claimer) public view returns(uint256){
        return affiliateOrCuratorFeesClaimable[_claimer];
    }

    /*
    * Returns basic project info
    */
    function getBasicProjectInfo(address _project) public view returns(
        address,
        uint256,
        uint256,
        uint256,
        bool
    ){
        return (
            projectRegistry[_project].curator,
            projectRegistry[_project].lootPrice,
            projectRegistry[_project].nonLootPrice,
            projectRegistry[_project].endorsementPerMint,
            projectRegistry[_project].isCustomProject
        );
    }

    /*
    * Returns advanced project info
    */
    function getAdvancedProjectInfo(address _project) public view returns(
        uint256,
        uint256,
        uint256,
        bool
    ) {
        return (
            projectRegistry[_project].nonLootMints,
            projectRegistry[_project].curatorMintCap,
            projectRegistry[_project].curatorMints,
            projectRegistry[_project].isCustomURIEnabled
        );
    }

    function isProjectEndorsed(address _project) public view returns(bool){
        return projectRegistry[_project].endorsementPerMint > 0;
    }

    function getOwnerOf(address _project, uint256 _tokenId) public view returns(address){
        if(tokenRegistry[_project][_tokenId]){
            return LCDProject(_project).ownerOf(_tokenId);
        }
        return address(0);
    }

    /*
    *
    * Private
    *
    */

    /*
    * Distributes LCD tokens to minters of endorsed projects
    */
    function _distributeEndorsement(address _minter, uint256 _amount) private {
        if(_amount > 0 && lcdToken.balanceOf(address(this)) >= _amount){
            lcdToken.transfer(_minter, _amount);
        }
    }

    /*
    * Registers tokenIds to global registry
    */
    function _registerId(address _project, uint256 _tokenId) private {
        require(!tokenRegistry[_project][_tokenId], "Already registered");
        tokenRegistry[_project][_tokenId] = true;
    }

    /*
    * Registers respective shares of mint fee to curator and protocol
    */
    function _registerFeesFromMint(address _project, uint256 _amount) private {
        if(_amount > 0){
            uint256 protocolShare = _amount.div(5);
            affiliateOrCuratorFeesClaimable[projectRegistry[_project].curator] =
                affiliateOrCuratorFeesClaimable[projectRegistry[_project].curator].add(_amount.sub(protocolShare));
            protocolClaimableFees = protocolClaimableFees.add(protocolShare);
        }
    }

    /*
    * Registers respective shares of prop or registry fee to affiliate and protocol
    */
    function _registerFeesFromProp(address _affiliate, uint256 _amount) private {
        if(_affiliate == address(0)){
            protocolClaimableFees = protocolClaimableFees.add(_amount);
        } else {
            uint256 protocolShare = _amount.div(5);
            affiliateOrCuratorFeesClaimable[_affiliate] = affiliateOrCuratorFeesClaimable[_affiliate].add(_amount.sub(protocolShare));
            protocolClaimableFees = protocolClaimableFees.add(protocolShare);
        }
    }
}