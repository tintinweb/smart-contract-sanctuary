pragma solidity >=0.8.7;

import "../PointFactory.sol";
import "./EtherPoint.sol";

contract EtherPointFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(dealId, address(new EtherPoint(router, needCount, from, to)));
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

import "../DealPoint.sol";

/// @dev эфировый пункт сделки
contract EtherPoint is DealPoint {
    uint256 public needCount;
    address public firstOwner;
    address public newOwner;

    constructor(
        address _router,
        uint256 _needCount,
        address _firstOwner,
        address _newOwner
    ) DealPoint(_router) {
        router = _router;
        needCount = _needCount;
        firstOwner = _firstOwner;
        newOwner = _newOwner;
    }

    function isComplete() external view override returns (bool) {
        return address(this).balance >= needCount;
    }

    function swap() external override {
        require(msg.sender == router);
        isSwapped = true;
    }

    function withdraw() external {
        address owner = isSwapped ? newOwner : firstOwner;
        require(msg.sender == owner || msg.sender == router);
        payable(owner).transfer(address(this).balance);
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