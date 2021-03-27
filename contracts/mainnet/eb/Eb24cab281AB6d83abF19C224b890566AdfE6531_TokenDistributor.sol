/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.5.16;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract Ownable is Initializable {
    address payable public owner;
    address payable internal newOwnerCandidate;


    function checkAuth() private view {
        require(msg.sender == owner, "Permission denied");
    }
    modifier onlyOwner {
        checkAuth();
        _;
    }


    // ** INITIALIZERS – Constructors for Upgradable contracts **
    function initialize() public initializer {
        owner = msg.sender;
    }

    function initialize(address payable newOwner) public initializer {
        owner = newOwner;
    }


    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }


    uint256[50] private ______gap;
}

contract Adminable is Initializable, Ownable {
    mapping(address => bool) public admins;


    function checkAuthAdmin() private view {
        require(msg.sender == owner || admins[msg.sender], "Permission denied");
    }
    modifier onlyOwnerOrAdmin {
        checkAuthAdmin();
        _;
    }


    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        Ownable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        Ownable.initialize(newOwner);  // Initialize Parent Contract
    }


    function setAdminPermission(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
    }

    uint256[50] private ______gap;
}

interface IToken {
    function balanceOf(address account) external view returns (uint);
    function totalSupply() view external returns (uint256);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function decimals() external view returns (uint);
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract TokenDistributor is Initializable, Adminable, DSMath {
    uint internal constant INITIAL_PRICE = 1e18; // 1 token for 1 USD
    uint internal constant RATE = 1000000700000000000000000000; // next token price = current token price * 1.0000007

    IToken public constant DAI = IToken(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IToken public token;

    uint public tokensWithdrawn; // without decimals: 1 token = 1

    uint public teamRatio = 0.25 * 1e18; // initial
    uint public buyBackRatio = 0.20 * 1e18;  // initial
    uint public treasureRatio = 0.50 * 1e18; // initial
    uint public charityRatio = 0.05 * 1e18; // initial

    address public teamAddress;
    address public buyBackAddress;
    address public treasureAddress;
    address public charityAddress;

    // Full Initializer
    function initialize(
        address payable _newOwner,
        IToken _token,
        address _teamAddress,
        address _buyBackAddress,
        address _treasureAddress,
        address _charityAddress
    ) public initializer {
        Adminable.initialize(_newOwner);  // Initialize Parent Contract

        token = _token;

        teamAddress = _teamAddress;
        buyBackAddress = _buyBackAddress;
        treasureAddress = _treasureAddress;
        charityAddress = _charityAddress;
    }

    function currentTokenPrice() external view returns (uint) {
        return calcPrice(1);
    }

    function calcPrice(uint _tokens) public view returns (uint) {
        uint withdrawnAmount = tokensWithdrawn;
        return sub(_calcSum(INITIAL_PRICE, RATE, add(withdrawnAmount, _tokens)), _calcSum(INITIAL_PRICE, RATE, withdrawnAmount));
    }

    // onlyOwnerOrAdmin check in the internal call
    function claimTokens(uint _tokens) external returns (uint) {
        claimTokens(_tokens, msg.sender);
    }

    function claimTokens(uint _tokens, address _account) public onlyOwnerOrAdmin returns (uint) {
        uint daiAmountIn = calcPrice(_tokens);

        // update withdrawn state
        tokensWithdrawn = add(tokensWithdrawn, _tokens);

        // transfer DAI from msg.sender
        address sender = msg.sender;
        DAI.transferFrom(sender, teamAddress, wmul(daiAmountIn, teamRatio));
        DAI.transferFrom(sender, buyBackAddress, wmul(daiAmountIn, buyBackRatio));
        DAI.transferFrom(sender, treasureAddress, wmul(daiAmountIn, treasureRatio));
        DAI.transferFrom(sender, charityAddress, wmul(daiAmountIn, charityRatio));

        // transfer tokens to msg.sender
        uint tokenAmount = _tokens * 1e18; // with decimals
        token.transfer(_account, tokenAmount);

        return daiAmountIn;
    }

    function setTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;
    }

    function setBuyBackAddress(address _buyBackAddress) external onlyOwner {
        buyBackAddress = _buyBackAddress;
    }

    function setTreasureAddress(address _treasureAddress) external onlyOwner {
        treasureAddress = _treasureAddress;
    }

    function setCharityAddress(address _charityAddress) external onlyOwner {
        charityAddress = _charityAddress;
    }

    function setRatio(
        uint _teamRatio,
        uint _buyBackRatio,
        uint _treasureRatio,
        uint _charityRatio
    ) external onlyOwner {
        require(
            add(_teamRatio, add(_buyBackRatio, add(_treasureRatio, _charityRatio))) == WAD,
            "Sum of ratio must be 10^18"
        );

        teamRatio = _teamRatio;
        buyBackRatio = _buyBackRatio;
        treasureRatio = _treasureRatio;
        charityRatio = _charityRatio;
    }

    // Geometric Progression Sum
    // Sn = b1*(q^n - 1)/(q - 1)
    function _calcSum(uint _principal, uint _rate, uint _num) internal pure returns (uint) {
        return rdiv(rmul(_principal, sub(rpow(_rate, _num), RAY)), sub(_rate, RAY));
    }
}