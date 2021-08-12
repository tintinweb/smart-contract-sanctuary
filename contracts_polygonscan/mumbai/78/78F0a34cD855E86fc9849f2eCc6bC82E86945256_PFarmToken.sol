pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";

import "./IERC20.sol";
import "./ERC20.sol";

// PFarmToken
contract PFarmToken is ERC20('PRE-FARM', 'PFARM'), ReentrancyGuard {

    address public feeAddress;

    uint256 public salePriceE35 = 1666 * (10 ** 31);

    uint256 public constant pFarmMaximumSupply = 30 * (10 ** 3) * (10 ** 18);

    // We use a counter to defend against people sending pfarm back
    uint256 public pFarmRemaining = pFarmMaximumSupply;

    uint256 public constant maxFarmPurchase = 600 * (10 ** 18);


    uint256 public start;
    uint256 public end;

    mapping(address => uint256) public userPfarmTally;

    event pFarmPurchased(address sender, uint256 maticSpent, uint256 pfarmReceived);
    event startBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event salePriceE35Changed(uint256 newSalePriceE5);

    constructor(uint256 _start,uint _end,address payable _feeAddress) {
        start = _start;
        end   = _end;
        feeAddress = _feeAddress;
        _mint(address(this), pFarmMaximumSupply);
    }

    function buyPFarm() external payable nonReentrant {
        require(block.timestamp >= start, "presale hasn't started yet, good things come to those that wait");
        require(block.timestamp < end, "presale has ended, come back next time!");
        require(pFarmRemaining > 0, "No more pfarm remaining! Come back next time!");
        require(IERC20(address(this)).balanceOf(address(this)) > 0, "No more pfarm left! Come back next time!");
        require(msg.value > 0, "not enough matic provided");
        require(msg.value <= 3e22, "too much matic provided");
        require(userPfarmTally[msg.sender] < maxFarmPurchase, "user has already purchased too much pfarm");

        uint256 originalPfarmAmount = (msg.value * salePriceE35) / 1e35;

        uint256 pFarmPurchaseAmount = originalPfarmAmount;

        if (pFarmPurchaseAmount > maxFarmPurchase)
            pFarmPurchaseAmount = maxFarmPurchase;

        if ((userPfarmTally[msg.sender] + pFarmPurchaseAmount) > maxFarmPurchase)
            pFarmPurchaseAmount = maxFarmPurchase - userPfarmTally[msg.sender];

        // if we dont have enough left, give them the rest.
        if (pFarmRemaining < pFarmPurchaseAmount)
            pFarmPurchaseAmount = pFarmRemaining;

        require(pFarmPurchaseAmount > 0, "user cannot purchase 0 pfarm");

        // shouldn't be possible to fail these asserts.
        assert(pFarmPurchaseAmount <= pFarmRemaining);
        assert(pFarmPurchaseAmount <= IERC20(address(this)).balanceOf(address(this)));
        IERC20(address(this)).transfer(msg.sender, pFarmPurchaseAmount);
        pFarmRemaining = pFarmRemaining - pFarmPurchaseAmount;
        userPfarmTally[msg.sender] = userPfarmTally[msg.sender] + pFarmPurchaseAmount;

        uint256 maticSpent = msg.value;
        uint256 refundAmount = 0;
        if (pFarmPurchaseAmount < originalPfarmAmount) {
            // max pFarmPurchaseAmount = 6e20, max msg.value approx 3e22 (if 10c matic, worst case).
            // overfow check: 6e20 * 3e22 * 1e24 = 1.8e67 < type(uint256).max
            // Rounding errors by integer division, reduce magnitude of end result.
            // We accept any rounding error (tiny) as a reduction in PAYMENT, not refund.
            maticSpent = ((pFarmPurchaseAmount * msg.value * 1e24) / originalPfarmAmount) / 1e24;
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

        emit pFarmPurchased(msg.sender, maticSpent, pFarmPurchaseAmount);
    }

    function setStartBlock(uint256 _newStart) external onlyOwner {
        require(block.timestamp < start, "cannot change start block if sale has already commenced");
        require(block.timestamp < _newStart, "cannot set start block in the past");
        start = _newStart;
        end   = _newStart;

        emit startBlockChanged(_newStart, end);
    }

    function setSalePriceE35(uint256 _newSalePriceE35) external onlyOwner {
        require(block.timestamp < start - 4 hours, "cannot change price 4 hours before start block");
        require(_newSalePriceE35 >= 2 * (10 ** 33), "new price can't too low");
        require(_newSalePriceE35 <= 4 * (10 ** 34), "new price can't too high");
        salePriceE35 = _newSalePriceE35;

        emit salePriceE35Changed(salePriceE35);
    }
}