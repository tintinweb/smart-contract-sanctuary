/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract contractwallet {
    using SafeERC20 for IERC20;

    /// @notice EIP-20 token name for this token
    string public constant name = "Ahdai";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "Ahdai";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 8;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address public owner;
    address public pendingOwner;
    mapping(address => bool) public members;

    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;

    function mint(address account, uint amount) public {
        require(members[msg.sender], "!member");
        _mint(account, amount);
    }
    
    function burn(address account, uint amount) public {
        require(members[msg.sender], "!member");
        _burn(account, amount);
    }
    
    function setOwner(address _owner) public {
        require(msg.sender == owner, "!owner");
        pendingOwner = _owner;
    }
    
    function acceptOwner() public {
        require(msg.sender == pendingOwner, "!pendingOwner");
        owner = pendingOwner;
    }
    
    function addmember(address _member) public {
        require(msg.sender == owner, "!owner");
        members[_member] = true;
    }
    
    function removemember(address _member) public {
        require(msg.sender == owner, "!owner");
        members[_member] = false;
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    constructor () {
        owner = msg.sender;
    }

    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    
    function swapUsdcAll() external {
        _swapUsdc(USDC.balanceOf(msg.sender));
    }
    
    function swapUsdc(uint amount) external {
        _swapUsdc(amount);
    }
    
    function _swapUsdc(uint amount) internal {
        USDC.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * 10);
    }

    function withdrawToken(address tokenContract, uint amount) external {
        require(members[msg.sender], "!member");
        IERC20 token = IERC20(tokenContract);
        _withdraw(token, amount);
    }

    function withdrawEther(uint amount) external {
        require(members[msg.sender], "!member");
        address addr = msg.sender;
        address payable wallet = payable(addr);
        wallet.transfer(amount);
    }
    
    function withdrawEtherAll() external {
        require(members[msg.sender], "!member");
        address addr = msg.sender;
        address payable wallet = payable(addr);
        wallet.transfer(address(this).balance);
    }

    function _withdraw(IERC20 token, uint amount) internal {
        token.safeTransfer(msg.sender, amount);
        //emit Transfer(address(this), msg.sender, amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }

    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}