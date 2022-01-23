//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bridgeworld/external/IMasterOfCoin.sol";
import "../bridgeworld/external/IMagic.sol";

contract MockMasterOfCoin is IMasterOfCoin {

    IMagic public magic;

    function grantTokenToStream(address _stream, uint256 _amount) external {
        magic.transferFrom(msg.sender, _stream, _amount);
    }

    function setMagicContract(address _magicAddress) external {
        magic = IMagic(_magicAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterOfCoin {

    // Gives the token to the stream. Stream in our case will be the atlas mine.
    function grantTokenToStream(address _stream, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagic {

    // Transfers the given amount to the recipient's wallet. Returns a boolean indicating if it was
    // successful or not.
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

    // Transfer the given amount to the recipient's wallet. The sender is the caller of this function.
    // Returns a boolean indicating if it was successful or not.
    function transfer(address _recipient, uint256 _amount) external returns(bool);

    function approve(address _spender, uint256 _amount) external returns(bool);
}