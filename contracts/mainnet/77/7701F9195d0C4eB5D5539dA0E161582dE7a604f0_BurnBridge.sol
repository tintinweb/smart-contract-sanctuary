/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(owner, _owner);
    }
}

contract BurnBridge is Ownable {
    uint256 public feeValues;
    address public adminAddress;
    mapping(address => Token) public tokens;
    mapping(address => mapping(uint256 => Token)) public pairs;
    uint256 public nativeCirculation = 0;
    uint256 public currentChainType;

    struct Token {
        bool active;
        address tokenAddress;
        bool isERC20; // false: native, true: ERC20
        bool mintable; // false: unlock, true: mint
        bool burnable; // false: lock,   true: burn
        uint256 chainType;
    }

    event Bridge(
        address indexed _from,
        address indexed _token1,
        address indexed _token2,
        address _to,
        uint256 _amount,
        uint256 chainType
    );
    event addPair(
        address _token1,
        address _token2,
        uint256 _token1ChainType,
        uint256 _token2ChainType,
        uint256 actionType
    );

    constructor(uint256 _currentChainType) {
        currentChainType = _currentChainType;
    }

    function setPair(
        address _token1,
        bool _mintable,
        bool _burnable,
        address _token2,
        uint256 chainType
    ) external onlyOwner returns (bool) {
        Token memory token1 = Token(
            true,
            _token1,
            _token1 == address(0) ? false : true,
            _mintable,
            _burnable,
            currentChainType
        );
        Token memory token2 = Token(
            true,
            _token2,
            _token2 == address(0) ? false : true,
            false,
            false,
            chainType
        );

        tokens[_token1] = token1;
        pairs[_token1][chainType] = token2;
        emit addPair(_token1, _token2, currentChainType, chainType, 1);
        return true;
    }

    function removePair(address _token1, uint256 chainType)
        external
        onlyOwner
        returns (bool)
    {
        pairs[_token1][chainType] = Token(
            true,
            address(0),
            false,
            false,
            false,
            chainType
        );
        emit addPair(
            _token1,
            pairs[_token1][chainType].tokenAddress,
            currentChainType,
            chainType,
            2
        );
        return true;
    }

    receive() external payable {
        // Do nothing
    }

    function deposit(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _chainType
    ) external payable returns (bool) {
        Token memory token1 = tokens[_token];
        Token memory token2 = pairs[_token][_chainType];
        require(token2.active, "the token is not acceptable");

        uint256 feeAmount;
        uint256 transferAmount;
        if (token1.isERC20) {
            IERC20 token = IERC20(_token);
            transferAmount = _amount;
            if (feeValues > 0 && adminAddress != address(0)) {
                feeAmount = (((feeValues) * transferAmount) / (10**5));
                transferAmount = transferAmount - feeAmount;
            }
            token.transferFrom(msg.sender, address(this), transferAmount);
            if (feeAmount > 0) {
                token.transferFrom(msg.sender, adminAddress, feeAmount);
            }

            if (token1.burnable) {
                token.burn(transferAmount);
            }
        } else {
            token1 = tokens[address(0)];
            token2 = pairs[address(0)][_chainType];
            transferAmount = msg.value;
            if (feeValues > 0 && adminAddress != address(0)) {
                feeAmount = (((feeValues) * transferAmount) / (10**5));
                transferAmount = transferAmount - feeAmount;
            }
            require(msg.value > 0, "msg.value is zero");
            require(token2.active, "the native token is not acceptable");
            if (feeAmount > 0) {
                (payable(adminAddress)).transfer(feeAmount);
            }
        }
        emit Bridge(
            msg.sender,
            token1.tokenAddress,
            token2.tokenAddress,
            _to,
            transferAmount,
            _chainType
        );

        return true;
    }

    function trigger(
        address _token,
        address payable _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        Token memory token = tokens[_token];
        require(token.active, "the token is not acceptable");

        if (!token.isERC20) {
            // Native token
            _to.transfer(_amount);
        } else if (token.mintable) {
            // Mintable ERC20
            IERC20(token.tokenAddress).mint(_to, _amount);
        } else {
            // Non-mintable ERC20
            IERC20(token.tokenAddress).transfer(_to, _amount);
        }
        return true;
    }

    function setFeeValues(uint256 _feeValues) external onlyOwner {
        feeValues = _feeValues;
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }
}