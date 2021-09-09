//SourceUnit: AddressSetLib.sol

pragma solidity 0.5.8;


library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}


//SourceUnit: Refer.sol

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