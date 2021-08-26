/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
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


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


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


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IMinerManage {

    function setOracleAddress(address _oracleAddress) external;
    function minerAdjustedStoragePowerInTiB(string memory minerId) external view returns(uint256);
    function whiteList(address walletAddress) external returns(bool);
    function minerInfoMap(address walletAddress) external returns(string memory);
    function getMinerList() external view returns(string[] memory);
    function getMinerId(address walletAddress) external view returns(string memory);
}

interface IMiningNFTManage {

    function getMinerIdByTokenId(uint256 _tokenId) external view returns(string memory);
    
}

interface IMiningNFT is IERC1155{

    function getInitialTokenId() external pure returns(uint256);
    function getCurrentTokenId() external view returns(uint256);

    function mint(address account, uint256 amount) external returns(uint256);

    function burn(address account,uint256 tokenId, uint256 amount) external ;
}

interface IFilChainStatOracle {
    function sectorInitialPledge() external view returns(uint256);
    function minerAdjustedPower(string memory _minerId) external view returns(uint256);
    function minerMiningEfficiency(string memory _minerId) external view returns(uint256);
    function minerSectorInitialPledge(string memory _minerId) external view returns(uint256);
    function minerTotalAdjustedPower() external view returns(uint256);
    function avgMiningEfficiency() external view returns(uint256);
    function latest24hBlockReward() external view returns(uint256);
    function rewardAttenuationFactor() external view returns(uint256);
    function networkStoragePower() external view returns(uint256);
    function dailyStoragePowerIncrease() external view returns(uint256);
    function removeMinerAdjustedPower(string memory _minerId) external;
    
}

interface IMiningNFTMintingLimitation {
    function getMinerMintLimitationInTiB(string memory _minerId) external view returns(uint256);
    function checkLimitation(string memory _minerId, uint256 _minerTotalMinted, uint256 _allMinersTotalMinted) external view returns(bool, string memory);
}

