pragma solidity >=0.8.7;

import "../../PointFactory.sol";
import "./Erc721CountPoint.sol";

contract Erc721CountFactory is PointFactory {
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
            address(new Erc721CountPoint(router, token, needCount, from, to))
        );
    }
}

pragma solidity >=0.8.7;

import "contracts/ISwapper.sol"; 
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
        ISwapper(router).addDealPoint(dealId, address(point));
    }
}

pragma solidity >=0.8.7;

import "../../DealPoint.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена
contract Erc721CountPoint is DealPoint {
    IERC721 public token;
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
        token = IERC721(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw(uint256 tokenId) external {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, tokenId);
    }
}

pragma solidity >=0.8.7;

interface ISwapper{
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