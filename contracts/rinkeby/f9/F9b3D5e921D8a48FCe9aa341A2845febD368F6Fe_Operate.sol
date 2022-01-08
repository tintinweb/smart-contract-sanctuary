// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "IERC20.sol";

contract Operate is Ownable {
    uint256 private goods_counter = 777;
    uint256 private donation_counter = 123;
    uint256 public available_coins = 0;
    address private contract_owner;

    Goods[] public all_goods;
    Donations[] public all_donations;

    mapping(uint256 => Goods) public id_to_good;
    mapping(uint256 => address[]) public goods_to_farmers;
    mapping(uint256 => uint256) public goods_to_availability;
    mapping(address => Goods[]) public farmer_to_allocations;
    mapping(address => mapping(uint256 => uint256)) public farmer_to_allocations_quantities;
    mapping(uint256 => uint256[2]) public good_last_farmer_index;
    mapping(uint256 => Donations) public id_to_donations;
    mapping(address => Donations[]) public donors_to_donations;
    mapping(address => uint256) public donors_to_total_amount_donated;
    mapping(uint256 => uint256) public goods_to_waiting;

    struct Goods {
        uint256 id;
        string name;
        uint256 token_amount;
        string image_uri;
        string description;
    }

    struct Donations {
        uint256 id;
        address donor_address;
        string item_ids;
        string item_qtys;
        uint256 total_amount;
    }

    constructor(){
        contract_owner = msg.sender;
    }

    function addGoods(
        string memory _name,
        uint256 _token_amount,
        string memory _image_uri,
        string memory _description
    ) public {
        Goods memory new_good = Goods(
            goods_counter,
            _name,
            _token_amount,
            _image_uri,
            _description
        );
        id_to_good[goods_counter] = new_good;
        all_goods.push(new_good);
        goods_counter++;
    }

    function requestDonation(address farmer_address, uint256[] memory good_ids)
        public
    {
        for (uint256 index = 0; index < good_ids.length; index++) {
            if(goods_to_availability[good_ids[index]] > 0 && goods_to_waiting[good_ids[index]]==0){
                farmer_to_allocations[farmer_address].push(id_to_good[good_ids[index]]);
                farmer_to_allocations_quantities[farmer_address][good_ids[index]]++;
                goods_to_availability[good_ids[index]]--;
            }
            else{
                goods_to_farmers[good_ids[index]].push(farmer_address);
                goods_to_waiting[good_ids[index]]++;
            }
        }
    }

    function placeDonation(address payment_token, address donor_address, uint256[] memory _goods_ids, uint256[] memory _good_quantities, string memory _str_goods_ids, string memory _str_good_quantities)
        public
    {
        IERC20 paymentToken = IERC20(payment_token);
        uint256 _total_amount = 0;

        for (uint256 index = 0; index < _goods_ids.length; index++) {
            _total_amount += (id_to_good[_goods_ids[index]].token_amount * _good_quantities[index]);
        }

        require(
            paymentToken.allowance(donor_address, address(this)) >=
                _total_amount,
            "Allowance is not enought"
        );

        donateCoins(payment_token, donor_address, _total_amount, 1);

        for (uint256 good_index = 0; good_index < _goods_ids.length; good_index++) {
            goods_to_availability[_goods_ids[good_index]] += _good_quantities[good_index];
        }

        Donations memory new_donation = Donations(
            donation_counter,
            donor_address,
            _str_goods_ids,
            _str_good_quantities,
            _total_amount
        );

        id_to_donations[donation_counter] = new_donation;
        all_donations.push(new_donation);
        donors_to_donations[donor_address].push(new_donation);

        donors_to_total_amount_donated[donor_address] += _total_amount;

        donation_counter++;

    }

    // Function to distribute the goods based on user donations
    function distributeDonation(uint256[] memory available_goods) public onlyOwner {
        for (uint256 good_index = 0; good_index < available_goods.length; good_index++) {

            uint256 curr_good_id = available_goods[good_index];
            uint256 available_good_quantity = goods_to_availability[curr_good_id];

            // When there is no requests
            if (goods_to_farmers[curr_good_id].length == 0) {
                continue;
            }
            // When the available good quantity is more than requested
            else if (available_good_quantity >= goods_to_farmers[curr_good_id].length) {
                for (uint256 farmer_index = 0; farmer_index < goods_to_farmers[curr_good_id].length; farmer_index++) {
                    farmer_to_allocations[goods_to_farmers[curr_good_id][farmer_index]].push(id_to_good[curr_good_id]);
                    farmer_to_allocations_quantities[goods_to_farmers[curr_good_id][farmer_index]][curr_good_id]++;
                    available_good_quantity--;
                }
                delete goods_to_farmers[curr_good_id];
                good_last_farmer_index[curr_good_id][0] = 0;
                good_last_farmer_index[curr_good_id][1] = 0;
            } else {
                uint256 cuur_farmer_index = good_last_farmer_index[curr_good_id][0];
                uint256 reverse = 0;

                // If we are ahead of last index and there are still elements left we reverse
                if (cuur_farmer_index > goods_to_farmers[curr_good_id].length - 1 && goods_to_farmers[curr_good_id].length > 0) {
                    reverse = 1;
                    cuur_farmer_index = goods_to_farmers[curr_good_id].length - 1;
                    good_last_farmer_index[curr_good_id][1] = 1;
                }

                if (reverse != 1 && good_last_farmer_index[curr_good_id][1] == 1) {
                    reverse = 1;
                }

                while (available_good_quantity != 0) {
                    farmer_to_allocations[goods_to_farmers[curr_good_id][cuur_farmer_index]].push(id_to_good[curr_good_id]);

                    farmer_to_allocations_quantities[goods_to_farmers[curr_good_id][cuur_farmer_index]][curr_good_id]++;

                    // Swap the allocated farmer with last member
                    goods_to_farmers[curr_good_id][cuur_farmer_index] = goods_to_farmers[curr_good_id][goods_to_farmers[curr_good_id].length - 1];

                    // Delete the last member
                    goods_to_farmers[curr_good_id].pop();

                    available_good_quantity--;
                    goods_to_waiting[curr_good_id]--;

                    if (reverse == 0) {
                        cuur_farmer_index++;
                    } else {
                        cuur_farmer_index--;
                    }

                    // If we are ahead of last index and there are still elements left we reverse
                    if (reverse != 1 && cuur_farmer_index > goods_to_farmers[curr_good_id].length - 1 && goods_to_farmers[curr_good_id].length > 0) {
                        reverse = 1;
                        cuur_farmer_index--;
                        good_last_farmer_index[curr_good_id][1] = 1;
                    }
                }
                good_last_farmer_index[curr_good_id][0] = cuur_farmer_index;
            }

            goods_to_availability[curr_good_id] = available_good_quantity;
        }

    }


    function increaseGoodQuantity(
        uint256[] memory good_ids,
        uint256[] memory good_qts,
        uint256 new_amount_available
    ) public onlyOwner{
        for (uint256 index = 0; index < good_ids.length; index++) {
            goods_to_availability[good_ids[index]] += good_qts[index];
        }
        available_coins = new_amount_available;
    }


    function getAllGoods() public view returns(Goods[] memory){
        return all_goods;
    }


    function getAllDonations() public view returns(Donations[] memory){
        return all_donations;
    }

    function getFarmerAllocations(address _farmer_address) public view returns(Goods[] memory){
        return farmer_to_allocations[_farmer_address];
    }

    function get_donor_donations(address _donor_address) public view returns(Donations[] memory){
        return donors_to_donations[_donor_address];
    }


    function donateCoins(address payment_token, address donor_address, uint256 amount_of_tokens, uint256 is_internal) public{
        IERC20 paymentToken = IERC20(payment_token);
        require(
            paymentToken.transferFrom(
                msg.sender,
                contract_owner,
                amount_of_tokens
            ),
            "transfer Failed"
        );

        if(is_internal != 1){
            donors_to_total_amount_donated[donor_address] += amount_of_tokens;
            available_coins += amount_of_tokens;
            Donations memory new_donation = Donations(
                donation_counter,
                donor_address,
                "-",
                "-",
                amount_of_tokens
            );
            donors_to_donations[donor_address].push(new_donation);
        }
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