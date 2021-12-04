/// SPDX-License-Identifier: MIT
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

// File: flatten\contracts\token\ERC721\IERC721.sol

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    constructor () {
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



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILandsNftContract {
    function mintToken(address to, uint256 tokenId) external payable;

    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function isTransferAllowed(address to, uint delta) external view returns (bool);

    function mintTokens(address to, uint tokensNumber) external;
}


contract PhaseManager is Ownable {

    enum Stages {
        Paused,
        Stage1,
        Stage2,
        Stage3,
        Stage4
    }

    Stages internal stage = Stages.Paused;

    uint _stage1StartTs;
    uint _stage2StartTs;
    uint _stage3StartTs;
    uint _stage4StartTs;

    uint _publicSaleDelay;

    constructor() {
        // just sample values that supposed to be setup manually
        _stage1StartTs = block.timestamp + 10 days;
        _stage2StartTs = block.timestamp + 40 days;
        _stage3StartTs = block.timestamp + 70 days;
        _stage4StartTs = block.timestamp + 100 days;
        _publicSaleDelay = 86400;
        // 24h
    }

    modifier timedTransitions() {
        if (stage == Stages.Paused &&
            block.timestamp >= _stage1StartTs)
            nextStage();
        if (stage == Stages.Stage1 &&
            block.timestamp >= _stage2StartTs)
            nextStage();
        if (stage == Stages.Stage2 &&
            block.timestamp >= _stage3StartTs)
            nextStage();
        if (stage == Stages.Stage3 &&
            block.timestamp >= _stage4StartTs)
            nextStage();
        // The other stages transition by transaction
        _;
    }


    function setPhasesTs(uint stage1StartTs, uint stage2StartTs, uint stage3StartTs, uint stage4StartTs) public onlyOwner {
        require(stage1StartTs > 0);
        require(stage2StartTs > stage1StartTs);
        require(stage3StartTs > stage2StartTs);
        require(stage4StartTs > stage3StartTs);
        _stage1StartTs = stage1StartTs;
        _stage2StartTs = stage2StartTs;
        _stage3StartTs = stage3StartTs;
        _stage4StartTs = stage4StartTs;
    }

    function setPublicSaleDelay(uint publicSaleDelay) public onlyOwner {
        require(publicSaleDelay > 0);
        _publicSaleDelay = publicSaleDelay;
    }

    function isPublicSale() public timedTransitions returns (bool) {
        if (stage == Stages.Paused)
            return false;
        if (stage == Stages.Stage1)
            return block.timestamp >= _stage1StartTs + _publicSaleDelay;
        if (stage == Stages.Stage2)
            return block.timestamp >= _stage2StartTs + _publicSaleDelay;
        if (stage == Stages.Stage3)
            return block.timestamp >= _stage3StartTs + _publicSaleDelay;
        if (stage == Stages.Stage4)
            return block.timestamp >= _stage4StartTs + _publicSaleDelay;
        return false;
    }

    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }


    function getCurrentStage() public view returns (Stages) {
        return stage;
    }
}


contract TokenPriceAndSupplyProvider is PhaseManager {

    uint256 _stage1Price;
    uint256 _stage2Price;
    uint256 _stage3Price;
    uint256 _stage4Price;

    constructor() {
        //0.001 ETH
        _stage1Price = 1000000000000000;
        //0.002 ETH
        _stage2Price = 2000000000000000;
        //0.003 ETH
        _stage3Price = 3000000000000000;
        //0.005 ETH
        _stage4Price = 5000000000000000;
    }

    function setPrices(uint256 stage1Price, uint256 stage2Price, uint256 stage3Price, uint256 stage4Price) public onlyOwner {
        require(stage1Price > 0);
        require(stage2Price > 0);
        require(stage3Price > 0);
        require(stage4Price > 0);
        _stage1Price = stage1Price;
        _stage2Price = stage2Price;
        _stage3Price = stage3Price;
        _stage4Price = stage4Price;
    }

    function getTotalSupplyForCurrentPeriod() internal view returns (uint256) {
        if (stage == Stages.Stage1)
        //            return 52500;
            return 10;
        if (stage == Stages.Stage2)
        //            return 85000;
            return 20;
        if (stage == Stages.Stage3)
        //            return 117500;
            return 30;
        if (stage == Stages.Stage4)
        //            return 150000;
            return 40;
        return 0;
    }

    function getTokenPriceForCurrentPeriod() internal view returns (uint256) {
        if (stage == Stages.Stage1)
            return _stage1Price;
        if (stage == Stages.Stage2)
            return _stage2Price;
        if (stage == Stages.Stage3)
            return _stage3Price;

        return _stage4Price;
    }
}

contract Mint is Ownable, Pausable, TokenPriceAndSupplyProvider {

    using SafeMath for uint256;

    uint private _maxTokensPerTransaction;
    address _paymentWallet;

    IERC20 private _wethContract;
    ILandsNftContract public _nftsContract;


    constructor(address wethContractAddress, address landTokenContractAddress, address paymentWallet_) {
        _wethContract = IERC20(wethContractAddress);
        _nftsContract = ILandsNftContract(landTokenContractAddress);
        _paymentWallet = paymentWallet_;
        _maxTokensPerTransaction = 3;
    }

    function setLimits(uint maxTokensPerTransaction_) public onlyOwner {
        require(maxTokensPerTransaction_ > 0, "maxTokensPerTransaction_ should be positive");
        _maxTokensPerTransaction = maxTokensPerTransaction_;
    }

    function buyToken(uint256 tokenId) public timedTransitions whenNotPaused {
        require(tokenId < super.getTotalSupplyForCurrentPeriod(),
            "Tokens number is outside of total number of tokens for this sale");
        require(!_nftsContract.tokenExists(tokenId), "This token already minted");
        require(_nftsContract.isTransferAllowed(msg.sender, 1), "Mint not allowed: exceeded max token number in target wallet");

        _wethContract.transferFrom(msg.sender, _paymentWallet, super.getTokenPriceForCurrentPeriod());
        _nftsContract.mintToken(msg.sender, tokenId);
    }


    function buyTokens(uint tokensNumber) public timedTransitions whenNotPaused {
        require(isPublicSale(), "Public sale is not started yet");
        require(tokensNumber <= _maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_nftsContract.totalSupply().add(tokensNumber) < super.getTotalSupplyForCurrentPeriod(),
            "Tokens number to mint exceeds total number of tokens for this sale");
        require(_nftsContract.isTransferAllowed(msg.sender, tokensNumber), "Mint not allowed: exceeded max token number in target wallet");

        _wethContract.transferFrom(msg.sender, _paymentWallet, super.getTokenPriceForCurrentPeriod().mul(tokensNumber));
        _nftsContract.mintTokens(msg.sender, tokensNumber);
    }


    function setNftsContract(address nftsContractAddress) public onlyOwner {
        require(nftsContractAddress != address(this), "wrong address");
        _nftsContract = ILandsNftContract(nftsContractAddress);
    }

    function setPaymentWallet(address paymentWallet_) public onlyOwner {
        require(_paymentWallet != address(this), "wrong address");
        _paymentWallet = paymentWallet_;
    }

    function setWethContract(address wethContract) public onlyOwner {
        require(wethContract != address(this), "wrong address");
        _wethContract = IERC20(wethContract);
    }
}