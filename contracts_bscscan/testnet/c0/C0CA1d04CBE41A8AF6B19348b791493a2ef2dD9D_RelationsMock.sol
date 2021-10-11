// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import '../utils/SafeMath.sol';

contract RelationsMock {
    using SafeMath for uint256;

    // 根地址
    address public rootAddress;

    // 地址总数
    uint256 public totalAddresses;

    // 上级检索
    mapping(address => address) public parentOf;

    // 深度记录
    mapping(address => uint256) public depthOf;

    // 下级检索-直推
    mapping(address => address[]) internal _childrenMapping;

    constructor() {
        rootAddress = address(0xdead);
        parentOf[rootAddress] = address(0xdeaddead);
    }

    // 获取指定地址的祖先结点链
    function getForefathers(address owner, uint256 depth)
        external
        view
        returns (address[] memory)
    {
        address[] memory forefathers = new address[](depth);

        for (
            (address parent, uint256 i) = (parentOf[owner], 0);
            i < depth && parent != address(0) && parent != rootAddress;
            (i = i.add(1), parent = parentOf[parent])
        ) {
            forefathers[i] = parent;
        }

        return forefathers;
    }

    // 获取推荐列表
    function childrenOf(address owner)
        external
        view
        returns (address[] memory)
    {
        return _childrenMapping[owner];
    }

    // 绑定推荐人并且生产自己短码同时设置昵称
    function makeRelation(address parent) external {
        require(parentOf[msg.sender] == address(0), "AlreadyBinded");
        require(parent != msg.sender, "CannotBindYourSelf");
        require(parentOf[parent] != address(0x0), "ParentNoRelation");

        // 累加数量
        totalAddresses = totalAddresses.add(1);

        // 上级检索
        parentOf[msg.sender] = parent;

        // 深度记录
        depthOf[msg.sender] = depthOf[parent].add(1);

        _childrenMapping[parent].push(msg.sender);
    }
    
    function helpMakeRelation(address sender,address parent) external{
         require(parentOf[sender] == address(0), "AlreadyBinded");
        require(parent != sender, "CannotBindYourSelf");
        require(parentOf[parent] != address(0x0), "ParentNoRelation");

        // 累加数量
        totalAddresses = totalAddresses.add(1);

        // 上级检索
        parentOf[sender] = parent;

        // 深度记录
        depthOf[sender] = depthOf[parent].add(1);

        _childrenMapping[parent].push(sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}