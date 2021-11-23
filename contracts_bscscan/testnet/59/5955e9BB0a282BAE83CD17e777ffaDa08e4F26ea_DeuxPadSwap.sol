// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface IDeuxToken is IERC20 {
    function setVestingAccount(address addr) external returns (bool);
}

contract DeuxPadSwap is Context, Ownable {
    using SafeMath for uint256;

    event Sale(
        address indexed signer,
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event CapLimitChange(uint256 minCap, uint256 maxCap);

    struct Pair {
        address token0;
        uint256 t0decimal;
        address token1;
        uint256 t1decimal;
        uint256 price;
        uint256 provision;
        bool active;
    }

    struct CapLimits {
        uint256 minCap;
        uint256 maxCap;
    }

    uint256 public vestingPercent = 30;
    bool public swapWhiteListingActive = true;
    bool public swapActive = true;

    mapping(address => bool) public swapWhiteList;
    mapping(bytes32 => mapping(address => uint256)) private swapLimits;

    Pair public pair;
    CapLimits public capLimits;

    address public receiver;
    address public deuxContract;

    modifier shouldPairDefined() {
        require(
            pair.token0 != address(0) && pair.token1 != address(0),
            "DEUX Crowdsale : pair is not defined"
        );
        _;
    }

    modifier shouldReceiverDefined() {
        require(
            receiver != address(0),
            "DEUX Crowdsale : receiver is not defined"
        );
        _;
    }

    modifier shouldSwapActive() {
        require(swapActive == true, "DEUX Crowdsale : swap is not active");
        _;
    }

    function setDeuxContract(address _addr) public onlyOwner {
        require(_addr != address(0), "Deux contract can not be zero address");
        deuxContract = _addr;
    }

    function addSingleAccountToWhitelist(address _addr) public onlyOwner {
        swapWhiteList[_addr] = true;
    }

    function removeSingleAccountFromWhitelist(address _addr) public onlyOwner {
        swapWhiteList[_addr] = false;
    }

    function addMultipleAccountToWhitelist(address[] memory _addrs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            swapWhiteList[_addrs[i]] = true;
        }
    }

    function removeMultipleAccountFromWhitelist(address[] memory _addrs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            swapWhiteList[_addrs[i]] = false;
        }
    }

    function setSwapWhitelistingStatus(bool _swapWhiteListingActive)
        public
        onlyOwner
    {
        swapWhiteListingActive = _swapWhiteListingActive;
    }

    function setSwapStatus(bool _swapActive) public onlyOwner {
        swapActive = _swapActive;
    }

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function setVestingPercent(uint256 _vestingPercent) public onlyOwner {
        vestingPercent = _vestingPercent;
    }

    function setPair(
        address _token0,
        address _token1,
        uint256 _token0decimal,
        uint256 _token1decimal,
        uint256 _price,
        uint256 _provision
    ) public onlyOwner {
        pair = Pair(
            _token0,
            _token0decimal,
            _token1,
            _token1decimal,
            _price,
            _provision,
            true
        );
    }

    function setCapLimits(uint256 _minCap, uint256 _maxCap) public onlyOwner {
        capLimits = CapLimits(_minCap, _maxCap);
        emit CapLimitChange(_minCap, _maxCap);
    }

    function getLiquidity() internal view returns (uint256) {
        return IERC20(pair.token1).balanceOf(address(this));
    }

    function calculateSendAmount(uint256 _amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            _amount > pair.price,
            "DEUX Crowdsale : given amount should be higher than unit price"
        );
        uint256 dustAmount = _amount % pair.price; // Dust amount for refund
        uint256 allowAmount = _amount.sub(dustAmount); // Accept amount for sell
        uint256 ratio = allowAmount.div(pair.price); // Sell ratio
        uint256 allTransferSize = pair.provision.mul(ratio); // Transfer before vesting applied
        uint256 transferSize = allTransferSize.div(100).mul(vestingPercent); // Transfer size after vesting applied

        // Check allowAmount between minCap & maxCap
        require(
            allowAmount >= capLimits.minCap,
            "DEUX Crowdsale : acceptable amount is lower than min cap"
        );

        require(
            allowAmount <= capLimits.maxCap,
            "DEUX Crowdsale : acceptable amount is higher than max cap"
        );

        return (allowAmount, transferSize, dustAmount);
    }

    function beforeBuy(uint256 _amount) internal view returns (bool) {
        require(pair.active == true, "DEUX Crowdsale : pair is not active");
        require(
            receiver != address(0),
            "DEUX Crowdsale : receiver is zero address"
        );
        require(
            deuxContract != address(0),
            "DEUX Crowdsale : deux contract is not defined"
        );

        if (swapWhiteListingActive) {
            require(
                swapWhiteList[_msgSender()] == true,
                "DEUX Crowdsale : signer is not in whitelist"
            );
        }

        // Check signer allowance for swap
        uint256 signerAllowance = IERC20(pair.token0).allowance(
            _msgSender(),
            address(this)
        );
        require(
            signerAllowance >= _amount,
            "DEUX Crowdsale : signer allowance required for `token0`"
        );

        return true;
    }

    function buy(uint256 _amount)
        public
        shouldPairDefined
        shouldSwapActive
        shouldReceiverDefined
    {
        require(
            beforeBuy(_amount) == true,
            "DEUX : Buy is not allowed currently"
        );

        // Calculate allowed amount, transfer size & dust amount for refund
        (
            uint256 _allowAmount,
            uint256 _transferSize,
            uint256 _dustAmount
        ) = calculateSendAmount(_amount);

        // Check liquidity
        require(
            _transferSize <= getLiquidity(),
            "DEUX Crowdsale : insufficient liquidity"
        );

        // Send token0 to current contract
        SafeERC20.safeTransferFrom(
            IERC20(pair.token0),
            _msgSender(),
            address(this),
            _amount
        );

        // Send allowAmount token0 to receiver
        SafeERC20.safeTransfer(IERC20(pair.token0), receiver, _allowAmount);

        // Send dustAmount to signer if exist
        if (_dustAmount > 0) {
            SafeERC20.safeTransfer(
                IERC20(pair.token0),
                _msgSender(),
                _dustAmount
            );
        }

        // Send token1 to signer
        SafeERC20.safeTransfer(
            IERC20(pair.token1),
            _msgSender(),
            _transferSize
        );

        bool vestingSuccess = IDeuxToken(deuxContract).setVestingAccount(
            _msgSender()
        );

        require(vestingSuccess == true, "Freeze call is failed");

        emit Sale(
            _msgSender(),
            pair.token0,
            pair.token1,
            _allowAmount,
            _transferSize
        );
    }

    function addLiquidity(uint256 _amount) public onlyOwner shouldPairDefined {
        uint256 allowance = IERC20(pair.token1).allowance(
            _msgSender(),
            address(this)
        );

        require(
            allowance >= _amount,
            "DEUX Crowdsale : allowance is not enough"
        );

        SafeERC20.safeTransferFrom(
            IERC20(pair.token1),
            _msgSender(),
            address(this),
            _amount
        );
    }

    function removeLiquidity(address _to, uint256 _amount)
        public
        onlyOwner
        shouldPairDefined
    {
        require(
            _to != address(0),
            "DEUX Crowdsale : to address is zero address"
        );

        require(
            getLiquidity() >= _amount,
            "DEUX Crowdsale : insufficient liquidity"
        );

        SafeERC20.safeTransfer(IERC20(pair.token1), _to, _amount);
    }

    function addLiquidityWithContract(address _contract, uint256 _amount)
        public
        onlyOwner
    {
        uint256 allowance = IERC20(_contract).allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowance >= _amount,
            "DEUX Crowdsale : allowance is not enough"
        );
        SafeERC20.safeTransferFrom(
            IERC20(_contract),
            _msgSender(),
            address(this),
            _amount
        );
    }

    function removeLiquidityWithContract(
        address _contract,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _to != address(0),
            "DEUX Crowdsale : to address is zero address"
        );
        require(
            IERC20(_contract).balanceOf(address(this)) >= _amount,
            "DEUX Crowdsale : insufficient liquidity"
        );

        SafeERC20.safeTransfer(IERC20(_contract), _to, _amount);
    }
}