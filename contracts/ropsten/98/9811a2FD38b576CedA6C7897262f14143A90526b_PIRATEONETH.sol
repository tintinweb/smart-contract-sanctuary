/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// website : pirateon.eth
// version : 0.01

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract PIRATEONETH is Owned {
    struct Queue {
        string episode;
        string title;
        string year;
        string category;
        string language;
        string quality;
        string contenthash;
        address owner;
    }

    Queue[] public datamap;

    mapping(string => bool) private dublicatePrevent;
    mapping(string => uint256) public spamscore;

    function add(
        string memory _episode,
        string memory _title,
        string memory _year,
        string memory _category,
        string memory _language,
        string memory _quality,
        string memory _contenthash
    ) public {
        require(dublicatePrevent[_contenthash] == false, "Dublicate Entry");
        require(filter_category[_category] == true, "Invalid Filter");
        require(filter_language[_language] == true, "Invalid Filter");
        require(filter_quality[_quality] == true, "Invalid Filter");

        Queue memory m;

        m.title = _title;
        m.year = _year;
        m.category = _category;
        m.language = _language;
        m.quality = _quality;
        m.contenthash = _contenthash;
        m.owner = msg.sender;
        m.episode = _episode;

        datamap.push(m);

        dublicatePrevent[_contenthash] = true;
    }

    function reportSpam(string memory _contenthash) public {
        spamscore[_contenthash] = spamscore[_contenthash] + 1;
    }

    function getLength() public view returns (uint256) {
        return datamap.length;
    }

    // filters
    mapping(string => bool) public filter_category;
    mapping(string => bool) public filter_language;
    mapping(string => bool) public filter_quality;

    function admin_filter_category(string memory _v) public onlyOwner {
        filter_category[_v] = true;
    }

    function admin_filter_language(string memory _v) public onlyOwner {
        filter_language[_v] = true;
    }

    function admin_filter_quality(string memory _v) public onlyOwner {
        filter_quality[_v] = true;
    }
}