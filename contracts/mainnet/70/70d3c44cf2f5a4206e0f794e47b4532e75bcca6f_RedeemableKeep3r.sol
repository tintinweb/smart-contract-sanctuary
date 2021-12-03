/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface erc20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface cl {
    function latestAnswer() external view returns (int);
}

contract RedeemableKeep3r {
    string public constant name = "Redeemable Keep3r v2";
    string public constant symbol = "rKP3Rv2";
    uint8 public constant decimals = 18;

    address public gov;
    address public nextGov;
    uint public delayGov;

    uint public fee = 90;
    uint public nextFee;
    uint public delayFee;

    address public treasury;
    address public nextTreasury;
    uint public delayTreasury;

    address constant KP3R = address(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    address constant ibEUR = address(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27);

    cl constant _kp3reth = cl(0xe7015CCb7E5F788B8c1010FC22343473EaaC3741);
    cl constant _eurusd = cl(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
    cl constant _ethusd = cl(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function kp3reth() public view returns (uint) {
        return uint(_kp3reth.latestAnswer());
    }

    function kp3rusd() public view returns (uint) {
        return uint(_kp3reth.latestAnswer() * _ethusd.latestAnswer() / 1e18);
    }

    function kp3reur() public view returns (uint) {
        return kp3rusd() * 1e18 / uint(_eurusd.latestAnswer());
    }

    uint32 constant DELAY = 1 days;
    uint32 constant BASE = 100;

    event Redeem(address indexed from, address indexed owner, uint amount, uint strike);

    constructor(address _treasury) {
        gov = msg.sender;
        treasury = _treasury;
    }

    modifier g() {
        require(msg.sender == gov);
        _;
    }

    function setGov(address _gov) external g {
        nextGov = _gov;
        delayGov = block.timestamp + DELAY;
    }

    function acceptGov() external {
        require(msg.sender == nextGov && delayGov < block.timestamp);
        gov = nextGov;
    }

    function setFee(uint _fee) external g {
        nextFee = _fee;
        delayFee = block.timestamp + DELAY;
    }

    function commitFee() external g {
        require(delayFee < block.timestamp);
        fee = nextFee;
    }

    function setTreasury(address _treasury) external g {
        nextTreasury = _treasury;
        delayTreasury = block.timestamp + DELAY;
    }

    function commitTreasury() external g {
        require(delayTreasury < block.timestamp);
        treasury = nextTreasury;
    }

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) public allowance;
    mapping(address => uint) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function calc(uint amount) public view returns (uint) {
        return kp3reur() * amount / 1e18 * fee / BASE;
    }

    function deposit(uint amount) external returns (bool) {
        _safeTransferFrom(KP3R, msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return true;
    }

    function claim(uint amount) external returns (bool) {
        _burn(msg.sender, amount);
        uint _strike = calc(amount);
        _safeTransferFrom(ibEUR, msg.sender, treasury, _strike);
        _safeTransfer(KP3R, msg.sender, amount);
        emit Redeem(msg.sender, msg.sender, amount, _strike);
        return true;
    }

    function _mint(address to, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}