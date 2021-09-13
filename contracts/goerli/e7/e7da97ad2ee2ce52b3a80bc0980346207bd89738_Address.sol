/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 {
    using SafeMath for uint;
    
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;
    
    string public descriptor;

    /// @notice EIP-20 token decimals for this token
    uint public immutable decimals;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0; // Initial 0
    
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;
    
    address public immutable market;
    
     /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    
    constructor(IERC20 _reserve, string memory _descriptor) {
        name = string(abi.encodePacked("p-", _descriptor));
        symbol = string(abi.encodePacked("p-", _descriptor));
        decimals = IERC20(_reserve).decimals();
        descriptor = _descriptor;
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        market = msg.sender;
    }
    
    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);
    
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
        if (spender == market && dst == market) {
            spenderAllowance = uint(-1);
        }

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "transferFrom: exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");

        balances[src] = balances[src].sub(amount, "_transferTokens: exceeds balance");
        balances[dst] = balances[dst].add(amount, "_transferTokens: overflows");
        emit Transfer(src, dst, amount);
    }

    function _getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function _mint(address dst, uint amount) internal {
        totalSupply = totalSupply.add(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        totalSupply = totalSupply.sub(amount);
        balances[dst] = balances[dst].sub(amount);
        emit Transfer(dst, address(0), amount);
    }
    
    function protect(address dst, uint amount) external {
        require(msg.sender == market);
        emit Transfer(market, dst, amount);
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}

contract pERC20 is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    IERC20 public immutable RESERVE; // underlying that is paid out
    address public immutable PROTECTED;
    
    ISushiswapV1OracleKeep3r constant oracle = ISushiswapV1OracleKeep3r(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);
    
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    mapping (address => uint) public shares;
    
    constructor(IERC20 _reserve, address _protected, string memory _descriptor) ERC20(_reserve, _descriptor) {
        RESERVE = _reserve;
        PROTECTED = _protected;
    }
    
    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function quote(uint positionSize) public view returns (uint) {
        if (PROTECTED == WETH || address(RESERVE) == WETH) {
            return oracle.quote(PROTECTED, positionSize, address(RESERVE), 2);
        } else {
            uint _temp = oracle.quote(PROTECTED, positionSize, WETH, 2);
            return oracle.quote(WETH, _temp, address(RESERVE), 2);
        }
    }
    
    // Calculate the bounded loss of an LP position given tokenIn as tokenA and tokenOut as tokenB
    function calculate(uint positionSize, uint entryPrice) public view returns (uint) {
        return calculate(positionSize, entryPrice, quote(positionSize), 10**decimals);
    }
    
    // Returns the bounded loss of a given LP position
    function calculate(uint positionSize, uint entryPrice, uint exitPrice, uint decimals) public pure returns (uint) {
        return positionSize * (((decimals*exitPrice/entryPrice+decimals)/2) - sqrt((decimals*decimals)*exitPrice/entryPrice));
    }
    
    function payout(uint _amount) external {
        require(msg.sender == market);
        RESERVE.safeTransfer(msg.sender, _amount);
    }
    
    function deposit() external returns (uint) {
        return _deposit(RESERVE.balanceOf(msg.sender));
    }
    
    function deposit(uint _amount) external returns (uint) {
        return _deposit(_amount);
    }
    
    function _deposit(uint _amount) internal returns (uint) {
        uint _pool = RESERVE.balanceOf(address(this));
        RESERVE.safeTransferFrom(msg.sender, address(this), _amount);
        uint _received = RESERVE.balanceOf(address(this)).sub(_pool);
        uint _shares = 0;
        if (_pool == 0) {
            _shares = _received;
        } else {
            _shares = (_received.mul(totalSupply)).div(_pool);
        }
        shares[msg.sender] = shares[msg.sender].add(_shares);
        _mint(address(this), _shares);
        return _shares;
    }
    
    function withdraw() external returns (uint) {
        return _withdraw(balances[msg.sender], msg.sender);
    }
    
    function withdraw(uint _amount, address recipient) external returns (uint) {
        return _withdraw(_amount, recipient);
    }
    
    function _withdraw(uint _shares, address recipient) internal returns (uint) {
        uint r = (RESERVE.balanceOf(address(this)).mul(_shares)).div(totalSupply);
        shares[msg.sender] = shares[msg.sender].sub(_shares);
        RESERVE.safeTransfer(recipient, r);
        _burn(address(this), _shares);
        return r;
    }
    
    function sharePrice() public view returns (uint) {
        return RESERVE.balanceOf(address(this)).mul(uint(10)**decimals).div(totalSupply);
    }
}

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
*/

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }
    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }

}

