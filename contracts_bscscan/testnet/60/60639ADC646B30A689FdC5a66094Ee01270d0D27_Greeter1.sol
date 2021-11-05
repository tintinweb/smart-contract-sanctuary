// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

struct FFFF
{
    uint8   Type;
    uint8   Count;
    string  Name;

    uint256 TotalCount;
    uint256 ChildCount;
}

struct CCCCCC
{
    uint256 NodeCount;
    mapping(uint8 => CCCCCC) Next;
}

contract Greeter1
{
    uint8 constant public MAX_FEATURE_TYPE          = 16;       //[1-16]
    uint8 constant public MAX_FEATURE_TYPE_COUNT    = 255;      //[1-255]

    FFFF[MAX_FEATURE_TYPE+1] internal m_FeatureType;
    CCCCCC internal m_FeatureChainRoot;

    constructor()
    {
        m_FeatureType[1] = FFFF(1, 3, "a1", 0, 0); 
        m_FeatureType[2] = FFFF(2, 3, "a2", 0, 0);
        m_FeatureType[3] = FFFF(3, 3, "a3", 0, 0);
        m_FeatureType[4] = FFFF(4, 3, "a4", 0, 0);
        m_FeatureType[5] = FFFF(5, 0, "a5", 0, 0);  
        m_FeatureType[6] = FFFF(6, 0, "a6", 0, 0);     

        m_FeatureType[7] = FFFF(7, 50, "unknown", 0, 0);
        m_FeatureType[8] = FFFF(8, 50, "unknown", 0, 0);
        m_FeatureType[9] = FFFF(9, 50, "unknown", 0, 0);
        m_FeatureType[10] = FFFF(10, 50, "unknown", 0, 0);
        m_FeatureType[11] = FFFF(11, 50, "unknown", 0, 0);
        m_FeatureType[12] = FFFF(12, 50, "unknown", 0, 0);
        m_FeatureType[13] = FFFF(13, 50, "unknown", 0, 0);
        m_FeatureType[14] = FFFF(14, 50, "unknown", 0, 0);
        m_FeatureType[15] = FFFF(15, 50, "unknown", 0, 0);
        m_FeatureType[16] = FFFF(16, 50, "unknown", 0, 0);

        _refreshFeatureCount(MAX_FEATURE_TYPE);
    }
    
    function Test() public returns(uint8[MAX_FEATURE_TYPE] memory)
    {
        uint8[MAX_FEATURE_TYPE] memory return_feature;

        for(uint8 i = 0; i < MAX_FEATURE_TYPE - 1; ++i)
        {
           uint8[] memory get_list = GetFeatureType(return_feature, i);
           
            require(get_list.length > 0, "get list err!");
            
            return_feature[i] = get_list[0];
        }
        
        SetFeatureType(return_feature);
        
        return return_feature;
    }

    function destroyC() public
    {
        selfdestruct(payable(msg.sender)); // 销毁合约
    }

    function GetFeatureType(uint8[MAX_FEATURE_TYPE] memory feature_sequence, uint8 next_feature) internal view returns(uint8[] memory)
    {
        uint8[] memory valid_feature;

        //find feature chain
        CCCCCC storage findChain = m_FeatureChainRoot;
        FFFF storage find_feature = m_FeatureType[0];

        for (uint8 i = 0; i < MAX_FEATURE_TYPE; i++)
        {
            if(i < next_feature)
            {
                findChain = findChain.Next[feature_sequence[i]];
                continue;
            }
            else
            {
                find_feature = m_FeatureType[i + 1];
                break;
            }
        }
        
        //get valid feature
        if(find_feature.ChildCount > 0)
        {
            if(findChain.NodeCount < find_feature.ChildCount)
            {
                valid_feature = new uint8[](find_feature.Count + 1);
                for(uint8 i = 0; i <= find_feature.Count; ++i)
                {
                    valid_feature[i] = i;
                }
            }
            else
            {
                require(findChain.NodeCount < find_feature.TotalCount, "not enough distributive features!");
                
                uint8[] memory temp_list = new uint8[](find_feature.Count);
                uint8 list_index = 0;

                for(uint8 m = 0; m <= find_feature.Count; m++)
                {
                    require(findChain.Next[m].NodeCount <= findChain.NodeCount, "child node count overflow!");

                    if(findChain.Next[m].NodeCount < find_feature.ChildCount)
                    {
                        temp_list[list_index] = m;
                        ++list_index;
                    }
                    else
                    {
                        continue;
                    }                    
                }

                valid_feature = new uint8[](list_index);
                for(uint8 i = 0; i < list_index; ++i)
                {
                    valid_feature[i] = temp_list[i];
                }
            }
        }
        else
        {
            //not found next one
            valid_feature = new uint8[](0);
        }

        return valid_feature;
    }

    function SetFeatureType(uint8[MAX_FEATURE_TYPE] memory feature_sequence) internal
    {
        CCCCCC storage setChain = m_FeatureChainRoot;
  
        for (uint8 i = 0; i < MAX_FEATURE_TYPE; i++)
        {
            {
                setChain.NodeCount += 1;
                setChain = setChain.Next[feature_sequence[i]];
            }
        }
    }

    function setFeatureCount(uint8 type_id, uint8 count) public returns(bool)
    {
        require((type_id > 0) && (type_id <= MAX_FEATURE_TYPE), "feature type err!");
        require((count > 0) && (count <= MAX_FEATURE_TYPE_COUNT), "feature count err!");

        FFFF storage featureData = m_FeatureType[type_id];

        require(featureData.Count < count, "feature count too few!");
        featureData.Count = count;

        _refreshFeatureCount(type_id);

        return true;
    }

    function _refreshFeatureCount(uint8 type_id) internal
    {
        require((type_id > 0) && (type_id <= MAX_FEATURE_TYPE), "feature type err!");

        uint256 last_childCount = 0;

        //the last
        if(type_id == MAX_FEATURE_TYPE)
        {
            last_childCount = m_FeatureType[type_id].Count + 1;
            type_id --;
        }
        else
        {
           last_childCount = m_FeatureType[type_id + 1].ChildCount;
        }

        for(; type_id > 0; type_id--)
        {
            FFFF storage featureData = m_FeatureType[type_id];

            featureData.TotalCount = last_childCount * (featureData.Count + 1);
            featureData.ChildCount = last_childCount;

            last_childCount = featureData.TotalCount;
        }
    }
}