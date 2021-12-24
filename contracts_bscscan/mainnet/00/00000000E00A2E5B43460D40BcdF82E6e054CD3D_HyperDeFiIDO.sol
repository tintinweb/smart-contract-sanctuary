// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.10;

import "./Context.sol";
import "./IERC20.sol";
import "./IHyperDeFi.sol";
import "./IHyperDeFiBuffer.sol";
import "./IHyperDeFiIDO.sol";


contract HyperDeFiIDO is Context, IHyperDeFiIDO {
    uint256 private immutable _AMOUNT_TOTAL;
    uint256 private immutable _DEPOSIT_CAP;
    uint256 private immutable _DEPOSIT_MAX;
    uint32  private immutable _TIMESTAMP_FROM;
    uint32  private immutable _TIMESTAMP_TO;

    address            private immutable _BLACK_HOLE = address(0xdead);
    IHyperDeFi         private immutable _TOKEN      = IHyperDeFi(0x99999999f678F56beF0Da5EB96F4c1300Cf8D69a);
    IHyperDeFiBuffer   private immutable _BUFFER;
    address[]          private           _founders;
    uint8              private           _decimals;


    uint256 private _depositTotal;

    mapping (address => uint256) private _deposits;
    mapping (address => bool)    private _redeemed;

    event Deposit(address indexed account, uint256 amount);


    constructor () {
        _decimals = _TOKEN.decimals();

        address buffer;
        (_AMOUNT_TOTAL, _DEPOSIT_CAP, _DEPOSIT_MAX, _TIMESTAMP_FROM, _TIMESTAMP_TO, buffer) = _TOKEN.getIDOConfigs();

        _BUFFER = IHyperDeFiBuffer(buffer);
    }

    // receive() external payable {
    //     _deposit();
    // }

    // fallback() external payable {
    //     _deposit();
    // }

    function depositBNB() external payable {
        _deposit();
    }

    function redeem() external {
        _redeem();
    }

    // price in WRAP
    function priceToken2WRAP() public view returns (uint256 price) {
        price = _depositTotal * 10 ** _decimals / _AMOUNT_TOTAL;
    }

    // price in USD
    function priceToken2USD() public view returns (uint256 price) {
        return priceToken2WRAP() * _BUFFER.priceWRAP2USD() / 1e18;
    }

    // founder
    function isFounder(address account) public view returns (bool) {
        return 0 < _deposits[account];
    }

    // read
    function getAccount(address account) public view 
        returns (
            uint256 amountWRAP,
            uint256 amountToken,
            bool redeemed
        )
    {
        amountWRAP  = _deposits[account];
        amountToken = _getAmount(account);
        redeemed    = _redeemed[account];
    }

    function getDepositTotal() public view returns (uint256) {
        return _depositTotal;
    }

    // founders
    function getFounders(uint256 offset) public view
        returns (
            uint256[250] memory ids,
            address[250] memory founders,
            uint256[250] memory wrapAmounts,
            uint256[250] memory tokenAmounts
        )
    {
        uint8 counter;
        for (uint256 i = offset; i < _founders.length; i++) {
            counter++;
            if (counter > 250) break;
            ids[i] = i;
            founders[i] = _founders[i];
            wrapAmounts[i] = _deposits[_founders[i]];
            tokenAmounts[i] = _getAmount(_founders[i]);
        }
    }

    // deposit
    function _deposit() private {
        require(0 < msg.value, "HyperDeFi IDO: deposit zero");
        require(block.timestamp > _TIMESTAMP_FROM, "HyperDeFi IDO: not started");
        require(!_TOKEN.isInitialLiquidityCreated(), "HyperDeFi IDO: initial liquidity has already been created");
        require(_DEPOSIT_MAX > _deposits[_msgSender()], "HyperDeFi IDO: deposit max reached for the sender");

        uint256 amount = msg.value;

        // DEPOSIT_MAX
        if (_DEPOSIT_MAX < amount + _deposits[_msgSender()]) {
            amount = _DEPOSIT_MAX -_deposits[_msgSender()];
            payable(_msgSender()).transfer(msg.value - amount);
        }

        // DEPOSIT_CAP
        if (_DEPOSIT_CAP < address(this).balance) {
            amount = address(this).balance - _DEPOSIT_CAP;
            payable(_msgSender()).transfer(address(this).balance - _DEPOSIT_CAP);
        }

        // deposit
        _depositTotal += amount;
        _deposits[_msgSender()] += amount;
        emit Deposit(_msgSender(), amount);

        if (_DEPOSIT_CAP <= address(this).balance || _TIMESTAMP_TO < block.timestamp) {
            _TOKEN.createInitLiquidity{value: address(this).balance}();
        }
    }

    // redeem
    function _redeem() private {
        require(_TOKEN.isInitialLiquidityCreated(), "HyperDeFi IDO: initial liquidity not created");
        require(!_redeemed[_msgSender()], "HyperDeFi IDO: caller has already redeemed");
        
        _TOKEN.transfer(_msgSender(), _getAmount(_msgSender()));
        
        _redeemed[_msgSender()] = true;
    }

    // portion
    function _getAmount(address account) private view returns (uint256) {
        if (0 < _depositTotal) {
            return _AMOUNT_TOTAL * _deposits[account] / _depositTotal;
        }

        return 0;
    }
}