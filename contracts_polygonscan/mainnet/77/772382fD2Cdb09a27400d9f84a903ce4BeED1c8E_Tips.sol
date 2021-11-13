pragma solidity ^0.7.6;

import "./NativeMetaTransaction.sol";
import "./OwnableInitializable.sol";
import {SafeMath} from "./SafeMath.sol";


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Tips is OwnableInitializable, NativeMetaTransaction {
    using SafeMath for uint256;

    uint256 public commissionRate; // rate from 0-100

    event TippedEth(address _to, address _from, uint256 _amount);
    event TippedToken(
        address tokenAddress,
        address _to,
        address _from,
        uint256 _amount
    );

    event Claimed(address _wallet, uint256 _amount);

    constructor(uint256 _commissionRate) public {
        // EIP712 init
        _initializeEIP712("Amnesia Tips", "1");
        // Ownable init
        _initOwnable();
        require(
            _commissionRate > 0 && _commissionRate <= 100,
            "Invalid commission rate"
        );
        commissionRate = _commissionRate;
    }

    function tipEth(address _to) public payable {
        require(msg.value > 0, "No value added");

        payable(_to).transfer((msg.value * (100 - commissionRate)) / 100);
        payable(owner()).transfer((msg.value * commissionRate) / 100);

        emit TippedEth(_to, msg.sender, msg.value);
    }

    function tipToken(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) public payable {
        require(_amount > 0, "Amount should be > 0");

        IERC20 token = IERC20(_tokenAddress);

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Not allowed"
        );

        token.transferFrom(
            msg.sender,
            _to,
            (_amount * (100 - commissionRate)) / 100
        );
        token.transferFrom(
            msg.sender,
            owner(),
            _amount * (commissionRate / 100)
        );

        emit TippedToken(_tokenAddress, _to, msg.sender, _amount);
    }

    function updateCommissionRate(uint256 _commissionRate) public onlyOwner {
        require(
            _commissionRate > 0 && _commissionRate <= 100,
            "Invalid commission rate"
        );
        commissionRate = _commissionRate;
    }
}