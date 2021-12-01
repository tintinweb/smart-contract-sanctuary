/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

//
interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}

//
interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface dRewards {
    function userInfo(uint256,address) external view returns(UserInfo calldata);
    // function stake(address _pair, uint256 _amount) external;
    // function unstake(address _pair, uint256 _amount) external;
    // function pendingToken(address _pair, address _user) external returns (uint256);
    
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}

struct UserInfo {                                                                
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of CAKEs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
}

interface WBNBContract{
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract Zap{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant marsRouter = 0xb68825C810E67D4e444ad5B9DeB55BA56A66e72D;
    address public constant pancakerouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant pancake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant aperouter = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;

    address public governance;

    mapping(address => bool) public farmers;

    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        require(_governance != address(0), "address error");
        governance = _governance;
    }
    
    
    function ZapInPancake(address _token1, address _token2, address _lptoken) payable public {
        
        _wrapBNB();
        uint half = IERC20(wbnb).balanceOf(address(this)).div(2);

        //50% Restake
        convertPancake(half, wbnb ,_token1);
        convertPancake(half, wbnb ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(pancakerouter, 0);
                IERC20(_token1).safeApprove(pancakerouter, uint256(-1));
                IERC20(_token2).safeApprove(pancakerouter, 0);
                IERC20(_token2).safeApprove(pancakerouter, uint256(-1));
                Uni(pancakerouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapInMars(address _token1, address _token2, address _lptoken) payable public {
        
        _wrapBNB();
        uint half = IERC20(wbnb).balanceOf(address(this)).div(2);

        //50% Restake
        convertMars(half, wbnb ,_token1);
        convertMars(half, wbnb ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(marsRouter, 0);
                IERC20(_token1).safeApprove(marsRouter, uint256(-1));
                IERC20(_token2).safeApprove(marsRouter, 0);
                IERC20(_token2).safeApprove(marsRouter, uint256(-1));
                Uni(marsRouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapInApe(address _token1, address _token2, address _lptoken) payable public {
        
        _wrapBNB();
        uint half = IERC20(wbnb).balanceOf(address(this)).div(2);

        //50% Restake
        convertApe(half, wbnb ,_token1);
        convertApe(half, wbnb ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(aperouter, 0);
                IERC20(_token1).safeApprove(aperouter, uint256(-1));
                IERC20(_token2).safeApprove(aperouter, 0);
                IERC20(_token2).safeApprove(aperouter, uint256(-1));
                Uni(aperouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapInTokenPancake(address _tokenin, uint _amount, address _token1, address _token2, address _lptoken) public {
        
        IERC20(_tokenin).transfer(address(this), _amount);
        uint half = IERC20(_tokenin).balanceOf(address(this)).div(2);

        //50% Restake
        convertPancake(half, _tokenin ,_token1);
        convertPancake(half, _tokenin ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(pancakerouter, 0);
                IERC20(_token1).safeApprove(pancakerouter, uint256(-1));
                IERC20(_token2).safeApprove(pancakerouter, 0);
                IERC20(_token2).safeApprove(pancakerouter, uint256(-1));
                Uni(pancakerouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapInTokenMars(address _tokenin, uint _amount, address _token1, address _token2, address _lptoken) public {
        
        IERC20(_tokenin).transfer(address(this), _amount);
        uint half = IERC20(_tokenin).balanceOf(address(this)).div(2);

        //50% Restake
        convertMars(half, _tokenin ,_token1);
        convertMars(half, _tokenin ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(marsRouter, 0);
                IERC20(_token1).safeApprove(marsRouter, uint256(-1));
                IERC20(_token2).safeApprove(marsRouter, 0);
                IERC20(_token2).safeApprove(marsRouter, uint256(-1));
                Uni(marsRouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapInTokenApe(address _tokenin, uint _amount,address _token1, address _token2, address _lptoken) payable public {
        
        IERC20(_tokenin).transfer(address(this), _amount);
        uint half = IERC20(_tokenin).balanceOf(address(this)).div(2);

        //50% Restake
        convertApe(half, _tokenin ,_token1);
        convertApe(half, _tokenin ,_token2);
        // Liquidity pool
        uint256 token0Amt = IERC20(_token1).balanceOf(address(this));
        uint256 token1Amt = IERC20(_token2).balanceOf(address(this));
        require(token0Amt > 0 && token1Amt > 0, "token1Amt or token0Amt not greater than 0");
        if (token0Amt > 0 && token1Amt > 0) {
                IERC20(_token1).safeApprove(aperouter, 0);
                IERC20(_token1).safeApprove(aperouter, uint256(-1));
                IERC20(_token2).safeApprove(aperouter, 0);
                IERC20(_token2).safeApprove(aperouter, uint256(-1));
                Uni(aperouter).addLiquidity(
                    _token1,
                    _token2,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(1800)
                );
        }
        
    }

    function ZapOutPancake(uint _amount, address _token1, address _token2, address _lptoken) public {
        
        IERC20(_lptoken).safeTransferFrom(msg.sender, address(this), _amount);
        // Remove Liquidity pool
        IERC20(_lptoken).safeApprove(pancakerouter, 0);
        IERC20(_lptoken).safeApprove(pancakerouter, uint256(-1));

        if (_token1 == wbnb || _token2 == wbnb) {
                Uni(pancakerouter).removeLiquidityETH(_token1 != wbnb ? _token1 : _token2, _amount, 0, 0, msg.sender, block.timestamp);
        } else {
                Uni(pancakerouter).removeLiquidity(_token1, _token2, _amount, 0, 0, msg.sender, block.timestamp);
        }
    }

    function ZapOutMRS(uint _amount, address _token1, address _token2, address _lptoken) public {
        
        IERC20(_lptoken).safeTransferFrom(msg.sender, address(this), _amount);
        // Remove Liquidity pool
        IERC20(_lptoken).safeApprove(marsRouter, 0);
        IERC20(_lptoken).safeApprove(marsRouter, uint256(-1));

        if (_token1 == wbnb || _token2 == wbnb) {
                Uni(marsRouter).removeLiquidityETH(_token1 != wbnb ? _token1 : _token2, _amount, 0, 0, msg.sender, block.timestamp);
        } else {
                Uni(marsRouter).removeLiquidity(_token1, _token2, _amount, 0, 0, msg.sender, block.timestamp);
        }
    }

    function ZapOutApe(uint _amount, address _token1, address _token2, address _lptoken) public {
        IERC20(_lptoken).safeTransferFrom(msg.sender, address(this), _amount);
        
        // Remove Liquidity pool
        IERC20(_lptoken).safeApprove(aperouter, 0);
        IERC20(_lptoken).safeApprove(aperouter, uint256(-1));

        if (_token1 == wbnb || _token2 == wbnb) {
                Uni(aperouter).removeLiquidityETH(_token1 != wbnb ? _token1 : _token2, _amount, 0, 0, msg.sender, block.timestamp);
        } else {
                Uni(aperouter).removeLiquidity(_token1, _token2, _amount, 0, 0, msg.sender, block.timestamp);
        }
    }

    function convertApe(uint _amount, address _tokenin, address _tokenout) public {
        require(!Address.isContract(msg.sender),"!contract");
        address[] memory path = new address[](2);
                    path[0] = _tokenin;
                    path[1] = _tokenout;
                    Uni(aperouter).swapExactTokensForTokens(
                            _amount,
                            uint256(0),
                            path,
                            address(this),
                            block.timestamp.add(1800)
                    );
    }

    function convertPancake(uint _amount, address _tokenin, address _tokenout) public {
        require(!Address.isContract(msg.sender),"!contract");
        address[] memory path = new address[](2);
                    path[0] = _tokenin;
                    path[1] = _tokenout;
                    Uni(pancakerouter).swapExactTokensForTokens(
                            _amount,
                            uint256(0),
                            path,
                            address(this),
                            block.timestamp.add(1800)
                    );
    }

    function convertMars(uint _amount, address _tokenin, address _tokenout) public {
        require(!Address.isContract(msg.sender),"!contract");
        address[] memory path = new address[](2);
                    path[0] = _tokenin;
                    path[1] = _tokenout;
                    Uni(marsRouter).swapExactTokensForTokens(
                            _amount,
                            uint256(0),
                            path,
                            address(this),
                            block.timestamp.add(1800)
                    );
    }
    
    function _wrapBNB() internal {
        // BNB -> WBNB
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            WBNBContract(wbnb).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    function wrapBNB() public {
        _wrapBNB();
    }

    
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
    
    
}