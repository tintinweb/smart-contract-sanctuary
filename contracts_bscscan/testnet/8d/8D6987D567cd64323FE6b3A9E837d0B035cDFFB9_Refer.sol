pragma solidity 0.5.8;

import "./AddressSetLib.sol";


contract Refer {
    using AddressSetLib for AddressSetLib.AddressSet;

    mapping (address => address) public referrers; // 推荐关系
    mapping (address => address[]) public referList; // 推荐列表

    AddressSetLib.AddressSet internal addressSet;

    event NewReferr(address indexed usr, address refer);

    // 提交推荐关系
    function submitRefer(address usr, address referrer) public returns (bool) {
        require(usr == tx.origin, "usr must be tx origin");
        require(usr != referrer, "can't invite your self");

        // 记录推荐关系
        if (referrers[usr] == address(0)) {
            referrers[usr] = referrer;
            emit NewReferr(usr, referrer);

            addressSet.add(referrer);

            if (!isReferContains(usr, referrer)) {
                referList[referrer].push(usr);
            }
        }
        return true;
    }

    // 查询推荐的总人数
    function getReferLength(address referrer) public view returns (uint256) {
        return referList[referrer].length;
    }

    // 查询用户是否在指定地址的推荐列表中
    function isReferContains(address usr, address referrer) public view returns (bool) {
        address[] memory addrList = referList[referrer];
        bool found = false;
        for (uint256 i = 0; i < addrList.length; i++) {
            if (usr == addrList[i]) {
                found = true;
                break;
            }
        }
        return found;
    }

    // 查询推荐人地址
    function getReferrer(address usr) public view returns (address) {
        return referrers[usr];
    }

    // 查询所有的推荐人，可指定index位置和返回数量
    function getReferrers(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return addressSet.getPage(index, pageSize);
    }
}