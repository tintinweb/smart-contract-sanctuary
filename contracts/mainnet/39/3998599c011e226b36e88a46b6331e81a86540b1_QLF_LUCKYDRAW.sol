/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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


abstract contract IQLF is IERC165 {
    /**
     * @dev Returns if the given address is qualified, implemented on demand.
     */
    function ifQualified (address account) virtual external view returns (bool);

    /**
     * @dev Logs if the given address is qualified, implemented on demand.
     */
    function logQualified (address account, uint256 ito_start_time) virtual external returns (bool);

    /**
     * @dev Ensure that custom contract implements `ifQualified` amd `logQualified` correctly.
     */
    function supportsInterface(bytes4 interfaceId) virtual external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector);
    }

    /**
     * @dev Emit when `ifQualified` is called to decide if the given `address`
     * is `qualified` according to the preset rule by the contract creator and 
     * the current block `number` and the current block `timestamp`.
     */
    event Qualification(address account, bool qualified, uint256 blockNumber, uint256 timestamp);
}

contract QLF_LUCKYDRAW is IQLF {

    string private name;
    uint256 private creation_time;
    uint256 start_time;
    // in wei
    uint256 public max_gas_price;
    uint256 public min_token_amount;
    address public token_addr;
    // Chance to be selected as a lucky player
    // 0 : 100%
    // 1 : 75%
    // 2 : 50%
    // 3 : 25%
    uint8 public lucky_factor;
    address creator;
    mapping(address => bool) black_list;
    mapping(address => bool) whilte_list;

    event GasPriceOver ();
    event Unlucky ();

    modifier creatorOnly {
        require(msg.sender == creator, "Not Authorized");
        _;
    }

    constructor (string memory _name,
                uint256 _start_time,
                uint256 _max_gas_price,
                uint256 _min_token_amount,
                address _token_addr,
                uint8 _lucky_factor) {
        name = _name;
        creation_time = block.timestamp;
        start_time = _start_time;
        max_gas_price = _max_gas_price;
        min_token_amount = _min_token_amount;
        token_addr = _token_addr;
        lucky_factor = _lucky_factor;
        creator = msg.sender;
    }

    function get_name() public view returns (string memory) {
        return name;
    }

    function get_creation_time() public view returns (uint256) {
        return creation_time;
    }

    function get_start_time() public view returns (uint256) {
        return start_time;
    }

    function set_start_time(uint256 _start_time) public creatorOnly {
        start_time = _start_time;
    }

    function set_max_gas_price(uint256 _max_gas_price) public creatorOnly {
        max_gas_price = _max_gas_price;
    }

    function set_min_token_amount(uint256 _min_token_amount) public creatorOnly {
        min_token_amount = _min_token_amount;
    }

    function set_lucky_factor(uint8 _lucky_factor) public creatorOnly {
        lucky_factor = _lucky_factor;
    }

    function set_token_addr(address _token_addr) public creatorOnly {
        token_addr = _token_addr;
    }

    function add_whitelist(address[] memory addrs) public creatorOnly {
        for (uint256 i = 0; i < addrs.length; i++) {
            whilte_list[addrs[i]] = true;
        }
    }

    function remove_whitelist(address[] memory addrs) public creatorOnly {
        for (uint256 i = 0; i < addrs.length; i++) {
            delete whilte_list[addrs[i]];
        }
    }

    function ifQualified(address account) public view override returns (bool qualified) {
        qualified = (whilte_list[account] || IERC20(token_addr).balanceOf(account) >= min_token_amount);
    } 

    function logQualified(address account, uint256 ito_start_time) public override returns (bool qualified) {
        if (tx.gasprice > max_gas_price) {
            emit GasPriceOver();
            revert("Gas price too high");
        }
        if (!whilte_list[account])
            require(IERC20(token_addr).balanceOf(account) >= min_token_amount, "Not holding enough tokens");

        if (start_time > block.timestamp || ito_start_time > block.timestamp) {
            black_list[account] = true;
            revert("Not started.");
        }
        require(black_list[account] == false, "Blacklisted");
        if (isLucky(account) == false) {
            emit Unlucky();
            emit Qualification(account, false, block.number, block.timestamp);
            revert("Not lucky enough");
        }
        emit Qualification(account, true, block.number, block.timestamp);
        qualified = true;
    } 

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector) ||
            interfaceId == this.get_start_time.selector ||
            interfaceId == this.isLucky.selector;
    }

    function isLucky(address account) public view returns (bool) {
        if (lucky_factor == 0) {
            return true;
        }
        uint256 blocknumber = block.number;
        uint256 random_block = blocknumber - 1 - uint256(
            keccak256(abi.encodePacked(blockhash(blocknumber-1), account))
        ) % 255;
        bytes32 sha = keccak256(abi.encodePacked(blockhash(random_block), account, block.coinbase, block.difficulty));
        return ((uint8(sha[0]) & 0x03) >= lucky_factor);
    }
}