contract MiningNFTManage is Ownable{
    using SafeMath for uint256;

    struct TokenInfo{
        string minerId;
        uint256 supply;
        uint256 initialPledgePerTiB;
    }

    mapping(string=>uint256) public mintedAmount; // in TiB
    mapping(string=>uint256[]) minerMintedTokens;
    mapping(uint256=>TokenInfo) public tokenInfoMap;
    mapping(string=>uint256) public minerTotalPledgedAmount;

    uint256 public totalMintedInTiB;
    uint256 public totalSectorInitialPledge; // attoFil/TiB
    
    IMinerManage public minerManage;
    IMiningNFT public miningNFT;
    IFilChainStatOracle public filChainStatOracle;
    IMiningNFTMintingLimitation public miningNFTMintingLimitation;

    event Mint(address indexed account, uint256 indexed tokenId, uint256 amount);
    event Burn(address indexed account, uint256 indexed tokenId, uint256 amount);
    event RemoveToken(address indexed account, string indexed minerId, uint256 tokenId);
    event MiningNftMintingLimitationChanged(address limitation, address newLimitation);
    event MinerManageChanged(address minerManage, address newMinerManage);
    event FilChainStatOracleChanged(address filChainStatOracle, address newFilChainStatOracle);

    constructor(IMinerManage _minerManage, IMiningNFT _miningNFT, IFilChainStatOracle _filChainStatOracle, IMiningNFTMintingLimitation _miningNFTMintingLimitation){
        minerManage = _minerManage;
        miningNFT = _miningNFT;
        filChainStatOracle = _filChainStatOracle;
        miningNFTMintingLimitation = _miningNFTMintingLimitation;
    }
    
    function setMiningNFTMintingLimitation(IMiningNFTMintingLimitation _miningNFTMintingLimitation) public onlyOwner{
        require(address(_miningNFTMintingLimitation) != address(0), "address should not be 0");
        address origin = address(miningNFTMintingLimitation);
        miningNFTMintingLimitation = _miningNFTMintingLimitation;
        emit MiningNftMintingLimitationChanged(origin, address(_miningNFTMintingLimitation));
    }

    function setMinerManage(IMinerManage _minerManage) external onlyOwner{
        require(address(_minerManage) != address(0), "address should not be 0");
        address originMinerManage = address(minerManage);
        minerManage = _minerManage;
        emit MinerManageChanged(originMinerManage, address(_minerManage));
    }

    function setFilChainStatOracle(IFilChainStatOracle _filChainStatOracle) external onlyOwner{
        require(address(_filChainStatOracle) != address(0), "address should not be 0");
        emit FilChainStatOracleChanged(address(filChainStatOracle), address(_filChainStatOracle));
        filChainStatOracle = _filChainStatOracle;
    }

    function getMinerMintedTokensByWalletAddress(address _walletAddress) external view returns(uint256[] memory){
        string memory minerId = minerManage.getMinerId(_walletAddress);
        return minerMintedTokens[minerId];
    }

    function getMinerMintedTokens(string memory _minerId) external view returns(uint256[] memory){
        return minerMintedTokens[_minerId];
    }

    function getMinerIdByTokenId(uint256 _tokenId) external view returns(string memory){
        return tokenInfoMap[_tokenId].minerId;
    }

    function getLastMintedTokenId(string memory _minerId) external view returns(uint256){
        uint256[] memory mintedTokens = minerMintedTokens[_minerId];
        if(mintedTokens.length>0){
            return mintedTokens[mintedTokens.length - 1];
        }else{
            return 0;
        }
    }

    function mint(uint256 _amount) external {
        require(minerManage.whiteList(_msgSender()), "sender not in whitelist");

        string memory minerId = minerManage.getMinerId(_msgSender());
        uint256 minerMintedAmount = mintedAmount[minerId];

        (bool success, string memory message) = miningNFTMintingLimitation.checkLimitation(minerId, minerMintedAmount.add(_amount), totalMintedInTiB.add(_amount));
        require(success, message);

        mintedAmount[minerId] = minerMintedAmount.add(_amount);
        totalMintedInTiB = totalMintedInTiB.add(_amount);

        uint256 newTokenId = miningNFT.mint(_msgSender(), _amount);
        minerMintedTokens[minerId].push(newTokenId);

        uint256 sectorInitialPledge = filChainStatOracle.sectorInitialPledge();
        require(sectorInitialPledge > 0, "sectorInitialPledge should be >0");
        
        tokenInfoMap[newTokenId] = TokenInfo(minerId, _amount, sectorInitialPledge);
        uint256 pledgeAmount = sectorInitialPledge.mul(_amount);
        totalSectorInitialPledge = totalSectorInitialPledge.add(pledgeAmount);
        minerTotalPledgedAmount[minerId] = minerTotalPledgedAmount[minerId].add(pledgeAmount);

        emit Mint(_msgSender(), newTokenId, _amount);
    }

    function burn(uint256 _tokenId, uint256 _amount) external {
        address account = _msgSender();
        require(miningNFT.balanceOf(account, _tokenId)>=_amount, "burn amount exceed balance");
        
        string memory minerId = minerManage.getMinerId(_msgSender());
        mintedAmount[minerId] = mintedAmount[minerId].sub(_amount);
        totalMintedInTiB = totalMintedInTiB.sub(_amount);

        uint256 tokenSectorInitialPledge = tokenInfoMap[_tokenId].initialPledgePerTiB;
        uint256 pledgeAmount = tokenSectorInitialPledge.mul(_amount);
        totalSectorInitialPledge = totalSectorInitialPledge.sub(pledgeAmount);
        minerTotalPledgedAmount[minerId] = minerTotalPledgedAmount[minerId].sub(pledgeAmount);

        miningNFT.burn(account, _tokenId, _amount);
        removeMintedToken(_tokenId);
        emit Burn(account, _tokenId, _amount);
    }

    function removeMintedToken(uint256 _tokenId) internal{
        if(miningNFT.balanceOf(_msgSender(), _tokenId) == 0){
            string memory minerId = minerManage.getMinerId(_msgSender());
            uint256[] storage mintedTokens = minerMintedTokens[minerId];

            for(uint i=0; i<mintedTokens.length; i++){
                if(mintedTokens[i] == _tokenId){
                    mintedTokens[i] = mintedTokens[mintedTokens.length - 1];
                    mintedTokens.pop();
                    emit RemoveToken(_msgSender(), minerId, _tokenId);
                    break;
                }
            }
        }
    }

    function getAvgInitialPledge() public view returns(uint256){
        if(totalMintedInTiB==0) return 0;
        return totalSectorInitialPledge.div(totalMintedInTiB);
    }

    function getMinerTotalPledgeFilAmount(string memory _minerId) public view returns(uint256){
        return minerTotalPledgedAmount[_minerId];
    }
}