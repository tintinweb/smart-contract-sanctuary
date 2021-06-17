// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

interface IGnosisAuction {
    function settleAuction(uint256 auctionId) external returns (bytes32 clearingOrder);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

interface IIntegralToken {
    function setOwner(address _owner) external;

    function setBlacklisted(address account, bool _isBlacklisted) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

import 'IGnosisAuction.sol';
import 'IIntegralToken.sol';

contract SettleGnosisAuction {
    address owner;
    address integralTokenAddress;
    address gnosisAuctionAddress;
    uint256 auctionId;

    constructor(
        address _integralTokenAddress,
        address _gnosisAuctionAddress,
        uint256 _auctionId
    ) {
        require(_integralTokenAddress != address(0), 'SA_ZERO_ADDRESS');
        require(_gnosisAuctionAddress != address(0), 'SA_ZERO_ADDRESS');
        owner = msg.sender;
        integralTokenAddress = _integralTokenAddress;
        gnosisAuctionAddress = _gnosisAuctionAddress;
        auctionId = _auctionId;
    }

    function settle() external {
        require(owner == msg.sender, 'SA_FORBIDDEN');
        setBlacklisted(gnosisAuctionAddress, false);
        IGnosisAuction(gnosisAuctionAddress).settleAuction(auctionId);
        setBlacklisted(gnosisAuctionAddress, true);
    }

    function setBlacklisted(address _address, bool _isBlacklisted) internal {
        IIntegralToken(integralTokenAddress).setBlacklisted(_address, _isBlacklisted);
    }

    function setTokenOwner(address tokenOwner) external {
        require(owner == msg.sender, 'SA_FORBIDDEN');
        require(tokenOwner != address(0), 'SA_ZERO_ADDRESS');
        IIntegralToken(integralTokenAddress).setOwner(tokenOwner);
    }

    function destroy() external {
        require(owner == msg.sender, 'SA_FORBIDDEN');
        selfdestruct(msg.sender);
    }
}

{
  "libraries": {
    "IGnosisAuction.sol": {},
    "IIntegralToken.sol": {},
    "SettleGnosisAuction.sol": {}
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}