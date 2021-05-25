/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// File: ERC20.sol

pragma solidity >=0.4.23 <0.6.0;

contract ERC20 {
  uint public totalSupply;

  event Transfer(address indexed from, address indexed to, uint value);  
  event Approval(address indexed owner, address indexed spender, uint value);

  function balanceOf(address who) public view returns (uint);
  function allowance(address owner, address spender) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);  
}
// File: AtomicSwapERC20.sol

pragma solidity >=0.5.11 <0.6.0;


contract AtomicSwapERC20 {

  struct Swap {
    uint256 timelock;
    uint256 erc20Value;
    address erc20Trader;
    address erc20ContractAddress;
    address withdrawTrader;
    bytes32 secretLock;
    bytes secretKey;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    EXPIRED
  }

  mapping (bytes32 => Swap) private swaps;
  mapping (bytes32 => States) private swapStates;

  event Open(bytes32 _swapID, address _withdrawTrader,bytes32 _secretLock);
  event Expire(bytes32 _swapID);
  event Close(bytes32 _swapID, bytes _secretKey);

  modifier onlyInvalidSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.INVALID);
    _;
  }

  modifier onlyOpenSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.OPEN);
    _;
  }

  modifier onlyClosedSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.CLOSED);
    _;
  }

  modifier onlyExpirableSwaps(bytes32 _swapID) {
    require (swaps[_swapID].timelock <= now);
    _;
  }

  modifier onlyWithSecretKey(bytes32 _swapID, bytes memory _secretKey) {
    // TODO: Require _secretKey length to conform to the spec
    require (swaps[_swapID].secretLock == sha256(_secretKey));
    _;
  }

    function open(bytes32 _swapID, uint256 _erc20Value, address _erc20ContractAddress, address _withdrawTrader, bytes32 _secretLock, uint256 _timelock) public onlyInvalidSwaps(_swapID) {
        require(swapStates[_swapID] == States.INVALID);

        // Store the details of the swap.
        Swap memory swap = Swap({
            timelock: _timelock,
            erc20Value: _erc20Value,
            erc20Trader: msg.sender,
            erc20ContractAddress: _erc20ContractAddress,
            withdrawTrader: _withdrawTrader,
            secretLock: _secretLock,
            secretKey: new bytes(0) });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;
        // Transfer value from the ERC20 trader to this contract.
        ERC20 erc20Contract = ERC20(_erc20ContractAddress);
        require(erc20Contract.transferFrom(msg.sender, address(this), _erc20Value));
        emit Open(_swapID, _withdrawTrader, _secretLock);
    }

  function close(bytes32 _swapID, bytes memory _secretKey) public onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) {
    // Close the swap.
    Swap memory swap = swaps[_swapID];
    swaps[_swapID].secretKey = _secretKey;
    swapStates[_swapID] = States.CLOSED;

    // Transfer the ERC20 funds from this contract to the withdrawing trader.
    ERC20 erc20Contract = ERC20(swap.erc20ContractAddress);
    require(erc20Contract.transfer(swap.withdrawTrader, swap.erc20Value));

    emit Close(_swapID, _secretKey);
  }

  function expire(bytes32 _swapID) public onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
    // Expire the swap.
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

    // Transfer the ERC20 value from this contract back to the ERC20 trader.
    ERC20 erc20Contract = ERC20(swap.erc20ContractAddress);
    require(erc20Contract.transfer(swap.erc20Trader, swap.erc20Value));

    emit Expire(_swapID);
  }

  function check(bytes32 _swapID) public view returns (uint256 timelock, uint256 erc20Value, address erc20ContractAddress, address withdrawTrader, bytes32 secretLock) {
    Swap memory swap = swaps[_swapID];
    return (swap.timelock, swap.erc20Value, swap.erc20ContractAddress, swap.withdrawTrader, swap.secretLock);
  }

  function checkSecretKey(bytes32 _swapID) public view onlyClosedSwaps(_swapID) returns (bytes memory secretKey) {
    Swap memory swap = swaps[_swapID];
    return swap.secretKey;
  }
}