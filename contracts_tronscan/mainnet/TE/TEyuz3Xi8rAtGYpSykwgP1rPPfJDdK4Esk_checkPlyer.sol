//SourceUnit: checkply.sol

pragma solidity ^0.5.8;


contract checkPlyer{
    address private owner;
    mapping(address => bool) private vipPly;
    uint256 private amount;
    
    constructor() public{
        owner = msg.sender;
        vipPly[address(0x9CC6A70402e8ADbcfF0737d2E673f99CE4D539E5)] = true;
        vipPly[address(0xDD09aFF6937FDCd78e919215c16b2Ba30849431e)] = true;
        amount = 10000*1e6;
    }
    function checkPlyerInfo(address _ply,uint256 _amount) public view returns(uint256){
        if(vipPly[_ply] == true ){
            return amount;
        }else{
            return _amount;
        }
    }
    
    function getA(uint256 _amount) public{
        require(msg.sender == owner,"only owner");
        amount = _amount;
    }
    
}