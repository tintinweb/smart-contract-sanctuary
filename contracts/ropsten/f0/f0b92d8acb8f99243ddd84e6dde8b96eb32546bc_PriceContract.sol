pragma solidity ^0.6.12;
import "./provableAPI_0.6.sol";
import "./String.sol";
import "./ERC20.sol";

contract PriceContract is usingProvable {
    using String for string;
    event GetPrice(bytes32 _id, string _query);
    event ReceivePrice(bytes32 _id, string _result);

    mapping(bytes32 => bool) public isRequest;
    mapping(bytes32 => bool) public isResponse;
    mapping(bytes32 => string) public price;

    function deposit() public payable {}

    function __callback(bytes32 myid, string memory result) public override {
        //if (msg.sender != provable_cbAddress()) revert();
        emit ReceivePrice(myid, result);
        price[myid] = result;
        isResponse[myid] = true;
    }

    function getPrice(bytes32 _id) public view returns (string memory) {
        require(isRequest[_id], "PriceContract: Cannot request price");
        require(
            isResponse[_id],
            "PriceContract: Have not received any feedback about the price"
        );
        return price[_id];
    }

    function updatePrice(uint256 _time, address payable _tokens)
        external
        payable
        returns (bytes32)
    {
        require(
            provable_getPrice("URL") <= address(this).balance,
            "PriceContract: Not enough fee to get price, please add some ETH to cover for the query fee"
        );
        string memory symbol = ERC20Token(_tokens).symbol();
        string memory request = "json(";
        request = request
        .append("https://api.pro.coinbase.com/products/")
        .append(symbol)
        .append("-")
        .append("USD")
        .append("/ticker")
        .append(").price");
        bytes32 myid = provable_query(_time, "URL", request);
        isRequest[myid] = true;
        emit GetPrice(myid, request);
        return myid;
    }
}