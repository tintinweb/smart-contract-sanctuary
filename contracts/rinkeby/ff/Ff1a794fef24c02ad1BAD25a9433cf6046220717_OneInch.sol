pragma experimental ABIEncoderV2;
import "../../IERC20Interface.sol";

contract OneInch {
    event TokenSwapped(
        address _source,
        uint256 _sourceAmount,
        address _destination,
        uint256 _destinationAmount
    );

    function swap(
        uint256 _amount,
        address _sourceToken,
        address _destinationToken,
        address _to,
        bytes memory _callData,
        uint256 _value
    ) public payable returns (uint256 _swappedAmount) {
        IERC20Interface(_sourceToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _swappedAmount = _swap(
            _amount,
            _sourceToken,
            _destinationToken,
            _to,
            _callData,
            _value
        );
    }

    function chainedSwap(
        uint256 _amount,
        address _sourceToken,
        address _destinationToken,
        address _to,
        bytes memory _callData,
        uint256 _value
    ) public payable returns (uint256 _swappedAmount) {
        _swappedAmount = _swap(
            _amount,
            _sourceToken,
            _destinationToken,
            _to,
            _callData,
            _value
        );
    }

    function _swap(
        uint256 _amount,
        address _sourceToken,
        address _destinationToken,
        address _to,
        bytes memory _callData,
        uint256 _value
    ) private returns (uint256 _swappedAmount) {
        IERC20Interface(_sourceToken).approve(_to, _amount);

        uint256 initialBalance =
            IERC20Interface(_destinationToken).balanceOf(address(this));
        // solium-disable-next-line security/no-call-value
        (bool success, ) = _to.call{value: _value}(_callData);
        if (!success) revert("1Inch-swap-failed");
        uint256 finalBalance =
            IERC20Interface(_destinationToken).balanceOf(address(this));
        IERC20Interface(_sourceToken).approve(_to, 0);
        _swappedAmount = finalBalance - initialBalance;

        emit TokenSwapped(
            _sourceToken,
            _amount,
            _destinationToken,
            _swappedAmount
        );
    }
}

interface IERC20Interface {
    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

