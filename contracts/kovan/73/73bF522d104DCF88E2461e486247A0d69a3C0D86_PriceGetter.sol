pragma solidity >=0.5.16 <0.7.0;

import './Ownable.sol';

interface PriceGetterV1Interface{
    function getUnderlyingPrice(address slToken) external view returns(uint256);
}

// current price getter
contract PriceGetter is Ownable {

    mapping(uint =>address) _orderAndViewAddrs;
    uint public _viewLen;
//  init
    constructor(address[] memory _address) public{
        setViewsAddress(_address);
    }
//    event
    event _SetViewAddressEvent(uint _order,address _addr);

    //  _order:fetch order , _addr: orcale views address
    function resetViewAddresss(address[] calldata _addr) external onlyOwner{
        setViewsAddress(_addr);
    }

    function setViewsAddress(address[] memory _address) internal {
        _viewLen = _address.length;
        for(uint i = 0;i<_address.length;i++){
            _orderAndViewAddrs[i] = _address[i];
            emit _SetViewAddressEvent(i,_address[i]);
        }
    }

    // get lastest price from defferent views in order. stop lookup when get the sltoken price
    function getLastestUnderlyingPrice(address slToken) public view returns(uint){
        for(uint32 i=0;i<_viewLen;i++){
            uint underlyingPrice =  uint256(PriceGetterV1Interface(_orderAndViewAddrs[i]).getUnderlyingPrice(slToken));
            if(underlyingPrice<=0){
                continue;
            }
            return underlyingPrice;
        }
        // caller need judge the value;
        return 0;
    }

}