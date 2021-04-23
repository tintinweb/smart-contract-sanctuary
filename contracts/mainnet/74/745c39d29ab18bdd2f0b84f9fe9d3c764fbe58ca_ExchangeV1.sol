/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.5.2;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

interface IVault {
    function transfer(address token, address from, address to, uint256 amount, uint256 fromFeeRate, uint256 toFeeRate) external;

    function calculateFee(uint256 amount, uint256 feeRate) external pure returns (uint256);

    function balanceOf(address token, address client) external view returns (uint256);

    event Transfer(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 fromFee, uint256 toFee);
}

pragma solidity ^0.5.2;





contract ExchangeV1 is Ownable {
    using SafeMath for uint256;

    event VaultChanged(address indexed account);
    event MarketPermissionChanged(address indexed base, address indexed quote, bool permission);
    event BlacklistChanged(address indexed client, bool tradeBlacklist);
    event MarketFeeRateChanged(address indexed base, address indexed quote, uint256 makeFeeRate, uint256 takeFeeRate);
    event Trade(bytes32 indexed orderHash, uint256 amount, uint256 price, address indexed take, uint256 makeFee, uint256 takeFee);
    event Cancel(bytes32 indexed orderHash);

    address private _vault;
    mapping (address => mapping (address => bool)) private _marketPermissions;
    mapping (address => bool) private _tradeBlacklist;
    mapping (address => mapping (address => uint256)) private _makeFeeRates;
    mapping (address => mapping (address => uint256)) private _takeFeeRates;
    mapping (bytes32 => uint256) private _orderFills;

    constructor () public {
    } 
    
    function renounceOwnership() public onlyOwner {
        revert();
    }

    function setVault(address account) public onlyOwner {
        if (_vault != account) {
            _vault = account;
            emit VaultChanged(account);
        }
    }

    function vault() public view returns (address) {
        return _vault;
    }

    function setMarketPermission(address base, address quote, bool permission) public onlyOwner {
        if (isMarketPermitted(base, quote) != permission) {
            _marketPermissions[base][quote] = permission;
            emit MarketPermissionChanged(base, quote, permission);
        }
    }

    function multiSetMarketPermission(address[] memory bases, address[] memory quotes, bool[] memory permissions) public onlyOwner {
        require(bases.length == quotes.length && bases.length == permissions.length);
        for (uint256 i = 0; i < bases.length; i++) {
            setMarketPermission(bases[i], quotes[i], permissions[i]);
        }
    }

    function isMarketPermitted(address base, address quote) public view returns (bool) {
        return _marketPermissions[base][quote];
    }

    function isTradeBlacklisted(address client) public view returns (bool) {
        return _tradeBlacklist[client];
    }

    function setBlacklist(address client, bool tradeBlacklist) public onlyOwner {
        if (isTradeBlacklisted(client) != tradeBlacklist) {
            _tradeBlacklist[client] = tradeBlacklist;
            emit BlacklistChanged(client, isTradeBlacklisted(client));
        }
    }
    
    function multiSetBlacklist(address[] memory clients, bool[] memory tradeBlacklists) public onlyOwner {
        require(clients.length == tradeBlacklists.length);
        for (uint256 i = 0; i < clients.length; i++) {
            setBlacklist(clients[i], tradeBlacklists[i]);
        }
    }

    function setMarketFeeRate(address base, address quote, uint256 makeFeeRate, uint256 takeFeeRate) public onlyOwner {
        if (makeFeeRateOf(base, quote) != makeFeeRate || takeFeeRateOf(base, quote) != takeFeeRate) {
            _makeFeeRates[base][quote] = makeFeeRate;
            _takeFeeRates[base][quote] = takeFeeRate;
            emit MarketFeeRateChanged(base, quote, makeFeeRate, takeFeeRate);
        }
    }

    function multiSetMarketFeeRate(address[] memory bases, address[] memory quotes, uint256[] memory makeFeeRates, uint256[] memory takeFeeRates) public onlyOwner {
        require(bases.length == quotes.length && bases.length == makeFeeRates.length && bases.length == takeFeeRates.length);
        for (uint256 i = 0; i < bases.length; i++) {
            setMarketFeeRate(bases[i], quotes[i], makeFeeRates[i], takeFeeRates[i]);
        }
    }

    function makeFeeRateOf(address base, address quote) public view returns (uint256) {
        return _makeFeeRates[base][quote];
    }

    function takeFeeRateOf(address base, address quote) public view returns (uint256) {
        return _takeFeeRates[base][quote];
    }

    function orderFillOf(bytes32 orderHash) public view returns (uint256) {
        return _orderFills[orderHash];
    }

    function trade(address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, uint256 expire, uint256 nonce, address make, uint256 amount, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 orderHash = _buildOrderHash(base, quote, baseAmount, quoteAmount, isBuy, expire, nonce);
        require(block.timestamp < expire && isMarketPermitted(base, quote) && !isTradeBlacklisted(msg.sender) && orderFillOf(orderHash).add(amount) <= baseAmount && _checkOrderHash(orderHash, make, v, r, s));
        _trade(orderHash, base, quote, baseAmount, quoteAmount, isBuy, make, amount);
    }

    function _trade(bytes32 orderHash, address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, address make, uint256 amount) private {
        uint256 price = amount.mul(quoteAmount).div(baseAmount);
        uint256 makeFeeRate = makeFeeRateOf(base, quote);
        uint256 takeFeeRate = takeFeeRateOf(base, quote);
        if (isBuy) {
            _transfer(base, msg.sender, make, amount, 0, 0);
            _transfer(quote, make, msg.sender, price, makeFeeRate, takeFeeRate);
        }
        else {
            _transfer(base, make, msg.sender, amount, 0, 0);
            _transfer(quote, msg.sender, make, price, takeFeeRate, makeFeeRate);
        }
        _orderFills[orderHash] = orderFillOf(orderHash).add(amount);
        emit Trade(orderHash, amount, price, msg.sender, _calculateFee(price, makeFeeRate), _calculateFee(price, takeFeeRate));
    }

    function multiTrade(address[] memory bases, address[] memory quotes, uint256[] memory baseAmounts, uint256[] memory quoteAmounts, bool[] memory isBuys, uint256[] memory expires, uint256[] memory nonces, address[] memory makes, uint256[] memory amounts, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) public {
        require(bases.length == quotes.length && bases.length == baseAmounts.length && bases.length == quoteAmounts.length && bases.length == isBuys.length && bases.length == expires.length && bases.length == nonces.length && bases.length == makes.length && bases.length == amounts.length && bases.length == vs.length && bases.length == rs.length && bases.length == ss.length);
        for (uint256 i = 0; i < bases.length; i++) {
            trade(bases[i], quotes[i], baseAmounts[i], quoteAmounts[i], isBuys[i], expires[i], nonces[i], makes[i], amounts[i], vs[i], rs[i], ss[i]);
        }
    }

    function availableAmountOf(address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, uint256 expire, uint256 nonce, address make, uint8 v, bytes32 r, bytes32 s) public view returns (uint256) {
        bytes32 orderHash = _buildOrderHash(base, quote, baseAmount, quoteAmount, isBuy, expire, nonce);
        return block.timestamp >= expire || !_checkOrderHash(orderHash, make, v, r, s) ? 0 : _availableAmountOf(orderHash, base, quote, baseAmount, quoteAmount, isBuy, make);
    }

    function _availableAmountOf(bytes32 orderHash, address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, address make) private view returns (uint256) {
        uint256 availableByFill = baseAmount.sub(orderFillOf(orderHash));
        uint256 availableByBalance = isBuy ? _balanceOf(quote, make).mul(baseAmount).div(quoteAmount) : _balanceOf(base, make);
        return availableByFill < availableByBalance ? availableByFill : availableByBalance;
    }

    function cancel(address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, uint256 expire, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 orderHash = _buildOrderHash(base, quote, baseAmount, quoteAmount, isBuy, expire, nonce);
        require(_checkOrderHash(orderHash, msg.sender, v, r, s));
        _orderFills[orderHash] = baseAmount;
        emit Cancel(orderHash);
    }

    function multiCancel(address[] memory bases, address[] memory quotes, uint256[] memory baseAmounts, uint256[] memory quoteAmounts, bool[] memory isBuys, uint256[] memory expires, uint256[] memory nonces, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) public {
        require(bases.length == quotes.length && bases.length == baseAmounts.length && bases.length == quoteAmounts.length && bases.length == isBuys.length && bases.length == expires.length && bases.length == nonces.length && bases.length == vs.length && bases.length == rs.length && bases.length == ss.length);
        for (uint256 i = 0; i < bases.length; i++) {
            cancel(bases[i], quotes[i], baseAmounts[i], quoteAmounts[i], isBuys[i], expires[i], nonces[i], vs[i], rs[i], ss[i]);
        }
    }

    function _transfer(address token, address from, address to, uint256 amount, uint256 fromFeeRate, uint256 toFeeRate) private {
        IVault(vault()).transfer(token, from, to, amount, fromFeeRate, toFeeRate);
    }

    function _calculateFee(uint256 amount, uint256 feeRate) private view returns (uint256) {
        return IVault(vault()).calculateFee(amount, feeRate);
    }

    function _balanceOf(address token, address client) private view returns (uint256) {
        return IVault(vault()).balanceOf(token, client);
    }

   function _buildOrderHash(address base, address quote, uint256 baseAmount, uint256 quoteAmount, bool isBuy, uint256 expire, uint256 nonce) private view returns (bytes32) {
        return sha256(abi.encodePacked(address(this), base, quote, baseAmount, quoteAmount, isBuy, expire, nonce));
    }

    function _checkOrderHash(bytes32 orderHash, address make, uint8 v, bytes32 r, bytes32 s) private pure returns (bool) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v, r, s) == make;
    }
}