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
    mapping(string => ReferrerEntity) private _refInfoOfUser;

    Counters.Counter private _tokenIds;

    RefToken public token;
    address public tokenAddress = 0xc39ed113b8cf23f8370C9DC127D44c1D06E232D4;

    uint256 public devFee = 75;
    uint256 public refFee = 33;
    uint256 public escowFee = 33;

    address public devAddress = 0x6Dc984c9bEd938F139CF4C89709c732EF34B3048;

    uint256 public referralDeadline = 100 * 1000;
    uint256 public mintingPrice = 100;
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

    function getReferrerEntity(string memory usercode) external view returns (uint256, address, string  memory, uint256) {
        ReferrerEntity memory ref = _refInfoOfUser[usercode];
        return (ref.creationTime, ref.account, ref.referrerCode, ref.rewardAmount);
    }

    function payToMintWithoutReferrer(address creator, string memory usercode) public returns (bool) {
        string memory empty = "";
        require(keccak256(bytes(usercode)) != keccak256(bytes(empty)), "ERROR:  user code shouldn't be empty");
        require(creator != address(0), "CSHT:  creation from the zero address");
        require(_refInfoOfUser[usercode].account == address(0), "usercode is already used");

        _refInfoOfUser[usercode] = ReferrerEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: "",
            rewardAmount: 0
        });

        uint256 devAmount = (mintingPrice * devFee) / 100;
        uint256 rewardAmount = mintingPrice - devAmount;
        
        token.pay(creator, devAddress, devAmount * 10**18);
        token.pay(creator, tokenAddress, rewardAmount * 10**18);

        return true;
    }

    function payToMintWithReferrer(address creator, string memory usercode, string memory referrerCode) public returns (bool) {
        string memory empty = "";
        require(keccak256(bytes(usercode)) != keccak256(bytes(empty)), "ERROR:  user code shouldn't be empty");
        require(keccak256(bytes(referrerCode)) != keccak256(bytes(empty)), "ERROR:  referrer code shouldn't be empty");
        require(creator != address(0), "CSHT:  creation from the zero address");
        require(_refInfoOfUser[referrerCode].account != address(0), "usercode isn't registered");
        require(_refInfoOfUser[usercode].account == address(0), "usercode is already used");

        uint256 escrowAmount = (mintingPrice * escowFee) / 100;
        uint256 rewardAmount = (mintingPrice * refFee) / 100;
        uint256 distriAmount = mintingPrice - escrowAmount - rewardAmount;

        _refInfoOfUser[usercode] = ReferrerEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: referrerCode,
            rewardAmount: escrowAmount
        });

        ReferrerEntity memory _ref = _refInfoOfUser[referrerCode];

        if (_ref.rewardAmount > 0 && keccak256(bytes(_ref.referrerCode)) != keccak256(bytes(empty)))
        {
            ReferrerEntity memory _parentRef = _refInfoOfUser[_ref.referrerCode];
            if (block.timestamp - _ref.creationTime < referralDeadline) {
                token.pay(devAddress, _parentRef.account, _ref.rewardAmount * 10**18);    
            } 
            ReferrerEntity storage _refT = _refInfoOfUser[referrerCode];
            _refT.rewardAmount = 0;
        }

        token.pay(creator, _ref.account, rewardAmount * 10**18);
        token.pay(creator, devAddress, escrowAmount * 10**18);
        token.pay(creator, tokenAddress, distriAmount * 10**18);

        return true;
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