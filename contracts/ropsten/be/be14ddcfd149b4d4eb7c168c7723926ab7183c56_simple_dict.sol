pragma solidity >=0.5.2 <0.6.0;
pragma experimental ABIEncoderV2;

contract simple_dict {
    struct Advertisement {
        string title;
        string url;
        uint256 price;
    }

    mapping(string => Advertisement) ads;

    function set_ad(string memory key, Advertisement memory ad) public {
        ads[key] = ad;
    }
    
    function get_ad(string memory key) public view returns (Advertisement memory ad) {
        return ads[key];
    }
}