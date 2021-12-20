// contracts/AgriOps.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "IERC20.sol";

contract AgriOps is Ownable {
    uint256 public fee;
    bytes32 public keyhash;
    uint256 private order_counter = 778;
    uint256 private goods_counter = 777;

    struct Goods {
        address good_owner;
        uint256 id;
        string name;
        uint256 token_amount;
        string image_uri;
        string description;
        uint256 index_all_goods;
        uint256 index_farmer_goods;
    }

    struct Order {
        uint256 order_id;
        address seller_address;
        address buyer_address;
        string goods_ids;
        string quantities;
        uint256 total_bill;
        bool isDelivered;
    }

    Goods[] public all_goods;
    address[] public all_farmers;

    mapping(address => Goods[]) public farmer_to_goods;
    mapping(uint256 => Goods) public id_to_good;
    mapping(uint256 => Order) public id_to_order;
    //TODO: remove public and make a function that uses msg.sender
    mapping(address => uint256[]) public buyer_to_orders;
    mapping(address => uint256[]) public farmer_to_orders;
    mapping(address => uint256) public farmer_to_amount_payable;

    constructor(){}

    function addGoods(
        address _farmer_address,
        string memory _name,
        uint256 _token_amount,
        string memory _image_uri,
        string memory _description
    ) public {
        Goods memory new_good = Goods(
            _farmer_address,
            goods_counter,
            _name,
            _token_amount,
            _image_uri,
            _description,
            all_goods.length,
            farmer_to_goods[_farmer_address].length
        );
        id_to_good[goods_counter] = new_good;
        farmer_to_goods[new_good.good_owner].push(new_good);
        all_goods.push(new_good);
        goods_counter ++;
    }

    function getAllGoods() public view returns (Goods[] memory) {
        return all_goods;
    }

    function getGoodByFarmer(address _farmer_address)
        public
        view
        returns (Goods[] memory)
    {
        return farmer_to_goods[_farmer_address];
    }

    function deleteGood(
        address _farmer_address,
        uint256 index1,
        uint256 index2
    ) public onlyOwner {
        require(index1 < all_goods.length, "Index doesn't exists");
        require(
            index2 < farmer_to_goods[_farmer_address].length,
            "Index doesn't exists"
        );
        delete all_goods[index1];
        delete id_to_good[farmer_to_goods[_farmer_address][index2].id];
        delete farmer_to_goods[_farmer_address][index2];
    }

    function addFarmer(address _farmer_address) public onlyOwner{
        all_farmers.push(_farmer_address);
    }

    function getAllFarmers() public view returns(address[] memory){
        return all_farmers;
    }

    function placeOrder(
        address _farm_token,
        address _buyer_address,
        uint256[] memory _goods_ids,
        uint256[] memory _good_quantities,
        string memory _goods_ids_str,
        string memory _good_quantities_str
    ) public returns (uint256) {
        IERC20 farm_token = IERC20(_farm_token);

        uint256 _total_amount = 0;
        address _seller_address = id_to_good[_goods_ids[0]].good_owner;

        for (uint256 index = 0; index < _goods_ids.length; index++) {
            _total_amount += (id_to_good[_goods_ids[index]].token_amount * _good_quantities[index]);
        }

        require(
            farm_token.allowance(_buyer_address, address(this)) >=
                _total_amount,
            "Allowance is not enought"
        );

        require(
            farm_token.transferFrom(
                _buyer_address,
                address(this),
                _total_amount
            ),
            "Something went wrong!"
        );

        Order memory new_order = Order(
            order_counter,
            _seller_address,
            _buyer_address,
            _goods_ids_str,
            _good_quantities_str,
            _total_amount,
            false
        );

        id_to_order[order_counter] = new_order;
        buyer_to_orders[_buyer_address].push(order_counter);

        farmer_to_orders[_seller_address].push(order_counter);

        order_counter++;
    }

    function getLatestOrder(address _user_address) view public returns(uint256){
        uint256[] memory all_orders = buyer_to_orders[_user_address];
        return all_orders[all_orders.length - 1];
    }

    function idDelivered(uint256 _order_id) public onlyOwner {
        id_to_order[_order_id].isDelivered = true;
        farmer_to_amount_payable[id_to_order[_order_id].seller_address] += id_to_order[_order_id].total_bill;
    }

    function farmerWithdraw(address _farm_token, address farmer_address)
        public
        onlyOwner
    {
        IERC20 farm_token = IERC20(_farm_token);
        require(
            farm_token.transfer(
                farmer_address,
                farmer_to_amount_payable[farmer_address]
            ),
            "Failed to transfer"
        );
        farmer_to_amount_payable[farmer_address] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT

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