contract InterestRateModel {
    using WadRayMath for uint;
    using SafeMath for uint;

   /**
    * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates
    * expressed in ray
    **/
    uint public constant OPTIMAL_UTILIZATION_RATE = 0.8 * 1e27;

   /**
    * @dev this constant represents the excess utilization rate above the optimal. It's always equal to
    * 1-optimal utilization rate. Added as a constant here for gas optimizations
    * expressed in ray
    **/

    uint public constant EXCESS_UTILIZATION_RATE = 0.2 * 1e27;


    //base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint public baseBorrowRate;

    //slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint public slope1;

    //slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint public slope2;

    constructor(uint _baseBorrowRate, uint _slope1, uint _slope2) {
        baseBorrowRate = _baseBorrowRate;
        slope1 = _slope1;
        slope2 = _slope2;
    }
    
    function calculateInterestRates(
        uint _availableLiquidity,
        uint _totalBorrows
    ) external view returns (uint currentBorrowRate) {

        uint utilizationRate = (_totalBorrows == 0 && _availableLiquidity == 0)
            ? 0
            : _totalBorrows.rayDiv(_availableLiquidity.add(_totalBorrows));

        if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint excessUtilizationRateRatio = utilizationRate
                .sub(OPTIMAL_UTILIZATION_RATE)
                .rayDiv(EXCESS_UTILIZATION_RATE);

            currentBorrowRate = baseBorrowRate.add(slope1).add(
                slope2.rayMul(excessUtilizationRateRatio)
            );
        } else {
            currentBorrowRate = baseBorrowRate.add(
                utilizationRate.rayDiv(OPTIMAL_UTILIZATION_RATE).rayMul(slope1)
            );
        }
    }
}


interface ISushiswapV1OracleKeep3r {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint);
}

