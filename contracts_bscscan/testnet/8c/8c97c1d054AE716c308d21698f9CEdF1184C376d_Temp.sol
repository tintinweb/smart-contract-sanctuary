//SPDX-License-Identifier: MIT

import "./libs...ERC721.sol";
import "./libs...Counters.sol";
import "./libs...Context.sol";
import "./libs...IERC20.sol";
import "./Ref.sol";

pragma solidity ^0.8.0;

// library IterableMapping {
//     // Iterable mapping from address to uint;
//     struct Map {
//         address[] keys;
//         mapping(address => uint256) values;
//         mapping(address => uint256) indexOf;
//         mapping(address => bool) inserted;
//     }

//     function get(Map storage map, address key) public view returns (uint256) {
//         return map.values[key];
//     }

//     function getIndexOfKey(Map storage map, address key)
//         public
//         view
//         returns (int256)
//     {
//         if (!map.inserted[key]) {
//             return -1;
//         }
//         return int256(map.indexOf[key]);
//     }

//     function getKeyAtIndex(Map storage map, uint256 index)
//         public
//         view
//         returns (address)
//     {
//         return map.keys[index];
//     }

//     function size(Map storage map) public view returns (uint256) {
//         return map.keys.length;
//     }

//     function set(
//         Map storage map,
//         address key,
//         uint256 val
//     ) public {
//         if (map.inserted[key]) {
//             map.values[key] = val; // Update value if already inserted
//         } else {
//             map.inserted[key] = true; // new insert
//             map.values[key] = val;
//             map.indexOf[key] = map.keys.length;
//             map.keys.push(key);
//         }
//     }

//     function remove(Map storage map, address key) public {
//         if (!map.inserted[key]) {
//             return;
//         }

//         delete map.inserted[key];
//         delete map.values[key];

//         uint256 index = map.indexOf[key];
//         uint256 lastIndex = map.keys.length - 1;
//         address lastKey = map.keys[lastIndex];

//         map.indexOf[lastKey] = index;
//         delete map.indexOf[key];

//         map.keys[index] = lastKey;
//         map.keys.pop();
//     }
// }

contract Temp is ERC721, Ownable {
    using Counters for Counters.Counter;
    using IterableMapping for IterableMapping.Map;

    struct ReferrerEntity {
        uint256 creationTime;
        address account;
        string referrerCode;
        uint256 rewardAmount;
    }

    IterableMapping.Map private referrers;
    mapping(address => string[]) private _subRefOfUser;
    mapping(string => ReferrerEntity) private _refInfoOfUser;

    Counters.Counter private _tokenIds;

    RefToken public token;
    address public tokenAddress = 0xc39ed113b8cf23f8370C9DC127D44c1D06E232D4;

    uint256 public refFee = 33;
    uint256 public escowFee = 33;

    address public primaryDevAddress = 0xCE048999dCa1e5895496E12b2458e02d137e1be2;
    address public secondaryDevAddress = 0xf31B2199C6322d6275a6f36bC4d338e15637C56A;

    uint256 public referralDeadline = 100 * 60;
    uint256 public mintingPrice = 100;
    uint256 public mintingPriceWithRef = 75;
    string public baseTokenURI;

    constructor() ERC721("tokenName", "symbol") {
        token = RefToken(tokenAddress);
        // token.payForNFT(0x6Dc984c9bEd938F139CF4C89709c732EF34B3048, 100);
        // payToMintWithoutReferrer(_msgSender(), "123");
        // payToMintWithReferrer(_msgSender(), "12345", "123");
    }

    function mintNFT(address owner) public returns (uint256)
    {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);

        return id;
    }

    function getReferrerEntity(string calldata usercode) external view returns (uint256, address, string  memory, uint256) {
        ReferrerEntity memory ref = _refInfoOfUser[usercode];
        return (ref.creationTime, ref.account, ref.referrerCode, ref.rewardAmount);
    }

    function payToMintWithoutReferrer(address creator, string memory usercode) public returns (bool) {
        // string memory empty = "";
        // require(keccak256(bytes(usercode)) != keccak256(bytes(empty)), "ERROR:  user code shouldn't be empty");
        require(bytes(usercode).length != 0, "ERROR:  user code shouldn't be empty");
        require(creator != address(0), "CSHT:  creation from the zero address");
        require(_refInfoOfUser[usercode].account == address(0), "usercode is already used");

        _refInfoOfUser[usercode] = ReferrerEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: "",
            rewardAmount: 0
        });
        
        token.pay(creator, primaryDevAddress, mintingPrice * 10**18);

        return true;
    }

    function payToMintWithReferrer(address creator, string memory usercode, string memory referrerCode) public returns (bool) {
        string memory empty = "";
        require(keccak256(bytes(usercode)) != keccak256(bytes(empty)), "ERROR:  user code shouldn't be empty");
        require(keccak256(bytes(referrerCode)) != keccak256(bytes(empty)), "ERROR:  referrer code shouldn't be empty");
        require(creator != address(0), "CSHT:  creation from the zero address");
        require(_refInfoOfUser[referrerCode].account != address(0), "usercode isn't registered");
        require(_refInfoOfUser[usercode].account == address(0), "usercode is already used");

        uint256 escrowAmount = (mintingPriceWithRef * escowFee) / 100;
        uint256 refAmount = (mintingPriceWithRef * refFee) / 100;
        uint256 devAmount = mintingPriceWithRef - escrowAmount - refAmount;

        _refInfoOfUser[usercode] = ReferrerEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: referrerCode,
            rewardAmount: escrowAmount
        });

        ReferrerEntity memory _ref = _refInfoOfUser[referrerCode];
        _subRefOfUser[_ref.account].push(usercode);

        if (_ref.rewardAmount > 0 && keccak256(bytes(_ref.referrerCode)) != keccak256(bytes(empty)))
        {
            ReferrerEntity memory _parentRef = _refInfoOfUser[_ref.referrerCode];
            if (block.timestamp - _ref.creationTime < referralDeadline) {
                token.pay(secondaryDevAddress, _parentRef.account, _ref.rewardAmount * 10**18);    
            } 
            ReferrerEntity storage _refT = _refInfoOfUser[referrerCode];
            _refT.rewardAmount = 0;
        }

        token.pay(creator, _ref.account, refAmount * 10**18);
        token.pay(creator, secondaryDevAddress, escrowAmount * 10**18);
        token.pay(creator, primaryDevAddress, devAmount * 10**18);

        return true;
    }

    function getSubReferral() external view returns (string memory) {
        string[] memory subRefs = _subRefOfUser[_msgSender()];
        ReferrerEntity memory _ref;
        string memory refsStr = "";
        string memory separator = "#";
        
        for (uint256 i=0; i<subRefs.length; i++) {
            _ref = _refInfoOfUser[subRefs[i]];
            refsStr = string(abi.encodePacked(refsStr, separator, _ref.account));
            refsStr = string(abi.encodePacked(refsStr, separator, _ref.creationTime));
            refsStr = string(abi.encodePacked(refsStr, separator, _ref.rewardAmount));
        }

        return refsStr;
    }

    function getMintPrice() external view returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 newMintingPrice) external onlyOwner {
        mintingPrice = newMintingPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

}