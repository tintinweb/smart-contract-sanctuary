/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:ADD_OVERFLOW");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:SUB_UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath:MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:DIV_ZERO");
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address _addr) external view returns (uint);

    function transfer(address _to, uint _value) external returns (bool);

    function transferFrom(address _from, address _to, uint _value) external returns (bool);

    function approve(address _spender, uint _value) external returns (bool);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
}

interface IUniswapRouterV2{
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

contract LiquidityData is AccessControl {
    using SafeMath for uint;

    bytes32 public constant LIQUIDITY_ROLE = keccak256("LIQUIDITY");

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    event RemoveLiquidity(address _addr, uint _liquidity, uint _rosNum, uint _ETHNum);

    event AddLiquidity(address _addr, uint _liquidity, uint _rosNum, uint _ETHNum);

    event CovertLog(address _addr, uint _type, uint _ETHNum, uint _rosNum);

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    address public uniswapAddress;
    address public rosAddress;
    bool public isRosApprove;
    bool public isUniProofApprove;
    address public uniswapFactoryAddress;
    address public uniswapPairAddress;
    address public WETHAddress;
    function setUniswapAddress(address _addr) external roleCheck(ADMIN_ROLE) {
        uniswapAddress = _addr;
        isRosApprove = false;
        isUniProofApprove = false;
    }

    function setWETHAddress() public roleCheck(ADMIN_ROLE) {
        WETHAddress = IUniswapRouterV2(uniswapAddress).WETH();
    }

    function setPairAddress() public roleCheck(ADMIN_ROLE) {
        uniswapPairAddress = IUniswapFactory(uniswapFactoryAddress).getPair(rosAddress, WETHAddress);
    }

    modifier roleCheck(bytes32 role) {
        require(hasRole(role, msg.sender), "LIQUIDITY:DON'T_HAVE_PERMISSION");
        _;
    }

}

contract LiquidityView is LiquidityData {
    function getUniswapReserves() public view returns (uint112 rosReserve, uint112 ethReserve, uint32 blockTimestampLast) {
        if (getUniswapToken0Address() == rosAddress) {
            (rosReserve, ethReserve, blockTimestampLast) = IUniswapPair(uniswapPairAddress).getReserves();
        } else {
            (ethReserve, rosReserve, blockTimestampLast) = IUniswapPair(uniswapPairAddress).getReserves();
        }
    }

    function getUniswapMinLiquidity() public view returns (uint) {
        return IUniswapPair(uniswapPairAddress).MINIMUM_LIQUIDITY();
    }

    function getUniswapToken0Address() public view returns (address) {
        return IUniswapPair(uniswapPairAddress).token0();
    }

    function getUniswapToken1Address() public view returns (address) {
        return IUniswapPair(uniswapPairAddress).token1();
    }

    function getAmountsOut(uint _tokenNum, address _symbolAddress, address _returnSymbolAddress) public view returns (uint) {
        address[] memory addr = new address[](2);
        addr[0] = _symbolAddress;
        addr[1] = _returnSymbolAddress;
        uint[] memory amounts = IUniswapRouterV2(uniswapAddress).getAmountsOut(_tokenNum, addr);
        return amounts[1];
    }

    function getAmountsOut(uint _tokenNum, address[] memory _symbolAddress) public view returns (uint[] memory) {
        uint[] memory amounts = IUniswapRouterV2(uniswapAddress).getAmountsOut(_tokenNum, _symbolAddress);
        return amounts;
    }

    function getAmountsOutRos2ETH(uint _tokenNum) external view returns (uint) {
        return getAmountsOut(_tokenNum, rosAddress, IUniswapRouterV2(uniswapAddress).WETH());
    }

    function getAmountsOutETH2Ros(uint _tokenNum) external view returns (uint) {
        return getAmountsOut(_tokenNum, IUniswapRouterV2(uniswapAddress).WETH(), rosAddress);
    }

    function getSlippage(uint _tokenNum, uint _slippage) internal pure returns (uint) {
        return _tokenNum.sub(_tokenNum.mul(_slippage).div(1000));
    }

    function getLiquidityProofAmount(address _sender) public view returns (uint _balance, uint _totalSupply) {
        IERC20 uniswapV2Prool = IERC20(uniswapPairAddress);
        _balance = uniswapV2Prool.balanceOf(_sender);
        _totalSupply = uniswapV2Prool.totalSupply();
    }

    function getRemoveLiquidityETHData(
        address _account,
        uint _liquidity,
        uint _slippage
    ) public view returns (uint amountTokenMin, uint amountETHMin) {
        (uint112 rosReserve, uint112 ethReserve,) = getUniswapReserves();
        (uint _balance, uint _totalSupply) = getLiquidityProofAmount(_account);
        require(_balance >= _liquidity, "LIQUIDITY_INSUFFICIENT");
        uint amountToken = uint(rosReserve).mul(_liquidity).div(_totalSupply);
        uint amountETH = uint(ethReserve).mul(_liquidity).div(_totalSupply);
        amountTokenMin = getSlippage(amountToken, _slippage);
        amountETHMin = getSlippage(amountETH, _slippage);
    }

    function getAddUniLiquidityDataETH2Ros(
        uint _eth,
        uint _slippage
    ) public view returns (uint _ethNum, uint _rosNum, uint _ethNumMin, uint _rosNumMin) {
        (uint112 _rosReserve, uint112 _ethReserve,) = getUniswapReserves();
        uint rosReserve  = uint(_rosReserve);
        uint ethReserve  = uint(_ethReserve);
        _ethNum = _eth;
        _rosNum = _ethNum.mul(rosReserve).div(ethReserve);
        _ethNumMin = getSlippage(_ethNum, _slippage);
        _rosNumMin = getSlippage(_rosNum, _slippage);
    }

    function getAddUniLiquidityDataRos2ETH(
        uint _ros,
        uint _slippage
    ) public view returns (uint _ethNum, uint _rosNum, uint _ethNumMin, uint _rosNumMin) {
        (uint112 _rosReserve, uint112 _ethReserve,) = getUniswapReserves();
        uint rosReserve  = uint(_rosReserve);
        uint ethReserve  = uint(_ethReserve);
        _rosNum = _ros;
        _ethNum = _rosNum.mul(ethReserve).div(rosReserve);
        _ethNumMin = getSlippage(_ethNum, _slippage);
        _rosNumMin = getSlippage(_rosNum, _slippage);
    }
}

contract Liquidity is LiquidityView {
    constructor(address _rosAddr) public {
        uniswapAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactoryAddress = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        rosAddress = _rosAddr;
        setWETHAddress();
        setPairAddress();
    }

    function uniswapExactTokensForETH(
        address _account,
        uint amountIn,
        uint amountOutMin,
        uint _deadline
    ) external roleCheck(LIQUIDITY_ROLE) returns (uint[] memory amounts) {
        require(IERC20(rosAddress).transferFrom(_account, address(this), amountIn), "NOT_APPROVE_ROS_EXACT");
        if (!isRosApprove) {
            if (IERC20(rosAddress).approve(uniswapAddress, 1e66)) {
                isRosApprove = true;
            } else {
                revert("APPROVE_FIELD");
            }
        }

        IUniswapRouterV2 uniswapRouter = IUniswapRouterV2(uniswapAddress);
        address[] memory addr = new address[](2);
        addr[0] = rosAddress;
        addr[1] = WETHAddress;

        amounts = uniswapRouter.swapExactTokensForETH(amountIn, amountOutMin, addr, _account, _deadline);
        uint _diff = amountIn.sub(amounts[0]);
        if (_diff > 0) {
            IERC20(rosAddress).transfer(_account, _diff);
        }
        emit CovertLog(_account, 2, amounts[1], amounts[0]);
    }

    function uniswapExactETHForTokens(
        address _account,
        uint amountOutMin,
        uint _deadline
    ) external payable roleCheck(LIQUIDITY_ROLE) returns (uint[] memory amounts) {
        IUniswapRouterV2 uniswapRouter = IUniswapRouterV2(uniswapAddress);
        address[] memory addr = new address[](2);
        addr[0] = WETHAddress;
        addr[1] = rosAddress;

        amounts = uniswapRouter.swapExactETHForTokens{value:msg.value}(amountOutMin, addr, _account, _deadline);
        emit CovertLog(_account, 1, amounts[0], amounts[1]);
    }

    function addUniLiquidityETH(
        address _account,
        uint _rosNum,
        uint _ethNumMin,
        uint _rosNumMin,
        uint deadline
    ) external payable roleCheck(LIQUIDITY_ROLE) returns (uint amountToken, uint amountETH, uint liquidity) {
        require(IERC20(rosAddress).transferFrom(_account, address(this), _rosNum), "NOT_APPROVE_ROS");

        if (!isRosApprove) {
            if (IERC20(rosAddress).approve(uniswapAddress, 1e66)) {
                isRosApprove = true;
            } else {
                revert("APPROVE_FIELD");
            }
        }

        (amountToken, amountETH, liquidity) = IUniswapRouterV2(uniswapAddress).addLiquidityETH{value:msg.value}(
            rosAddress,
            _rosNum,
            _rosNumMin,
            _ethNumMin,
            _account,
            deadline
        );

        uint _diff = _rosNum.sub(amountToken);
        if (_diff > 0) {
            IERC20(rosAddress).transfer(_account, _diff);
        }

        emit AddLiquidity(_account, liquidity, _rosNum, msg.value);
    }

    function removeUniswapLiquidityETH(
        address _account,
        uint _liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external roleCheck(LIQUIDITY_ROLE) returns (uint amountToken, uint amountETH) {
        require(IERC20(uniswapPairAddress).transferFrom(_account, address(this), _liquidity), "NOT_APPROVE_UNIV2");

        if (!isUniProofApprove) {
            if (IERC20(uniswapPairAddress).approve(uniswapAddress, 1e66)) {
                isUniProofApprove = true;
            } else {
                revert("APPROVE_FIELD");
            }
        }

        IUniswapRouterV2 uniswapRouter = IUniswapRouterV2(uniswapAddress);
        (amountToken, amountETH) = uniswapRouter.removeLiquidityETH(
            rosAddress,
            _liquidity,
            amountTokenMin,
            amountETHMin,
            _account,
            deadline
        );
        emit RemoveLiquidity(_account, _liquidity, amountToken, amountETH);
    }

    function withdrawETH(address payable _to) public roleCheck(ADMIN_ROLE) {
        _to.transfer(address(this).balance);
    }

    function withdrawETH() external roleCheck(ADMIN_ROLE) {
        withdrawETH(payable(this));
    }

    receive() external payable {
        payable(tx.origin).transfer(msg.value);
    }
}