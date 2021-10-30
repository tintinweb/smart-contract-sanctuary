/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

contract Apparel {
    uint256 uuid = 0;

    struct Product {
        uint256 product_id;
        string status;
        string product_name;
    }

    struct FiberInfo {
        uint256 product_id;
        string employee_name;
        string product_quantity;
        string microscopic_test_result;
        string tensile_test_result;
        string fiber_type;
        string BSTI_standards_accoradance;
        string fiber_color_palette_img;
        string img2;
    }

    struct FiberHash {
        uint256 product_id;
        string hash;
    }

    struct ApparelInfo {
        uint256 product_id;
        string thread_diameter;
        string thread_friction;
        string uniformity;
        string tensile_strength;
        string thread_count;
        string apparel_color_palette_img;
        string img2;
    }

    struct ApparelHash {
        uint256 product_id;
        string hash;
    }

    mapping(uint256 => Product) products;
    mapping(uint256 => uint256[]) userProducts;
    mapping(uint256 => uint256[]) productOrders;

    mapping(uint256 => uint256[]) fiberOrders;
    mapping(uint256 => string) fiberHashes;
    mapping(uint256 => FiberInfo) fiberInfos;

    mapping(uint256 => uint256[]) apparelOrders;
    mapping(uint256 => string) apparelHashes;
    mapping(uint256 => ApparelInfo) apparelInfos;

    function orderProduct(
        uint256 user_id,
        uint256 product_id,
        string calldata product_name
    ) public {
        products[product_id] = Product(product_id, "PENDING", product_name);
        userProducts[user_id].push(product_id);
    }

    function getUserProducts(uint256 user_id)
        public
        view
        returns (uint256[] memory)
    {
        return userProducts[user_id];
    }

    function getProductInfo(uint256 product_id)
        public
        view
        returns (Product memory)
    {
        return products[product_id];
    }

    function updateProductStatus(uint256 product_id, string memory status)
        internal
    {
        products[product_id].status = status;
    }

    function addFiberInfo(
        uint256 user_id,
        uint256 product_id,
        string memory employee_name,
        string memory product_quantity,
        string memory microscopic_test_result,
        string memory tensile_test_result,
        string memory fiber_type,
        string memory BSTI_standards_accoradance,
        string memory fiber_color_palette_img,
        string memory img2
    ) public {
        fiberOrders[user_id].push(product_id);
        fiberInfos[product_id] = FiberInfo(
            product_id,
            employee_name,
            product_quantity,
            microscopic_test_result,
            tensile_test_result,
            fiber_type,
            BSTI_standards_accoradance,
            fiber_color_palette_img,
            img2
        );
        updateProductStatus(product_id, "IN APPAREL");
    }

    function getFiberInfo(uint256 product_id)
        public
        view
        returns (FiberInfo memory)
    {
        return fiberInfos[product_id];
    }

    function addFiberHash(uint256 product_id, string calldata hash) public {
        fiberHashes[product_id] = hash;
    }

    function getFiberHash(uint256 product_id)
        public
        view
        returns (string memory)
    {
        return fiberHashes[product_id];
    }

    function addApparelInfo(
        uint256 product_id,
        uint256 user_id,
        string memory thread_diameter,
        string memory thread_friction,
        string memory uniformity,
        string memory tensile_strength,
        string memory thread_count,
        string memory apparel_color_palette_img,
        string memory img2
    ) public {
        apparelOrders[user_id].push(user_id);
        apparelInfos[product_id] = ApparelInfo(
            product_id,
            thread_diameter,
            thread_friction,
            uniformity,
            tensile_strength,
            thread_count,
            apparel_color_palette_img,
            img2
        );
        updateProductStatus(product_id, "COMPLETE PRODUCTION");
    }

    function getApparelInfo(uint256 product_id)
        public
        view
        returns (ApparelInfo memory)
    {
        return apparelInfos[product_id];
    }

    function addApparelHash(uint256 product_id, string calldata hash) public {
        apparelHashes[product_id] = hash;
    }

    function getApparelHash(uint256 product_id)
        public
        view
        returns (string memory)
    {
        return apparelHashes[product_id];
    }

    // function getFiberOrders(uint256 user_id)
    //     public
    //     view
    //     returns (uint256[] memory)
    // {
    //     return fiberOrders[user_id];
    // }
}