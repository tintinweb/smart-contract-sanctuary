// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ReentrancyGuard.sol";
import "./Ownable.sol";


import "./IERC20.sol";
import "./ERC20.sol";
// Token
// Forked from Hermes Defi (objects changed, vars same for diff check)
contract FeatherToken is ERC20('Feather', 'FEATHER'), ReentrancyGuard {

    address public constant feeAddress = 0xD7a96Df0258907aB2792295306ca2F65ff2Bc68d;

    uint256 public salePriceE35 = (30) * (10 ** 34);

    uint256 public constant fenixMaximumSupply = 60 * (10 ** 3) * (10 ** 18); // 60 000 token 40 000 to the presale 20 000 to the liquidity at 1$/token

    // We use a counter to defend against people sending Fenix back
    uint256 public fenixRemaining = fenixMaximumSupply;

    uint256 public constant maxFenixPurchase = 2000 * (10 ** 18);

    uint256 oneHourMatic = 1800;
    uint256 oneDayMatic = oneHourMatic * 24;
    uint256 threeDaysMatic = oneDayMatic * 3;

    uint256 public startBlock;
    uint256 public endBlock;

    mapping(address => uint256) public userFenixTally;

    event fenixPurchased(address sender, uint256 maticSpent, uint256 fenixReceived);
    event startBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event salePriceE35Changed(uint256 newSalePriceE5);

    constructor(uint256 _startBlock) {
        startBlock = _startBlock;
        endBlock   = _startBlock + threeDaysMatic;
        _mint(address(this), fenixMaximumSupply);
    }

    function buyFeather() external payable nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(fenixRemaining > 0, "No more Fenix remaining! Come back next time!");
        require(IERC20(address(this)).balanceOf(address(this)) > 0, "No more Fenix left! Come back next time!");
        require(msg.value > 0, "not enough matic provided");
        require(msg.value <= 3e22, "too much matic provided");
        require(userFenixTally[msg.sender] < maxFenixPurchase, "user has already purchased too much Fenix");

        uint256 originalFenixAmount = (msg.value * salePriceE35) / 1e35;

        uint256 fenixPurchaseAmount = originalFenixAmount;

        if (fenixPurchaseAmount > maxFenixPurchase)
            fenixPurchaseAmount = maxFenixPurchase;

        if ((userFenixTally[msg.sender] + fenixPurchaseAmount) > maxFenixPurchase)
            fenixPurchaseAmount = maxFenixPurchase - userFenixTally[msg.sender];

        // if we dont have enough left, give them the rest.
        if (fenixRemaining < fenixPurchaseAmount)
            fenixPurchaseAmount = fenixRemaining;

        require(fenixPurchaseAmount > 0, "user cannot purchase 0 Fenix");

        // shouldn't be possible to fail these asserts.
        assert(fenixPurchaseAmount <= fenixRemaining);
        assert(fenixPurchaseAmount <= IERC20(address(this)).balanceOf(address(this)));
        IERC20(address(this)).transfer(msg.sender, fenixPurchaseAmount);
        fenixRemaining = fenixRemaining - fenixPurchaseAmount;
        userFenixTally[msg.sender] = userFenixTally[msg.sender] + fenixPurchaseAmount;

        uint256 maticSpent = msg.value;
        uint256 refundAmount = 0;
        if (fenixPurchaseAmount < originalFenixAmount) {
            // max fenixPurchaseAmount = 6e20, max msg.value approx 3e22 (if 10c matic, worst case).
            // overfow check: 6e20 * 3e22 * 1e24 = 1.8e67 < type(uint256).max
            // Rounding errors by integer division, reduce magnitude of end result.
            // We accept any rounding error (tiny) as a reduction in PAYMENT, not refund.
            maticSpent = ((fenixPurchaseAmount * msg.value * 1e24) / originalFenixAmount) / 1e24;
            refundAmount = msg.value - maticSpent;
        }
        if (maticSpent > 0) {
            (bool success, bytes memory returnData) = payable(address(feeAddress)).call{value: maticSpent}("");
            require(success, "failed to send matic to fee address");
        }
        if (refundAmount > 0) {
            (bool success, bytes memory returnData) = payable(msg.sender).call{value: refundAmount}("");
            require(success, "failed to send matic to customer address");
        }

        emit fenixPurchased(msg.sender, maticSpent, fenixPurchaseAmount);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + threeDaysMatic;

        emit startBlockChanged(_newStartBlock, endBlock);
    }

    function setSalePriceE35(uint256 _newSalePriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newSalePriceE35 >= 25 * (10 ** 34), "new price can't be below 2.5 matic");
        require(_newSalePriceE35 <= 100 * (10 ** 34), "new price can't be above 10 matic");
        salePriceE35 = _newSalePriceE35;

        emit salePriceE35Changed(salePriceE35);
    }
}