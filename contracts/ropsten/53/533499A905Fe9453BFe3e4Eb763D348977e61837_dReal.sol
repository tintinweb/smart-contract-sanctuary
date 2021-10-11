// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract dReal is Ownable {
    IERC20 token;
    
    event NewOffer(address indexed landlord, uint256 price, uint256 collateral, uint256 repetitions, uint256 id);
    event OfferAccepted(uint256 indexed id, address indexed tenant);
    event RentPaid(uint256 id);
    event CollateralClaimed(uint256 id);
    event PaymentClaimed(uint256 id, uint256 totalClaimed);
    
    struct Offer {
        bool valid;
        uint256 startDate;
        address tenant;
        address landlord;
        uint256 price;
        uint256 collateral;
        uint256 repetitions;
        string street;
        string description;
        bool accepted;
        uint256 timesPaid;
        bool collateralClaimed;
    }
    
    mapping(address => uint256[]) landlordOffers;
    mapping(address => uint256[]) tenantOffers;
    mapping(uint256 => Offer) public offers;
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function getTotalOffersByLandlord(address _landlord) public view returns(uint256) {
        return landlordOffers[_landlord].length;
    }
    
    function getTotalOffersByTenant(address _tenant) public view returns(uint256) {
        return tenantOffers[_tenant].length;
    }
    
    function getLandlordOfferByIndex(address _landlord, uint256 _position) public view returns(uint256) {
         return landlordOffers[_landlord][_position];
    }

    function getTenantOfferByIndex(address _tenant, uint256 _position) public view returns(uint256) {
         return tenantOffers[_tenant][_position];
    }
    
    function _TEST_updateStartDate(uint256 _id, uint256 _startDate) public onlyOwner {
        offers[_id].startDate = _startDate;
    }
    
    function createRent(uint256 _price, uint256 _collateral, uint256 _repetitions, string memory _street, string memory _description) public {
        uint256 id = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        require(!offers[id].valid, "The offer already exists");
        require(_price > 0, "Invalid price");
        require(_repetitions > 0, "Invalid repetitions");
        
        Offer memory o;
        o.valid = true;
        o.landlord = msg.sender;
        o.price = _price;
        o.collateral = _collateral;
        o.repetitions = _repetitions;
        o.street = _street;
        o.description = _description;
        
        offers[id] = o;
        landlordOffers[msg.sender].push(id);
        
        emit NewOffer(msg.sender, _price, _collateral, _repetitions, id);
    }

    function acceptRent(uint256 _id) public {
        require(offers[_id].valid, "Invalid offer");
        Offer storage offer = offers[_id];
        require(offer.landlord != msg.sender, "Landlord cannot accept self offer");
        require(!offer.accepted, "Already accepted");
        
        require(token.transferFrom(msg.sender, address(this), offer.collateral + offer.price), 'Could not transfer tokens');

        offer.accepted = true;
        offer.tenant = msg.sender;
        offer.startDate = block.timestamp;
        offer.timesPaid = 1;

        tenantOffers[msg.sender].push(_id);

        emit OfferAccepted(_id, msg.sender);
        emit RentPaid(_id);
    }
    
    function payRent(uint256 _id) public {
        require(offers[_id].valid, "Invalid offer");
        Offer storage offer = offers[_id];
        require(offer.tenant == msg.sender, "Invalid caller");
        require(offer.repetitions > offer.timesPaid, "Already paid it all");
        
        require(token.transferFrom(msg.sender, address(this), offer.price), 'Could not transfer tokens');

        offer.timesPaid += 1;
        
        emit RentPaid(_id);
    }
    
    function claimCollateral(uint256 _id) public {
        require(offers[_id].valid, "Invalid offer");
        Offer storage offer = offers[_id];
        require(offer.accepted, "Invalid offer");
        require(offer.tenant == msg.sender, "Invalid caller");
        require(offer.repetitions == offer.timesPaid, "Not yet totally paid");
        require(!offer.collateralClaimed, "Already claimed");
        
        offer.collateralClaimed = true;

        require(token.transfer(msg.sender, offer.collateral), 'Could not transfer tokens');
        
        emit CollateralClaimed(_id);
    }
    
    function calculatePaymentsToClaim(uint256 _startDate, uint256 _timesPaid, uint256 _repetitions) public view returns(uint256) {
        if (_timesPaid >= _repetitions) {
            return 0;
        }

        uint256 timePassed = block.timestamp - _startDate;
        uint256 monthsPassed = timePassed / 30 days;
        uint256 expectedTimesPaid = monthsPassed + 1;
        
        if (expectedTimesPaid > _repetitions) {
            expectedTimesPaid = _repetitions;
        }
        
        return expectedTimesPaid - _timesPaid;
    }
    
    function claimPayment(uint256 _id) public {
        require(offers[_id].valid, "Invalid offer");
        Offer storage offer = offers[_id];
        require(offer.accepted, "Invalid offer");
        require(offer.landlord == msg.sender, "Invalid caller");
        
        uint256 paymentsToClaim = calculatePaymentsToClaim(offer.startDate, offer.timesPaid, offer.repetitions);
        
        uint256 totalToClaim = paymentsToClaim * offer.price;
        
        if (totalToClaim > offer.collateral) {
            totalToClaim = offer.collateral;
        }
        
        require(totalToClaim > 0, "Not enough collateral");
        
        offer.collateral -= totalToClaim;
        offer.timesPaid += paymentsToClaim;
     
        require(token.transfer(msg.sender, totalToClaim), 'Could not transfer tokens');
        
        emit PaymentClaimed(_id, totalToClaim);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}