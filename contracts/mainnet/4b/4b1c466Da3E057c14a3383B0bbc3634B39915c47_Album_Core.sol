/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


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


contract Album_Core {
  string public artist;
  string public uri;
  address public owner_address;
  uint16 public release_count;
  uint16 public product_count;

  constructor(string memory _artist, string memory _uri) {
    owner_address = msg.sender;
    artist = _artist;
    uri = _uri;
  }

  event Release_Created(uint16 indexed release_id, uint8 indexed release_type, string name, string root_uri);
  event Release_Limited(uint16 indexed release_id);
  event Product_Created(uint16 indexed product_id, string name, string metadata_uri);
  event Transfer(address indexed from, address indexed to, uint16[] indicies, uint32[] counts);
  event Product_Listed(uint16 indexed product_id, address indexed currency, uint256 price);
  event Product_Delisted(uint16 indexed product_id);
  event Product_Purchased(uint16 indexed product_id, address indexed buyer);
  event Approval(address indexed owner, address indexed target, bool approved);

  struct release {
      uint32 total_created;
      bool limited;
      uint8 release_type;
  }

  struct product {
    uint16[] indicies;
    uint32[] counts;
    uint16 available_for_sale;
    bool listed;
    address currency;
    uint256 price;
    address profit_owner;
  }

  mapping(uint16 => release) public releases;
  mapping(address=>mapping(address => bool)) public approvals;
  mapping(uint16 => product) public products;
  mapping(address => mapping(uint16 => uint32)) public balances;

  function get_product_release_indicies(uint16 product_id) public view returns(uint16[] memory){
    return products[product_id].indicies;
  }
  function get_product_release_counts(uint16 product_id) public view returns(uint32[] memory){
    return products[product_id].counts;
  }

  function create_release(string calldata name, string calldata root_uri, uint8 release_type) public only_owner {
    require(release_count + 1 > release_count, "no more releases allowed, launch new contract");
    releases[release_count] = release(0, false, release_type);
    emit Release_Created(release_count, release_type, name, root_uri);
    release_count++;
  }

  function create_product(string calldata name, string calldata metadata_uri, uint16[] memory indicies, uint32[] memory counts, uint16 max_copies, address profit_owner) public only_owner {
    require(product_count + 1 > product_count, "no more products allowed, launch new contract");
    require(indicies.length == counts.length, "array mismatch");

    //up to 255 item types in 1 product
    for(uint8 item_idx = 0; item_idx < counts.length; item_idx++ ){
      require(indicies[item_idx] < release_count, "cannot include unreleased items");
      require(!releases[indicies[item_idx]].limited, "cannot include limited release");
      require(releases[indicies[item_idx]].total_created + counts[item_idx] > releases[indicies[item_idx]].total_created, "too many of specific release");
      releases[indicies[item_idx]].total_created = releases[indicies[item_idx]].total_created + (counts[item_idx] * max_copies);

    }
    products[product_count] = product(indicies, counts, max_copies, false, address(0), 0, profit_owner );
    emit Product_Created(product_count, name, metadata_uri);
    product_count++;
  }
  function limit_release(uint16 release_id) public only_owner{
    require(release_id < release_count);
    releases[release_id].limited = true;
    emit Release_Limited(release_id);
  }
  function list_product(uint16 product_id, address currency, uint256 price) public only_owner {
    products[product_id].listed = true;
    products[product_id].currency = currency;
    products[product_id].price = price;
    emit Product_Listed(product_id, currency, price);
  }

  function delist_product(uint16 product_id) public only_owner {
    products[product_id].listed = false;
    emit Product_Delisted(product_id);
  }

  function change_uri(string memory new_uri) public only_owner {
    uri = new_uri;
  }
  function change_owner(address new_address) public only_owner {
    owner_address = new_address;
  }

  function buy_product(uint16 product_id, address currency, uint256 price) public {
    require(products[product_id].listed);
    require(products[product_id].available_for_sale > 0);
    require(products[product_id].currency == currency);
    require(products[product_id].price == price);
    require(IERC20(currency).transferFrom(msg.sender, products[product_id].profit_owner, price));
    for(uint8 item_idx = 0; item_idx < products[product_id].counts.length; item_idx++ ){
        balances[msg.sender][products[product_id].indicies[item_idx]] += products[product_id].counts[item_idx];
    }
    products[product_id].available_for_sale--;
    emit Product_Purchased(product_id, msg.sender);
    //this is when it's actually popped into being
    emit Transfer(address(0), msg.sender, products[product_id].indicies, products[product_id].counts);
  }

  function set_approve_all(address target, bool approve) public {
    approvals[msg.sender][target] = approve;
    emit Approval(msg.sender, target, approve);
  }

  function transfer_from(uint16[] memory indicies, uint32[] memory counts, address from, address target) public {
    require(indicies.length == counts.length, "array mismatch");
    require(approvals[msg.sender][from] || msg.sender == from, "not approved");
    for(uint8 item_idx = 0; item_idx < counts.length; item_idx++ ){
        require(balances[from][indicies[item_idx]] - counts[item_idx] < balances[from][indicies[item_idx]]);
        balances[from][indicies[item_idx]] -= counts[item_idx];
        balances[target][indicies[item_idx]] += counts[item_idx];
    }
    emit Transfer(from, target, indicies, counts);
  }

  modifier only_owner {
     require(msg.sender == owner_address, "only owner");
     _;
  }
}