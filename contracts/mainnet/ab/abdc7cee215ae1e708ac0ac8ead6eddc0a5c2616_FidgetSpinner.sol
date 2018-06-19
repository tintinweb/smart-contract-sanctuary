pragma solidity ^0.4.8;

contract Owned {
  address public owner;

  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
  }
}

contract FidgetSpinner is Owned {
  int omega;
  int theta;
  uint public lastUpdate;

  uint public decayRate;
  uint public omegaPerEther;

  int public largestRetro;
  int public largestPro;

  event Spin(
    address indexed from,
    int indexed direction,
    uint amount
  );

  /*
   * Creates a new FidgetSpinner whose spin decays at a rate of _decayNumerator/_decayDenominator% per second
   * and who gains _omegaPerEther spin per Ether spent on spinning it.
   */
	function FidgetSpinner(uint _decayRate, uint _omegaPerEther) {
    lastUpdate = now;
		decayRate = _decayRate;
    omegaPerEther = _omegaPerEther;
	}


  /*
   * This makes it easy to override deltaTime in FidgetSpinnerTest so we can test that velocity/displacement decay is
   * working correctly
   */
  function deltaTime() constant returns(uint) {
    return now - lastUpdate;
  }

  /*
   * Returns the velocity of the spinner during this specific block in the chain
   */
  function getCurrentVelocity() constant returns(int) {
    if(decayRate == 0) {
      return omega;
    }

    int dir = -1;
    if(omega == 0) {
      return 0;
    } else if(omega < 0) {
      dir = 1;
    }

    uint timeElapsed = deltaTime();
    uint deltaOmega = timeElapsed * decayRate;
    int newOmega = omega + (int(deltaOmega) * dir);

    // make sure we didn&#39;t cross zero
    if((omega > 0 && newOmega < 0) || (omega < 0 && newOmega > 0)) {
      return 0;
    }

    return newOmega;
  }

  /*
   * Returns the displacement of the spinner during this specific block in the chain
   */
  function getCurrentDisplacement() constant returns(int) {
    // integrates omega over time
    int timeElapsed = int(deltaTime());

    if(decayRate == 0) {
      return theta + (timeElapsed * omega);
    }

    // find max time elapsed before v=0 (becomes max-height of trapezoid)
    int maxTime = omega / int(decayRate);

    if (maxTime < 0) {
      maxTime *= -1;
    }

    if(timeElapsed > maxTime) {
      timeElapsed = maxTime;
    }

    int deltaTheta = ((omega + getCurrentVelocity()) * timeElapsed) / 2;
    return theta + deltaTheta;
  }

  /*
   * Adds or subtracts from the spin of the spinner
   *
   * All changes to the spinner state should happen at the end of the current block. So multiple spins in the same block
   * should be additive with their effects only becoming apparent in the next block.
   */
  function spin(int direction) payable {
    require(direction == -1 || direction == 1);

    int deltaOmega = (int(msg.value) * direction * int(omegaPerEther)) / 1 ether;
    int newOmega = getCurrentVelocity() + deltaOmega;
    int newTheta = getCurrentDisplacement();

    omega = newOmega;
    theta = newTheta;

    if(-omega > largestRetro) {
      largestRetro = -omega;
    } else if(omega > largestPro) {
      largestPro = omega;
    }

    Spin(msg.sender, direction, msg.value);
    lastUpdate = now;
  }

  /*
   * Withdraws all the money from the contract
   */
  function withdrawAll() onlyOwner {
    withdraw(address(this).balance);
  }

  /*
   * Withdraws a given amount of money from the contract
   */
  function withdraw(uint amount) onlyOwner {
    owner.transfer(amount);
  }
}