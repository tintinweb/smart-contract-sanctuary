pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AtomicSwapERC20ToERC20 {

  struct Swap {
    uint256 openValue;
    address openTrader;
    address openContractAddress;
    uint256 closeValue;
    address closeTrader;
    address closeContractAddress;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    EXPIRED
  }

  mapping (bytes32 => Swap) private swaps;
  mapping (bytes32 => States) private swapStates;

  event Open(bytes32 _swapID, address _closeTrader);
  event Expire(bytes32 _swapID);
  event Close(bytes32 _swapID);

  modifier onlyInvalidSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.INVALID);
    _;
  }

  modifier onlyOpenSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.OPEN);
    _;
  }

  function open(bytes32 _swapID, uint256 _openValue, address _openContractAddress, uint256 _closeValue, address _closeTrader, address _closeContractAddress) public onlyInvalidSwaps(_swapID) {
    // Transfer value from the opening trader to this contract.
    IERC20 openERC20Contract = IERC20(_openContractAddress);
    require(_openValue <= openERC20Contract.allowance(msg.sender, address(this)));
    require(openERC20Contract.transferFrom(msg.sender, address(this), _openValue));

    // Store the details of the swap.
    Swap memory swap = Swap({
      openValue: _openValue,
      openTrader: msg.sender,
      openContractAddress: _openContractAddress,
      closeValue: _closeValue,
      closeTrader: _closeTrader,
      closeContractAddress: _closeContractAddress
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.OPEN;

    emit Open(_swapID, _closeTrader);
  }

  function close(bytes32 _swapID) public onlyOpenSwaps(_swapID) {
    // Close the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.CLOSED;

    // Transfer the closing funds from the closing trader to the opening trader.
    IERC20 closeERC20Contract = IERC20(swap.closeContractAddress);
    require(swap.closeValue <= closeERC20Contract.allowance(swap.closeTrader, address(this)));
    require(closeERC20Contract.transferFrom(swap.closeTrader, swap.openTrader, swap.closeValue));

    // Transfer the opening funds from this contract to the closing trader.
    IERC20 openERC20Contract = IERC20(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.closeTrader, swap.openValue));

    emit Close(_swapID);
  }

  function expire(bytes32 _swapID) public onlyOpenSwaps(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer opening value from this contract back to the opening trader.
    IERC20 openERC20Contract = IERC20(swap.openContractAddress);
    require(openERC20Contract.transfer(swap.openTrader, swap.openValue));

    emit Expire(_swapID);
  }

  function check(bytes32 _swapID) public view returns (uint256 openValue, address openContractAddress, uint256 closeValue, address closeTrader, address closeContractAddress) {
    Swap memory swap = swaps[_swapID];
    return (swap.openValue, swap.openContractAddress, swap.closeValue, swap.closeTrader, swap.closeContractAddress);
  }
}