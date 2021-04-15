/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.4.24;

library SafeMath {
    function add(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        c = a + b;
        require(c >= a);
    }

    function sub(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        require(b <= a);
        c = a - b;
    }

    function mul(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
     function div(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




pragma solidity >=0.4.24;

contract IDODistribution is Owned, Pausable {
    
    using SafeMath for uint;

    /**
     * @notice Authorised address able to call batchDeposit
     */
    address public authority;

    /**
     * @notice Address of ERC20 token
     */
    address public erc20Address;


    mapping(address => uint) balances;
    mapping(address => uint) counts;

    uint public totalSupply;

    constructor(
        address _owner,
        address _authority
    ) public Owned(_owner) {
        authority = _authority;
    }

    function balanceOf(address _address) public view returns (uint) {
        return balances[_address];
    }

    function depositNumberOf(address _address) public view returns (uint) {
        return counts[_address];
    }

    // ========== EXTERNAL SETTERS ==========

    function setTokenAddress(address _erc20Address) public onlyOwner {
        erc20Address = _erc20Address;
    }

    /**
     * @notice Set the address of the contract authorised to call distributeReward()
     * @param _authority Address of the authorised calling contract.
     */
    function setAuthority(address _authority) public onlyOwner {
        authority = _authority;
    }

    function batchDeposit(address[] destinations, uint[] amounts) public returns (bool) {
        require(msg.sender == authority, "Caller is not authorized");
        require(erc20Address != address(0), "erc20 token address is not set");
        require(destinations.length == amounts.length, "length of inputs not match");

        // we don't need check amount[i] > 0 or destinations != 0x0 because they cannot claim anyway
        uint amount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            amount = amount.add(amounts[i]);
            balances[destinations[i]] =  balances[destinations[i]].add(amounts[i]);
            counts[destinations[i]] += 1;
        }

        totalSupply = totalSupply.add(amount);

        emit TokenDeposit(amount);
        return true;
    }

    function claim() public whenNotPaused returns (bool) {
        require(erc20Address != address(0), "erc20 token address is not set");
        require(balances[msg.sender] > 0, "account balance is zero");

        uint _amount = balances[msg.sender];
        require(
            IERC20(erc20Address).balanceOf(address(this)) >= _amount,
            "This contract does not have enough tokens to distribute"
        );

        balances[msg.sender] = 0;
        IERC20(erc20Address).transfer(msg.sender, _amount);
        totalSupply = totalSupply.sub(_amount);

        emit UserClaimed(msg.sender, _amount);
        return true;
    }

    function transfer(address _address, uint _amount) public returns (bool) {
        require(msg.sender == authority, "Caller is not authorized");
        require(erc20Address != address(0), "erc20 token address is not set");
        require(
            IERC20(erc20Address).balanceOf(address(this)) >= _amount,
            "This contract does not have enough tokens to distribute"
        );
        IERC20(erc20Address).transfer(_address, _amount);
        return true;

    }

    /* ========== Events ========== */
    event TokenDeposit(uint _amount);
    event UserClaimed(address _address, uint _amount);
}