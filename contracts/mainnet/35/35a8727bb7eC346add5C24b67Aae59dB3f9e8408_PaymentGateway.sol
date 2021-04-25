// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ERC20Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address _owner) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20Token.sol";

contract PaymentGateway is Ownable {
    // if ERC20 is the 0 address it means that the payment
    // was done with ether
    event Transaction(
        string indexed itxid,
        address indexed recipient,
        address indexed sender,
        string txid,
        Amount[] payments,
        uint256 date
    );

    struct Amount {
        uint256 value;
        address tokenAddress;
    }

    // 10000ths, instead of 100ths to handle decimal percentage values.
    uint16 basisPoints = 10000;

    uint256 defaultFee = 50; // This would be 0.005

    // Set to 10000 for 0% fee.
    mapping(address => uint256) customFee;

    function pay(
        string memory _txid,
        address _recipient,
        Amount[] memory _amounts
    ) external payable {
        require(_amounts.length > 0 || msg.value > 0, "Nothing to pay :shrug:");

        uint256 fee = defaultFee;

        if (customFee[_recipient] == basisPoints) {
            // Since solidity's default value for an unset map of uint256 is 0,
            // we use a 100% fee as no fee.
            fee = 0;
        } else if (customFee[_recipient] != 0) {
            fee = customFee[_recipient];
        }

        uint256 length = msg.value > 0 ? _amounts.length + 1 : _amounts.length;
        Amount[] memory payments = new Amount[](length);
        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 feeAmount;
            if (fee > 0) {
                feeAmount = mulScale(_amounts[i].value, fee, basisPoints);
            }

            ERC20Token token = ERC20Token(_amounts[i].tokenAddress);
            require(
                token.transferFrom(
                    msg.sender,
                    _recipient,
                    _amounts[i].value - feeAmount
                ),
                "transferFrom failed"
            );

            payments[i] = Amount(_amounts[i].value, _amounts[i].tokenAddress);
            if (feeAmount > 0) {
                require(
                    token.transferFrom(msg.sender, address(this), feeAmount),
                    "transferFrom failed"
                );
            }
        }

        if (msg.value > 0) {
            uint256 feeAmount;
            if (fee > 0) {
                feeAmount = mulScale(msg.value, fee, basisPoints);
            }

            payable(_recipient).transfer(msg.value - feeAmount);
            payments[payments.length - 1] = Amount(msg.value, address(0));
        }

        emit Transaction(
            _txid,
            _recipient,
            msg.sender,
            _txid,
            payments,
            block.timestamp
        );
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address[] memory _tokenAddress) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            ERC20Token token = ERC20Token(_tokenAddress[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                require(token.transfer(msg.sender, balance), "transfer failed");
            }
        }
    }

    function getDefaultFee() external view returns (uint256) {
        return defaultFee;
    }

    function setDefaultFee(uint256 _defaultFee) external onlyOwner {
        defaultFee = _defaultFee;
    }

    function getCustomFee(address _address) external view returns (uint256) {
        return customFee[_address];
    }

    function setCustomFee(address _address, uint256 _customFee)
        external
        onlyOwner
    {
        customFee[_address] = _customFee;
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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