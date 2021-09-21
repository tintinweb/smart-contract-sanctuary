/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

contract PokeMeReady {
    address payable public immutable pokeMe;

    constructor(address payable _pokeMe) {
        pokeMe = _pokeMe;
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
        _;
    }
}

contract Counter is PokeMeReady {
  uint256 public count;
  uint256 public lastExecuted;

  constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

  function increaseCount(uint256 amount) external onlyPokeMe {
    require(
      ((block.timestamp - lastExecuted) > 180),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
  }
}