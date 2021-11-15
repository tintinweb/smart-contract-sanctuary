// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Relations {
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
            (i++, parent = parentOf[parent])
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
        totalAddresses++;

        // 上级检索
        parentOf[msg.sender] = parent;

        // 深度记录
        depthOf[msg.sender] = depthOf[parent] + 1;

        _childrenMapping[parent].push(msg.sender);
    }
}

