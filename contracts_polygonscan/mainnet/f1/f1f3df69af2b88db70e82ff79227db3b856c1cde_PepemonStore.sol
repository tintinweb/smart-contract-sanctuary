/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

interface ERC1155Tradable{
    function getMaxSupplyBoosterpack(uint256 _id) external view returns (uint256);
    function getCurrentSupplyBoosterpack(uint _id) external view returns (uint);
    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external;
        function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
contract PepemonStore is Ownable {

    ERC1155Tradable public PepemonFactory;
    IERC20 private PepedexToken;
    address public fundAddress;
    uint256 public totalPPDEXSpend;

    mapping(uint256 => uint256) public cardCosts;

    event CardAdded(uint256 card, uint256 points);
    event Redeemed(address indexed user, uint256 amount);

    constructor() {
        PepemonFactory = ERC1155Tradable(0xd92AA4c68ad3F11490CcF4E7F813084A530cB171);
        PepedexToken = IERC20(0x127984b5E6d5c59f81DACc9F1C8b3Bdc8494572e);
        fundAddress = address(0xE71FbB197BC8fD11090FA657C100d52Dbb407662);
        totalPPDEXSpend = 0;
    }

    function setFundAddress(address _fundAddress) public onlyOwner {
        fundAddress = _fundAddress;
    }

    function addCard(uint256 cardId, uint256 amount) public onlyOwner {
        cardCosts[cardId] = amount;
        emit CardAdded(cardId, amount);
    }

    function redeem(uint256 card) public {
        require(cardCosts[card] != 0, "Card not found");
        require(PepedexToken.balanceOf(msg.sender) >= cardCosts[card], "Not enough points to redeem for card");
        require(PepemonFactory.getCurrentSupplyBoosterpack(card) < PepemonFactory.getMaxSupplyBoosterpack(card), "Max cards minted");

        PepedexToken.transferFrom(msg.sender, address(0xdead), cardCosts[card]*(9) / (10));
        PepedexToken.transferFrom(msg.sender, fundAddress, cardCosts[card] / (10));
        totalPPDEXSpend += (cardCosts[card]);

        PepemonFactory.mint(msg.sender, card, 1, "");
        emit Redeemed(msg.sender, cardCosts[card]);
    }
}