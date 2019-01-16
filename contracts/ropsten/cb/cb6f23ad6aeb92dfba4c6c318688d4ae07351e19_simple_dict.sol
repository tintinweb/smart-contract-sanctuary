pragma solidity ^0.4.20;
//pragma experimental ABIEncoderV2;

contract simple_dict {
    // struct Advertisement {
    //     bytes[] title;
    //     bytes[] url;
    //     uint256 price;
    // }
    
    //ads
    mapping(string => bytes32) ads_titles;
    mapping(string => bytes32) ads_urls;
    mapping(string => uint256) ads_prices;

    function set_ad(string memory key, bytes32 title_, bytes32 url_, uint256 price_) public {
        ads_urls[key] = url_;
        ads_titles[key] = title_;
        ads_prices[key] = price_;
    }
    
    // function get_ad(string memory key) public view returns (bytes32 title_, bytes32 url_, uint256 price_) {
    //     title_ = ads_titles[key];
    //     url_ = ads_urls[key];
    //     price_ = ads_prices[key];
    // }
    
    function get_ad_title(string memory key) public view returns (bytes32 title_){
        title_ = ads_titles[key];
    }

    function get_ad_price(string memory key) public view returns (uint256 price_){
        price_ = ads_prices[key];
    }

    
    // function get_kek() public view returns (Advertisement memory ad)
    // {
    //     returns ads["kek"];
    // }
    
    // function get_ads() public view returns (mapping(string ) memory )
    // {
    //     returns ads["kek"];
    // }

}