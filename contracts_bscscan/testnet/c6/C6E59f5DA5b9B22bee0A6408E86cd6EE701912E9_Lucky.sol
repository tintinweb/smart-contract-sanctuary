// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IAttr.sol";

// value
struct LuckyType {
    uint256 minRange;
    uint256 maxRange;
    uint256 typeId;
}

struct IndexValue {
    uint256 keyIndex;
    LuckyType value;
}

struct KeyFlag {
    uint256 key;
    bool deleted;
}

struct itmap {
    mapping(uint256 => IndexValue) data;
    KeyFlag[] keys;
    uint256 size;
}

library IterableMapping {
    function insert(
        itmap storage self,
        uint256 key,
        LuckyType memory value
    ) internal returns (uint256 keyIndex, bool replaced) {
        keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0) replaced = true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            replaced = false;
        }
    }

    function remove_by_dict_key(itmap storage self, uint256 key)
        internal
        returns (bool success)
    {
        uint256 keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0) return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(itmap storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self)
        internal
        view
        returns (uint256 keyIndex)
    {
        return iterate_next(self, 10000000);
    }

    function iterate_valid(itmap storage self, uint256 keyIndex)
        internal
        view
        returns (bool)
    {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint256 keyIndex)
        internal
        view
        returns (uint256 r_keyIndex)
    {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get_by_array_key(itmap storage self, uint256 keyIndex)
        internal
        view
        returns (uint256 key, LuckyType memory value)
    {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function iterate_get_by_dict_key(itmap storage self, uint256 k)
        internal
        view
        returns (uint256 key, LuckyType memory value)
    {
        value = self.data[k].value;
        key = self.data[k].keyIndex;
    }
}

contract Lucky is Ownable, Context, Attr {
    constructor() {
        mktAddress = _msgSender();
    }

    modifier onlyUse() {
        require(use, "contract not use!");
        _;
    }

    bool public use;

    function setUse(bool status) public onlyOwner {
        use = status;
    }

    IERC721 public nftAddress;

    function setNftAddress(address nft) public onlyOwner {
        // require(nft != address(nftAddress), "nft address Currently in use!");
        nftAddress = IERC721(nft);
    }

    address public mktAddress;

    function setMktAddress(address mktAddr) public onlyOwner {
        require(
            mktAddr != address(mktAddress),
            "mktAddress address Currently in use!"
        );
        mktAddress = mktAddr;
    }

    IERC20 public tokenAddress;
    uint256 public luckyPrice;

    function setLuckPrice(uint256 price) public onlyOwner {
        require(price > 100, "price must be gt 100!");
        luckyPrice = price;
    }

    function setTokenAddress(address token) public onlyOwner {
        require(
            token != address(tokenAddress),
            "token address Currently in use!"
        );
        tokenAddress = IERC20(token);
    }

    function tokenAddressTransFrom() internal {
        if (address(tokenAddress) != address(0)) {
            // token
            IERC20(tokenAddress).transferFrom(
                _msgSender(),
                mktAddress,
                luckyPrice
            );
        } else {
            // eth
            require(msg.value == luckyPrice, "msg.value Too little");
            payable(mktAddress).transfer(address(this).balance);
        }
    }

    itmap LuckyTypeMap;
    using IterableMapping for itmap;

    function getLuckyTypeMapByDictKey(uint256 key)
        public
        view
        returns (LuckyType memory value)
    {
        (, value) = LuckyTypeMap.iterate_get_by_dict_key(key);
    }

    function getLuckyTypeMapByArrayKey(uint256 key)
        public
        view
        returns (LuckyType memory value)
    {
        (, value) = LuckyTypeMap.iterate_get_by_array_key(key);
    }

    function addLuckyTypeMap(uint256 key, LuckyType memory template)
        public
        onlyOwner
        returns (uint256, bool flag)
    {
        return LuckyTypeMap.insert(key, template);
    }

    function DelLuckyTypeeMap(uint256 key) public onlyOwner returns (bool) {
        return LuckyTypeMap.remove_by_dict_key(key);
    }

    LuckyType[] public allTemplateList;

    function userGetAllLuckTypeMap() public view returns (LuckyType[] memory) {
        return allTemplateList;
    }

    function getAllLuckTypeMap() public onlyOwner returns (LuckyType[] memory) {
        delete allTemplateList;
        for (uint256 i = 0; i < LuckyTypeMap.keys.length; i++) {
            if (LuckyTypeMap.keys[i].deleted) {
                continue;
            }
            (, LuckyType memory value) = LuckyTypeMap.iterate_get_by_array_key(
                i
            );
            allTemplateList.push(value);
        }
        return allTemplateList;
    }

    // 随机数种子
    uint32[5] private randomSeed;
    
    function genRandomSeed(uint32[5] memory _randomSeed)public onlyOwner{
        randomSeed = _randomSeed;
    }
    
    function insertRandomSeed(uint32 newNum)internal returns(uint32){
        uint32 returnNum = randomSeed[randomSeed.length -1];
        for(uint256 i = randomSeed.length -1; i > 0; i--){
            randomSeed[i]=randomSeed[i-1];
        }
        randomSeed[0]=newNum;
        
        return returnNum;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender.balance
                )
            )
        );
        uint32 popNum = insertRandomSeed(uint32(random));
        random += popNum; 
        return random % _length;
    }

    uint32 public maxNum;
    uint32 public curNum;
    function setMaxNum(uint32 _num) public onlyOwner{
        maxNum = _num;
    }

    function isContractaddr(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    mapping(address => bool) public contractWhitelist;

    function updateContractWhitelist(address newAddress, bool flag) public onlyOwner {
        require(contractWhitelist[newAddress] != flag, "The contractWhitelist already has that address");
        contractWhitelist[newAddress] = flag;
    }
    event LuckyDog(address indexed, NftInfo);

    function lucky()
        public
        payable
        onlyUse
        returns (NftInfo memory info, uint256 randomNum)
    {
        require(curNum <= maxNum || maxNum == 0, "current num > max num!");
        
        if(isContractaddr(msg.sender)){
            require(contractWhitelist[msg.sender], "sender is contract, not in whitelist");
        }

        tokenAddressTransFrom();

        randomNum = rand(1000);

        uint256 typeId = 0;
        for (uint256 i = 0; i < LuckyTypeMap.keys.length; i++) {
            if (LuckyTypeMap.keys[i].deleted) {
                continue;
            }
            (, LuckyType memory value) = LuckyTypeMap.iterate_get_by_array_key(
                i
            );
            if (randomNum >= value.minRange && randomNum <= value.maxRange) {
                typeId = value.typeId;
                break;
            }
        }

        // 寻找attr合约生成卡牌对应详细属性
        info = nftAttrAddress.genearteNftInfo(typeId);
        nftAddress.mint(_msgSender(), info.tokenId, info.uri);
        curNum += 1;
        emit LuckyDog(_msgSender(), info);
    }

    receive() external payable {}

    function OwnerSafeWithdrawalEth(uint256 amount) public onlyOwner {
        if (amount == 0) {
            payable(owner).transfer(address(this).balance);
            return;
        }
        payable(owner).transfer(amount);
    }

    function OwnerSafeWithdrawalToken(address token_address, uint256 amount)
        public
        onlyOwner
    {
        IERC20 token_t = IERC20(token_address);
        if (amount == 0) {
            token_t.transfer(owner, token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner, amount);
    }
}