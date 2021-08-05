pragma solidity ^0.6.0;

import "./provableAPI_0.6.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";

contract APIConsumer is usingProvable {
    string public ethv;
    address public owner;

    event Publish(string ethv, uint256 timestamp);
    event LogNewProvableQuery(string description);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateETHV() public payable {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery(
                "Provable query was NOT sent, please send some ETH to cover for the query fee"
            );
        } else {
            LogNewProvableQuery(
                "Provable query sent, standing by for the answer.."
            );
            provable_query(
                "URL",
                "https://volmex-labs.firebaseio.com/current_evix/evix.json"
            );
        }
    }

    /**
     * Receive the response in the form of uint256
     */

    function __callback(bytes32 _requestId, string memory curr_ethv)
        public
        override
    {
        if (msg.sender != provable_cbAddress()) revert();
        ethv = curr_ethv;
        emit Publish(ethv, block.timestamp);
    }
}
