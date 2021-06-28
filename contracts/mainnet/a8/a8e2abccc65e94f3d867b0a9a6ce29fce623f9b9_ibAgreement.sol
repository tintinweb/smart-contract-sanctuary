/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SafeERC20 {

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface cyToken {
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function underlying() external view returns (address);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

contract ibAgreement {
    using SafeERC20 for IERC20;
    
    address public immutable executor;
    address public immutable borrower;
    cyToken public immutable cy;
    IERC20 public immutable underlying;
    
    constructor(address _executor, address _borrower, address _cy) {
        executor = _executor;
        borrower = _borrower;
        cy = cyToken(_cy);
        underlying = IERC20(cyToken(_cy).underlying());
    }
    
    function debt() external view returns (uint borrowBalance) {
        (,,borrowBalance,) = cy.getAccountSnapshot(address(this));
    }
    
    function seize(IERC20 token, uint amount) external {
        require(msg.sender == executor);
        token.safeTransfer(executor, amount);
    }
    
    function borrow(uint _amount) external {
        require(msg.sender == borrower);
        require(cy.borrow(_amount) == 0, 'borrow failed');
        underlying.safeTransfer(borrower, _amount);
    }
    
    function repay() external {
        uint _balance = underlying.balanceOf(address(this));
        underlying.safeApprove(address(cy), _balance);
        cy.repayBorrow(_balance);
    }
}