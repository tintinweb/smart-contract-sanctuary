/**
 *Submitted for verification at polygonscan.com on 2021-11-22
*/

// File: dm/contracts/lib/Lottery.sol

pragma solidity ^0.8.0;


library Lottery{
    
    struct LotteryValue{
        uint256 minValue;
        uint256 maxValue;
    }
    
    function random(uint256[] memory _list, bytes memory _seed) external pure returns(uint256 index_, uint256 max_, uint256 winNumber_){
        require(_list.length > 0, "list length not 0");
        
        uint256 min = 0;
        uint256 max = 0;
        LotteryValue[] memory temp = new LotteryValue[](_list.length);
        for(uint256 i = 0; i != _list.length; ++i){
            min = max;
            max += _list[i];
            temp[i] = (LotteryValue({
                minValue : min,
                maxValue : max
            }));
        }
        
        //bytes memory randomInfo = abi.encodePacked(block.timestamp, _seed);
        //bytes32 randomHash = keccak256(randomInfo);
        bytes32 randomHash = keccak256(_seed);
        max_ = max;
        winNumber_ = uint256(randomHash) % max;
        index_ = 0;
        for(uint256 i = 0; i != _list.length; ++i){
            uint minValue = temp[i].minValue;
            uint maxValue = temp[i].maxValue;
            if(minValue != maxValue && winNumber_ >= minValue && winNumber_ < maxValue){
                index_ = i;
                break;
            }
        }
    }

    //取指定区间的随机数
    function randomNum(uint256 _min, uint256 _max, bytes memory _seed) external pure returns(uint256){
        if(_max <= _min){
            return _max;
        }

        uint256 count = _max - _min;
        bytes32 randomHash = keccak256(_seed);
        uint256 winNumber = uint256(randomHash) % count;
        return _min + winNumber;
    }
}
// File: dm/contracts/interface/IDragonInfo.sol

pragma solidity ^0.8.0;


interface IDragonInfo {
    function checkValid(uint32 _type, uint8 _size) external view returns(bool);
    function getTypeSizes(uint32 _type) external view returns(uint8[] memory);

    function open(uint32 _type, uint8 _size, bytes32 _bh) external view returns(uint16[] memory nameIds_, uint32[] memory values_);
    function open(uint256 _id, uint256 _blocknumber) external view returns(uint16[] memory nameIds_, uint32[] memory values_);
}
// File: dm/contracts/Owner.sol

pragma solidity ^0.8.0;


abstract contract Owner {
    address public owner = msg.sender;
    
    modifier OwnerOnly {
        require(msg.sender == owner, "contract owner only");
        _;
    }
}

// File: dm/contracts/DragonInfo2.sol

pragma solidity ^0.8.0;





