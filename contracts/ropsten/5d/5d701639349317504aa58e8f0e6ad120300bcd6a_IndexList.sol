pragma solidity ^0.4.24;

library IndexList
{
    function insert(uint32[] storage self, uint32 index, uint pos) external
    {
        require(self.length >= pos);
        self.length++;
        for (uint i=self.length; i>pos; i++)
        {
            self[i+1] = self[i];
        }
        self[pos] = index;
    }

    function remove(uint32[] storage self, uint32 index) external returns(bool)
    {
        return remove(self,index,0);
    }

    function remove(uint32[] storage self, uint32 index, uint startPos) public returns(bool)
    {
        for (uint i=startPos; i<self.length; i++)
        {
            if (self[i] != index) continue;
            for (uint j=i; j<self.length-1; j++)
            {
                self[j] = self[j+1];
            }
            delete self[self.length-1];
            self.length--;
            return true;
        }
        return false;
    }

}

library ItemList {

    using IndexList for uint32[];
    
    struct Data {
        uint32[] m_List;
        mapping(uint32 => uint) m_Maps;
    }

    function _insert(Data storage self, uint32 key, uint val) internal
    {
        self.m_List.push(key);
        self.m_Maps[key] = val;
    }

    function _delete(Data storage self, uint32 key) internal
    {
        self.m_List.remove(key);
        delete self.m_Maps[key];
    }

    function set(Data storage self, uint32 key, uint num) public
    {
        if (!has(self,key)) {
            if (num == 0) return;
            _insert(self,key,num);
        }
        else if (num == 0) {
            _delete(self,key);
        } 
        else {
            uint old = self.m_Maps[key];
            if (old == num) return;
            self.m_Maps[key] = num;
        }
    }

    function add(Data storage self, uint32 key, uint num) external
    {
        uint iOld = get(self,key);
        uint iNow = iOld+num;
        require(iNow >= iOld);
        set(self,key,iNow);
    }

    function sub(Data storage self, uint32 key, uint num) external
    {
        uint iOld = get(self,key);
        require(iOld >= num);
        set(self,key,iOld-num);
    }

    function has(Data storage self, uint32 key) public view returns(bool)
    {
        return self.m_Maps[key] > 0;
    }

    function get(Data storage self, uint32 key) public view returns(uint)
    {
        return self.m_Maps[key];
    }

    function list(Data storage self) view external returns(uint32[],uint[])
    {
        uint len = self.m_List.length;
        uint[] memory values = new uint[](len);
        for (uint i=0; i<len; i++)
        {
            uint32 key = self.m_List[i];
            values[i] = self.m_Maps[key];
        }
        return (self.m_List,values);
    }

    function isEmpty(Data storage self) view external returns(bool)
    {
        return self.m_List.length == 0;
    }

    function keys(Data storage self) view external returns(uint32[])
    {
        return self.m_List;
    }

}