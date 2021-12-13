pragma solidity ^0.8.0;

/// @title Contract that facilitates and ranks monetary contributions
contract LiquidVote {
  struct Contributor {
    string name; // Contributor's name
    uint256 amount; // Amount contributed
  }

  address payable owner; // Contract owner
  address[] private contributors; // Addresses of top contributors
  mapping(address => Contributor) private contributions; // Map to store contributors
  uint8 private length; // Size of the map

  /// @dev Constructor
  constructor() public {
    owner = payable(msg.sender);
  }

  /// @dev Event that is emitted when a contribution is made
  event Contribution(address indexed user, uint256 amount);

  /// @dev Modifier that restricts the execution of the function to the user
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  /// @dev Modifier that only allows contributions more than 0
  modifier nonZero() {
    require(msg.value > 0, "Contribution must be greater than 0");
    _;
  }

  /// @dev Allows the user to make a contribution
  function contribute(string memory name) public payable nonZero {
    // Add the user to the map
    address currUser = msg.sender;
    uint256 amount = msg.value;
    bool isContributor = contributions[currUser].amount > 0;
    contributions[currUser].amount += amount;

    if (keccak256(bytes(name)) != keccak256(bytes(""))) {
      contributions[currUser].name = name;
    }

    if (!isContributor) {
      contributors.push(currUser);
      length++;
    }

    // Sort the queue
    uint256 index = length < 11 ? length - 1 : 10;

    while (
      index > 0 &&
      contributions[contributors[index]].amount >
      contributions[contributors[index - 1]].amount
    ) {
      address temp = contributors[index];
      contributors[index] = contributors[index - 1];
      contributors[index - 1] = temp;
      index--;
    }

    if (length > 10) {
      contributors.pop();
    }

    emit Contribution(currUser, amount);
  }

  /// @dev Gets a contributor
  function getContributor() public view returns (string memory, uint256) {
    return (contributions[msg.sender].name, contributions[msg.sender].amount);
  }

  /// @dev Returns a list of the top ten contributors
  function getTopContributors()
    public
    view
    returns (string[] memory names, uint256[] memory amounts, address[] memory addresses)
  {
    uint256 index = length < 10 ? length : 10;
    names = new string[](index);
    amounts = new uint256[](index);
    addresses = new address[](index);

    for (uint256 i = 0; i < index; i++) {
      names[i] = contributions[contributors[i]].name;
      amounts[i] = contributions[contributors[i]].amount;
      addresses[i] = contributors[i];
    }

    return (names, amounts, addresses);
  }

  /// @dev Returns the total number of contributors
  function getTotalContributors() public view returns (uint8) {
    return length;
  }

  /// @dev Destroys the contract
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }
}