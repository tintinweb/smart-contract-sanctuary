pragma solidity ^0.4.25;

contract ERC223ReceiverMixin {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

interface ERC223TokenBurner {
  function burn(uint256 _amount) external returns (bool);
}


contract Burner is ERC223ReceiverMixin {

  event Burn(address burner, uint256 amount, uint256 discount);

  uint256 public constant DATE_01_JUN_2018 = 1527811200;
  uint256 public constant DATE_31_DEC_2018 = 1546300799;
  uint256 public constant DATE_31_DEC_2019 = 1577836799;
  uint256 public constant DATE_31_DEC_2020 = 1609459199;
  uint256 public constant DATE_31_DEC_2021 = 1640995199;
  uint256 public constant DATE_31_DEC_2022 = 1672531199;

  struct Phase {
    uint256 startDate;
    uint256 endDate;
    uint256 discount;
  }

  Phase[] phases;
  ERC223TokenBurner public token;

  constructor(address _token) public {
    token = ERC223TokenBurner(_token);
    phases.push(Phase(DATE_01_JUN_2018, DATE_31_DEC_2018, 50));
    phases.push(Phase(DATE_31_DEC_2018 + 1, DATE_31_DEC_2019, 75));
    phases.push(Phase(DATE_31_DEC_2019 + 1, DATE_31_DEC_2020, 80));
    phases.push(Phase(DATE_31_DEC_2020 + 1, DATE_31_DEC_2021, 90));
    phases.push(Phase(DATE_31_DEC_2021 + 1, DATE_31_DEC_2022, 95));
  }

  function tokenFallback(address _from, uint256 _value, bytes) public {
    require(msg.sender == address(token));
    for (uint256 i = 0; i < phases.length; i++) {
      // solium-disable-next-line security/no-block-members
      if (phases[i].startDate <= now && now <= phases[i].endDate) {
        require(token.burn(_value));
        emit Burn(_from, _value, phases[i].discount);
        return;
      }
    }
    revert();
  }

}