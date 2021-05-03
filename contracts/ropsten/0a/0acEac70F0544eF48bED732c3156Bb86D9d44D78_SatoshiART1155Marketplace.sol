/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISatoshiART1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function getCreator(uint256 _id) external view returns (address);
}

contract SatoshiART1155Marketplace is Ownable {
    using SafeMath for uint256;

    struct Listing {
        bytes1 status; // 0x00 onHold 0x01 onSale 0x02 isDropOfTheDay 0x03 isAuction
        uint256 price;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => Listing)) private _listings;
    ISatoshiART1155 public satoshiART1155;
    mapping(address => uint256) _outstandingPayment;
    mapping(address => uint256) _outstandingRoyalty;
    uint256 _outstandingCommission;

    event PurchaseConfirmed();
    event PaymentWithdrawed();

    constructor(address satoshiART1155Address) {
        satoshiART1155 = ISatoshiART1155(satoshiART1155Address);
    }

    function putOnSale(
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        require(
            satoshiART1155.balanceOf(msg.sender, tokenId) >= amount,
            "You are trying to sell more than you have"
        );

        _listings[tokenId][msg.sender] = Listing({
            status: 0x01,
            price: price,
            amount: amount
        });
    }

    // Todo: remove from sale

    function listingOf(address account, uint256 id)
        external
        view
        returns (
            bytes1,
            uint256,
            uint256
        )
    {
        require(
            account != address(0),
            "ERC1155: listing query for the zero address"
        );
        return (
            _listings[id][account].status,
            _listings[id][account].price,
            _listings[id][account].amount
        );
    }

    function setCommission(uint256 netPrice, uint256 commissionPercent)
        internal
        pure
        returns (uint256)
    {
        uint256 _commission = netPrice.mul(commissionPercent).div(10000);
        return _commission;
    }

    function setRoyalty(uint256 netPrice) internal pure returns (uint256) {
        uint256 _royaltyPercent = 1000; // 10% royalty set
        uint256 _royalty = netPrice.mul(_royaltyPercent).div(10000);
        return _royalty;
    }

    function buy(
        uint256 tokenId,
        uint256 amount,
        address itemOwner
    ) external payable returns (bool) {
        require(msg.sender != address(0));
        require(
            _listings[tokenId][itemOwner].status == 0x01,
            "buy: trying to buy not listed item"
        );
        require(
            _listings[tokenId][itemOwner].amount >= amount,
            "buy: trying to buy more than listed"
        );
        require(
            satoshiART1155.balanceOf(itemOwner, tokenId) >= amount,
            "buy: trying to buy more than owned"
        );
        require(
            msg.value >= _listings[tokenId][itemOwner].price.mul(amount),
            "buy: not enough fund"
        );

        _listings[tokenId][itemOwner].amount = _listings[tokenId][itemOwner]
            .amount
            .sub(amount);

        satoshiART1155.safeTransferFrom(
            itemOwner,
            msg.sender,
            tokenId,
            amount,
            ""
        );

        uint256 _commision = setCommission(msg.value, 250);
        _outstandingCommission = _outstandingCommission.add(
            setCommission(msg.value, 250)
        );

        if (itemOwner == satoshiART1155.getCreator(tokenId)) {
            _outstandingPayment[itemOwner] = _outstandingPayment[itemOwner].add(
                msg.value.sub(_commision)
            );
        } else {
            uint256 _royalty = setRoyalty(msg.value);
            _outstandingRoyalty[itemOwner] = _outstandingRoyalty[itemOwner].add(
                _royalty
            );
            _outstandingPayment[itemOwner] = _outstandingPayment[itemOwner].add(
                msg.value.sub(_commision).sub(_royalty)
            );
        }

        emit PurchaseConfirmed();
        return true;
    }

    // allow owner to withdraw the owned eth
    function paymentWithdraw() external payable returns (bool) {
        uint256 amount = _outstandingPayment[msg.sender];
        require(msg.sender != address(0));
        if (amount > 0) {
            _outstandingPayment[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingPayment[msg.sender] = amount;
                return false;
            }
        }
        // emit PaymentWithdrawed; ?  --- where to put this line if necessary
        return true;
    }

    function commisionWithdraw() external payable onlyOwner returns (bool) {
        uint256 amount = _outstandingCommission;
        if (amount > 0) {
            _outstandingCommission = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingCommission = amount;
                return false;
            }
        }
        return true;
    }

    function royaltyWithdraw(address creator)
        external
        payable
        onlyOwner
        returns (bool)
    {
        uint256 amount = _outstandingRoyalty[creator];
        if (amount > 0) {
            _outstandingRoyalty[creator] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingRoyalty[creator] = amount;
                return false;
            }
        }
        return true;
    }

    function getOutstandingPayment(address user)
        external
        view
        returns (uint256)
    {
        return _outstandingPayment[user];
    }

    function getOutstandingCommision() external view returns (uint256) {
        return _outstandingCommission;
    }

    function getOutstandingRoyalty(address user)
        external
        view
        returns (uint256)
    {
        return _outstandingRoyalty[user];
    }
}

// to do:
// 1. beneficiary(owner) withdraw payment
// 2. withdraw commision (selected address)