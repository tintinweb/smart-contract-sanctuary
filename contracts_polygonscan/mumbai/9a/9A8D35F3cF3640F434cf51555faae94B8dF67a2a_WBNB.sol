/**
 *Submitted for verification at polygonscan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title Interface of a wrapped BNB token
 * @dev This interface describes a wrapping ERC20 token for native BNB currency
 */
interface IWBNB {
    /**
     * @dev Deposits native currency by sending it with the function call and creates
     * an equivalent amount of ERC20 token known as wrapping. The equivalent amount of
     * wrapped tokens is added to the senders account.
     */
    function deposit() external payable;

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Withraws the native currency for the given amount of wrapped token hold
     * by the function caller. The equivalent amount of native currency is sent to
     * the function caller.
     */
    function withdraw(uint256) external;
}


pragma solidity 0.6.12;


contract WBNB is IWBNB {
    string public constant name = "Wrapped BNB";
    string public constant symbol = "WBNB";
    uint8 public constant decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function deposit() public payable override {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external override {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) external returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad)
        external
        override
        returns (bool)
    {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}