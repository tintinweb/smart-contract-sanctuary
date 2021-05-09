/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

pragma solidity >=0.5.0;

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



contract IDOLinearDistribution is Owned, Pausable {
    
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
    mapping(address => uint) remains;

    uint public totalSupply;
    uint public startDate;
    uint public unlockDuration = 276 days;

    constructor(
        address _owner,
        address _authority,
        uint _startDate
    ) public Owned(_owner) {
        authority = _authority;
        startDate = _startDate;
    }

    function lockedBalanceOf(address _address) public view returns (uint) {
        uint bal = balances[_address];
        uint currentTime = block.timestamp;
        if (startDate + unlockDuration <= currentTime) {
            return 0;
        }
        uint rest = startDate + unlockDuration - currentTime;
        if (rest >= unlockDuration) {
            return bal;
        }
        uint locked = bal.mul(rest).div(unlockDuration);
        return locked;
    }

    function balanceOf(address _address) public view returns (uint) {
        return balances[_address];
    }
    
    function remainBalanceOf(address _address) public view returns (uint) {
        return remains[_address];
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

    function batchDeposit(address[] memory destinations, uint[] memory amounts) public returns (bool) {
        require(msg.sender == authority, "Caller is not authorized");
        require(erc20Address != address(0), "erc20 token address is not set");
        require(destinations.length == amounts.length, "length of inputs not match");

        // we don't need check amount[i] > 0 or destinations != 0x0 because they cannot claim anyway
        uint amount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            amount = amount.add(amounts[i]);
            balances[destinations[i]] =  balances[destinations[i]].add(amounts[i]);
            remains[destinations[i]] =  remains[destinations[i]].add(amounts[i]);
        }

        totalSupply = totalSupply.add(amount);

        emit TokenDeposit(amount);
        return true;
    }

    function canWithdraw(address _address) public view returns (uint) {
        uint _amount = remains[_address];
        if (_amount == 0) {
            return 0;
        }
        uint _locked = lockedBalanceOf(_address);
        return  _amount - _locked;
    }

    function claim() public whenNotPaused returns (bool) {
        require(erc20Address != address(0), "erc20 token address is not set");
        require(remains[msg.sender] > 0, "account balance is zero");

        uint _locked = lockedBalanceOf(msg.sender);
        uint _canWithdraw = canWithdraw(msg.sender);

        require(
            _canWithdraw > 0,
            "the amount of token can withdraw is zero"
        );
        require(
            IERC20(erc20Address).balanceOf(address(this)) >= _canWithdraw,
            "This contract does not have enough tokens to distribute"
        );

        remains[msg.sender] = _locked;
        if (_locked == 0) {
            balances[msg.sender] = 0;
        }

        IERC20(erc20Address).transfer(msg.sender, _canWithdraw);
        totalSupply = totalSupply.sub(_canWithdraw);
        emit UserClaimed(msg.sender, _canWithdraw);
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
        emit Transfered(_address, _amount);
        return true;
    }

    /* ========== Events ========== */
    event TokenDeposit(uint _amount);
    event UserClaimed(address _address, uint _amount);
    event Transfered(address _address, uint _amount);
}