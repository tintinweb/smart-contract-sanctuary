/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Ownable {
    address private m_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        m_Owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return m_Owner;
    }    
    function transferOwnership(address _address) public virtual {
        require(msg.sender == m_Owner);
        m_Owner = _address;
        emit OwnershipTransferred(msg.sender, _address);
    }                                                                                        
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}
interface Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
}
interface Pair { 
    function token0() external returns (address);
    function token1() external returns (address);
}
interface ERC20 { 
    function balanceOf(address _address) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}
interface WETH9 {
    function withdraw(uint256 wad) external;
}

contract FTPLiqLock is Ownable {
    using SafeMath for uint256;

    address m_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address m_BackupBurn = 0x000000000000000000000000000000000000dEaD;

    mapping (address => address) private m_Router;
    mapping (address => uint256) private m_PairRelease;
    mapping (address => address) private m_PayoutAddress;
    mapping (address => uint256) private m_StartingBalance;
    
    event Lock (address Pair, address Token1, address Token2, address Payout, uint256 Release);
    event LockExtended (address Pair, uint256 Release);
    event BurnFailure (string Error);

    constructor() {}
    receive() external payable {}
    
    // You can use this contract to autolock upon addLiquidity(). * coding required * Reference FairTokenProject deployed contracts
    // Locks can be WETH or USDC based pairs.
    // Locks can be from Uniswap or Sushiswap.(Or any uniswap clone)
    // Developer can only receive funds equal to what was present at time of the lock. 
    // Token supply that would normally be returned to locking party is instead burned.
    // Unused LP tokens are burned.
    // Example: Developer locks with 5 ETH in the pair, Developer is issued 500 LP tokens as keys, LP tokens get locked with this contract
    //          Lock expires with 50 ETH in the pair, Developer withdraws (removes liquidity), Contract uses 50 LP keys to return 5 ETH to Developer
    //          Remaining 450 LP Keys are sent to the burn address, the 10% of the tokens in pair that were withdrawn are also burned.
    function lockTokens(address _pair, uint256 _epoch, address _tokenPayout, address _router) external {
        address _factory = Router(_router).factory();
        address _weth = Router(_router).WETH();
        require(Factory(_factory).getPair(Pair(_pair).token0(), Pair(_pair).token1()) == _pair, "Please only deposit valid pair tokens");
        require(Pair(_pair).token0() == _weth || Pair(_pair).token0() == m_USDC || Pair(_pair).token1() == _weth || Pair(_pair).token1() == m_USDC, "Only ETH or USDC pairs");
        uint256 _balance = ERC20(_pair).balanceOf(msg.sender);
        require(_balance.mul(100).div(ERC20(_pair).totalSupply()) >= 99, "Caller must hold all UniV2 tokens");
        m_PairRelease[_pair] = _epoch;
        m_PayoutAddress[_pair] = _tokenPayout;
        m_Router[_pair] = _router;
        ERC20(_pair).transferFrom(address(msg.sender), address(this), _balance);
        if(Pair(_pair).token0() == m_USDC || Pair(_pair).token1() == m_USDC)
            m_StartingBalance[_pair] = ERC20(m_USDC).balanceOf(_pair);
        else
            m_StartingBalance[_pair] = ERC20(_weth).balanceOf(_pair);
        
        emit Lock(_pair, Pair(_pair).token0(), Pair(_pair).token1(), _tokenPayout, _epoch);
    }    
    function releaseTokens(address _pair) external {
        uint256 _pairBalance = ERC20(_pair).balanceOf(address(this));
        require(msg.sender == m_PayoutAddress[_pair]);
        require(_pairBalance > 0, "No tokens to release");
        require(block.timestamp > m_PairRelease[_pair], "Lock expiration not reached");
        address _router = m_Router[_pair];
        address _contract;
        address _weth = Router(_router).WETH();
        if(Pair(_pair).token0() == _weth || Pair(_pair).token0() == m_USDC)
            _contract = Pair(_pair).token1();
        else
            _contract = Pair(_pair).token0();
        uint256 _factor = 0;
        uint256 _share = 0;

        // Calculates balances and removes appropriate amount of liquidity to give developer initial balance.
        if (Pair(_pair).token0() == m_USDC || Pair(_pair).token1() == m_USDC) {
            uint256 _USDBalance = ERC20(m_USDC).balanceOf(_pair);
            uint256 _starting = m_StartingBalance[_pair];
            _factor = _USDBalance.div(_starting);
            _share = _pairBalance.div(_factor);
            ERC20(_pair).approve(_router, _share);
            (uint256 _USDFunds,) = Router(_router).removeLiquidity(m_USDC, _contract, _share, _starting.sub(1), 0, address(this), block.timestamp); //sub(1) due to LP burn on initial addLiquidity
            ERC20(m_USDC).transfer(m_PayoutAddress[_pair], _USDFunds);
        }
        else {
            uint256 _wethBalance = ERC20(_weth).balanceOf(_pair);
            uint256 _starting = m_StartingBalance[_pair];
            _factor = _wethBalance.div(_starting);
            _share = _pairBalance.div(_factor);
            ERC20(_pair).approve(_router, _share);
            (uint256 _wethFunds,) = Router(_router).removeLiquidity(_weth, _contract, _share, _starting.sub(1), 0, address(this), block.timestamp); //sub(1) due to LP burn on initial addLiquidity
            WETH9(_weth).withdraw(_wethFunds);
            payable(m_PayoutAddress[_pair]).transfer(_wethFunds);    
        }

        // Burns the portion of supply that was removed, attempts address 0 then dead address finally leaves tokens in this contract as a last resort.
        try ERC20(_contract).transfer(address(0), ERC20(_contract).balanceOf(address(this))) {
        } catch Error(string memory _err) {
            emit BurnFailure(_err);
            try ERC20(_contract).transfer(m_BackupBurn, ERC20(_contract).balanceOf(address(this))) {
            } catch Error(string memory _err2) {
                emit BurnFailure(_err2);
                emit BurnFailure("Excess tokens locked in FTPLiqLock as last resort");
            }
        }

        // Burns remaining Keys, if any.
        uint256 _remaining = ERC20(_pair).balanceOf(address(this));
        if(_remaining > 0)
            ERC20(_pair).transfer(address(0), _remaining);
    }    
    // Developer may choose to burn at any time.
    function burnKeys(address _pair) external {
        require(msg.sender == m_PayoutAddress[_pair]);
        m_StartingBalance[_pair] = 0;
        ERC20(_pair).transfer(address(0), ERC20(_pair).balanceOf(address(this)));
    }
    function extendLock(address _pair, uint256 _epoch) external {
        uint256 _pairBalance = ERC20(_pair).balanceOf(address(this));
        require(_pairBalance > 0);
        require(msg.sender == m_PayoutAddress[_pair]);
        require(_epoch > m_PairRelease[_pair]);
        m_PairRelease[_pair] = _epoch;
        emit LockExtended(_pair, _epoch);
    }
    function getLockedTokens(address _pair) external view returns (uint256 ReleaseDate, address PayoutAddress, uint256 StartingBalance) {
        return (m_PairRelease[_pair], m_PayoutAddress[_pair], m_StartingBalance[_pair]);
    }
    function updateUSDC(address _address) external {
        require(msg.sender == owner());
        m_USDC = _address;
    }
}