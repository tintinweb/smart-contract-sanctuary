pragma solidity >=0.8.7;

import "../../PointFactory.sol";
import "./Erc20CountPoint.sol";

contract Erc20CountPointFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(new Erc20CountPoint(router, token, needCount, from, to))
        );
    }
}

pragma solidity >=0.8.7;

import "contracts/ISwaper.sol"; 
import "contracts/IDealPointFactory.sol";

abstract contract PointFactory is IDealPointFactory{
    address public router;
    mapping(address => uint256) public countsByCreator;
    uint256 countTotal;

    constructor(address routerAddress) {
        router = routerAddress;
    }

    function addPoint(uint256 dealId, address point) internal {
        ++countTotal;
        uint256 localCount = countsByCreator[msg.sender] + 1;
        countsByCreator[msg.sender] = localCount;
        ISwaper(router).addDealPoint(dealId, address(point));
    }
}

pragma solidity >=0.8.7;

import "../../DealPoint.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена
contract Erc20CountPoint is DealPoint {
    IERC20 public token;
    uint256 public needCount;
    address public from;
    address public to;

    constructor(
        address _router,
        address _token,
        uint256 _needCount,
        address _from,
        address _to
    ) DealPoint(_router) {
        router = _router;
        token = IERC20(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw() external {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}

pragma solidity >=0.8.7;

interface ISwaper{
    /// @dev добавляет в сделку пункт договора с указанным адресом
    /// данный метод может вызывать только фабрика
    function addDealPoint(uint256 dealId, address point) external;
}

pragma solidity >=0.8.7;

import "contracts/IDealPoint.sol";

interface IDealPointFactory{
}

pragma solidity >=0.8.7;

interface IDealPoint{
    function isComplete() external view returns(bool); // выполнены ли условия
    function swap() external;   // свап
}

pragma solidity >=0.8.7;

import "contracts/IDealPoint.sol";

abstract contract DealPoint is IDealPoint {
    address public router;
    bool public isSwapped;

    constructor(address _router) {
        router = _router;
    }

    function swap() external virtual {
        require(msg.sender == router);
        isSwapped = true;
    }

    function isComplete() external view virtual returns (bool);
}