pragma solidity 0.4.24;


interface ChickenHunt {

  /* FUNCTION */

  function callFor(
    address _to, 
    uint256 _value, 
    uint256 _gas, 
    bytes _code
  ) external payable returns (bool);

  function addPet(
    uint256 _huntingPower,
    uint256 _offensePower,
    uint256 _defense,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  ) external;

  function changePet(
    uint256 _id,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  ) external;

  function addItem(
    uint256 _huntingMultiplier,
    uint256 _offenseMultiplier,
    uint256 _defenseMultiplier,
    uint256 _price
  ) external;

  function setDepot(uint256 _price, uint256 _max) external;

  function setConfiguration(
    uint256 _chickenA,
    uint256 _ethereumA,
    uint256 _maxA,
    uint256 _chickenB,
    uint256 _ethereumB,
    uint256 _maxB
  ) external;

  function setDistribution(
    uint256 _dividendRate,
    uint256 _altarCut,
    uint256 _storeCut,
    uint256 _devCut
  )
    external;

  function setCooldownTime(uint256 _cooldownTime) external;
  function setNameAndSymbol(string _name, string _symbol) external;
  function setDeveloper(address _developer) external;
  function join() external;
  function withdraw() external;

}


/**
 * @title ChickenHuntCommittee
 * @author M.H. Kang
 * @notice Wrapper solution to unintended flaw that
 * the committee could use ChickenHunt contract ether with callFor function.
 * This vulnerability was discovered by &#39;blah&#39;. I appreciate it!
 */
contract CHCommitteeWrapper {

  /* STORAGE */

  ChickenHunt public chickenHunt;
  address public committee;

  /* CONSTRUCTOR */

  constructor(address _chickenHunt) public {
    committee = msg.sender;
    chickenHunt = ChickenHunt(_chickenHunt);
    chickenHunt.join();
  }

  /* FUNCTION */

  function () public payable {}

  function callFor(address _to, uint256 _gas, bytes _code)
    external
    payable
    onlyCommittee
    returns (bool)
  {
    return chickenHunt.callFor.value(msg.value)(_to, msg.value, _gas, _code);
  }

  function addPet(
    uint256 _huntingPower,
    uint256 _offensePower,
    uint256 _defense,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  )
    external
    onlyCommittee
  {
    chickenHunt.addPet(
      _huntingPower, 
      _offensePower, 
      _defense, 
      _chicken, 
      _ethereum, 
      _max
    );
  }

  function changePet(
    uint256 _id,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  )
    external
    onlyCommittee
  {
    chickenHunt.changePet(
      _id,
      _chicken,
      _ethereum,
      _max
    );
  }

  function addItem(
    uint256 _huntingMultiplier,
    uint256 _offenseMultiplier,
    uint256 _defenseMultiplier,
    uint256 _price
  )
    external
    onlyCommittee
  {
    chickenHunt.addItem(
      _huntingMultiplier,
      _offenseMultiplier,
      _defenseMultiplier,
      _price
    );
  }

  function setDepot(uint256 _price, uint256 _max) external onlyCommittee {
    chickenHunt.setDepot(_price, _max);
  }

  function setConfiguration(
    uint256 _chickenA,
    uint256 _ethereumA,
    uint256 _maxA,
    uint256 _chickenB,
    uint256 _ethereumB,
    uint256 _maxB
  )
    external
    onlyCommittee
  {
    chickenHunt.setConfiguration(
      _chickenA,
      _ethereumA,
      _maxA,
      _chickenB,
      _ethereumB,
      _maxB
    );
  }

  function setDistribution(
    uint256 _dividendRate,
    uint256 _altarCut,
    uint256 _storeCut,
    uint256 _devCut
  )
    external
    onlyCommittee
  {
    chickenHunt.setDistribution(
      _dividendRate,
      _altarCut,
      _storeCut,
      _devCut
    );
  }

  function setCooldownTime(uint256 _cooldownTime) external onlyCommittee {
    chickenHunt.setCooldownTime(_cooldownTime);
  }

  function setNameAndSymbol(string _name, string _symbol)
    external
    onlyCommittee
  {
    chickenHunt.setNameAndSymbol(_name, _symbol);
  }

  function setDeveloper(address _developer) external onlyCommittee {
    chickenHunt.setDeveloper(_developer);
  }

  function withdraw() external {
    chickenHunt.withdraw();
    committee.transfer(address(this).balance);
  }

  function setCommittee(address _committee) external onlyCommittee {
    committee = _committee;
  }

  /* MODIFIER */

  modifier onlyCommittee {
    require(msg.sender == committee);
    _;
  }

}