/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.8.1;

/// Use this contract for investing in SDGs.
/// @title Sustainable Development Goals (SDGs) investment management.
contract Sdgs {

  enum GoalType {
    Unspecified,
    NoPoverty,
    ZeroHunger,
    GoodHealthAndWellBeing,
    QualityEducation,
    GenderEquality,
    CleanWaterAndSanitation,
    AffordableAndCleanEnergy,
    DecentWorkAndEconomicGrowth,
    Industry,
    InnovationAndInfrastructure,
    ReducedInequalities,
    SustainableCitiesAndCommunities,
    ResponsibleConsumptionAndProduction,
    ClimateAction,
    LifeBelowWater,
    LifeOnLand,
    Peace,
    JusticeAndStrongInstitutions,
    PartnershipsForTheGoals
  }
  enum DepositType {
    Donation,
    ContractManaged,
    InvestorManaged
  }
  struct Goal {
    string name;
    uint balance;
  }
  /// TODO: Could separate amount marked as DepositType.InvestorManaged from
  /// DepositType.ContractManaged, and could also add separate
  /// DepositType.Donation amount. For now, it can be fetched from emited
  /// events.
  struct Investor {
    uint balance;
    bool verified;
  }

  address payable public owner;
  mapping(GoalType => Goal) public goals;
  mapping(address => Investor) public investors;

  /// @dev Logs deposit into a specific SDG or in a common fund.
  event Deposited(address indexed _from, uint _amount, GoalType _goalType,
    DepositType _depositType);
  /// @dev Logs verified wallet.
  event VerifiedAddress(address _verificator, address _verified);

  constructor() {
    owner = payable(msg.sender);

    goals[GoalType.Unspecified] = Goal('Unspecified', 0);
    goals[GoalType.NoPoverty] = Goal('No Poverty', 0);
    goals[GoalType.ZeroHunger] = Goal('Zero hunger', 0);
    goals[GoalType.GoodHealthAndWellBeing] =
      Goal('Good health and well being', 0);
    goals[GoalType.QualityEducation] = Goal('Quality education', 0);
    goals[GoalType.GenderEquality] = Goal('Gender equality', 0);
    goals[GoalType.CleanWaterAndSanitation] =
      Goal('Clean water and sanitation', 0);
    goals[GoalType.AffordableAndCleanEnergy] =
      Goal('Affordable and clean energy', 0);
    goals[GoalType.DecentWorkAndEconomicGrowth] =
      Goal('Decent work and economic growth', 0);
    goals[GoalType.Industry] =  Goal('Industry', 0);
    goals[GoalType.InnovationAndInfrastructure] =
      Goal('Innovation and infrastructure', 0);
    goals[GoalType.ReducedInequalities] = Goal('Reduced inequalities', 0);
    goals[GoalType.SustainableCitiesAndCommunities] =
      Goal('Sustainable cities and communities', 0);
    goals[GoalType.ResponsibleConsumptionAndProduction] =
      Goal('Responsible consumption and production', 0);
    goals[GoalType.ClimateAction] = Goal('Climate action', 0);
    goals[GoalType.LifeBelowWater] = Goal('Life below water', 0);
    goals[GoalType.LifeOnLand] = Goal('Life on land', 0);
    goals[GoalType.Peace] = Goal('Peace', 0);
    goals[GoalType.JusticeAndStrongInstitutions] =
      Goal('Justice and strong institutions', 0);
    goals[GoalType.PartnershipsForTheGoals] =
      Goal('Partnerships for the goals', 0);
  }

  /// Donate ETH in a common fund.
  /// This function is called when no other function matches the called
  /// one and the call data isn't empty. It receives any ETH sent to the
  /// contract. There is currently no way to send funds back.
  /// @dev The fallback function called when no other function matches
  /// (if the receive ether function does not exist then this includes
  /// calls with empty call data). You can make this function payable or
  /// not. If it is not payable, then transactions which send value but
  /// aren't matching any other function, will revert. It is limited to
  /// 2300 gas, to make this function call as cheap as possible.
  fallback() external payable {
    GoalType goalType = GoalType.Unspecified;
    goals[goalType].balance += msg.value;
    emit Deposited(msg.sender, msg.value, goalType, DepositType.Donation);
  }

  /// Donate ETH in a common fund.
  /// This function is called when the call data is empty (i.e. for plain
  /// Ether transfers). It receives any ETH sent to the contract. There
  /// is currently no way to send funds back.
  /// @dev If present, the receive ether function is called whenever the
  /// call data is empty (whether or not ether is received). This
  /// function is implicitly payable. It's executed e.g. via .send() or
  /// .transfer().
  receive() external payable {
    GoalType goalType = GoalType.Unspecified;
    goals[goalType].balance += msg.value;
    emit Deposited(msg.sender, msg.value, goalType, DepositType.Donation);
  }

  /// Donate ETH in specific SDG or in a common fund.
  /// @dev Sent ETH are donated in the specified SDG's fund, unless the
  /// GoalType.Unspecified is picked, then ETH are donated in the common
  /// fund.
  /// @param goalType SDG type.
  /// @return New balance of the donated SDG.
  function donate(GoalType goalType) public payable returns (uint) {
    goals[goalType].balance += msg.value;
    emit Deposited(msg.sender, msg.value, goalType, DepositType.Donation);
    return goals[goalType].balance;
  }

  /// Invest ETH in specific SDG or in a common fund.
  /// @dev Sent ETH are invested in the specified SDG's fund, unless the
  /// GoalType.Unspecified is picked, then ETH are invested in the common
  /// fund.
  /// @param goalType SDG type.
  /// @return New balance of the invested SDG.
  function invest(GoalType goalType) public payable returns (uint) {
    investors[msg.sender].balance += msg.value;
    goals[goalType].balance += msg.value;
    emit Deposited(msg.sender, msg.value, goalType,
      DepositType.ContractManaged);
    return goals[goalType].balance;
  }

  /// Verify that investor is the owner of his specified wallet, enabling
  /// him to manage his investments.
  /// @param toVerify Walltet address to verify.
  function verifyInvestor(address toVerify) public {
    require(msg.sender == owner, "Only owner can authorize investors.");
    investors[toVerify].verified = true;
    emit VerifiedAddress(msg.sender, toVerify);
  }

  /// Invest ETH in specific SDG or in a common fund, but let investor
  /// manage the investments with this deposited funds.
  /// @dev Sent ETH are invested in the specified SDG's fund, unless the
  /// GoalType.Unspecified is picked, then ETH are invested in the common
  /// fund. Balance deposited by investor in this way, will allow him to
  /// manage the investments by himself (e.g. invest in chosen projects
  /// and / or withdraw the funds even before investing).
  /// @param goalType SDG type.
  /// @return New balance of the invested SDG.
  function managerialInvest(GoalType goalType) public payable returns
    (uint) {
    require(investors[msg.sender].verified, 'Unverified investor, you must '
      'first get verified.');
    investors[msg.sender].balance += msg.value;
    goals[goalType].balance += msg.value;
    emit Deposited(msg.sender, msg.value, goalType,
      DepositType.InvestorManaged);
    return goals[goalType].balance;
  }

  /// Get name for specific SDG goal.
  function getGoalName(GoalType goalType) public view returns
    (string memory) {
    return goals[goalType].name;
  }

  /// Get balance for specific SDG fund.
  function getGoalBalance(GoalType goalType) public view returns (uint) {
    return goals[goalType].balance;
  }

  /// Get whether a specific investor's wallet is verified.
  function isInvestorVerified(address investor) public view returns
    (bool) {
    return investors[investor].verified;
  }

  /// Get balance for specific investor's wallet.
  function getInvestorBalance(address investor) public view returns
    (uint) {
    return investors[investor].balance;
  }
}