contract DragonInfo2 is IDragonInfo,Owner{
    struct OpenRateType{
        uint32 min;
        uint32 max;
        uint16 rate;
    }
    
    struct OpenRateTypeRet{
        uint16 propId;
        uint32 min;
        uint32 max;
        uint16 rate;
    }
    
    //type => (size => (propId => rates))
    mapping(uint32 => mapping(uint8 => mapping(uint16 => OpenRateType[]))) specialPropRates;
    //type => propIds
    mapping(uint32 => uint16[]) dragonProperties;
    //type => sizeIds
    mapping(uint32 => uint8[]) dragonSizes;
    //types
    uint32[] public dragonTypes;
    
    //propId => (size => rates)
    mapping(uint16 => mapping(uint8 => OpenRateType[])) basePropRates;

    constructor() {
        init();
        initProp();
        //attack
        _initBaseRatesItem(0, [uint32(51), 31, 16, 6], [uint32(101), 51, 31, 16]);
        //weight
        _initBaseRatesItem(1, [uint32(6), 21, 41, 71], [uint32(21), 41, 71, 121]);
        //speed
        _initBaseRatesItem(2, [uint32(100), 100, 100, 100], [uint32(100), 100, 100, 100]);
        //durability
        _initBaseRatesItem(3, [uint32(200), 200, 200, 200], [uint32(200), 200, 200, 200]);
        
        _initSpecialPropRates();
    }
    
    function init() internal {
        delete dragonTypes;
        uint32[18] memory types = [uint32(0),1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];
        dragonTypes = types;
        
        uint8[4] memory normalSizes = [uint8(0), 1, 2, 3];
        for(uint32 i = 0; i != 11; ++i){
            dragonSizes[i] = normalSizes;
        }
        
        uint8[1] memory lSizes = [uint8(2)];
        for(uint32 i = 11; i != 16; ++i){
            dragonSizes[i] = lSizes;
        }
        
        dragonSizes[16] = [3];
        dragonSizes[17] = [1];
    }
    
    function initProp() internal {
        uint16[4] memory normalSkills = [uint16(0),1,2,3];
        dragonProperties[0] = normalSkills;
        dragonProperties[1] = normalSkills;
        dragonProperties[7] = normalSkills;
        dragonProperties[12] = normalSkills;
        dragonProperties[17] = normalSkills;
        
        dragonProperties[2] = [uint16(0),1,2,3,4];
        dragonProperties[3] = [uint16(0),1,2,3,5];
        dragonProperties[5] = [uint16(0),1,2,3,8];
        dragonProperties[6] = [uint16(0),1,2,3,9];
        dragonProperties[8] = [uint16(0),1,2,3,10];
        dragonProperties[9] = [uint16(0),1,2,3,11];
        dragonProperties[11] = [uint16(0),1,2,3,13];
        dragonProperties[13] = [uint16(0),1,2,3,18];
        dragonProperties[14] = [uint16(0),1,2,3,14];
        dragonProperties[15] = [uint16(0),1,2,3,17];
        
        dragonProperties[4] = [uint16(0),1,2,3,6,7];
        dragonProperties[16] = [uint16(0),1,2,3,15,16];
        
        dragonProperties[10] = [uint16(0),1,2,3,12,19,20];
    }
    
    function _initBaseRatesItem(uint16 _propId, uint32[4] memory _mins, uint32[4] memory _maxs) internal{
        basePropRates[_propId][0].push(OpenRateType({min:_mins[0], max:_maxs[0], rate:100}));
        basePropRates[_propId][1].push(OpenRateType({min:_mins[1], max:_maxs[1], rate:100}));
        basePropRates[_propId][2].push(OpenRateType({min:_mins[2], max:_maxs[2], rate:100}));
        basePropRates[_propId][3].push(OpenRateType({min:_mins[3], max:_maxs[3], rate:100}));
    }
    
    function _initSpecialPropRates() internal {
        OpenRateType memory baseRate = OpenRateType({min:1, max:101, rate:100});
        uint length = dragonTypes.length;
        for(uint32 i = 0; i != length; ++i){
            uint32 dragonType = dragonTypes[i];
            uint8[] memory sizes = dragonSizes[dragonType];
            uint sizeLength = sizes.length;
            for(uint h = 0; h != sizeLength; ++h){
                uint8 size = sizes[h];
                uint16[] memory dps = dragonProperties[dragonType];
                uint propLength = dps.length;
                if(propLength > 4){
                    //init special prop
                    for(uint m = 4; m != propLength; ++m){
                        uint16 propId = dps[m];
                        if(5 == propId){
                            specialPropRates[dragonType][size][propId].push(OpenRateType({min:1, max:1001, rate:100}));
                        }else if(9 == propId){
                            specialPropRates[dragonType][size][propId].push(OpenRateType({min:1, max:11, rate:100}));
                        }else if(12 == propId || 13 == propId){
                            specialPropRates[dragonType][size][propId].push(OpenRateType({min:1, max:51, rate:100}));
                        }else if(20 == propId){
                            specialPropRates[dragonType][size][propId].push(OpenRateType({min:51, max:101, rate:100}));
                        }else{
                            specialPropRates[dragonType][size][propId].push(baseRate);
                        }
                    }
                }
            }
        }
    }
    

    function checkValid(uint32 _type, uint8 _size) external view override returns(bool){
        return checkType(_type) && checkSize(_type, _size);
    }
    
    function checkType(uint32 _type) internal view returns(bool){
        uint length = dragonTypes.length;
        for(uint i = 0; i != length; ++i){
            if(_type == dragonTypes[i]){
                return true;
            }
        }
        
        return false;
    }
    
    function checkSize(uint32 _type, uint8 _size) internal view returns(bool){
        uint8[] memory ds = dragonSizes[_type];
        uint length = ds.length;
        for(uint i = 0; i != length; ++i){
            if(_size == ds[i]){
                return true;
            }
        }
        
        return false;
    }

    function getDragonTypes() public view returns(uint32[] memory){
        return dragonTypes;
    }

    //设置类型
    function setTypes(uint32[] memory _types) public OwnerOnly{
        delete dragonTypes;
        uint256 length = _types.length;
        for(uint256 i = 0; i != length; ++i){
            dragonTypes.push(_types[i]);
        }
    }
    
    function setSizes(uint32 _type, uint8[] memory _sizes) public OwnerOnly{
        require(checkType(_type), "DRAGON_INFO_ERROR:type not exist");
        dragonSizes[_type] = _sizes;
    }
    
    function getTypeSizes(uint32 _type) external view override returns(uint8[] memory){
        return dragonSizes[_type];
    }

    //--------------------------------------------------------------
    function getBaseRates(uint16 _propId, uint8 _size) public view returns(OpenRateType[] memory result_) {
        require(_propId < 4, "DRAGON_INFO_ERROR:Only basic attributes are supported");
        return basePropRates[_propId][_size];
    }
    
    function setBaseRates(uint16 _propId, uint8 _size, uint32[] memory _min, uint32[] memory _max, uint16[] memory _rates) public OwnerOnly{
        require(_propId < 4, "DRAGON_INFO_ERROR:Only basic attributes are supported");
        uint256 length = _min.length;
        require(length > 0 && length == _max.length && length == _rates.length, "DRAGON_INFO_ERROR:params error");
        OpenRateType[] storage rates = basePropRates[_propId][_size];
        delete basePropRates[_propId][_size];
        for(uint i = 0; i != length; ++i){
            rates.push(OpenRateType({min:_min[i], max:_max[i], rate:_rates[i]}));
        }
    }
    
    
    function getRates(uint32 _typeId, uint8 _size) public view returns(OpenRateTypeRet[] memory result_) {
        require(checkType(_typeId) && checkSize(_typeId, _size), "DRAGON_INFO_ERROR:type or size not exist");
        
        uint resultLength = 0;
        uint16[] memory dp = dragonProperties[_typeId];
        uint dpLength = dp.length;
        if(dpLength < 5){
            return new OpenRateTypeRet[](0);
        }
        
        for(uint m = 4; m != dpLength; ++m){
            resultLength += specialPropRates[_typeId][_size][dp[m]].length;
        }
        
        result_ = new OpenRateTypeRet[](resultLength);
        uint retIndex = 0;
        for(uint m = 4; m != dpLength; ++m){
            uint16 _propId = dp[m];
            OpenRateType[] memory ort = specialPropRates[_typeId][_size][_propId];
            uint ortLength = ort.length;
            for(uint h = 0; h != ortLength; ++h){
                result_[retIndex++] = OpenRateTypeRet({propId:_propId, min: ort[h].min, max: ort[h].max, rate: ort[h].rate});
            }
        }
    }

    function setRates(uint32 _type, uint8 _size, uint16 _propId, uint32[] memory _min, uint32[] memory _max, uint16[] memory _rates) public OwnerOnly{
        require(_propId > 3, "DRAGON_INFO_ERROR:Only special attributes can be set");
        require(checkType(_type), "DRAGON_INFO_ERROR:type not exist");
        require(checkSize(_type, _size), "DRAGON_INFO_ERROR:size not exist");
        uint256 length = _min.length;
        require(length > 0 && length == _max.length && length == _rates.length, "DRAGON_INFO_ERROR:params error");

        OpenRateType[] storage rates = specialPropRates[_type][_size][_propId];
        delete specialPropRates[_type][_size][_propId];
        for(uint i = 0; i != length; ++i){
            rates.push(OpenRateType({min:_min[i], max:_max[i], rate:_rates[i]}));
        }

        _updateProperties(_type, _propId, true);
    }

    function delRates(uint32 _type, uint16 _propId) public OwnerOnly {
        require(_propId > 3, "DRAGON_INFO_ERROR:Only special attributes can be delete");
        uint8[] memory sizes = dragonSizes[_type];
        uint length = sizes.length;
        for(uint i = 0; i != length; ++i){
            delete specialPropRates[_type][sizes[i]][_propId];
        }
        
        _updateProperties(_type, _propId, false);
    }

    function _updateProperties(uint32 _type, uint16 _propId, bool _add) internal {
        uint16[] storage props = dragonProperties[_type];
        uint256 length = props.length;
        uint i = 0;
        for(; i != length; ++i){
            if(_propId == props[i]){
                break;
            }
        }

        if(_add){
            if(i == length){
                props.push(_propId);
            }
        }else{
            if(i != length){
                props[i] = props[length-1];
                props.pop();
            }
        }
    }

    function open(uint32 _type, uint8 _size, bytes32 _bh) external view override returns(uint16[] memory nameIds_, uint32[] memory values_){
        bytes memory bh = abi.encode(_bh, _type, _size);
        return _open(bh, _type, _size);
    }

    function open(uint256 _id, uint256 _blocknumber) external view override returns(uint16[] memory nameIds_, uint32[] memory values_) {
        //TODO 取上一个区块的hash为随机数
        bytes32 _bh = blockhash(block.number-1);
        bytes memory bh = abi.encode(_bh, _id, _blocknumber);
        return _open(bh, uint32(_id >> 64), uint8(_id >> 96));
    }

    function _open(bytes memory _bh, uint32 _type, uint8 _size) internal view returns(uint16[] memory nameIds_, uint32[] memory values_){
        uint16[] memory props = dragonProperties[_type];
        uint propLength = props.length;
        nameIds_ = new uint16[](propLength);
        values_ = new uint32[](propLength);
        for(uint i = 0; i != propLength; ++i){
            OpenRateType[] memory rates;
            if(i < 4){
                rates = basePropRates[props[i]][_size];
            }else{
                rates = specialPropRates[_type][_size][props[i]];
            }
            
            uint rateLength = rates.length;
            require(rates.length > 0, "DRAGON_INFO_ERROR:No corresponding configuration");

            //第一步随机区间，第二步随机值
            uint index = 0;
            if(rateLength != 1){
                uint256[] memory tempRates = new uint256[](rateLength);
                for(uint m = 0; m != rateLength; ++m){
                    tempRates[m] = rates[m].rate;
                }

                //第一步随机区间
                _bh = abi.encode(_bh, i);
                (index,,) = Lottery.random(tempRates, _bh);
            }

            //第二步随机值
            _bh = abi.encode(_bh, i);
            nameIds_[i] = props[i];
            values_[i] = uint32(Lottery.randomNum(rates[index].min, rates[index].max, _bh));
        }
    }
}