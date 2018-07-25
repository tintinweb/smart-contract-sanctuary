pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title TokenVesting
 * @dev Modifier by Rolong <rolong at vip.qq.com>
 */
contract TokenVesting {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Released(uint256 amount);

    // beneficiary of tokens after they are released
    address public constant beneficiary1 = 0xD2A0cADD34De9E514D5c87C3c1BfC30bC7a05bF9;
    address public constant beneficiary2 = 0xbAf2A44d11Ded7d0ba1D03a3baE3b36E6125Ac24;

    uint256 public constant start = 1548086400; // 2019/1/22 0:0:0
    uint256 public constant duration = 15638400; // duration = 1563724800(2019/7/22) - 1548086400(2018/1/22)
    uint256 public constant month = 2606400; // month = duration / 6
    
    // YCCC
    ERC20Basic token = ERC20Basic(0xc9ca0a382ae69dba0c8ff2c00c1662529ddee430);

    uint256 public released;

    function TokenVesting() public
    {
    }

    function() payable public {
        if (msg.value > 0) { revert();  }

        uint256 unreleased = releasableAmount();

        require(unreleased > 0);

        uint256 unreleasedHalf = unreleased.div(2);

        released = released.add(unreleasedHalf.mul(2));

        token.safeTransfer(beneficiary1, unreleasedHalf);
        token.safeTransfer(beneficiary2, unreleasedHalf);

        emit Released(unreleasedHalf.mul(2));
    }

    function releasableAmount() public view returns (uint256) {
        uint256 amount = vestedAmount().sub(released);
        uint256 currentBalance = token.balanceOf(this);
        if (amount > currentBalance) {
            return currentBalance;
        }
        return amount;
    }

    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            uint256 timeGap = block.timestamp.sub(start);
            if (timeGap < month) {
                return 0;
            } else {
                uint256 sec = timeGap.div(month).mul(month);
                return totalBalance.mul(sec).div(duration);
            }
        }
    }
}