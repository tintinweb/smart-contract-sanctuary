pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

pragma solidity 0.5.16;

interface IAMB {
    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

interface IAUSC {
    function rebase(
        uint256 epoch,
        uint256 supplyDelta,
        bool positive
    ) external;

    function mint(address to, uint256 amount) external;
}

interface IERC20 {
    function safeApprove(address spender, uint256 value) external;

    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IPoolEscrow {
    function notifySecondaryTokens(uint256 number) external;
}

contract RebaseReceiverMediator {
    using SafeMath for uint256;

    address internal bridge;
    address internal mediatorOnOtherSide;
    address internal ausc;
    address internal secondaryPool;
    uint256 internal gasLimit;
    uint256 public epoch = 1;
    uint256 public constant BASE = 1e18;

    event NoSecondaryMint();
    event NoRebaseNeeded();

    IUniswapV2Pair public constant UNIPAIR =
        IUniswapV2Pair(0x92FacdfB69427CffC1395a7e424AeA91622035Fc);

    function init(
        address _bridge,
        address _mediatorOnOtherSide,
        address _ausc,
        address _secondaryPool,
        uint256 _gasLimit
    ) public {
        bridge = _bridge;
        mediatorOnOtherSide = _mediatorOnOtherSide;
        ausc = _ausc;
        secondaryPool = _secondaryPool;
        gasLimit = _gasLimit;
    }

    function mediatorContractOnOtherSide() private view returns (address) {
        return mediatorOnOtherSide;
    }

    function bridgeContract() public view returns (IAMB) {
        return IAMB(bridge);
    }

    function executionGasLimit() public view returns (uint256) {
        return gasLimit;
    }

    function handleRebase(uint256 averageAUSC, uint256 averageXAU) public {
        require(msg.sender == address(bridgeContract()));
        require(
            bridgeContract().messageSender() == mediatorContractOnOtherSide()
        );

        // only rebase if there is a 5% difference between the price of XAU and AUSC
        uint256 highThreshold = averageXAU.mul(105).div(100);
        uint256 lowThreshold = averageXAU.mul(95).div(100);

        if (averageAUSC > highThreshold) {
            // AUSC is too expensive, this is a positive rebase increasing the supply
            uint256 currentSupply = IERC20(ausc).totalSupply();
            uint256 desiredSupply =
                currentSupply.mul(averageAUSC).div(averageXAU);
            uint256 secondaryPoolBudget =
                desiredSupply.sub(currentSupply).mul(10).div(100);
            desiredSupply = desiredSupply.sub(secondaryPoolBudget);

            // Cannot underflow as desiredSupply > currentSupply, the result is positive
            // delta = (desiredSupply / currentSupply) * 100 - 100
            uint256 delta =
                desiredSupply.mul(BASE).div(currentSupply).sub(BASE);
            IAUSC(ausc).rebase(epoch, delta, true);

            if (secondaryPool != address(0)) {
                // notify the pool escrow that tokens are available
                IAUSC(ausc).mint(address(this), secondaryPoolBudget);
                IERC20(ausc).safeApprove(secondaryPool, 0);
                IERC20(ausc).safeApprove(secondaryPool, secondaryPoolBudget);
                IPoolEscrow(secondaryPool).notifySecondaryTokens(
                    secondaryPoolBudget
                );
            } else {
                emit NoSecondaryMint();
            }
            UNIPAIR.sync();
            epoch++;
        } else if (averageAUSC < lowThreshold) {
            // AUSC is too cheap, this is a negative rebase decreasing the supply
            uint256 currentSupply = IERC20(ausc).totalSupply();
            uint256 desiredSupply =
                currentSupply.mul(averageAUSC).div(averageXAU);

            // Cannot overflow as desiredSupply > currentSupply
            // delta = 100 - (desiredSupply / currentSupply) * 100
            uint256 delta =
                uint256(BASE).sub(desiredSupply.mul(BASE).div(currentSupply));
            IAUSC(ausc).rebase(epoch, delta, false);
            UNIPAIR.sync();
            epoch++;
        } else {
            // else the price is within bounds
            emit NoRebaseNeeded();
        }
    }

    // Need to accept checkRebase call from AUSC
    function checkRebase() external {}
}

