/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

contract Apparel {
    uint256 uuid = 0;

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

    mapping(uint256 => uint256[]) productOrders;
    mapping(uint256 => uint256[]) fiberOrders;
    mapping(uint256 => FiberInfo) fiberInfos;

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
    }

    function getFiberOrders(uint256 user_id)
        public
        view
        returns (uint256[] memory)
    {
        return fiberOrders[user_id];
    }

    function getFiberInfo(uint256 product_id)
        public
        view
        returns (FiberInfo memory)
    {
        return fiberInfos[product_id];
    }
}