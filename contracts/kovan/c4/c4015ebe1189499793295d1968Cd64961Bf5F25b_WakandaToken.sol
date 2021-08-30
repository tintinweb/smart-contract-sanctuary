/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/WakandaToken.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";


contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
contract WakandaToken is IERC20, SafeMath {
    address owner;
    string symbol;
    string name;
    uint8 decimals;
    uint256 totalTokenSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => WakandaAddressStatus) wakandaAddressState;

    struct WakandaAddressStatus {
        bool registered;
        bool inactive;
    }

    constructor() {
        owner = msg.sender;
        symbol = "WKND";
        name = "WKND Token";
        decimals = 0;
        totalTokenSupply = 6000000;
        balances[owner] = totalTokenSupply;
        emit Transfer(address(0), owner, totalTokenSupply);
    }

    function totalSupply() public view override returns (uint256) {
        require(msg.sender == owner, "You don't have permission!");
        return totalTokenSupply;
    }

    function balanceOf(address _tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_tokenOwner];
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        wakandaAddressState[_to].registered = true;

        if (owner != msg.sender) {
            wakandaAddressState[msg.sender].inactive = true;
            approve(_to, 1);
            transferFrom(msg.sender, _to, _value);
        } else {
            balances[msg.sender] = sub(balances[msg.sender], _value);
            balances[_to] = add(balances[_to], _value);

            emit Transfer(msg.sender, _to, _value);
        }

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        balances[_from] = sub(balances[_from], _value);
        allowed[_from][_to] = sub(allowed[_from][_to], _value);
        balances[_to] = add(balances[_to], _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        require(
            _value == 1,
            "It is allowed only 1 WKND token to be spent in behalf of you!"
        );

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _tokenOwner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_tokenOwner][_spender];
    }

    function withdraw(address _from, uint256 _value)
        private
        returns (bool success)
    {
        balances[_from] = sub(balances[_from], _value);

        emit Transfer(_from, address(0), _value);

        return true;
    }

    function updateWakandaAddressState(address _wakanda, uint256 _amount)
        public
        returns (bool success)
    {
        if (balanceOf(_wakanda) == _amount) {
            wakandaAddressState[_wakanda].inactive = true;
        }
        withdraw(_wakanda, _amount);

        return true;
    }

    function isRegistered(address _wakanda) public view returns (bool success) {
        return wakandaAddressState[_wakanda].registered;
    }

    function isInactive(address _wakanda) public view returns (bool success) {
        return wakandaAddressState[_wakanda].inactive;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}