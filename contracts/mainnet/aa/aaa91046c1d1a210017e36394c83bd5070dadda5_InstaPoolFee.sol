/**
 *Submitted for verification at Etherscan.io on 2020-07-17
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

contract Helpers {

    event LogChangeFee(uint256 _fee);
    event LogChangeFeeCollector(address _feeCollector);

    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    uint256 public fee;
    address public feeCollector;

    modifier isChief {
        require(IndexInterface(instaIndex).master() == msg.sender, "not-Master");
        _;
    }

    function changeFee(uint256 _fee) external isChief {
        require(_fee <= 2 * 10 ** 15, "Fee is more than 0.2%");
        fee = _fee;
        emit LogChangeFee(_fee);
    }

    function changeFeeCollector(address _feeCollector) external isChief {
        require(feeCollector != _feeCollector, "Same-feeCollector");
        require(_feeCollector != address(0), "feeCollector-is-address(0)");
        feeCollector = _feeCollector;
        emit LogChangeFeeCollector(_feeCollector);
    }
}

contract InstaPoolFee is Helpers {
    constructor () public {
        fee = 9 * 10 ** 14;  // 0.09%
        feeCollector = IndexInterface(instaIndex).master();
    }
}