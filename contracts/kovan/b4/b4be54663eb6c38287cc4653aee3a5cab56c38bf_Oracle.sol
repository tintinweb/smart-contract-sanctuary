/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.8;

/**
*   @notice 节点注册时用的合约，用来将数据传给聚合器
*/
contract Oracle {
/*    address owner;
    address public immutable forceLink;*/
uint256 public priceId;
uint256 public price;

event request(uint256 _requestId);

/*    constructor (address _owner, address _forceLink) {
        owner = _owner;
//        forceLink = _forceLink;
    }*/

function receiveData(uint256 _priceId, uint256 _price) external {
//        require(msg.sender == owner, "not depoist");
sendMeassage(_priceId, _price);
}

function sendMeassage(uint256 _priceId, uint256 _price) private {
// IAggreator aggreator = IAggreator(forceLink);
// aggreator.receiveData(_priceId, _price);
priceId = _priceId;
price = _price;
}

function getPrice() external returns (uint256 _priceId, uint256 _price){
_priceId = priceId;
_price = price;
}

function getRequest(uint256 _priceId) external{
emit request(_priceId);
}
function getId() public view returns (uint256) {
return priceId;
}
}