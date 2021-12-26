pragma solidity 0.5.16;

import "SafeMath.sol";
import "ERC20Mintable.sol";

contract BitwaveMultiSend {
    using SafeMath for uint256;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier restrictedToOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    function sendEth(address payable [] memory _to, uint256[] memory _value) public restrictedToOwner payable returns (bool _success) {
        // input validation
        require(_to.length == _value.length);
        require(_to.length <= 255);

        // count values for refunding sender
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            afterValue = afterValue.add(_value[i]);
            assert(_to[i].send(_value[i]));
        }

        // send back remaining value to sender
        uint256 remainingValue = beforeValue.sub(afterValue);
        if (remainingValue > 0) {
            assert(msg.sender.send(remainingValue));
        }
        return true;
    }

    function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) public restrictedToOwner returns (bool _success) {
        // input validation
        require(_to.length == _value.length);
        require(_to.length <= 255);

        // use the erc20 abi
        ERC20 token = ERC20(_tokenAddress);

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
        }
        return true;
    }
}