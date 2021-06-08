/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.8;


/**
*   @notice 节点注册时用的合约，用来将数据传给聚合器
*/
contract Oracle {
    address public immutable owner;
    uint256 public priceId;
    uint256 public price;

    event request(uint256 _requestId);

    constructor (address _owner) {
        owner = _owner;
    }

    function receiveData(uint256 _priceId,uint256 _price) external {
        require(msg.sender == owner, "not depoist");
        sendMeassage(_priceId,_price);
    }

    function sendMeassage(uint256 _priceId,uint256 _price) private {
        // IAggreator aggreator = IAggreator(forceLink);
        // aggreator.receiveData(_priceId, _price);
        priceId = _priceId;
        price = _price;
    }

    function getPrice() public view returns(uint256) {
        return price;
    }

    function getRequest(uint256 _priceId) external {   
        emit request(_priceId);
    }
}