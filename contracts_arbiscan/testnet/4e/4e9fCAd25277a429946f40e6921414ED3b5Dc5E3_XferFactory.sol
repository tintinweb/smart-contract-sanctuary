//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './XferToken.sol';

contract XferFactory {
    event NewToken(address token, address xfer);

    function createTokenContract(address token) external {
        address xfer = address(new XferToken(token));
        emit NewToken(token, xfer);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract XferToken {
    IERC20 public immutable token;

    error TooShort();
    error TooLong();

    constructor(address _token) {
        token = IERC20(_token);
    }

    fallback() external {
        if (msg.data.length < 21) {
            revert TooShort();
        }
        if (msg.data.length > 52) {
            revert TooLong();
        }
        address to = address(bytes20(msg.data[:20]));

        uint256 amountToShift = (52 - msg.data.length) * 8;
        uint256 value = uint256(bytes32(msg.data[20:]) >> amountToShift);

        token.transferFrom(msg.sender, to, value);
    }
}