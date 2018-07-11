pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Avatar is SafeMath{
    struct creator {
        bool    enable;
        uint    point;
    }
    struct asset {
        address creator;
        uint    price;
    }
    mapping(address=>creator)   creators;
    mapping(uint=>asset[])      category;
    uint constant               point   = 1000;
    uint constant               maxLayer= 10;

    event ASSET(uint indexed, uint indexed, bytes);
    function addAsset(uint _cat, uint _price, bytes _asset) public {
        category[_cat].push(asset(msg.sender,_price));
        if(creators[msg.sender].enable)
            creators[msg.sender].point  = safeAdd(creators[msg.sender].point,point);
        else
            creators[msg.sender]        = creator(true,1000);
        emit ASSET(_cat,safeSub(category[_cat].length,1),_asset);
    }

    event AVATAR(address indexed,uint[],uint[]);
    function price(uint[] _cats, uint[] _ids) public constant returns(uint) {
        uint sum = 0;
        for(uint i = 0 ; i < _cats.length ; i++)
            sum = safeAdd(sum,category[_cats[i]][_ids[i]].price);
        return sum;
    }
    function verify(uint[] _cats, uint[] _ids) public constant returns(bool) {
        if(_cats.length!=_ids.length)   return false;
        for(uint i = 0 ; i < _cats.length ; i++)
            if(category[_cats[i]].length<=_ids[i])
                return false;
        return true;
    }
    function create(uint[] _cats, uint[] _ids) public {
        require(verify(_cats,_ids));
        // todo : check price
        
        emit AVATAR(msg.sender,_cats,_ids);
    }
}