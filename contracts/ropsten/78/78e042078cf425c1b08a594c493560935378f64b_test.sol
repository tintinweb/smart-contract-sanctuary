pragma solidity ^0.4.24;

contract test  {
    
    enum Paragmeters {uint256_, uint8_, int256_, int8_, address_, bytes4_, bytes32_, bool_}

    
    struct FuncInterface {
        bytes4 methodId;
        Paragmeters[] para;
    }

    FuncInterface[] functions;

    function registerFuntion(bytes4 _methodId,  Paragmeters[]  _paras) public {
        
        FuncInterface memory _tempFunc;
        _tempFunc.methodId = _methodId;

        _tempFunc.para = _paras;
        
        functions.push(_tempFunc);
    }
    
    function get(uint256 k) public view returns(bytes4) {
        return functions[k].methodId;
    }
    
    function getPara(uint256 k,uint256 j) public view returns(Paragmeters) {
        return functions[k].para[j];
    }
    
    

    
    
    
}