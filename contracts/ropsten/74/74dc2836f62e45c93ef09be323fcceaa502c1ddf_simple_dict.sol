pragma solidity ^0.4.20;
//pragma experimental ABIEncoderV2;

contract simple_dict {
    struct Advertisement {
        string title;
        string url;
        uint256 price;
    }

    mapping(string => Advertisement) ads;

    function set_ad(string memory key, string title_, string url_, uint256 price_) public {
        Advertisement memory ad;
        ad.title = title_;
        ad.url = url_;
        ad.price = price_;
        ads[key] = ad;
    }
    
    function get_ad(string memory key) public view returns (string title_, string url_, uint256 price_) {
        Advertisement memory ad;
        ad = ads[key];
        title_ = ad.title;
        url_ = ad.url;
        price_ = ad.price;
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