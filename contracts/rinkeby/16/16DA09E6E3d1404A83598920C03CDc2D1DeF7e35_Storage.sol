// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Storage {
    struct ProductDetail {
        uint256 productId;
        uint256 timestamp;
        string description;
    }

    uint256 public productCount;
    ProductDetail[] public productDetails;

    function createProduct(string calldata _description) external {
        productCount++;
        productDetails.push(
            ProductDetail(productCount, block.timestamp, _description)
        );
    }

    function getInfoProduct(uint256 productId)
        external
        view
        returns (ProductDetail[] memory)
    {
        ProductDetail[] memory productInfo = new ProductDetail[](
            getInfoProductCount(productId)
        );
        uint256 len = 0;
        for (uint256 i = 0; i < productDetails.length; i++) {
            if (productDetails[i].productId == productId) {
                productInfo[len++] = productDetails[i];
            }
        }

        return productInfo;
    }

    function updateProduct(uint256 productId, string calldata _description)
        external
    {
        require(
            0 < productId && productId <= productCount,
            "Id product not exist"
        );
        productDetails.push(
            ProductDetail(productId, block.timestamp, _description)
        );
    }

    function getInfoProductCount(uint256 productId)
        internal
        view
        returns (uint256)
    {
        uint256 cnt = 0;
        for (uint256 i = 0; i < productDetails.length; i++) {
            if (productDetails[i].productId == productId) {
                cnt++;
            }
        }
        return cnt;
    }
}