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
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IPoolEscrow {
    function notifySecondaryTokens(uint256 number) external;
}

contract RebaseReceiverMediator {
    address internal bridge;
    address internal mediatorOnOtherSide;
    address internal ausc;
    address internal secondaryPool;
    uint256 internal gasLimit;

    event NoSecondaryMint();

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

    function handleRebase(
        uint256 secondaryPoolBudget,
        uint256 epoch,
        uint256 supplyDelta,
        bool positive
    ) public {
        require(msg.sender == address(bridgeContract()));
        require(
            bridgeContract().messageSender() == mediatorContractOnOtherSide()
        );

        if (positive) {
            IAUSC(ausc).rebase(epoch, supplyDelta, positive);

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
        } else {
            IAUSC(ausc).rebase(epoch, supplyDelta, positive);
            UNIPAIR.sync();
        }
    }
}

