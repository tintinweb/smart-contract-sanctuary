pragma solidity ^0.4.18;
contract mapp
{
    struct Details
    {
        uint id;
        string name;
        string desig;
    }
    mapping(address=>Details) public mapped;
    address[] public adds;
    function add(address _address,uint _id,string _name,string _desig)
    {
        var addrs=mapped[_address];
        addrs.id=_id;
        addrs.name=_name;
        addrs.desig=_desig;
        adds.push(_address);
    }
    
    function Check(address _address)
    {
        mapped[_address].name="Asshish";
    }
    
    function show(address _address) view public returns(uint,string,string)
    {
        return(mapped[_address].id,mapped[_address].name,mapped[_address].desig);
    }
}

/*
    function showLength() view public returns(uint)
    {
        return(adds.length);
    }
0x14723a09acff6d2a60dcdf7aa4aff308fddc160c-Abhay
0x583031d1113ad414f02576bd6afabfb302140225-prakash
0x583031d1113ad414f02576bd6afabfb302140225-Dheeraj
*/