contract ProtectionMarket {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    IERC20 public immutable RESERVE;
    
    InterestRateModel public model;
    pERC20 public immutable P;
    
    uint public index = 0;
    
    mapping(address => uint) public supplyIndex;
    mapping(address => uint) public fees;
    
    uint public constant MIN = 1 days;
    
    constructor(IERC20 _reserve, address _protected, string memory _descriptor, uint _baseBorrowRate, uint _slope1, uint _slope2) {
        RESERVE = _reserve;
        pERC20 _p = new pERC20(_reserve, _protected, _descriptor);
        P = _p;
        model = new InterestRateModel(_baseBorrowRate, _slope1, _slope2);
        IERC20(_reserve).safeApprove(address(_p), uint(-1));
    }
    
    uint public currentBorrowRate = 0;
    uint public blockTimestampLast = 0;

    
    function update() external {
        _update();
    }
    
    function getBorrowRate() external view returns (uint) {
        return model.calculateInterestRates(totalProtection, totalHedged);
    }
    
    function _update() internal {
        if (totalHedged > 0) {
            (uint _currentBorrowRate) = model.calculateInterestRates(totalProtection, totalHedged);
            uint _timeElapsed = block.timestamp - blockTimestampLast;
            uint _cummulativeBorrowRate = currentBorrowRate.mul(_timeElapsed);
            if (_cummulativeBorrowRate > 0) {
                uint256 _ratio = _cummulativeBorrowRate.mul(P.decimals()).div(totalHedged);
                if (_ratio > 0) {
                  index = index.add(_ratio);
                  blockTimestampLast = block.timestamp;
                }
            }
            currentBorrowRate = _currentBorrowRate;
        }
    }
    
    struct position {
        uint reserves;
        uint hedged;
        uint size;
        uint p0;
    }
    
    mapping(address => position) public positions;
    uint public totalHedged = 0;
    
    mapping(address => uint) public protection;
    uint public totalProtection = 0;
    
    function accrue(address _owner) public {
        _update();
        uint _hedged = positions[_owner].hedged;
        if (_hedged > 0) {
            uint _supplyIndex = supplyIndex[_owner];
            supplyIndex[_owner] = index;
            uint _delta = index.sub(_supplyIndex, "::accrue: index delta");
            if (_delta > 0) {
                uint _share = _delta.mul(_hedged).div(WadRayMath.RAY);
                fees[_owner] = fees[_owner].add(_share);
            }
        } else {
            supplyIndex[_owner] = index;
        }
    }
    
    function profit(address owner) public view returns (uint) {
        return P.calculate(positions[owner].hedged, positions[owner].p0);
    }
    
    function exercise() public {
        accrue(msg.sender);
        collect(msg.sender);
        uint _profit = profit(msg.sender);
        positions[msg.sender].reserves = positions[msg.sender].reserves.add(_profit);
        positions[msg.sender].hedged = 0;
        P.payout(_profit);
    }
    
    function protect(uint _reserve, uint _amount) external {
        accrue(msg.sender);
        collect(msg.sender);
        if (_reserve > 0) {
            topup(_reserve);
        }
        position storage _position = positions[msg.sender];
        
        uint _positionSize = _position.size.add(_amount);
        uint _hedged = P.quote(_positionSize);
        
        uint minReserves = _hedged.mul(currentBorrowRate).mul(MIN).div(WadRayMath.RAY);
        require(minReserves < _position.reserves);
        
        _position.size = _positionSize;
        _position.p0 = _hedged;
        
        totalHedged = totalHedged.add(_hedged);
        
        P.protect(msg.sender, _hedged);
        
        require(totalProtection > totalHedged, "insufficient cover");
        positions[msg.sender] = _position;
        _update();
    }
    
    function close(uint _amount) external {
        accrue(msg.sender);
        collect(msg.sender);
        positions[msg.sender].hedged = positions[msg.sender].hedged.sub(_amount);
        totalHedged = totalHedged.sub(_amount);
        _update();
    }
    
    function collect(address _owner) public {
        uint _fees = fees[_owner]; // gas saving
        if (_fees > 0) {
            position storage _local = positions[_owner];
            uint _reserves = _local.reserves; // gas saving
            if (_fees > _reserves) {
                RESERVE.safeTransfer(address(P), _reserves);
                totalHedged = totalHedged.sub(_local.hedged);
                _local.reserves = 0;
                _local.hedged = 0;
                _update();
            } else {
                RESERVE.safeTransfer(address(P), _reserves);
                _local.reserves = _local.reserves.sub(_fees);
            }
            fees[_owner] = 0;
            positions[_owner] = _local;
        }
    }
    
    function depositUnderlying(uint _amount) external {
        RESERVE.safeTransferFrom(msg.sender, address(this), _amount);
        uint _received = P.deposit(_amount);
        protection[msg.sender] = protection[msg.sender].add(_received);
        totalProtection = totalProtection.add(_received);
    }
    
    function deposit(uint _amount) external {
        uint _pool = P.balanceOf(address(this));
        P.transferFrom(msg.sender, address(this), _amount);
        uint _received = P.balanceOf(address(this)).sub(_pool);
        protection[msg.sender] = protection[msg.sender].add(_received);
        totalProtection = totalProtection.add(_received);
    }
    
    function withdraw(uint _amount) external {
        protection[msg.sender] = protection[msg.sender].sub(_amount);
        totalProtection = totalProtection.sub(_amount);
        require(totalProtection < totalHedged, "insufficient cover");
        P.transfer(msg.sender, _amount);
    }
    
    function withdrawUnderlying(uint _amount) external {
        protection[msg.sender] = protection[msg.sender].sub(_amount);
        totalProtection = totalProtection.sub(_amount);
        require(totalProtection >= totalHedged, "insufficient cover");
        P.withdraw(_amount, msg.sender);
    }
    
    function topup(uint _amount) public {
        accrue(msg.sender);
        uint _pool = RESERVE.balanceOf(address(this));
        RESERVE.safeTransferFrom(msg.sender, address(this), _amount);
        uint _received = RESERVE.balanceOf(address(this)).sub(_pool);
        positions[msg.sender].reserves = positions[msg.sender].reserves.add(_received);
        collect(msg.sender);
    }
    
    function skim(uint _amount) public {
        accrue(msg.sender);
        collect(msg.sender);
        
        uint _reserves = positions[msg.sender].reserves;
        
        if (_amount > _reserves) {
            _amount = _reserves;
        }
        
        positions[msg.sender].reserves = _reserves.sub(_amount);
        RESERVE.safeTransfer(msg.sender, _amount);
    }
}